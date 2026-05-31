class_name PauseMenu
extends CanvasLayer

signal resumed
signal quit_to_menu

var _panel       : Panel
var _active      : bool = false
var U            : Node
var _title_lbl   : Label
var _sub_lbl     : Label
var _hint_lbl    : Label
var _btn_resume  : Button
var _btn_options : Button
var _btn_menu    : Button
var _btn_quit    : Button

func setup(u: Node) -> void:
	U = u
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()

func _build() -> void:
	var bg := ColorRect.new()
	bg.color         = Color(0.0, 0.0, 0.0, 0.60)
	bg.size          = Vector2(1152, 720)
	bg.position      = Vector2.ZERO
	add_child(bg)

	_panel = Panel.new()
	_panel.position = Vector2(1152.0 / 2.0 - 200, 720.0 / 2.0 - 200)
	_panel.size     = Vector2(400, 380)
	_panel.add_theme_stylebox_override("panel",
		U.flat(Color(0.04, 0.02, 0.10, 0.96), U.C_PINK, 2, 16))
	add_child(_panel)

	_title_lbl      = U.lbl(U.lt("pause_title"), Vector2(0, 28), 28, U.C_PINK)
	_title_lbl.size = Vector2(400, 50)
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_child(_title_lbl)

	_sub_lbl      = U.lbl(U.lt("pause_sub"), Vector2(0, 68), 11, Color(0.55, 0.40, 0.70))
	_sub_lbl.size = Vector2(400, 20)
	_sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_child(_sub_lbl)

	var div := ColorRect.new()
	div.color    = Color(U.C_PINK.r, U.C_PINK.g, U.C_PINK.b, 0.35)
	div.position = Vector2(30, 96)
	div.size     = Vector2(340, 1)
	_panel.add_child(div)

	var btn_defs := [
		{"key": "pause_resume",  "col": U.C_PINK,              "fn": func(): resume(),         "ref": "_btn_resume"},
		{"key": "pause_options", "col": U.C_CYAN,              "fn": func(): _open_options(),  "ref": "_btn_options"},
		{"key": "pause_menu",    "col": U.C_GOLD,              "fn": func(): _go_to_menu(),    "ref": "_btn_menu"},
		{"key": "pause_quit", "col": Color(0.70, 0.20, 0.20), "fn": func(): _quit_game(), "ref": "_btn_quit"},
	]

	for i in range(btn_defs.size()):
		var bd : Dictionary = btn_defs[i]
		var col : Color = bd["col"]
		var b : Button = U.btn(U.lt(bd["key"]), Vector2(50, 118 + i * 58), Vector2(300, 46), 16)
		b.add_theme_stylebox_override("normal",
			U.flat(Color(col.r*0.15, col.g*0.15, col.b*0.15), col, 2, 8))
		b.add_theme_stylebox_override("hover",
			U.flat(Color(col.r*0.28, col.g*0.28, col.b*0.28), col, 2, 8))
		b.add_theme_color_override("font_color", U.C_WHITE)
		b.pressed.connect(bd["fn"])
		_panel.add_child(b)

		match bd["ref"]:
			"_btn_resume":  _btn_resume  = b
			"_btn_options": _btn_options = b
			"_btn_menu":    _btn_menu    = b
			"_btn_quit":    _btn_quit    = b

	_hint_lbl      = U.lbl(U.lt("pause_hint"), Vector2(0, 350), 10, Color(0.40, 0.30, 0.55))
	_hint_lbl.size = Vector2(400, 20)
	_hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_child(_hint_lbl)

	visible = false

func toggle() -> void:
	if _active:
		resume()
	else:
		pause()

func pause() -> void:
	_active           = true
	visible           = true
	get_tree().paused = true
	if _title_lbl:   _title_lbl.text   = U.lt("pause_title")
	if _sub_lbl:     _sub_lbl.text     = U.lt("pause_sub")
	if _hint_lbl:    _hint_lbl.text    = U.lt("pause_hint")
	if _btn_resume:  _btn_resume.text  = U.lt("pause_resume")
	if _btn_options: _btn_options.text = U.lt("pause_options")
	if _btn_menu:    _btn_menu.text    = U.lt("pause_menu")
	if _btn_quit:    _btn_quit.text    = U.lt("pause_quit")

