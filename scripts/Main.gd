# =============================================================================
#  Main.gd — SupKonQuest · Totally Spies Edition
#
#  Script racine de Main.tscn.
#  Orchestre le game loop complet en connectant :
#    - UI.gd  (menus, HUD, signaux joueur)
#    - Camp_hani.gd (camps en scène via groupe "camps")
#    - Combat (autoload, résolution des batailles)
#    - MapDefs (autoload, données des cartes)
#    - UnitDefs (autoload, prix et stats)
#    - Sound / Lang (autoloads)
# =============================================================================

extends Node2D

# ─────────────────────────────────────────────────────────────────────────────
# CONSTANTES
# ─────────────────────────────────────────────────────────────────────────────
const INCOME_INTERVAL : float = 12.0
const MAX_QUEUE       : int   = 3
const PLAYER_NAMES    := ["Clover", "Adversaire"]

const UNIT_SCENES := {
	"infantry"   : "res://scenes/units/fantassin.tscn",
	"range"      : "res://scenes/units/tir_distance.tscn",
	"heavy"      : "res://scenes/units/lourd.tscn",
	"anti_armor" : "res://scenes/units/anti_blindage.tscn",
	"mortar"     : "res://scenes/units/mortier.tscn",
	"support"    : "res://scenes/units/soutien.tscn",
	"healer"     : "res://scenes/units/soigneur.tscn",
	"spy_yacht"      : "res://scenes/units/transport.tscn",
	"woohp_cruiser"  : "res://scenes/units/fregate.tscn",
	"shadow_vessel"  : "res://scenes/units/destroyer.tscn",
}

# ─────────────────────────────────────────────────────────────────────────────
# ÉTAT
# ─────────────────────────────────────────────────────────────────────────────
var _camps          : Array = []   # Array[Camp] — nodes du groupe "camps"
var camps           : Array :   # alias public pour minimap.gd
	get: return _camps
var _gold           : Array = [150, 150]
var _turn           : int   = 1
var _cur            : int   = 0    # joueur actuel (0 ou 1)
var _selected       : Node  = null # Camp sélectionné
var _map_index      : int   = 0
var _game_over      : bool  = false
var _income_timer   : float = 0.0
var _overlay        : CampOverlay = null

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

	if GameConfig.mode == "ai":
		var map_idx : int = 0
		match GameConfig.map:
			"clover": map_idx = 0
			"sam":    map_idx = 1
			"alex":   map_idx = 2
		await get_tree().process_frame
		_ui.start_from_online(map_idx)
		# Pas de return — on continue pour connecter les signaux
	
	call_deferred("_connect_ui")


func _connect_ui() -> void:
	if not is_instance_valid(_ui):
		push_error("[Main] nœud UI introuvable")
		return
	_ui.map_selected.connect(_on_map_selected)
	_ui.recruit_pressed.connect(_on_recruit_pressed)
	if _ui.has_signal("end_turn_pressed"):
		_ui.end_turn_pressed.connect(_on_end_turn)


func _on_map_selected(index: int) -> void:
	_map_index = index
	_start_game()


func _start_game() -> void:
	_game_over    = false
	_turn         = 1
	_cur          = 0
	_gold         = [150, 150]
	_selected     = null
	_income_timer = 0.0
	_game_start_time = Time.get_ticks_msec() / 1000.0
	_camps_peak   = [0, 0]
	_income_peak  = [0, 0]
	_units_lost   = [0, 0]

	# Supprime les anciens camps (rejouer)
	for c in _camps:
		if is_instance_valid(c):
			c.queue_free()
	_camps.clear()

	# Crée les camps depuis MapDefs
	var map_data : Dictionary = MapDefs.MAPS[_map_index]
	var CampScene := load("res://scenes/camp_base.tscn") as PackedScene

	for i in range(map_data["camps"].size()):
		var d : Dictionary = map_data["camps"][i]
		var camp : Node2D = CampScene.instantiate()
		camp.position     = d["pos"]
		camp.camp_name    = d["name"]
		camp.camp_id      = i
		camp.income_value = d["income"]
		camp.is_port      = d.get("is_port", false)
		camp.units        = d["units"]
		camp.unit_type    = "infantry"
		camp.production_queue = []
		match d["owner"]:
			1: camp.owner_id = 0
			2: camp.owner_id = 1
			_: camp.owner_id = -1
		add_child(camp)
		_camps.append(camp)

	_refresh_ui()
	# Crée/recycle l'overlay de dessin (z_index haut = au-dessus des TileMaps)
	if _overlay == null:
		_overlay = CampOverlay.new()
		_overlay.z_index = 100
		add_child(_overlay)
	_overlay.main = self
	_overlay.queue_redraw()


