extends Node2D

# ─────────────────────────────────────────────────────────────────────────────
# CONSTANTES
# ─────────────────────────────────────────────────────────────────────────────
const INCOME_INTERVAL : float = 12.0
const MAX_QUEUE       : int   = 3
const PLAYER_NAMES    := ["Clover", "Adversaire"]

const UNIT_SCENES := {
	"infantry"   : "res://assets/units/fantassin.tscn",
	"range"      : "res://assets/units/tir_distance.tscn",
	"heavy"      : "res://assets/units/lourd.tscn",
	"anti_armor" : "res://assets/units/anti_blindage.tscn",
	"mortar"     : "res://assets/units/mortier.tscn",
	"support"    : "res://assets/units/soutien.tscn",
	"healer"     : "res://assets/units/soigneur.tscn",
	"spy_yacht"      : "res://assets/units/transport.tscn",
	"woohp_cruiser"  : "res://assets/units/fregate.tscn",
	"shadow_vessel"  : "res://assets/units/destroyer.tscn",
}

const CAMP_CLICK_RADIUS : float = 145.0
const UNIT_CLICK_RADIUS : float = 30.0
const CAMP_CAPTURE_RADIUS : float = 90.0
const UNIT_FORMATION_SPACING : float = 34.0

const BASIC_LAND_UNITS := ["infantry", "range", "support", "healer"]
const ADVANCED_LAND_UNITS := ["heavy", "anti_armor", "mortar"]
const SEA_UNITS := ["spy_yacht", "woohp_cruiser", "shadow_vessel"]

# ─────────────────────────────────────────────────────────────────────────────
# ÉTAT
# ─────────────────────────────────────────────────────────────────────────────
var _camps          : Array = []   # Array[Camp] — nodes du groupe "camps"
var camps           : Array :   # alias public pour minimap.gd
	get: return _camps
var _gold           : Array = [0, 100000, 150]  # index = owner_id (0=neutre,1=j1,2=j2)
var local_player_id: int = 1
var _ai_enabled: bool = false
var _ai_player_id: int = 2
var _ai_timer: float = 0.0
var _ai_interval: float = 3.0
var _selected       : Node  = null # Camp sélectionné
var _map_index      : int   = 0
var _game_over      : bool  = false
var _income_timer   : float = 0.0
var _overlay        : CampOverlay = null
var _selected_units : Array = []
var _drag_start     : Vector2 = Vector2.ZERO
var _drag_end       : Vector2 = Vector2.ZERO
var _is_dragging    : bool = false

var _unit_net_id_seq : int = 1
var _units_by_net_id : Dictionary = {}
var _pending_initial_sync_time : float = 0.0
var _ai_units_per_attack : int = 2
var _ai_recruit_choices : Array = ["infantry", "range"]
var _winner_id : int = 0


# ── Statistiques de fin de partie ────────────────────────────────────────────
var _game_start_time : float = 0.0
var _camps_peak      : Array = [0, 0]   # max camps possédés simultanément
var _income_peak     : Array = [0, 0]
var _units_lost      : Array = [0, 0]

# ─────────────────────────────────────────────────────────────────────────────
# RÉFÉRENCES
# ─────────────────────────────────────────────────────────────────────────────
@onready var _ui : CanvasLayer = $UI

# ─────────────────────────────────────────────────────────────────────────────
# INIT
# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	add_to_group("main_node")
	_ui = $UI
	# Les signaux doivent être connectés AVANT que le splash émette map_selected.
	# UI._ready() tourne avant Main._ready() (enfant avant parent en Godot 4),
	# donc _ui est déjà initialisé ici.
	# Le splash (UI._ready) appelle _on_splash_finished() → start_from_online()
	# → map_selected.emit() → _on_map_selected() → _start_game() ✓
	_connect_ui()


func _connect_ui() -> void:
	if not is_instance_valid(_ui):
		push_error("[Main] nœud UI introuvable")
		return

	_ui.map_selected.connect(_on_map_selected)
	_ui.recruit_pressed.connect(_on_recruit_pressed)

	if _ui.has_signal("end_turn_pressed"):
		_ui.end_turn_pressed.connect(_on_end_turn)

	if _ui.has_signal("squads_selected"):
		_ui.squads_selected.connect(_on_squads_selected)


func _on_map_selected(index: int) -> void:
	_map_index = index
	_start_game()


func _start_game() -> void:
	_game_over = false

	print("[Main] Démarrage de la partie — mode : %s  map : %s" %
		[GameConfig.mode, MapDefs.MAPS[_map_index].get("name", "?")])

	if GameConfig.mode == "multi":
		local_player_id = 1 if GameConfig.is_host else 2
		print("[Main] local_player_id = %d  is_host = %s" % [local_player_id, GameConfig.is_host])
	else:
		local_player_id = 1

	_ai_enabled = (GameConfig.mode == "ai")
	_ai_player_id = 2
	_ai_timer = 0.0
	_configure_ai_difficulty()

	_selected = null
	_clear_unit_selection()
	_units_by_net_id.clear()
	_unit_net_id_seq = 1
	_income_timer = 0.0
	_game_start_time = Time.get_ticks_msec() / 1000.0
	_gold         = [0, 150, 150]
	_camps_peak   = [0, 0]
	_income_peak  = [0, 0]
	_units_lost   = [0, 0]

	for unit in get_tree().get_nodes_in_group("units"):
		if is_instance_valid(unit):
			unit.queue_free()

	for c in _camps:
		if is_instance_valid(c):
			c.queue_free()
	_camps.clear()

	var map_data : Dictionary = MapDefs.MAPS[_map_index]
	var CampScene := load("res://scenes/camp_base.tscn") as PackedScene

	for i in range(map_data["camps"].size()):
		var d : Dictionary = map_data["camps"][i]
		var camp : Node2D = CampScene.instantiate()
		camp.position = d["pos"]
		camp.scale = Vector2(1.45, 1.45)
		camp.z_index = 50
		camp.camp_name = d["name"]
		camp.camp_id = i
		camp.income_value = d["income"]
		camp.is_port = d.get("is_port", false)
		camp.is_neutral_hard = d.get("is_neutral_hard", false)
		camp.unit_type = "infantry"
		camp.production_queue = []
		camp.units = 0
		camp.set_meta("initial_units", max(1, int(d.get("units", 1))))
		if camp.has_signal("camp_empty") and not camp.camp_empty.is_connected(_on_camp_empty):
			camp.camp_empty.connect(_on_camp_empty)
		add_child(camp)
		_camps.append(camp)
		camp.owner_id = int(d.get("owner", 0))

		var camp_color: Color = _get_owner_color(camp.owner_id)

		if camp.has_method("set_team_color"):
			camp.set_team_color(camp_color)

		if camp.has_method("change_owner"):
			camp.change_owner(camp.owner_id, camp_color)

	GameManager.start_game_with_camps(_camps)

	if GameConfig.mode != "multi" or GameConfig.is_host:
		_randomize_camp_owners()
		if GameManager.has_method("_assign_camps_to_players"):
			GameManager._assign_camps_to_players()
		if GameConfig.mode == "multi" and multiplayer.multiplayer_peer != null:
			_broadcast_state()

	if _is_authority():
		for camp in _camps:
			var initial_units : int = int(camp.get_meta("initial_units", 1))
			if camp.is_neutral_hard:
				initial_units = max(initial_units, 5)
			for j in range(initial_units):
				_spawn_unit(camp.unit_type, camp, true)
		if GameConfig.mode == "multi":
			_pending_initial_sync_time = 1.0
			_broadcast_state()

	_refresh_ui()
	if _overlay == null:
		_overlay = CampOverlay.new()
		_overlay.z_index = 100
		add_child(_overlay)
	_overlay.main = self
	_overlay.queue_redraw()

	# En multi, le client annonce à l'hôte qu'il a fini de construire ses camps.
	# L'hôte lui renverra alors l'état complet (évite la course de synchro).
	if GameConfig.mode == "multi" and not GameConfig.is_host and multiplayer.multiplayer_peer != null:
		_rpc_client_ready.rpc_id(1)