func resume() -> void:
	_active              = false
	visible              = false
	get_tree().paused    = false
	resumed.emit()

func _open_options() -> void:
	var scr : Panel = Panel.new()
	scr.position = Vector2(1152.0 / 2.0 - 300, 720.0 / 2.0 - 260)
	scr.size     = Vector2(600, 480)
	scr.process_mode = Node.PROCESS_MODE_ALWAYS
	scr.add_theme_stylebox_override("panel",
		U.flat(Color(0.04, 0.02, 0.10, 0.98), U.C_CYAN, 2, 14))
	add_child(scr)

	var title : Label = U.lbl(U.lt("opt_title"), Vector2(0, 22), 22, U.C_CYAN)
	title.size = Vector2(600, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scr.add_child(title)

	var div := ColorRect.new()
	div.color = Color(U.C_CYAN.r, U.C_CYAN.g, U.C_CYAN.b, 0.30)
	div.position = Vector2(30, 60); div.size = Vector2(540, 1)
	scr.add_child(div)

	scr.add_child(U.lbl(U.lt("opt_language"), Vector2(40, 80), 13, U.C_PINK))
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

	scr.add_child(U.lbl(U.lt("opt_sound"), Vector2(40, 155), 13, U.C_CYAN))
	var sv : HSlider = HSlider.new()
	sv.position = Vector2(40, 177); sv.size = Vector2(520, 22)
	sv.min_value = 0; sv.max_value = 100; sv.value = 80
	sv.process_mode = Node.PROCESS_MODE_ALWAYS
	sv.value_changed.connect(func(v: float):
		AudioServer.set_bus_volume_db(
			AudioServer.get_bus_index("Master"), linear_to_db(v / 100.0)))
	scr.add_child(sv)

	scr.add_child(U.lbl(U.lt("opt_music"), Vector2(40, 215), 13, U.C_CYAN))
	var mv : HSlider = HSlider.new()
	mv.position = Vector2(40, 237); mv.size = Vector2(520, 22)
	mv.min_value = 0; mv.max_value = 100; mv.value = 50
	mv.process_mode = Node.PROCESS_MODE_ALWAYS
	mv.value_changed.connect(func(v: float):
		var bus_idx : int = AudioServer.get_bus_index("Music")
		if bus_idx >= 0:
			AudioServer.set_bus_volume_db(bus_idx, linear_to_db(v / 100.0)))
	scr.add_child(mv)

	scr.add_child(U.lbl(U.lt("opt_display"), Vector2(40, 278), 13, U.C_GOLD))
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

	var close : Button = U.btn(U.lt("opt_close"), Vector2(200, 415), Vector2(200, 42), 15)
	close.process_mode = Node.PROCESS_MODE_ALWAYS
	close.add_theme_stylebox_override("normal",
		U.flat(Color(0.15,0.05,0.05), U.C_PINK, 2, 8))
	close.add_theme_color_override("font_color", U.C_WHITE)
	close.pressed.connect(func(): scr.queue_free())
	scr.add_child(close)

func _go_to_menu() -> void:
	get_tree().paused = false
	quit_to_menu.emit()
	print("[PauseMenu] _go_to_menu mode='%s' is_host=%s" % [GameConfig.mode, GameConfig.is_host])
	if GameConfig.mode == "multi":
		if GameConfig.is_host:
			NetworkManager.notify_host_leaving()
			await get_tree().create_timer(0.3).timeout
			NetworkManager.disconnect_from_server()
			get_tree().quit()
			return
		else:
			NetworkManager.disconnect_from_server()
			GameConfig.mode = ""
			get_tree().change_scene_to_file("res://scenes/Main.tscn")
			return
	GameConfig.mode = ""
	get_tree().reload_current_scene()
	
func _quit_game() -> void:
	if GameConfig.mode == "multi":
		if GameConfig.is_host:
			NetworkManager.notify_host_leaving()
			await get_tree().create_timer(0.3).timeout
		NetworkManager.disconnect_from_server()
	get_tree().quit()
