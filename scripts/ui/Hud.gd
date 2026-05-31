class_name HUD
extends CanvasLayer
# ─────────────────────────────────────────────────────────────────────────────
#  HUD.gd — SupKonQuest · Totally Spies Edition
# ─────────────────────────────────────────────────────────────────────────────

var U : Node

signal recruit_pressed(unit_type: String)
signal pause_requested

const MAX_LOG : int = 6

# ── Références nœuds ──────────────────────────────────────────────────────────
var info_label   : Label
var gold_label   : Label
var income_label : Label
var camps_label  : Label
var msg_label    : Label
var unit_label   : Label

var leaderboard_container : VBoxContainer
var _lb_bg      : Panel
var _minimap    : Node2D
var recruit_bar : Control
var camp_label  : Label
var recruit_btns : Array = []
var _pause_btn  : Button = null
var _lb_title   : Label  = null

# Panneau stats unité — reconstruit avec style
var selection_panel  : Panel = null
var _sel_bg          : Panel = null
var unit_count_label : Label = null
var unit_stats_label : Label = null
var spell_button     : Button = null
# Barres HP / stats visuelles dans le panneau
var _sel_hp_bg  : ColorRect = null
var _sel_hp_fg  : ColorRect = null
var _sel_dmg_lbl : Label = null
var _sel_spd_lbl : Label = null
var _sel_rng_lbl : Label = null
var _sel_type_lbl: Label = null

var event_log         : RichTextLabel
var _log_btn          : Button = null
var _log_panel_open   : bool = false
var _stats_bg         : Panel = null

var _log_entries : Array = []
var _lb_refresh_acc : float = 0.0

# Notification région capturée
var _notif_panel  : Panel = null
var _notif_label  : Label = null
var _notif_timer  : float = 0.0
const NOTIF_DURATION : float = 3.0

# Camp actuellement sélectionné (pour maj des progress bars)
var _current_camp = null


func setup(u: Node) -> void:
	U = u
	_build_stats_bar()
	_build_leaderboard()
	_build_event_log()
	_build_recruit_bar()
	_build_selection_panel()
	_connect_game_manager()
	_build_minimap()
	_build_notif_panel()


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	_lb_refresh_acc += delta
	if _lb_refresh_acc >= 2.0:
		_lb_refresh_acc = 0.0
		refresh_leaderboard()
	_refresh_stats()
	_update_build_progress()

	# Notification région — fade out
	if _notif_timer > 0.0:
		_notif_timer -= delta
		if _notif_timer <= 0.5:
			_notif_panel.modulate.a = _notif_timer / 0.5
		if _notif_timer <= 0.0:
			_notif_panel.visible = false
			_notif_panel.modulate.a = 1.0


# ─────────────────────────────────────────────────────────────────────────────
#  CONSTRUCTION
# ─────────────────────────────────────────────────────────────────────────────

func _build_stats_bar() -> void:
	_stats_bg = Panel.new()
	_stats_bg.visible = false
	_stats_bg.position = Vector2(68, 8)
	_stats_bg.size = Vector2(640, 42)
	_stats_bg.add_theme_stylebox_override("panel",
		U.flat(Color(0.04, 0.02, 0.10, 0.90), U.C_PINK, 2, 10))
	add_child(_stats_bg)

	info_label   = _lbl_add(Vector2(82,  15), Vector2(190, 24))
	gold_label   = _lbl_add(Vector2(275, 15), Vector2(110, 24))
	income_label = _lbl_add(Vector2(390, 15), Vector2(130, 24))
	camps_label  = _lbl_add(Vector2(525, 15), Vector2(160, 24))
	msg_label    = _lbl_add(Vector2(720, 15), Vector2(240, 24))
	unit_label   = _lbl_add(Vector2(720, 42), Vector2(260, 22))

	for lbl in [info_label, gold_label, income_label, camps_label, msg_label, unit_label]:
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", U.C_WHITE)
		lbl.visible = false

	info_label.add_theme_color_override("font_color", U.C_PINK)
	gold_label.add_theme_color_override("font_color", U.C_GOLD)
	income_label.add_theme_color_override("font_color", U.C_CYAN)
	camps_label.add_theme_color_override("font_color", U.C_WHITE)
	msg_label.add_theme_color_override("font_color", Color(0.75, 0.65, 0.85))
	unit_label.add_theme_color_override("font_color", U.C_CYAN)
	unit_label.visible = false

	_pause_btn          = Button.new()
	_pause_btn.text     = "  ⏸  "
	_pause_btn.position = Vector2(10, 10)
	_pause_btn.size     = Vector2(52, 32)
	_pause_btn.add_theme_font_size_override("font_size", 16)
	_pause_btn.add_theme_stylebox_override("normal",
		U.flat(Color(0.08, 0.03, 0.16, 0.85), U.C_PINK, 1, 8))
	_pause_btn.add_theme_stylebox_override("hover",
		U.flat(Color(0.20, 0.06, 0.30, 0.95), U.C_PINK, 2, 8))
	_pause_btn.add_theme_color_override("font_color", U.C_PINK)
	_pause_btn.visible = false
	_pause_btn.pressed.connect(func(): pause_requested.emit())
	add_child(_pause_btn)