func _on_squads_selected(squad1: String, squad2: String) -> void:
	GameConfig.selected_team_ids = [
		_get_team_index_by_name(squad1),
		_get_team_index_by_name(squad2)
	]
	print("[Main] Teams sélectionnées : ", GameConfig.selected_team_ids)


func _get_team_index_by_name(team_name: String) -> int:
	for i in range(GameManager.available_teams.size()):
		var team: Dictionary = GameManager.available_teams[i]
		if team.get("name", "") == team_name:
			return i
	return 0


func _is_authority() -> bool:
	return GameConfig.mode != "multi" or GameConfig.is_host

func _configure_ai_difficulty() -> void:
	_ai_interval = 3.0
	_ai_units_per_attack = 2
	_ai_recruit_choices = ["infantry", "range"]

	match GameConfig.diff:
		"easy":
			_ai_interval = 5.0
			_ai_units_per_attack = 1
			_ai_recruit_choices = ["infantry"]
		"med", "medium":
			_ai_interval = 3.0
			_ai_units_per_attack = 2
			_ai_recruit_choices = ["infantry", "range", "support"]
		"hard":
			_ai_interval = 1.6
			_ai_units_per_attack = 3
			_ai_recruit_choices = ["infantry", "range", "heavy", "anti_armor", "mortar", "support", "healer"]

	print("[Main][IA] Difficulté=", GameConfig.diff,
		" interval=", _ai_interval,
		" units_per_attack=", _ai_units_per_attack,
		" choices=", _ai_recruit_choices)

# ─────────────────────────────────────────────────────────────────────────────
# BOUCLE
# ─────────────────────────────────────────────────────────────────────────────
# ── Sync multijoueur ─────────────────────────────────────────────────────────
const SYNC_INTERVAL : float = 0.5
var _sync_timer     : float = 0.0

func _process(delta: float) -> void:
	if _game_over or _camps.is_empty():
		return
	_camps = _camps.filter(func(c): return is_instance_valid(c))
	if _camps.is_empty():
		return

	var _is_client : bool = GameConfig.mode == "multi" and not GameConfig.is_host

	if not _is_client:
		_income_timer += delta
		if _income_timer >= INCOME_INTERVAL:
			_income_timer = 0.0
			_distribute_income()
			for p in [1, 2]:
				var idx : int = p - 1
				var cnt : int = 0
				var inc : int = 0
				for c in _camps:
					if c.owner_id == p:
						cnt += 1
						inc += c.income_value
				if cnt > _camps_peak[idx]:  _camps_peak[idx]  = cnt
				if inc > _income_peak[idx]: _income_peak[idx] = inc

		if GameConfig.mode == "multi":
			_sync_timer += delta
			if _sync_timer >= SYNC_INTERVAL:
				_sync_timer = 0.0
				_broadcast_state()

		for camp in _camps:
			if camp.production_queue.is_empty():
				continue
			var entry : Dictionary = camp.production_queue[0]
			entry["remaining"] -= delta
			if entry["remaining"] <= 0.0:
				camp.production_queue.pop_front()
				_spawn_unit(entry["unit_type"], camp, true)
				_log("Unité produite à %s" % camp.camp_name)
				if not camp.production_queue.is_empty():
					camp.production_queue[0]["remaining"] = _build_time(camp.production_queue[0]["unit_type"])
				_refresh_ui()

	if _is_authority():
		_process_unit_camp_orders()

	if _is_authority() and _ai_enabled:
		_ai_timer += delta
		if _ai_timer >= _ai_interval:
			_ai_timer = 0.0
			_run_ai_tick()

	if _pending_initial_sync_time > 0.0 and _is_authority():
		_pending_initial_sync_time -= delta
		_broadcast_state()

	if _overlay:
		_overlay.queue_redraw()

# ─────────────────────────────────────────────────────────────────────────────
# INPUT
# ─────────────────────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if _game_over or _camps.is_empty():
		return

	if event is InputEventMouseButton and _is_mouse_over_clickable_ui():
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		var world_pos : Vector2 = get_global_mouse_position()

		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_drag_start = world_pos
				_drag_end = world_pos
				_is_dragging = false
			else:
				_drag_end = world_pos
				if _is_dragging or _drag_start.distance_to(_drag_end) > 12.0:
					_select_units_in_rect(_drag_start, _drag_end)
				else:
					_handle_left_click(world_pos, mb.shift_pressed)
				_is_dragging = false
				queue_redraw()
			return

		if mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			_handle_right_click(world_pos)
			return

	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_drag_end = get_global_mouse_position()
		if _drag_start.distance_to(_drag_end) > 12.0:
			_is_dragging = true
			queue_redraw()

func _is_mouse_over_clickable_ui() -> bool:
	var hovered: Control = get_viewport().gui_get_hovered_control()

	if hovered == null:
		return false

	if hovered is BaseButton:
		return true

	if hovered is Slider:
		return true

	if hovered is LineEdit:
		return true

	var node: Node = hovered
	while node != null:
		if node.name.to_lower().contains("recruit"):
			return true
		if node.name.to_lower().contains("button"):
			return true
		node = node.get_parent()

	return false

func _handle_left_click(pos: Vector2, shift_held: bool = false) -> void:
	var clicked_owned_camp: Node = _get_owned_camp_at(pos)

	if clicked_owned_camp != null:
		_select(clicked_owned_camp)
		if not shift_held:
			_clear_unit_selection()
		return

	var clicked_unit := _get_unit_at(pos)

	if clicked_unit != null and clicked_unit.can_be_controlled_by(local_player_id):
		if not shift_held:
			_clear_unit_selection()
		_toggle_unit_selection(clicked_unit)
		_deselect()
		return

	var clicked_camp: Node = _get_camp_at(pos)

	if clicked_camp != null:
		if clicked_camp.owner_id == 0:
			_log("Camp neutre : envoyez des unités pour le capturer.")
		else:
			_log("Camp adverse : envoyez des unités pour l'attaquer.")
		return

	if not shift_held:
		_clear_unit_selection()
		_deselect()

