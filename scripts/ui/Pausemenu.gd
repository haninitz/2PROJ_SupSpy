class_name PauseMenu
extends CanvasLayer
# =============================================================================
#  PauseMenu.gd — SupKonQuest · Totally Spies Edition
#
#  Menu pause affiché quand le joueur appuie sur ESC en jeu.
#  S'ajoute comme enfant de Main (ou UI) avec layer = 10.
#  Gèle le jeu via get_tree().paused = true.
# =============================================================================

signal resumed
signal quit_to_menu

var _panel  : Panel
var _active : bool = false
var U       : Node


func setup(u: Node) -> void:
	U = u
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()


func _build() -> void:
	# Fond sombre semi-transparent
	var bg := ColorRect.new()
	bg.color         = Color(0.0, 0.0, 0.0, 0.60)
	bg.size          = Vector2(1152, 720)
	bg.position      = Vector2.ZERO
	add_child(bg)

	# Panneau central
	_panel = Panel.new()
	_panel.position = Vector2(1152.0 / 2.0 - 200, 720.0 / 2.0 - 200)
	_panel.size     = Vector2(400, 380)
	_panel.add_theme_stylebox_override("panel",
		U.flat(Color(0.04, 0.02, 0.10, 0.96), U.C_PINK, 2, 16))
	add_child(_panel)

	# Titre
	var title : Label = U.lbl("— PAUSE —", Vector2(0, 28), 28, U.C_PINK)
	title.size = Vector2(400, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_child(title)

	var sub : Label = U.lbl("W.O.O.H.P · Mission en attente",
		Vector2(0, 68), 11, Color(0.55, 0.40, 0.70))
	sub.size = Vector2(400, 20)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_child(sub)

	# Diviseur
	var div := ColorRect.new()
	div.color    = Color(U.C_PINK.r, U.C_PINK.g, U.C_PINK.b, 0.35)
	div.position = Vector2(30, 96)
	div.size     = Vector2(340, 1)
	_panel.add_child(div)

	# Boutons
	var buttons := [
		{"t": "▶  Reprendre",       "col": U.C_PINK,   "fn": func(): resume()},
		{"t": "⚙  Options",         "col": U.C_CYAN,   "fn": func(): _open_options()},
		{"t": "↺  Menu principal",  "col": U.C_GOLD,   "fn": func(): _go_to_menu()},
		{"t": "✕  Quitter le jeu",  "col": Color(0.70, 0.20, 0.20), "fn": func(): get_tree().quit()},
	]

	for i in range(buttons.size()):
		var bd : Dictionary = buttons[i]
		var b : Button = U.btn(bd["t"], Vector2(50, 118 + i * 58), Vector2(300, 46), 16)
		b.add_theme_stylebox_override("normal",
			U.flat(Color(bd["col"].r*0.15, bd["col"].g*0.15, bd["col"].b*0.15),
				   bd["col"], 2, 8))
		b.add_theme_stylebox_override("hover",
			U.flat(Color(bd["col"].r*0.28, bd["col"].g*0.28, bd["col"].b*0.28),
				   bd["col"], 2, 8))
		b.add_theme_color_override("font_color", U.C_WHITE)
		b.pressed.connect(bd["fn"])
		_panel.add_child(b)

	# Raccourci ESC affiché
	var hint : Label = U.lbl("ESC — reprendre", Vector2(0, 350), 10,
		Color(0.40, 0.30, 0.55))
	hint.size = Vector2(400, 20)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_child(hint)

	visible = false


# ── API publique ──────────────────────────────────────────────────────────────

func toggle() -> void:
	if _active:
		resume()
	else:
		pause()


func pause() -> void:
	_active              = true
	visible              = true
	get_tree().paused    = true


func resume() -> void:
	_active              = false
	visible              = false
	get_tree().paused    = false
	resumed.emit()


# ── Privé ─────────────────────────────────────────────────────────────────────

func _open_options() -> void:
	# Crée un panel settings par-dessus le menu pause
	var scr : Panel = Panel.new()
	scr.position = Vector2(1152.0 / 2.0 - 300, 720.0 / 2.0 - 260)
	scr.size     = Vector2(600, 480)
	scr.process_mode = Node.PROCESS_MODE_ALWAYS
	scr.add_theme_stylebox_override("panel",
		U.flat(Color(0.04, 0.02, 0.10, 0.98), U.C_CYAN, 2, 14))
	add_child(scr)

	# Titre
	var title : Label = U.lbl("⚙  OPTIONS", Vector2(0, 22), 22, U.C_CYAN)
	title.size = Vector2(600, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scr.add_child(title)

	var div := ColorRect.new()
	div.color = Color(U.C_CYAN.r, U.C_CYAN.g, U.C_CYAN.b, 0.30)
	div.position = Vector2(30, 60); div.size = Vector2(540, 1)
	scr.add_child(div)

	# Langue
	scr.add_child(U.lbl("Language:", Vector2(40, 80), 13, U.C_PINK))
	var lang_codes  : Array[String] = ["fr", "en", "es"]
	var lang_labels : Array[String] = ["🇫🇷 FR", "🇬🇧 EN", "🇪🇸 ES"]
	for i in range(3):
		var lc : String = lang_codes[i]
		var lb : Button = U.btn(lang_labels[i], Vector2(40 + i * 100, 102), Vector2(88, 34), 12)
		lb.process_mode = Node.PROCESS_MODE_ALWAYS
		lb.add_theme_stylebox_override("normal",
			U.flat(Color(0.12,0.05,0.18), U.C_PINK, 2, 6))
		lb.add_theme_color_override("font_color", U.C_WHITE)
		lb.pressed.connect(func(captured_lc: String = lc):
			var lang : Node = get_node_or_null("/root/Lang")
			if lang: lang.current = captured_lc)
		scr.add_child(lb)

	# Volume son
	scr.add_child(U.lbl("Sound Volume:", Vector2(40, 155), 13, U.C_CYAN))
	var sv : HSlider = HSlider.new()
	sv.position = Vector2(40, 177); sv.size = Vector2(520, 22)
	sv.min_value = 0; sv.max_value = 100; sv.value = 80
	sv.process_mode = Node.PROCESS_MODE_ALWAYS
	sv.value_changed.connect(func(v: float):
		AudioServer.set_bus_volume_db(
			AudioServer.get_bus_index("Master"), linear_to_db(v / 100.0)))
	scr.add_child(sv)

	# Volume musique
	scr.add_child(U.lbl("Music Volume:", Vector2(40, 215), 13, U.C_CYAN))
	var mv : HSlider = HSlider.new()
	mv.position = Vector2(40, 237); mv.size = Vector2(520, 22)
	mv.min_value = 0; mv.max_value = 100; mv.value = 50
	mv.process_mode = Node.PROCESS_MODE_ALWAYS
	mv.value_changed.connect(func(v: float):
		var bus_idx : int = AudioServer.get_bus_index("Music")
		if bus_idx >= 0:
			AudioServer.set_bus_volume_db(bus_idx, linear_to_db(v / 100.0)))
	scr.add_child(mv)

	# Affichage
	scr.add_child(U.lbl("Display:", Vector2(40, 278), 13, U.C_GOLD))
	var disp_labels : Array[String] = ["Fullscreen", "Windowed", "Borderless"]
	for i in range(3):
		var db : Button = U.btn(disp_labels[i],
			Vector2(40 + i * 175, 300), Vector2(160, 34), 12)
		db.process_mode = Node.PROCESS_MODE_ALWAYS
		db.add_theme_stylebox_override("normal",
			U.flat(Color(0.14,0.10,0.04), U.C_GOLD, 2, 6))
		db.add_theme_color_override("font_color", U.C_WHITE)
		match i:
			0: db.pressed.connect(func():
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN))
			1: db.pressed.connect(func():
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED))
			2: db.pressed.connect(func():
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED))
		scr.add_child(db)

	# Bouton fermer
	var close : Button = U.btn("✕  Fermer", Vector2(200, 415), Vector2(200, 42), 15)
	close.process_mode = Node.PROCESS_MODE_ALWAYS
	close.add_theme_stylebox_override("normal",
		U.flat(Color(0.15,0.05,0.05), U.C_PINK, 2, 8))
	close.add_theme_color_override("font_color", U.C_WHITE)
	close.pressed.connect(func(): scr.queue_free())
	scr.add_child(close)


func _go_to_menu() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
	quit_to_menu.emit()