func _build_leaderboard() -> void:
	_lb_bg = Panel.new()
	_lb_bg.visible  = false
	var lb_bg : Panel = _lb_bg
	lb_bg.position = Vector2(U.WIN_W - 218, 8)
	lb_bg.size     = Vector2(210, 154)
	var lbs : StyleBoxFlat = StyleBoxFlat.new()
	lbs.bg_color    = Color(0.04, 0.02, 0.10, 0.88)
	lbs.border_color = U.C_PINK
	lbs.set_border_width_all(2)
	lbs.set_corner_radius_all(8)
	lb_bg.add_theme_stylebox_override("panel", lbs)
	add_child(lb_bg)

	_lb_title = Label.new()
	var lt : Label = _lb_title
	lt.text     = U.lt("players_title")
	lt.position = Vector2(0, 5)
	lt.size     = Vector2(210, 20)
	lt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lt.add_theme_font_size_override("font_size", 12)
	lt.add_theme_color_override("font_color", U.C_GOLD)
	lb_bg.add_child(lt)

	leaderboard_container = VBoxContainer.new()
	leaderboard_container.position = Vector2(6, 28)
	leaderboard_container.size     = Vector2(198, 118)
	leaderboard_container.add_theme_constant_override("separation", 4)
	lb_bg.add_child(leaderboard_container)

func _build_event_log() -> void:
	event_log = RichTextLabel.new()
	event_log.position       = Vector2(12, 58)
	event_log.size           = Vector2(360, 96)
	event_log.scroll_active  = false
	event_log.fit_content    = true
	event_log.mouse_filter   = Control.MOUSE_FILTER_IGNORE
	var bg : StyleBoxFlat = StyleBoxFlat.new()
	bg.bg_color = Color(0.04, 0.02, 0.10, 0.82)
	bg.border_color = Color(U.C_PURPLE.r, U.C_PURPLE.g, U.C_PURPLE.b, 0.60)
	bg.set_border_width_all(1)
	bg.set_corner_radius_all(6)
	event_log.add_theme_stylebox_override("normal", bg)
	event_log.visible = false
	add_child(event_log)

	_log_btn = Button.new()
	_log_btn.text = "Journal"
	_log_btn.position = Vector2(12, 54)
	_log_btn.size = Vector2(86, 28)
	_log_btn.visible = false
	_log_btn.add_theme_font_size_override("font_size", 11)
	_log_btn.add_theme_stylebox_override("normal",
		U.flat(Color(0.05, 0.03, 0.12, 0.85), U.C_PURPLE, 1, 6))
	_log_btn.add_theme_stylebox_override("hover",
		U.flat(Color(0.12, 0.05, 0.20, 0.95), U.C_PURPLE, 2, 6))
	_log_btn.add_theme_color_override("font_color", U.C_WHITE)
	_log_btn.pressed.connect(func():
		_log_panel_open = not _log_panel_open
		event_log.visible = _log_panel_open)
	add_child(_log_btn)