func _handle_right_click(pos: Vector2) -> void:
	if _selected_units.is_empty():
		return

	var target_camp : Node = _get_camp_at(pos)

	if GameConfig.mode == "multi" and not GameConfig.is_host:
		var unit_ids : Array = []
		for unit in _selected_units:
			if is_instance_valid(unit) and unit.can_be_controlled_by(local_player_id):
				unit_ids.append(_get_unit_net_id(unit))
		var camp_idx : int = _camps.find(target_camp) if target_camp != null else -1
		_rpc_request_unit_order.rpc(unit_ids, camp_idx, pos, target_camp != null, local_player_id)
		return

	if target_camp != null:
		_order_units_to_camp(_selected_units, target_camp)
	else:
		_order_units_to_position(_selected_units, pos)

func _get_camp_at(pos: Vector2) -> Node:
	var nearest : Node = null
	var nearest_dist : float = INF

	for camp in _camps:
		if not is_instance_valid(camp):
			continue

		var dist: float = camp.global_position.distance_to(pos)

		if dist <= CAMP_CLICK_RADIUS and dist < nearest_dist:
			nearest = camp
			nearest_dist = dist

	return nearest

func _get_owned_camp_at(pos: Vector2) -> Node:
	var nearest: Node = null
	var nearest_dist: float = INF

	for camp in _camps:
		if not is_instance_valid(camp):
			continue

		if camp.owner_id != local_player_id:
			continue

		var dist: float = camp.global_position.distance_to(pos)

		if dist <= CAMP_CLICK_RADIUS and dist < nearest_dist:
			nearest = camp
			nearest_dist = dist

	return nearest

func _get_unit_at(pos: Vector2) -> Unit:
	var nearest : Unit = null
	var nearest_dist : float = INF
	for unit in get_tree().get_nodes_in_group("units"):
		if unit is Unit and unit.is_alive:
			var dist : float = unit.global_position.distance_to(pos)
			if dist <= UNIT_CLICK_RADIUS and dist < nearest_dist:
				nearest = unit
				nearest_dist = dist
	return nearest

func _select_units_in_rect(a: Vector2, b: Vector2) -> void:
	var rect := Rect2(Vector2(minf(a.x, b.x), minf(a.y, b.y)), Vector2(absf(a.x - b.x), absf(a.y - b.y)))
	_clear_unit_selection()
	for unit in get_tree().get_nodes_in_group("units"):
		if unit is Unit and unit.can_be_controlled_by(local_player_id) and rect.has_point(unit.global_position):
			_add_unit_selection(unit)
	_log("%d unité(s) sélectionnée(s)" % _selected_units.size())

func _toggle_unit_selection(unit: Unit) -> void:
	if _selected_units.has(unit):
		_remove_unit_selection(unit)
	else:
		_add_unit_selection(unit)

func _add_unit_selection(unit: Unit) -> void:
	if _selected_units.has(unit):
		return
	_selected_units.append(unit)
	if unit.has_method("select"):
		unit.select()
	if _ui and _ui.has_method("update_selection_panel"):
		_ui.update_selection_panel(_selected_units)

func _remove_unit_selection(unit: Unit) -> void:
	if not _selected_units.has(unit):
		return
	_selected_units.erase(unit)
	if is_instance_valid(unit) and unit.has_method("deselect"):
		unit.deselect()
	if _ui and _ui.has_method("update_selection_panel"):
		_ui.update_selection_panel(_selected_units)

func _clear_unit_selection() -> void:
	for unit in _selected_units:
		if is_instance_valid(unit) and unit.has_method("deselect"):
			unit.deselect()
	_selected_units.clear()
	if _ui and _ui.has_method("update_selection_panel"):
		_ui.update_selection_panel(_selected_units)

func _order_units_to_position(units_list: Array, target_pos: Vector2, controller_id: int = -1) -> void:
	var ctrl_id: int = controller_id if controller_id > 0 else local_player_id
	for i in range(units_list.size()):
		var unit = units_list[i]
		if not is_instance_valid(unit) or not unit.can_be_controlled_by(ctrl_id):
			continue
		_detach_unit_from_home(unit)
		unit.clear_target_camp()
		unit.move_to(target_pos + _formation_offset(i, units_list.size()))

func _order_units_to_camp(units_list: Array, target_camp: Node, controller_id: int = -1) -> void:
	var ctrl_id: int = controller_id if controller_id > 0 else local_player_id
	for i in range(units_list.size()):
		var unit = units_list[i]
		if not is_instance_valid(unit) or not unit.can_be_controlled_by(ctrl_id):
			continue
		_detach_unit_from_home(unit)
		unit.move_to_camp(target_camp, _formation_offset(i, units_list.size()))
	if target_camp.owner_id == ctrl_id:
		_log("Déplacement vers %s" % target_camp.camp_name)
	else:
		_log("Attaque de %s" % target_camp.camp_name)

func _formation_offset(index: int, total: int) -> Vector2:
	var per_row: int = 4
	var row: int = index / per_row
	var col: int = index % per_row
	var row_count: int = mini(total - row * per_row, per_row)

	var x: float = (float(col) - float(row_count - 1) / 2.0) * 26.0
	var y: float = (float(row) - float(ceili(float(total) / float(per_row)) - 1) / 2.0) * 26.0

	return Vector2(x, y)

func _detach_unit_from_home(unit: Unit) -> void:
	if unit.home_camp != null and is_instance_valid(unit.home_camp):
		if unit.home_camp.has_method("unregister_unit"):
			unit.home_camp.unregister_unit(unit, true)
	unit.home_camp = null

func _select(camp: Node) -> void:
	_selected = camp
	_ui.show_recruit(camp)
	_log("%s sélectionné" % camp.camp_name)
	_refresh_ui()
	if _overlay: _overlay.queue_redraw()

func _deselect() -> void:
	_selected = null
	_ui.hide_recruit()
	_refresh_ui()
	if _overlay: _overlay.queue_redraw()

func _draw() -> void:
	if _is_dragging:
		var rect := Rect2(Vector2(minf(_drag_start.x, _drag_end.x), minf(_drag_start.y, _drag_end.y)), Vector2(absf(_drag_start.x - _drag_end.x), absf(_drag_start.y - _drag_end.y)))
		draw_rect(rect, Color(0.2, 0.8, 1.0, 0.15), true)
		draw_rect(rect, Color(0.2, 0.8, 1.0, 0.75), false, 2.0)

func _get_owner_color(owner_id: int) -> Color:
	if owner_id == 0:
		return Color(0.55, 0.55, 0.55)

	var color: Color = Color.WHITE

	if GameManager and GameManager.has_method("get_team_color"):
		color = GameManager.get_team_color(owner_id)
	else:
		var player = GameManager.find_player_by_id(owner_id)
		if player and "color" in player:
			color = player.color

	if color == Color.WHITE:
		if owner_id == 1:
			color = Color(0.22, 0.45, 0.90)
		elif owner_id == 2:
			color = Color(0.88, 0.22, 0.22)

	if color.r < 0.12 and color.g < 0.12 and color.b < 0.12:
		color = Color(0.45, 0.45, 0.70)

	return color