# ─────────────────────────────────────────────────────────────────────────────
# BOUCLE
# ─────────────────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if _game_over or _camps.is_empty():
		return

	# Revenus
	_income_timer += delta
	if _income_timer >= INCOME_INTERVAL:
		_income_timer = 0.0
		_distribute_income()
		# Mise à jour des pics de stats
		for p in [0, 1]:
			var cnt : int = 0
			var inc : int = 0
			for c in _camps:
				if c.owner_id == p:
					cnt += 1
					inc += c.income_value
			if cnt > _camps_peak[p]:  _camps_peak[p]  = cnt
			if inc > _income_peak[p]: _income_peak[p] = inc

	# Production
	for camp in _camps:
		if camp.production_queue.is_empty():
			continue
		var entry : Dictionary = camp.production_queue[0]
		entry["remaining"] -= delta
		if entry["remaining"] <= 0.0:
			camp.production_queue.pop_front()
			camp.units += 1
			_spawn_unit(entry["unit_type"], camp)
			_log("Unité produite à %s" % camp.camp_name)
			# Lance la suivante si elle existe
			if not camp.production_queue.is_empty():
				camp.production_queue[0]["remaining"] = _build_time(camp.production_queue[0]["unit_type"])
			_refresh_ui()

	if _overlay: _overlay.queue_redraw()


# ─────────────────────────────────────────────────────────────────────────────
# INPUT
# ─────────────────────────────────────────────────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
	if _game_over or _camps.is_empty():
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return

	var click : Vector2 = get_global_mouse_position()
	var clicked : Node  = _get_camp_at(click)

	if clicked == null:
		_deselect()
		return

	# Pas de sélection → sélectionner si camp allié
	if _selected == null:
		if clicked.owner_id == _cur:
			_select(clicked)
		else:
			_log("Ce camp ne vous appartient pas !")
		return

	# Même camp → désélectionner
	if clicked == _selected:
		_deselect()
		return

	# Camp allié → changer sélection
	if clicked.owner_id == _cur:
		_select(clicked)
		return

	# Ennemi ou neutre → ATTAQUE
	if _selected.units < 1:
		_log("Pas d unités dans ce camp !")
		return

	_do_attack(_selected, clicked)


func _get_camp_at(pos: Vector2) -> Node:
	for camp in _camps:
		if camp.global_position.distance_to(pos) <= 48.0:
			return camp
	return null


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


# ─────────────────────────────────────────────────────────────────────────────
# COMBAT
# ─────────────────────────────────────────────────────────────────────────────
func _do_attack(src: Node, tgt: Node) -> void:
	var old_owner : int = tgt.owner_id

	# Passe les nodes directement à Combat.resolve
	Combat.resolve(src, tgt)

	if tgt.owner_id != old_owner:
		_log("✓ %s capturé !" % tgt.camp_name)
		_check_victory()
	else:
		_log("✗ Attaque sur %s repoussée" % tgt.camp_name)

	_deselect()


func _camp_to_dict(camp: Node) -> Dictionary:
	return {
		"name"     : camp.camp_name,
		"pos"      : camp.global_position,
		"owner"    : camp.owner_id,
		"units"    : camp.units,
		"income"   : camp.income_value,
		"unit_type": camp.unit_type,
		"type"     : "port" if camp.is_port else "normal",
		"queue"    : []
	}


# ─────────────────────────────────────────────────────────────────────────────
# RECRUTEMENT
# ─────────────────────────────────────────────────────────────────────────────
func _on_recruit_pressed(unit_type: String) -> void:
	if _selected == null:
		_log("Sélectionnez d'abord un camp !")
		return
	if _selected.owner_id != _cur:
		return

	var price : int = UnitDefs.TYPES.get(unit_type, {}).get("price", 50)
	if _gold[_cur] < price:
		_log("Pas assez d'or ! (%d requis)" % price)
		return
	if _selected.production_queue.size() >= MAX_QUEUE:
		_log("File pleine !")
		return

	_gold[_cur] -= price
	var bt : float = _build_time(unit_type)
	# Si file vide, le premier entre directement en production avec son timer
	_selected.production_queue.append({"unit_type": unit_type, "remaining": bt})
	_selected.unit_type = unit_type
	_log("%s ajouté à la file de %s" % [unit_type, _selected.camp_name])
	_refresh_ui()


func _build_time(unit_type: String) -> float:
	return UnitDefs.TYPES.get(unit_type, {}).get("build_time", 5.0)


# ─────────────────────────────────────────────────────────────────────────────
# FIN DE TOUR
# ─────────────────────────────────────────────────────────────────────────────
func _on_end_turn() -> void:
	_deselect()
	_cur = 1 - _cur
	if _cur == 0:
		_turn += 1
	_log("--- Tour de %s ---" % PLAYER_NAMES[_cur])
	# Écran de transition entre les tours (cache la map à l'autre joueur)
	if _ui.has_method("show_turn_screen"):
		_ui.show_turn_screen(PLAYER_NAMES[_cur], _turn)
	_refresh_ui()