func _build_recruit_bar() -> void:
	recruit_bar          = Control.new()
	recruit_bar.position = Vector2(0, U.MAP_H)
	recruit_bar.size     = Vector2(U.WIN_W - 190, 100)
	recruit_bar.visible  = false
	add_child(recruit_bar)

	# Fond semi-transparent
	var bar_bg := ColorRect.new()
	bar_bg.color    = Color(0.04, 0.02, 0.10, 0.82)
	bar_bg.position = Vector2(0, 0)
	bar_bg.size     = Vector2(U.WIN_W - 190, 100)
	recruit_bar.add_child(bar_bg)

	# Ligne de séparation en haut
	var sep := ColorRect.new()
	sep.color    = U.C_PINK
	sep.position = Vector2(0, 0)
	sep.size     = Vector2(U.WIN_W - 190, 2)
	recruit_bar.add_child(sep)

	camp_label          = Label.new()
	camp_label.position = Vector2(10, 5)
	camp_label.size     = Vector2(U.WIN_W - 200, 24)
	camp_label.add_theme_font_size_override("font_size", 13)
	camp_label.add_theme_color_override("font_color", U.C_GOLD)
	recruit_bar.add_child(camp_label)

	var ud : Node = get_node_or_null("/root/UnitDefs")
	if not ud:
		return
	var types : Dictionary = ud.get("TYPES") if ud else {}
	if types.is_empty():
		return

	var x : int = 5
	for unit_type in types.keys():
		var stats  : Dictionary = types[unit_type]
		var label  : String = stats.get("label", unit_type)
		var price  : int    = stats.get("price", 0)
		var btime  : float  = stats.get("build_time", 5.0)

		# Conteneur pour bouton + barre de build
		var container := Control.new()
		container.position = Vector2(x, 28)
		container.size     = Vector2(U.BTN_W, 66)
		recruit_bar.add_child(container)

		# Bouton principal
		var b := Button.new()
		b.text     = "%s\n%d G  •  %.0fs" % [label, price, btime]
		b.position = Vector2(0, 0)
		b.size     = Vector2(U.BTN_W, 50)
		b.add_theme_stylebox_override("normal",
			U.flat(Color(0.10, 0.04, 0.20), U.C_PINK, 2, 6))
		b.add_theme_stylebox_override("hover",
			U.flat(Color(0.18, 0.06, 0.30), U.C_PINK, 2, 6))
		b.add_theme_stylebox_override("pressed",
			U.flat(Color(0.06, 0.20, 0.22), U.C_CYAN, 2, 6))
		b.add_theme_color_override("font_color", U.C_WHITE)
		b.add_theme_font_size_override("font_size", 11)
		var t : String = unit_type
		b.set_meta("unit_type", t)
		b.pressed.connect(func():
			Sound.play("recruit")
			recruit_pressed.emit(t))
		container.add_child(b)
		recruit_btns.append(b)
		b.set_meta("container", container)

		# Fond barre de progression
		var prog_bg := ColorRect.new()
		prog_bg.color    = Color(0.12, 0.08, 0.18, 0.95)
		prog_bg.position = Vector2(0, 52)
		prog_bg.size     = Vector2(U.BTN_W, 7)
		container.add_child(prog_bg)

		# Barre de progression (cyan)
		var prog_fg := ColorRect.new()
		prog_fg.color    = U.C_CYAN
		prog_fg.position = Vector2(0, 52)
		prog_fg.size     = Vector2(0, 7)
		prog_fg.set_meta("unit_type", t)
		prog_fg.set_meta("btn_w", float(U.BTN_W))
		container.add_child(prog_fg)
		b.set_meta("prog_fg", prog_fg)

		# Label temps restant (ex: "2.4s")
		var time_lbl := Label.new()
		time_lbl.position = Vector2(0, 52)
		time_lbl.size     = Vector2(U.BTN_W, 12)
		time_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		time_lbl.add_theme_font_size_override("font_size", 9)
		time_lbl.add_theme_color_override("font_color", U.C_CYAN)
		time_lbl.visible = false
		container.add_child(time_lbl)
		b.set_meta("time_lbl", time_lbl)

		x += U.BTN_W + 4