# ─────────────────────────────────────────────────────────────────────────────
# COMBAT
# L attaquant calcule le résultat (randi unique) et envoie le résultat exact
# à tous les peers. Pas de recalcul côté client (évite la divergence rng).
# ─────────────────────────────────────────────────────────────────────────────
func _do_attack(src: Node, tgt: Node, deselect_after: bool = true) -> void:
	var src_idx : int = _camps.find(src)
	var tgt_idx : int = _camps.find(tgt)
	var old_owner : int = tgt.owner_id

	# Calcul local (aléatoire, une seule fois chez l attaquant)
	Combat.resolve(src, tgt)

	# En multi : envoyer le RÉSULTAT (pas les paramètres) à tous les peers
	if GameConfig.mode == "multi" and multiplayer.multiplayer_peer != null:
		_rpc_sync_attack_result.rpc(
			src_idx, tgt_idx,
			src.owner_id, src.units, src.unit_type,
			tgt.owner_id, tgt.units, tgt.unit_type
		)

	var captured : bool = (tgt.owner_id != old_owner)
	if captured:
		_log("✓ %s capturé !" % tgt.camp_name)
		_check_victory()
	else:
		_log("✗ Attaque sur %s repoussée" % tgt.camp_name)
	if deselect_after:
		_deselect()
	if _overlay: _overlay.queue_redraw()


@rpc("any_peer", "reliable")
func _rpc_sync_attack_result(
		src_idx: int, tgt_idx: int,
		src_owner: int, src_units: int, src_type: String,
		tgt_owner: int, tgt_units: int, tgt_type: String) -> void:
	# Le peer distant applique directement le résultat reçu (sans recalcul rng)
	if src_idx < 0 or src_idx >= _camps.size(): return
	if tgt_idx < 0 or tgt_idx >= _camps.size(): return
	var src = _camps[src_idx]
	var tgt = _camps[tgt_idx]
	var old_owner : int = tgt.owner_id

	src.units     = src_units
	src.unit_type = src_type
	src.owner_id  = src_owner

	var new_owner_different : bool = (tgt_owner != old_owner)
	if new_owner_different and tgt.has_method("change_owner"):
		tgt.change_owner(tgt_owner)
	else:
		tgt.owner_id = tgt_owner
	tgt.units     = tgt_units
	tgt.unit_type = tgt_type
	if new_owner_different:
		tgt.production_queue = []

	if new_owner_different:
		_log("✓ %s capturé !" % tgt.camp_name)
		_check_victory()
	else:
		_log("✗ Attaque repoussée")
	if _overlay: _overlay.queue_redraw()


func _camp_to_dict(camp: Node) -> Dictionary:
	return {
		"name"     : camp.camp_name,
		"camp_name": camp.camp_name,
		"pos"      : camp.global_position,
		"owner"    : camp.owner_id,
		"owner_id" : camp.owner_id,
		"units"    : camp.units,
		"income"   : camp.income_value,
		"unit_type": camp.unit_type,
		"type"     : "port" if camp.is_port else "normal",
		"queue"    : camp.production_queue,
		"color"    : _get_owner_color(camp.owner_id)
	}


#ia
func _run_ai_tick() -> void:
	if _game_over:
		return

	var ai_player = GameManager.find_player_by_id(_ai_player_id)
	if ai_player == null:
		print("[AI DEBUG] Joueur IA introuvable")
		return

	var ai_camps: Array = []
	var targets: Array = []

	for camp in _camps:
		if camp.owner_id == _ai_player_id:
			ai_camps.append(camp)
		else:
			targets.append(camp)

	print("[AI DEBUG] camps IA = ", ai_camps.size(), " | targets = ", targets.size())

	if ai_camps.is_empty() or targets.is_empty():
		return

	_ai_recruit(ai_player, ai_camps)
	_ai_attack(ai_camps, targets)


func _ai_recruit(ai_player, ai_camps: Array) -> void:
	var unit_choices: Array = _ai_recruit_choices.duplicate()
	var available_camps: Array = []
	for camp in ai_camps:
		if camp.production_queue.size() < MAX_QUEUE:
			available_camps.append(camp)
	if available_camps.is_empty():
		return
	var camp = available_camps.pick_random()
	if camp.has_method("get_available_unit_types"):
		unit_choices = camp.get_available_unit_types()
	var affordable_units: Array = []
	for unit_type in unit_choices:
		var price: int = UnitDefs.TYPES.get(unit_type, {}).get("price", 50)
		if ai_player.gold >= price:
			affordable_units.append(unit_type)
	if affordable_units.is_empty():
		return
	var chosen_unit: String = affordable_units.pick_random()
	var price: int = UnitDefs.TYPES.get(chosen_unit, {}).get("price", 50)
	if not ai_player.spend_gold(price):
		return
	camp.production_queue.append({"unit_type": chosen_unit, "remaining": _build_time(chosen_unit)})
	camp.unit_type = chosen_unit
	_log("IA recrute %s à %s" % [chosen_unit, camp.camp_name])
	_refresh_ui()

func _ai_attack(ai_camps: Array, targets: Array) -> void:
	var possible_attackers: Array = []
	for camp in ai_camps:
		if camp.has_method("get_available_garrison") and camp.get_available_garrison().size() > 1:
			possible_attackers.append(camp)
	if possible_attackers.is_empty():
		return
	var attacker = possible_attackers.pick_random()
	var target = _ai_find_best_target(attacker, targets)
	if target == null:
		return
	var send_count: int = mini(_ai_units_per_attack, attacker.get_available_garrison().size() - 1)
	var units_to_send: Array = attacker.get_available_garrison().slice(0, send_count)
	for unit in units_to_send:
		_detach_unit_from_home(unit)
		unit.move_to_camp(target, Vector2(randf_range(-30, 30), randf_range(-30, 30)))
	_log("IA envoie %d unité(s) vers %s" % [units_to_send.size(), target.camp_name])

func _ai_find_best_target(attacker: Node, targets: Array) -> Node:
	var best_target: Node = null
	var best_score: float = INF

	for target in targets:
		if target == null:
			continue

		if target.owner_id == _ai_player_id:
			continue

		var distance: float = attacker.global_position.distance_to(target.global_position)
		var defense_score: float = float(target.units) * 40.0
		var neutral_penalty: float = 0.0

		if target.owner_id == 0:
			neutral_penalty = 80.0

		var score: float = distance + defense_score + neutral_penalty

		if score < best_score:
			best_score = score
			best_target = target

	return best_target
# ─────────────────────────────────────────────────────────────────────────────
# RECRUTEMENT
# ─────────────────────────────────────────────────────────────────────────────
func _on_recruit_pressed(unit_type: String) -> void:
	print("[Main] Recrutement demandé : %s" % unit_type)
	if _selected == null:
		_log("Sélectionnez d'abord un camp !")
		return
	if _selected.owner_id != local_player_id:
		_log("Ce camp ne vous appartient pas !")
		return

	var camp_idx : int = _camps.find(_selected)

	if GameConfig.mode == "multi" and not GameConfig.is_host:
		_rpc_request_recruit.rpc(camp_idx, unit_type, local_player_id)
		return

	_perform_recruit(local_player_id, camp_idx, unit_type)