# ─────────────────────────────────────────────────────────────────────────────
# REVENUS
# ─────────────────────────────────────────────────────────────────────────────
func _distribute_income() -> void:
	var regions : Array = MapDefs.MAPS[_map_index].get("regions", [])
	for p in [0, 1]:
		var inc : int = 0
		for c in _camps:
			if c.owner_id == p:
				inc += c.income_value
		for region in regions:
			if _region_owner(region["camps"]) == p:
				inc += region["bonus"]
		_gold[p] += inc
		_log("Joueur %d +%d or" % [p + 1, inc])
	_refresh_ui()


func _region_owner(camp_indices: Array) -> int:
	if camp_indices.is_empty():
		return -1
	var owner : int = -2
	for i in camp_indices:
		if i >= _camps.size():
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
func _check_victory() -> void:
	var has := [false, false]
	for c in _camps:
		if c.owner_id == 0: has[0] = true
		elif c.owner_id == 1: has[1] = true
	if not has[0]: _end_game(1)
	elif not has[1]: _end_game(0)


func _end_game(winner: int) -> void:
	_game_over = true

	# ── Calcul des stats finales ──────────────────────────────────────────────
	var now       : float = Time.get_ticks_msec() / 1000.0
	var duration  : float = now - _game_start_time

	var camps_final : Array = [0, 0]
	var inc_final   : Array = [0, 0]
	for c in _camps:
		var oid : int = c.owner_id
		if oid == 0 or oid == 1:
			camps_final[oid] += 1
			inc_final[oid]   += c.income_value

	# Stats du vainqueur
	var winner_stats : Dictionary = {
		"duration_sec": duration,
		"camps_peak":   _camps_peak[winner],
		"camps_final":  camps_final[winner],
		"income_peak":  _income_peak[winner],
		"units_lost":   _units_lost[winner],
	}
	# Stats du perdant (l'autre joueur)
	var loser : int = 1 - winner
	var loser_stats : Dictionary = {
		"duration_sec": duration,
		"camps_peak":   _camps_peak[loser],
		"camps_final":  camps_final[loser],
		"income_peak":  _income_peak[loser],
		"units_lost":   _units_lost[loser],
	}

	# UI : show_victory détecte automatiquement si le joueur local a gagné ou perdu
	_ui.show_victory(PLAYER_NAMES[winner], _turn, winner_stats)


# ─────────────────────────────────────────────────────────────────────────────
# UI
# ─────────────────────────────────────────────────────────────────────────────
func _refresh_ui() -> void:
	var inc : int = 0
	var cnt : int = 0
	for c in _camps:
		if c.owner_id == _cur:
			inc += c.income_value
			cnt += 1
	var sel_unit : String = _selected.unit_type if _selected else ""
	_ui.update_hud(PLAYER_NAMES[_cur], _turn, _gold[_cur], inc, cnt, sel_unit, "", _cur)
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

	var COLORS := [Color(0.22, 0.45, 0.90), Color(0.88, 0.22, 0.22)]

	for p in [0, 1]:
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
		nl.text = PLAYER_NAMES[p]
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


func _spawn_unit(unit_type: String, camp: Node) -> void:
	if not UNIT_SCENES.has(unit_type):
		return
	var scene = load(UNIT_SCENES[unit_type]) as PackedScene
	if not scene:
		return
	var unit = scene.instantiate()
	unit.owner_id = camp.owner_id
	var offset := Vector2(randf_range(-30, 30), randf_range(-30, 30))
	unit.position = camp.position + offset
	if _overlay:
		_overlay.add_child(unit)
	else:
		add_child(unit)

	# Tracker la mort de l'unité pour les stats de fin
	var oid : int = camp.owner_id
	unit.tree_exiting.connect(func():
		if oid == 0 or oid == 1:
			_units_lost[oid] += 1)


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
	var font  : Font = ThemeDB.fallback_font
	var r = load("res://scripts/ui/Renderer.gd").new()
	var map_data : Dictionary = MapDefs.MAPS[_map_index]

	# Convertit les camps Node en dicts pour Renderer
	var camp_dicts : Array = []
	for c in _camps:
		camp_dicts.append(_camp_to_dict(c))

	var sel_idx : int = -1
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
		PLAYER_NAMES[1 - _cur] if _game_over else "")

# ─────────────────────────────────────────────────────────────────────────────
# OVERLAY — Node2D dédié au dessin des camps (z_index élevé)
# ─────────────────────────────────────────────────────────────────────────────
class CampOverlay extends Node2D:
	var main : Node = null
	func _draw() -> void:
		if main and main.has_method("_draw_camps"):
			main._draw_camps(self)