func _build_selection_panel() -> void:
	# Panneau stylisé — positionné au-dessus de la barre de recrutement
	selection_panel          = Panel.new()
	selection_panel.position = Vector2(8, U.MAP_H - 108)
	selection_panel.size     = Vector2(400, 100)
	selection_panel.visible  = false
	var sp_style := StyleBoxFlat.new()
	sp_style.bg_color     = Color(0.04, 0.02, 0.12, 0.92)
	sp_style.border_color = U.C_PINK
	sp_style.set_border_width_all(2)
	sp_style.set_corner_radius_all(6)
	selection_panel.add_theme_stylebox_override("panel", sp_style)
	add_child(selection_panel)

	# En-tête : nombre d'unités + bouton spell
	var header := Label.new()
	header.name     = "Header"
	header.position = Vector2(10, 6)
	header.size     = Vector2(280, 22)
	header.add_theme_font_size_override("font_size", 13)
	header.add_theme_color_override("font_color", U.C_PINK)
	selection_panel.add_child(header)
	unit_count_label = header

	spell_button         = Button.new()
	spell_button.text    = "✦ Spell"
	spell_button.position = Vector2(300, 4)
	spell_button.size    = Vector2(90, 26)
	spell_button.visible = false
	spell_button.add_theme_stylebox_override("normal",
		U.flat(Color(0.10, 0.04, 0.22), U.C_CYAN, 2, 5))
	spell_button.add_theme_color_override("font_color", U.C_CYAN)
	spell_button.add_theme_font_size_override("font_size", 12)
	spell_button.pressed.connect(_on_spell_pressed)
	selection_panel.add_child(spell_button)

	# Barre de cooldown (fond + remplissage)
	var cd_bg := ColorRect.new()
	cd_bg.name     = "CooldownBg"
	cd_bg.color    = Color(0.12, 0.08, 0.22, 0.95)
	cd_bg.position = Vector2(300, 32)
	cd_bg.size     = Vector2(90, 5)
	selection_panel.add_child(cd_bg)

	var cd_fg := ColorRect.new()
	cd_fg.name     = "CooldownFg"
	cd_fg.color    = U.C_CYAN
	cd_fg.position = Vector2(300, 32)
	cd_fg.size     = Vector2(0, 5)
	selection_panel.add_child(cd_fg)

	var cd_lbl := Label.new()
	cd_lbl.name     = "CooldownLbl"
	cd_lbl.position = Vector2(296, 38)
	cd_lbl.size     = Vector2(98, 14)
	cd_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cd_lbl.add_theme_font_size_override("font_size", 9)
	cd_lbl.add_theme_color_override("font_color", U.C_CYAN)
	cd_lbl.visible = false
	selection_panel.add_child(cd_lbl)

	# Séparateur
	var div := ColorRect.new()
	div.color    = Color(U.C_PINK.r, U.C_PINK.g, U.C_PINK.b, 0.35)
	div.position = Vector2(10, 30)
	div.size     = Vector2(380, 1)
	selection_panel.add_child(div)

	# Barre HP (fond + remplissage)
	var hp_label := Label.new()
	hp_label.name     = "HpLabel"
	hp_label.text     = "HP"
	hp_label.position = Vector2(10, 36)
	hp_label.size     = Vector2(22, 16)
	hp_label.add_theme_font_size_override("font_size", 10)
	hp_label.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0))
	selection_panel.add_child(hp_label)

	_sel_hp_bg          = ColorRect.new()
	_sel_hp_bg.color    = Color(0.15, 0.10, 0.22, 0.95)
	_sel_hp_bg.position = Vector2(34, 40)
	_sel_hp_bg.size     = Vector2(180, 8)
	selection_panel.add_child(_sel_hp_bg)

	_sel_hp_fg          = ColorRect.new()
	_sel_hp_fg.color    = Color(0.20, 0.88, 0.35)
	_sel_hp_fg.position = Vector2(34, 40)
	_sel_hp_fg.size     = Vector2(180, 8)
	selection_panel.add_child(_sel_hp_fg)

	var hp_val_lbl := Label.new()
	hp_val_lbl.name     = "HpVal"
	hp_val_lbl.position = Vector2(220, 36)
	hp_val_lbl.size     = Vector2(80, 16)
	hp_val_lbl.add_theme_font_size_override("font_size", 10)
	hp_val_lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0))
	selection_panel.add_child(hp_val_lbl)

	# Ligne stats texte (DMG / SPD / RNG / Type)
	unit_stats_label          = Label.new()
	unit_stats_label.position = Vector2(10, 56)
	unit_stats_label.size     = Vector2(380, 36)
	unit_stats_label.add_theme_font_size_override("font_size", 11)
	unit_stats_label.add_theme_color_override("font_color", Color(0.80, 0.90, 1.0))
	unit_stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	unit_stats_label.visible = false
	selection_panel.add_child(unit_stats_label)