@rpc("any_peer", "reliable")
func _rpc_request_recruit(camp_idx: int, unit_type: String, player_id: int) -> void:
	if not GameConfig.is_host:
		return
	_perform_recruit(player_id, camp_idx, unit_type)
	_broadcast_state()


func _perform_recruit(player_id: int, camp_idx: int, unit_type: String) -> void:
	if camp_idx < 0 or camp_idx >= _camps.size():
		return

	var camp : Node = _camps[camp_idx]

	if camp.owner_id != player_id:
		_log("Ce camp ne vous appartient pas !")
		return

	if not _can_recruit_unit_at_camp(camp, unit_type):
		_log("Cette unité n'est pas disponible dans ce camp.")
		return

	if camp.production_queue.size() >= MAX_QUEUE:
		_log("File pleine !")
		return

	var price: int = UnitDefs.TYPES.get(unit_type, {}).get("price", 50)
	var player = GameManager.find_player_by_id(player_id)

	if player == null or not player.spend_gold(price):
		_log("Pas assez d or ! (%d requis)" % price)
		return

	if player_id < _gold.size():
		_gold[player_id] = player.gold

	_resolve_recruit(camp_idx, unit_type)


@rpc("any_peer", "reliable")
func _rpc_recruit(camp_idx: int, unit_type: String) -> void:
	if not GameConfig.is_host:
		return
	_perform_recruit(local_player_id, camp_idx, unit_type)


func _resolve_recruit(camp_idx: int, unit_type: String) -> void:
	if camp_idx < 0 or camp_idx >= _camps.size():
		return

	var camp : Node = _camps[camp_idx]
	camp.production_queue.append({"unit_type": unit_type, "remaining": _build_time(unit_type)})
	camp.unit_type = unit_type
	_log("%s ajouté à la file de %s" % [unit_type, camp.camp_name])
	_refresh_ui()

func _can_recruit_unit_at_camp(camp: Node, unit_type: String) -> bool:
	if camp == null:
		return false
	if camp.has_method("get_available_unit_types"):
		return camp.get_available_unit_types().has(unit_type)
	if camp.is_port:
		return SEA_UNITS.has(unit_type)
	if camp.is_neutral_hard and camp.owner_id != 0:
		return ADVANCED_LAND_UNITS.has(unit_type)
	return BASIC_LAND_UNITS.has(unit_type)

# =============================================================================
#  ASSIGNATION ALÉATOIRE DES CAMPS
#  Règle sujet : chaque joueur reçoit le même nombre de camps aléatoirement,
#  sans qu aucun joueur ne possède une région entière dès le départ.
# =============================================================================
func _randomize_camp_owners() -> void:
	if _camps.size() < 2:
		return

	for camp in _camps:
		if not is_instance_valid(camp):
			continue
		_set_camp_owner(camp, 0)

	var start_pair: Array = _pick_random_start_camps()

	if start_pair.size() < 2:
		return

	var p1_start: Node = start_pair[0]
	var p2_start: Node = start_pair[1]

	_set_camp_owner(p1_start, 1)
	_set_camp_owner(p2_start, 2)

	print("[Main] Camp départ joueur : ", p1_start.camp_name)
	print("[Main] Camp départ adversaire : ", p2_start.camp_name)

	_refresh_ui()
	if _overlay:
		_overlay.queue_redraw()


func _pick_random_start_camps() -> Array:
	var valid_camps: Array = []

	for camp in _camps:
		if not is_instance_valid(camp):
			continue
		if camp.is_port:
			continue
		if camp.is_neutral_hard:
			continue
		valid_camps.append(camp)

	if valid_camps.size() < 2:
		return []

	valid_camps.shuffle()

	var min_distance: float = 420.0
	var best_pair: Array = []
	var best_distance: float = 0.0

	for i in range(valid_camps.size()):
		for j in range(i + 1, valid_camps.size()):
			var a: Node = valid_camps[i]
			var b: Node = valid_camps[j]
			var dist: float = a.global_position.distance_to(b.global_position)

			if dist >= min_distance:
				return [a, b]

			if dist > best_distance:
				best_distance = dist
				best_pair = [a, b]

	return best_pair


func _set_camp_owner(camp: Node, new_owner_id: int) -> void:
	if not is_instance_valid(camp):
		return

	var new_color: Color = _get_owner_color(new_owner_id)

	if camp.has_method("change_owner"):
		camp.change_owner(new_owner_id, new_color)
	else:
		camp.owner_id = new_owner_id

	if camp.has_method("set_team_color"):
		camp.set_team_color(new_color)

	if _overlay:
		_overlay.queue_redraw()

func _fix_complete_regions(regions: Array) -> void:
	for region in regions:
		var camp_indices : Array = region.get("camps", [])
		if camp_indices.size() < 2:
			continue
		# Vérifier si tous les camps de la région ont le même propriétaire non-neutre
		var first_owner : int = _camps[camp_indices[0]].owner_id
		if first_owner == 0:
			continue
		var all_same : bool = true
		for ci in camp_indices:
			if ci >= _camps.size() or _camps[ci].owner_id != first_owner:
				all_same = false
				break
		if all_same:
			# Rendre le dernier camp de la région neutre pour casser le bonus
			var last_ci : int = camp_indices[camp_indices.size() - 1]
			var camp    = _camps[last_ci]
			camp.owner_id = 0
			if camp.has_method("change_owner"):
				camp.change_owner(0)
			print("[Main] Région '%s' brisée — camp %d → neutre" % [region.get("name","?"), last_ci])


# =============================================================================
#  SYNC MULTIJOUEUR — broadcast d état complet depuis l hote
# =============================================================================

func _broadcast_state() -> void:
	if GameConfig.mode != "multi" or not GameConfig.is_host:
		return

	var state: Dictionary = _make_sync_state()
	_rpc_receive_full_state.rpc(state)


@rpc("any_peer", "reliable")
func _rpc_client_ready() -> void:
	# Appelé par le client quand ses camps sont construits → on lui pousse l'état.
	if not GameConfig.is_host:
		return
	_broadcast_state()

func _make_sync_state() -> Dictionary:
	var camps_data : Array = []
	for i in range(_camps.size()):
		var c = _camps[i]
		if not is_instance_valid(c):
			continue

		camps_data.append({
			"i": i,
			"own": c.owner_id,
			"u": c.units,
			"ut": c.unit_type,
			"q": c.production_queue.duplicate(true),
		})

	var units_data : Array = []
	for unit in get_tree().get_nodes_in_group("units"):
		if not (unit is Unit) or not is_instance_valid(unit):
			continue

		var uid: int = _get_unit_net_id(unit)
		if uid <= 0:
			continue

		var home_idx: int = _camps.find(unit.home_camp) if is_instance_valid(unit.home_camp) else -1
		var target_idx: int = _camps.find(unit.target_camp) if is_instance_valid(unit.target_camp) else -1

		units_data.append({
			"id": uid,
			"type": unit.unit_type_key,
			"owner": unit.owner_id,
			"pos": unit.global_position,
			"hp": unit.hp,
			"alive": unit.is_alive,
			"home": home_idx,
			"target": target_idx,
		})

	return {
		"camps": camps_data,
		"units": units_data,
		"gold": _gold.duplicate(),
		"winner": _winner_id if _game_over else 0,
	}


@rpc("any_peer", "reliable")
func _rpc_receive_full_state(state: Dictionary) -> void:
	if GameConfig.is_host:
		return
	_apply_sync_state(state)


func _apply_sync_state(state: Dictionary) -> void:
	# Le 1er état de l'hôte peut arriver avant que _start_game ait construit nos
	# camps côté client. Dans ce cas on ignore : le prochain broadcast suivra.
	if _camps.is_empty():
		return
	if state.has("gold"):
		var gold_data: Array = state["gold"]
		if gold_data.size() == _gold.size():
			_gold = gold_data.duplicate()
			for p_id in range(_gold.size()):
				var player = GameManager.find_player_by_id(p_id)
				if player:
					player.gold = int(_gold[p_id])

	for cd in state.get("camps", []):
		var idx: int = int(cd.get("i", -1))
		if idx < 0 or idx >= _camps.size():
			continue

		var camp = _camps[idx]
		if not is_instance_valid(camp):
			continue

		var new_owner: int = int(cd.get("own", 0))
		if camp.owner_id != new_owner:
			_set_camp_owner(camp, new_owner)
		else:
			camp.owner_id = new_owner

		camp.units = int(cd.get("u", camp.units))
		camp.unit_type = String(cd.get("ut", camp.unit_type))
		camp.production_queue = cd.get("q", []).duplicate(true)
	# Recalcule owned_camps de chaque joueur d'après les propriétaires
	# synchronisés, sinon le panneau "X camps" du client reste figé sur
	# l'état initial de la map (ex. affiche 2 camps au lieu de 1).
	if GameManager and GameManager.has_method("_assign_camps_to_players"):
		GameManager._assign_camps_to_players()

	var seen_units: Dictionary = {}

	for ud in state.get("units", []):
		var uid: int = int(ud.get("id", -1))
		if uid <= 0:
			continue

		seen_units[uid] = true

		# is_instance_valid() gère à la fois null ET une instance libérée.
		# On n'utilise JAMAIS "!= null" ici : en Godot 4 une instance libérée
		# peut être considérée == null, ce qui laisserait passer une instance
		# morte vers la variable typée `unit` → crash "freed instance".
		var stored = _units_by_net_id.get(uid, null)
		var unit: Unit = null
		if is_instance_valid(stored):
			unit = stored
		else:
			_units_by_net_id.erase(uid)

		if unit == null:
			var camp_idx: int = int(ud.get("home", -1))
			var fallback_camp: Node = null
			if camp_idx >= 0 and camp_idx < _camps.size() and is_instance_valid(_camps[camp_idx]):
				fallback_camp = _camps[camp_idx]
			else:
				for c in _camps:
					if is_instance_valid(c):
						fallback_camp = c
						break
			if fallback_camp == null:
				continue
			unit = _spawn_unit(String(ud.get("type", "infantry")), fallback_camp, false, uid, true)

		if unit == null or not is_instance_valid(unit):
			continue

		unit.owner_id = int(ud.get("owner", 0))
		unit.unit_type_key = String(ud.get("type", unit.unit_type_key))
		unit.global_position = ud.get("pos", unit.global_position)
		unit.hp = float(ud.get("hp", unit.hp))
		unit.is_alive = bool(ud.get("alive", true))

		var home_idx: int = int(ud.get("home", -1))
		if home_idx >= 0 and home_idx < _camps.size() and is_instance_valid(_camps[home_idx]):
			unit.home_camp = _camps[home_idx]
		else:
			unit.home_camp = null

		var target_idx: int = int(ud.get("target", -1))
		if target_idx >= 0 and target_idx < _camps.size() and is_instance_valid(_camps[target_idx]):
			unit.target_camp = _camps[target_idx]
		else:
			unit.target_camp = null

		if unit.has_method("_update_hp_bar"):
			unit._update_hp_bar()

	var to_remove: Array = []
	for uid in _units_by_net_id.keys():
		if not seen_units.has(uid):
			to_remove.append(uid)

	for uid in to_remove:
		var dead = _units_by_net_id.get(uid, null)
		_units_by_net_id.erase(uid)
		if is_instance_valid(dead):
			dead.queue_free()

	var winner: int = int(state.get("winner", 0))
	if winner > 0 and not _game_over:
		_show_end_game_for_winner(winner)

	_refresh_ui()
	if _overlay:
		_overlay.queue_redraw()


func _get_unit_net_id(unit: Node) -> int:
	if unit == null or not is_instance_valid(unit):
		return -1

	if unit.has_meta("net_id"):
		return int(unit.get_meta("net_id"))

	if not _is_authority():
		return -1

	var uid: int = _unit_net_id_seq
	_unit_net_id_seq += 1
	unit.set_meta("net_id", uid)
	_units_by_net_id[uid] = unit
	return uid


func _setup_network_proxy(unit: Unit) -> void:
	unit.set_physics_process(false)
	unit.set_process(false)
	if unit.attack_timer:
		unit.attack_timer.stop()
	if unit.range_area:
		unit.range_area.monitoring = false
		unit.range_area.monitorable = false


@rpc("any_peer", "reliable")
func _rpc_request_unit_order(unit_ids: Array, camp_idx: int, target_pos: Vector2, has_camp: bool, player_id: int) -> void:
	if not GameConfig.is_host:
		return

	var units_list: Array = []
	for uid in unit_ids:
		var stored = _units_by_net_id.get(int(uid), null)
		if is_instance_valid(stored) and stored.owner_id == player_id and stored.is_alive:
			units_list.append(stored)

	if units_list.is_empty():
		return

	if has_camp and camp_idx >= 0 and camp_idx < _camps.size():
		_order_units_to_camp(units_list, _camps[camp_idx], player_id)
	else:
		_order_units_to_position(units_list, target_pos, player_id)

	_broadcast_state()


func _build_time(unit_type: String) -> float:
	return UnitDefs.TYPES.get(unit_type, {}).get("build_time", 5.0)


func _on_end_turn() -> void:
	pass


# ─────────────────────────────────────────────────────────────────────────────
# REVENUS
# ─────────────────────────────────────────────────────────────────────────────
func _distribute_income() -> void:
	if GameConfig.mode == "multi" and not GameConfig.is_host:
		return
	var regions : Array = MapDefs.MAPS[_map_index].get("regions", [])
	for p_id in [1, 2]:
		var inc : int = 0
		for c in _camps:
			if c.owner_id == p_id:
				inc += c.income_value
		for region in regions:
			if _region_owner(region["camps"]) == p_id:
				inc += region["bonus"]
		var player = GameManager.find_player_by_id(p_id)
		if player:
			player.add_gold(inc)
		if p_id < _gold.size():
			_gold[p_id] = player.gold if player else _gold[p_id] + inc
		_log("Joueur %d +%d or" % [p_id, inc])
	_refresh_ui()