# ─────────────────────────────────────────────────────────────────────────────
#  MISE À JOUR BUILD PROGRESS
# ─────────────────────────────────────────────────────────────────────────────

func _update_build_progress() -> void:
	if not recruit_bar.visible or _current_camp == null:
		return

	var queue : Array = _current_camp.get("production_queue") if "production_queue" in _current_camp \
		else _current_camp.get("queue", [])

	for b in recruit_btns:
		if not is_instance_valid(b):
			continue
		if not b.has_meta("prog_fg"):
			continue
		var prog_fg : ColorRect = b.get_meta("prog_fg")
		var time_lbl : Label    = b.get_meta("time_lbl") if b.has_meta("time_lbl") else null
		if not is_instance_valid(prog_fg):
			continue

		var unit_type : String = b.get_meta("unit_type") if b.has_meta("unit_type") else ""
		var btn_w     : float  = prog_fg.get_meta("btn_w") if prog_fg.has_meta("btn_w") else float(U.BTN_W)

		# Cherche si ce type est en cours de production (premier de la file)
		var ratio : float = 0.0
		var remaining : float = 0.0
		if queue.size() > 0:
			var entry : Dictionary = queue[0]
			if entry.get("unit_type", "") == unit_type:
				var total : float = UnitDefs.TYPES.get(unit_type, {}).get("build_time", 5.0)
				remaining = entry.get("remaining", 0.0)
				ratio = clamp(1.0 - (remaining / total), 0.0, 1.0)

		prog_fg.size.x = btn_w * ratio
		# Couleur : cyan en cours → vert quand presque fini
		if ratio > 0.75:
			prog_fg.color = Color(0.20, 0.90, 0.35)
		else:
			prog_fg.color = U.C_CYAN

		if time_lbl:
			if ratio > 0.0 and remaining > 0.0:
				time_lbl.text    = "%.1fs" % remaining
				time_lbl.visible = true
			else:
				time_lbl.visible = false


# ─────────────────────────────────────────────────────────────────────────────
#  MISE À JOUR
# ─────────────────────────────────────────────────────────────────────────────

func _build_minimap() -> void:
	_minimap = load("res://scripts/ui/minimap.gd").new()
	add_child(_minimap)
	_minimap.setup()


func _build_notif_panel() -> void:
	_notif_panel          = Panel.new()
	_notif_panel.position = Vector2(1152.0 / 2.0 - 280, 240)
	_notif_panel.size     = Vector2(560, 80)
	_notif_panel.visible  = false
	_notif_panel.add_theme_stylebox_override("panel",
		U.flat(Color(0.04, 0.02, 0.10, 0.92), U.C_GOLD, 2, 12))
	add_child(_notif_panel)

	_notif_label          = Label.new()
	_notif_label.position = Vector2(0, 10)
	_notif_label.size     = Vector2(560, 60)
	_notif_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notif_label.add_theme_font_size_override("font_size", 22)
	_notif_label.add_theme_color_override("font_color", U.C_GOLD)
	_notif_panel.add_child(_notif_label)