func _region_owner(camp_indices: Array) -> int:
	if camp_indices.is_empty():
		return -1
	var owner : int = -2
	for i in camp_indices:
		if i >= _camps.size():
			return -1
		if not is_instance_valid(_camps[i]):
			return -1
		var o : int = _camps[i].owner_id
		if owner == -2:
			owner = o
		elif o != owner:
			return -1
	return owner if owner != -2 else -1


# ─────────────────────────────────────────────────────────────────────────────
# VICTOIRE
# ─────────────────────────────────────────────────────────────────────────────
@rpc("any_peer", "reliable")
func _rpc_show_end_game(winner: int) -> void:
	if _game_over:
		return
	_show_end_game_for_winner(winner)


func _check_victory() -> void:
	var p1_has_camp := false
	var p2_has_camp := false
	for c in _camps:
		if not is_instance_valid(c):
			continue
		if c.owner_id == 1:   p1_has_camp = true
		elif c.owner_id == 2: p2_has_camp = true
	if not p1_has_camp:   _end_game(2)  # joueur 2 gagne
	elif not p2_has_camp: _end_game(1)  # joueur 1 gagne


func _get_winner_id() -> int:
	for p in [1, 2]:
		for c in _camps:
			if is_instance_valid(c) and c.owner_id == p:
				return p
	return 0


func _show_end_game_for_winner(winner: int, winner_stats: Dictionary = {}) -> void:
	_game_over = true
	_winner_id = winner
	var winner_player = GameManager.find_player_by_id(winner)
	var winner_name: String

	if winner_player == null:
		winner_name = "Joueur %d" % winner
	elif winner_player.is_ai:
		var _dn : Array = ["IA", "IA — " + UIUtils.lt("diff_easy"), "IA — " + UIUtils.lt("diff_med"), "IA — " + UIUtils.lt("diff_hard")]
		winner_name = _dn[winner_player.ai_level] if winner_player.ai_level < _dn.size() else "IA"
	else:
		winner_name = winner_player.player_name

	if GameConfig.mode == "multi" and GameConfig.token != "":
		Matchmaker.update_stats(GameConfig.token, winner == local_player_id)

	_ui.show_victory(winner_name, winner_stats)


func _end_game(winner: int) -> void:
	if _game_over:
		return
	_game_over = true
	_winner_id = winner
	# Sync l écran de fin sur tous les peers
	if GameConfig.mode == "multi" and multiplayer.multiplayer_peer != null:
		_rpc_show_end_game.rpc(winner)

	# ── Calcul des stats finales ──────────────────────────────────────────────
	var now: float = Time.get_ticks_msec() / 1000.0
	var duration: float = now - _game_start_time

	var camps_final: int = 0
	var income_final: int = 0

	for c in _camps:
		if c.owner_id == winner:
			camps_final += 1
			income_final += c.income_value

	# Comme les joueurs sont maintenant 1 et 2,
	# mais les tableaux commencent à 0, on convertit.
	var winner_index: int = winner - 1

	var camps_peak: int = 0
	var income_peak: int = 0
	var units_lost: int = 0

	if winner_index >= 0 and winner_index < _camps_peak.size():
		camps_peak = _camps_peak[winner_index]

	if winner_index >= 0 and winner_index < _income_peak.size():
		income_peak = _income_peak[winner_index]

	if winner_index >= 0 and winner_index < _units_lost.size():
		units_lost = _units_lost[winner_index]

	var winner_stats: Dictionary = {
		"duration_sec": duration,
		"camps_peak": camps_peak,
		"camps_final": camps_final,
		"income_peak": income_peak,
		"income_final": income_final,
		"units_lost": units_lost,
	}

	var winner_player = GameManager.find_player_by_id(winner)
	var winner_name: String
	if winner_player == null:
		winner_name = "Joueur %d" % winner
	elif winner_player.is_ai:
		var _dn : Array = ["IA", "IA — " + UIUtils.lt("diff_easy"), "IA — " + UIUtils.lt("diff_med"), "IA — " + UIUtils.lt("diff_hard")]
		winner_name = _dn[winner_player.ai_level] if winner_player.ai_level < _dn.size() else "IA"
	else:
		winner_name = winner_player.player_name

	_show_end_game_for_winner(winner, winner_stats)
	if GameConfig.mode == "multi" and GameConfig.is_host:
		_broadcast_state()

# ─────────────────────────────────────────────────────────────────────────────
# UI
# ─────────────────────────────────────────────────────────────────────────────
func _refresh_ui() -> void:
	var inc: int = 0
	var cnt: int = 0

	for c in _camps:
		if c.owner_id == local_player_id:
			inc += c.income_value
			cnt += 1

	var sel_unit: String = _selected.unit_type if _selected else ""

	var player = GameManager.find_player_by_id(local_player_id)
	var player_name: String = player.player_name if player else "Joueur"
	var player_gold: int = player.gold if player else 0

	# Le 2e paramètre doit rester un int.
	# On met 0 pour remplacer l'ancien tour.
	_ui.update_hud(player_name, 0, player_gold, inc, cnt, sel_unit, "", local_player_id)

	_refresh_leaderboard()


func _refresh_leaderboard() -> void:
	# Délègue au HUD — évite la duplication et les doublons dus à queue_free() asynchrone
	if _ui and _ui.has_method("refresh_leaderboard"):
		_ui.refresh_leaderboard()
		return

	# Fallback manuel si le HUD n'est pas dispo (ne devrait pas arriver)
	var hud : CanvasLayer = _ui.hud
	if not hud:
		return
	var lb : Node = hud.leaderboard_container
	if not lb:
		return

	# Suppression synchrone
	for c in lb.get_children():
		lb.remove_child(c)
		c.free()

	var COLORS := {1: _get_owner_color(1), 2: _get_owner_color(2)}

	for p in [1, 2]:
		var cnt : int = 0
		var inc : int = 0
		for c in _camps:
			if c.owner_id == p:
				cnt += 1
				inc += c.income_value
		var col : Color = COLORS[p]

		var card := Panel.new()
		var st := StyleBoxFlat.new()
		st.bg_color = Color(col.r*0.14, col.g*0.14, col.b*0.14, 0.92)
		st.border_color = col
		st.set_border_width_all(2)
		st.set_corner_radius_all(4)
		card.add_theme_stylebox_override("panel", st)
		card.custom_minimum_size = Vector2(208, 40)
		lb.add_child(card)

		var bar := ColorRect.new()
		bar.color = col
		bar.size  = Vector2(5, 40)
		card.add_child(bar)

		var nl := Label.new()
		nl.text = PLAYER_NAMES[p - 1]
		nl.position = Vector2(12, 3)
		nl.size = Vector2(194, 17)
		nl.add_theme_font_size_override("font_size", 12)
		nl.add_theme_color_override("font_color", Color.WHITE)
		card.add_child(nl)

		var sl := Label.new()
		sl.text = "%d camps  +%d G/tick  %d G" % [cnt, inc, _gold[p]]
		sl.position = Vector2(12, 22)
		sl.size = Vector2(194, 15)
		sl.add_theme_font_size_override("font_size", 10)
		sl.add_theme_color_override("font_color", col)
		card.add_child(sl)


func _spawn_unit(unit_type: String, camp: Node, attach_to_camp: bool = true, net_id: int = -1, is_proxy: bool = false) -> Unit:
	if not UNIT_SCENES.has(unit_type):
		print("[Main] Type d'unité inconnu : ", unit_type)
		return null

	var scene = load(UNIT_SCENES[unit_type]) as PackedScene
	if not scene:
		print("[Main] Impossible de charger la scène : ", UNIT_SCENES[unit_type])
		return null

	var unit = scene.instantiate()
	var offset := Vector2(randf_range(-55, 55), randf_range(-55, 55))
	unit.global_position = camp.global_position + offset
	unit.z_index = 200

	if unit.has_method("setup"):
		unit.setup(camp.owner_id, camp if attach_to_camp else null, unit_type)
	else:
		unit.owner_id = camp.owner_id

	add_child(unit)

	var uid: int = net_id
	if uid <= 0:
		uid = _unit_net_id_seq
		_unit_net_id_seq += 1
	unit.set_meta("net_id", uid)
	_units_by_net_id[uid] = unit

	if is_proxy:
		_setup_network_proxy(unit)

	if attach_to_camp and camp.has_method("register_unit"):
		camp.register_unit(unit, true)

	if not is_proxy and unit.has_signal("unit_died") and not unit.unit_died.is_connected(_on_unit_died):
		unit.unit_died.connect(_on_unit_died)

	return unit

func _on_unit_died(unit: Unit, killer_owner_id: int, killer_unit: Node) -> void:
	if not _is_authority():
		return

	if unit.has_meta("net_id"):
		_units_by_net_id.erase(int(unit.get_meta("net_id")))

	_clear_dead_units_from_selection()
	if unit.owner_id >= 1 and unit.owner_id <= 2:
		_units_lost[unit.owner_id - 1] += 1
	var player = GameManager.find_player_by_id(unit.owner_id)
	if player:
		player.on_unit_lost()
	var killer_player = GameManager.find_player_by_id(killer_owner_id)
	if killer_player:
		killer_player.on_unit_killed()
	_refresh_ui()

func _on_camp_empty(camp: Node, killer_owner_id: int, killer_unit: Node) -> void:
	if not is_instance_valid(camp):
		return
	var new_owner : int = 0
	if killer_owner_id > 0 and is_instance_valid(killer_unit):
		new_owner = killer_owner_id
	_capture_camp(camp, new_owner)
	if new_owner > 0 and is_instance_valid(killer_unit):
		if killer_unit is Unit:
			killer_unit.clear_target_camp()
			killer_unit.home_camp = camp
			camp.register_unit(killer_unit, true)
			killer_unit.move_to(camp.global_position + Vector2(randf_range(-25, 25), randf_range(-25, 25)))
	_check_victory()
	_refresh_ui()

func _capture_camp(camp: Node, new_owner_id: int) -> void:
	if GameManager and GameManager.has_method("capture_camp"):
		GameManager.capture_camp(camp, new_owner_id)
	elif camp.has_method("change_owner"):
		camp.change_owner(new_owner_id)
	camp.production_queue.clear()
	camp.unit_type = "infantry"
	_log("✓ %s capturé par %s" % [camp.camp_name, "Neutre" if new_owner_id == 0 else "Joueur %d" % new_owner_id])
	if GameConfig.mode == "multi" and GameConfig.is_host:
		_broadcast_state()

func _process_unit_camp_orders() -> void:
	for unit in get_tree().get_nodes_in_group("units"):
		if not (unit is Unit) or not unit.is_alive:
			continue
		var camp = unit.target_camp
		if camp == null or not is_instance_valid(camp):
			continue
		if unit.global_position.distance_to(camp.global_position) > CAMP_CAPTURE_RADIUS:
			continue
		if camp.owner_id == unit.owner_id:
			unit.clear_target_camp()
			if camp.has_method("register_unit"):
				camp.register_unit(unit, true)
			unit.home_camp = camp
			_refresh_ui()
			continue
		if camp.has_method("has_living_garrison") and camp.has_living_garrison():
			var defender := _get_nearest_garrison_enemy(unit, camp)
			if defender != null and unit.current_target == null:
				unit.nav_agent.target_position = defender.global_position
			continue
		if camp.units <= 0 or (camp.has_method("has_living_garrison") and not camp.has_living_garrison()):
			_capture_camp(camp, unit.owner_id)
			unit.clear_target_camp()
			unit.home_camp = camp
			if camp.has_method("register_unit"):
				camp.register_unit(unit, true)
			unit.move_to(camp.global_position + Vector2(randf_range(-25, 25), randf_range(-25, 25)))
			_check_victory()
			_refresh_ui()

func _get_nearest_garrison_enemy(unit: Unit, camp: Node) -> Unit:
	if not camp.has_method("get_available_garrison"):
		return null
	var nearest : Unit = null
	var nearest_dist : float = INF
	for defender in camp.get_available_garrison():
		if defender is Unit and defender.owner_id != unit.owner_id and defender.is_alive:
			var dist: float = unit.global_position.distance_to(defender.global_position)
			if dist < nearest_dist:
				nearest = defender
				nearest_dist = dist
	return nearest

func _clear_dead_units_from_selection() -> void:
	var alive : Array = []
	for unit in _selected_units:
		if is_instance_valid(unit) and unit.is_alive:
			alive.append(unit)
	_selected_units = alive
	if _ui and _ui.has_method("update_selection_panel"):
		_ui.update_selection_panel(_selected_units)

func _log(msg: String) -> void:
	if _ui and _ui.has_method("add_log"):
		_ui.add_log(msg)
	print("[Main] ", msg)


# ─────────────────────────────────────────────────────────────────────────────
# DESSIN (camps par-dessus les TileMaps)
# ─────────────────────────────────────────────────────────────────────────────
func _draw_camps(canvas: Node2D) -> void:
	if _camps.is_empty():
		return

	var font: Font = ThemeDB.fallback_font
	var r = load("res://scripts/ui/Renderer.gd").new()
	var map_data: Dictionary = MapDefs.MAPS[_map_index]

	var camp_dicts: Array = []
	for c in _camps:
		camp_dicts.append(_camp_to_dict(c))

	var sel_idx: int = -1
	if _selected != null:
		sel_idx = _camps.find(_selected)

	r.draw(canvas, font, camp_dicts, sel_idx,
		map_data.get("forests", []),
		map_data.get("river_x", -1),
		map_data.get("bridge_y", -1),
		map_data.get("bridge_h", 0),
		map_data.get("has_water", false),
		map_data.get("land_zones", []),
		_game_over,
		"")

# ─────────────────────────────────────────────────────────────────────────────
# OVERLAY — Node2D dédié au dessin des camps (z_index élevé)
# ─────────────────────────────────────────────────────────────────────────────
class CampOverlay extends Node2D:
	var main : Node = null
	func _draw() -> void:
		if main and main.has_method("_draw_camps"):
			main._draw_camps(self)