func show_hud() -> void:
	if _lb_bg:
		_lb_bg.visible = true
	if _pause_btn:
		_pause_btn.visible = true
	refresh_leaderboard()
	if _minimap:
		_minimap.show_minimap()
	if _log_btn:
		_log_btn.visible = true
	if event_log:
		event_log.visible = _log_panel_open
	if _stats_bg:
		_stats_bg.visible = true
	info_label.visible   = true
	gold_label.visible   = true
	income_label.visible = true
	camps_label.visible  = true
	msg_label.visible    = true
	var end_btn = get_node_or_null("EndTurnBtn")
	if end_btn:
		end_btn.visible = true


func hide_hud() -> void:
	if _lb_bg:
		_lb_bg.visible = false
	if _pause_btn:
		_pause_btn.visible = false
	if _stats_bg:
		_stats_bg.visible = false
	if _log_btn:
		_log_btn.visible = false
	if event_log:
		event_log.visible = false


func _refresh_stats() -> void:
	pass


func refresh_leaderboard() -> void:
	if not leaderboard_container:
		return
	var gm := get_node_or_null("/root/GameManager")
	if not gm:
		return

	if _lb_title:
		_lb_title.text = U.lt("players_title")
	for child in leaderboard_container.get_children():
		child.queue_free()

	var sorted : Array = gm.players.duplicate()
	sorted.sort_custom(func(a, b): return a.get_camp_count() > b.get_camp_count())

	for player in sorted:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)

		# Couleur d'affichage : on s'assure qu'elle soit visible sur fond sombre
		var dc : Color = player.color
		if dc.v < 0.45:
			dc = Color.from_hsv(dc.h, clamp(dc.s, 0.3, 1.0), 0.8)

		# Bande de couleur de l'équipe
		var bar := ColorRect.new()
		bar.color = dc
		bar.custom_minimum_size = Vector2(5, 32)

		# Infos équipe
		var vbox := VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.add_theme_constant_override("separation", 1)

		var name_lbl := Label.new()
		if player.is_ai:
			var _diff_names : Array = ["IA",
				"IA — " + U.lt("diff_easy"),
				"IA — " + U.lt("diff_med"),
				"IA — " + U.lt("diff_hard")]
			name_lbl.text = _diff_names[player.ai_level] if player.ai_level < _diff_names.size() else "IA"
		else:
			name_lbl.text = player.player_name
		name_lbl.add_theme_font_size_override("font_size", 12)
		name_lbl.add_theme_color_override("font_color", dc)
		name_lbl.clip_text = true

		var stats_lbl := Label.new()
		var defeated : bool = player.get_camp_count() == 0
		if defeated:
			stats_lbl.text = U.lt("eliminated")
			stats_lbl.add_theme_color_override("font_color", Color(0.6, 0.3, 0.3))
		else:
			stats_lbl.text = "%d camps  +%dG" % [player.get_camp_count(), player.get_income()]
			stats_lbl.add_theme_color_override("font_color", Color(dc.r, dc.g, dc.b, 0.75))
		stats_lbl.add_theme_font_size_override("font_size", 10)

		vbox.add_child(name_lbl)
		vbox.add_child(stats_lbl)

		row.add_child(bar)
		row.add_child(vbox)

		if player.get_camp_count() == 0:
			row.modulate.a = 0.5

		leaderboard_container.add_child(row)


func show_recruit(camp) -> void:
	if camp == null:
		return

	_current_camp = camp

	var q_parts : Array = []
	var queue : Array = camp.get("production_queue") if "production_queue" in camp \
		else camp.get("queue", [])
	for e in queue:
		var ut : String = e.get("unit_type", "?")
		var ud2 : Node = get_node_or_null("/root/UnitDefs")
		var lbl : String = ud2.TYPES.get(ut, {}).get("label", ut) if ud2 else ut
		q_parts.append(lbl)

	var camp_n : String = camp.get("camp_name") if "camp_name" in camp else camp.get("name", "?")
	var mode_text : String = "Unités navales" if camp.get("is_port") == true else "Unités terrestres"
	if q_parts.is_empty():
		camp_label.text = "%s  —  %s  —  %s" % [camp_n, mode_text, U.lt("queue_empty_lbl")]
	else:
		camp_label.text = "%s  —  %s  —  ▶ %s" % [camp_n, mode_text, "  →  ".join(q_parts)]

	var ud : Node = get_node_or_null("/root/UnitDefs")
	var is_port : bool = camp.get("is_port") == true
	var allowed : Array = []
	if ud:
		allowed = ud.get_sea_units() if is_port else ud.get_land_units()

	var x : int = 5
	for b in recruit_btns:
		if not is_instance_valid(b):
			continue
		var unit_type : String = b.get_meta("unit_type") if b.has_meta("unit_type") else ""
		var is_allowed : bool = allowed.is_empty() or unit_type in allowed
		var container : Control = b.get_meta("container") if b.has_meta("container") else b.get_parent()
		if is_instance_valid(container):
			container.visible = is_allowed
			if is_allowed:
				container.position = Vector2(x, 28)
				x += U.BTN_W + 8
		b.visible = is_allowed

	recruit_bar.visible = true

func hide_recruit() -> void:
	recruit_bar.visible = false
	_current_camp = null


func update_selection_panel(selected_units: Array) -> void:
	if selected_units.is_empty():
		selection_panel.visible = false
		return

	selection_panel.visible = true

	# En-tête
	unit_count_label.text = U.lt("units_selected") % selected_units.size()

	# Bouton spell + cooldown
	var has_spell : bool = false
	var spell_unit = null
	for u in selected_units:
		if is_instance_valid(u) and u.get("unit_type") in [
				Unit.UnitType.SOUTIEN, Unit.UnitType.SOIGNEUR]:
			has_spell = true
			spell_unit = u
			break
	spell_button.visible = has_spell

	# Mise à jour barre cooldown
	var cd_fg  : ColorRect = selection_panel.get_node_or_null("CooldownFg")
	var cd_lbl : Label     = selection_panel.get_node_or_null("CooldownLbl")
	if cd_fg and cd_lbl and has_spell and is_instance_valid(spell_unit):
		var cd_remain : float = spell_unit.get("spell_cooldown_remaining") \
			if spell_unit.get("spell_cooldown_remaining") != null else 0.0
		var cd_total  : float = spell_unit.get("spell_cooldown_max") \
			if spell_unit.get("spell_cooldown_max") != null else 1.0
		var on_cd : bool = cd_remain > 0.01
		if on_cd:
			var ratio : float = clamp(cd_remain / max(cd_total, 0.01), 0.0, 1.0)
			cd_fg.size.x = 90.0 * (1.0 - ratio)
			cd_fg.color  = Color(0.80, 0.30, 0.10)
			cd_lbl.text  = "CD %.1fs" % cd_remain
			cd_lbl.visible = true
			spell_button.disabled = true
			spell_button.add_theme_color_override("font_color", Color(0.50, 0.40, 0.60))
		else:
			cd_fg.size.x = 90.0
			cd_fg.color  = U.C_CYAN
			cd_lbl.visible = false
			spell_button.disabled = false
			spell_button.add_theme_color_override("font_color", U.C_CYAN)

	# Stats détaillées si 1 seule unité
	if selected_units.size() == 1:
		var u = selected_units[0]
		if is_instance_valid(u):
			var hp_val  : float = u.get("hp")     if u.get("hp")     != null else 0.0
			var max_hp  : float = u.get("max_hp") if u.get("max_hp") != null else 1.0
			var dmg     : float = u.get("damage") if u.get("damage") != null else 0.0
			var spd     : float = u.get("speed")  if u.get("speed")  != null else 0.0
			var rng     : float = u.get("attack_range") if u.get("attack_range") != null else 0.0
			var utype_i : int   = u.get("unit_type") if u.get("unit_type") != null else 0
			var ud_node : Node  = get_node_or_null("/root/UnitDefs")

			# Barre HP
			var ratio : float = clamp(hp_val / max(max_hp, 1.0), 0.0, 1.0)
			_sel_hp_fg.size.x = 180.0 * ratio
			if ratio > 0.5:
				_sel_hp_fg.color = Color(0.20, 0.88, 0.35)
			elif ratio > 0.25:
				_sel_hp_fg.color = Color(1.00, 0.65, 0.10)
			else:
				_sel_hp_fg.color = Color(0.90, 0.15, 0.15)

			# Valeur HP texte
			var hp_val_node : Label = selection_panel.get_node_or_null("HpVal")
			if hp_val_node:
				hp_val_node.text = "%d / %d" % [int(hp_val), int(max_hp)]

			# Ligne stats
			var rng_str : String = U.lt("stat_melee") if rng <= 0.0 else "%.0f px" % rng
			var type_name : String = "?"
			# Récupère le nom du type depuis UnitDefs si dispo
			var type_key : String = Unit.UnitType.keys()[utype_i] \
				if utype_i < Unit.UnitType.size() else "?"
			if ud_node:
				var key_lower : String = type_key.to_lower()
				type_name = ud_node.TYPES.get(key_lower, {}).get("label", type_key)
			unit_stats_label.text = "DMG  %.0f   •   SPD  %.0f   •   RNG  %s   •   %s" % [
				dmg, spd, rng_str, type_name]
			unit_stats_label.visible = true
			_sel_hp_bg.visible = true
			_sel_hp_fg.visible = true
	else:
		unit_stats_label.visible = false
		_sel_hp_bg.visible = false
		_sel_hp_fg.visible = false


func add_log(message: String) -> void:
	_log_entries.append(message)
	if _log_entries.size() > MAX_LOG:
		_log_entries.pop_front()
	if event_log:
		event_log.text = "\n".join(_log_entries)
	if _log_btn:
		_log_btn.text = "Journal (%d)" % _log_entries.size()


# ─────────────────────────────────────────────────────────────────────────────
#  CALLBACKS GAMEMANAGER
# ─────────────────────────────────────────────────────────────────────────────

func _connect_game_manager() -> void:
	var gm : Node = get_node_or_null("/root/GameManager")
	if not gm:
		return
	var signal_map : Dictionary = {
		"income_distributed": _on_income_distributed,
		"camp_captured":      _on_camp_captured,
		"player_defeated":    _on_player_defeated,
		"region_captured":    _on_region_captured,
	}
	for sig_name in signal_map.keys():
		if gm.has_signal(sig_name) and not gm.get(sig_name + "_connected"):
			gm.connect(sig_name, signal_map[sig_name])


func _on_income_distributed(player, amount: int) -> void:
	refresh_leaderboard()
	add_log("+ %s +%dG" % [player.player_name.split(" ")[0], amount])


func _on_camp_captured(camp, _old: int, new_owner_id: int) -> void:
	refresh_leaderboard()
	var gm : Node = get_node_or_null("/root/GameManager")
	var owner  = gm.find_player_by_id(new_owner_id) if gm else null
	var camp_n : String = camp.get("camp_name") if "camp_name" in camp else camp.get("name", "?")
	add_log("🏠 %s → %s" % [camp_n,
		owner.player_name.split(" ")[0] if owner else "?"])


func _on_player_defeated(player) -> void:
	add_log("💀 %s eliminated!" % player.player_name)
	refresh_leaderboard()


func _on_region_captured(region_name: String, player) -> void:
	add_log("⭐ %s owns %s!" % [player.player_name.split(" ")[0], region_name])
	if _notif_panel and _notif_label:
		_notif_label.text   = "⭐  %s conquiert %s  ⭐" % [player.player_name.split(" ")[0], region_name]
		_notif_panel.visible = true
		_notif_panel.modulate.a = 1.0
		_notif_timer = NOTIF_DURATION
		Sound.play("capture")


# ─────────────────────────────────────────────────────────────────────────────
#  PRIVÉ
# ─────────────────────────────────────────────────────────────────────────────

func _lbl_add(pos: Vector2, sz: Vector2) -> Label:
	var l : Label = Label.new()
	l.position = pos
	l.size     = sz
	add_child(l)
	return l


func _on_spell_pressed() -> void:
	var s : Node = get_tree().get_first_node_in_group("unit_selection")
	if s and s.has_method("_activate_spell_on_selected"):
		s._activate_spell_on_selected()
