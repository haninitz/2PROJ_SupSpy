class_name MainMenu
extends Node
# =============================================================================
#  Mainmenu.gd -- SupKonQuest
#  Tous les textes passent par U.lt() pour la localisation
# =============================================================================

signal map_selected(map_index: int)
signal mode_selected(is_ai: bool, difficulty: String)
signal squads_selected(squad1: String, squad2: String)

var main_menu    : Panel
var setup_screen : Panel
var map_screen   : Panel
var mode_screen       : Panel
var difficulty_screen : Panel
var squad_screen      : Panel

var title_label  : Label
var _sparkles    : Array = []
var _is_ai_mode    : bool   = false
var _ai_difficulty : String = "medium"
var _parent : Node
var U : Node


func initialize(parent: Node, u: Node) -> void:
	U = u
	_parent = parent
	_build_main_menu()
	_build_setup_screen()
	_build_map_screen()
	_build_compat_screens()


func _rebuild() -> void:
	for child in [main_menu, setup_screen, map_screen,
			mode_screen, difficulty_screen, squad_screen]:
		if is_instance_valid(child):
			child.queue_free()
	_sparkles.clear()
	_build_main_menu()
	_build_setup_screen()
	_build_map_screen()
	_build_compat_screens()
	main_menu.visible = true


func animate(t: float) -> void:
	if main_menu and main_menu.visible:
		if title_label:
			var r : float = 0.88 + sin(t * 1.4) * 0.12
			var b : float = 0.65 + sin(t * 1.4 + 0.9) * 0.15
			title_label.modulate = Color(r, 0.20, b)
		for i in range(_sparkles.size()):
			var star : Label = _sparkles[i]
			if not is_instance_valid(star):
				continue
			var ph : float = float(i) * 0.72
			star.position.y = star.get_meta("by") + sin(t * 0.9 + ph) * 12.0
			star.position.x = star.get_meta("bx") + cos(t * 0.6 + ph) * 6.0
			star.modulate.a = (sin(t * 1.8 + ph) + 1.0) * 0.45 + 0.1
			star.rotation   = t * 0.4 + ph


func _build_main_menu() -> void:
	main_menu = U.make_screen()
	_parent.add_child(main_menu)

	var grid := _GridNode.new()
	main_menu.add_child(grid)

	var band_colors : Array[Color] = [U.C_PINK, U.C_CYAN, U.C_GOLD, U.C_PURPLE, U.C_PINK]
	for i in range(5):
		var s := ColorRect.new()
		s.color    = Color(band_colors[i].r, band_colors[i].g, band_colors[i].b, 0.04)
		s.size     = Vector2(300, 720)
		s.position = Vector2(i * 240 - 60, 0)
		s.rotation = deg_to_rad(8.0)
		main_menu.add_child(s)

	title_label          = Label.new()
	title_label.text     = "SupKonQuest"
	title_label.position = Vector2(0, 220)
	title_label.size     = Vector2(U.WIN_W, 100)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 72)
	title_label.modulate = U.C_PINK
	main_menu.add_child(title_label)

	var d1 := ColorRect.new()
	d1.color    = U.C_PINK
	d1.position = Vector2(U.WIN_W / 2.0 - 220, 368)
	d1.size     = Vector2(440, 2)
	main_menu.add_child(d1)

	# Boutons principaux — textes via U.lt()
	var btn_data : Array = [
		{"t": U.lt("play"),         "bn": Color(0.28,0.05,0.18), "bb_k": "C_PINK",   "fn": func(): UIUtils.goto(main_menu, setup_screen)},
		{"t": U.lt("multiplayer"),  "bn": Color(0.05,0.18,0.28), "bb_k": "C_CYAN",   "fn": func(): _open_multiplayer()},
		{"t": U.lt("leaderboard"),  "bn": Color(0.15,0.05,0.28), "bb_k": "C_PURPLE", "fn": func(): _open_leaderboard()},
		{"t": U.lt("settings"),     "bn": Color(0.10,0.08,0.20), "bb_k": "C_WHITE",  "fn": func(): _open_settings()},
		{"t": U.lt("quit"),         "bn": Color(0.18,0.05,0.05), "bb_k": "C_WHITE",  "fn": func(): _parent.get_tree().quit()},
	]

	for i in range(btn_data.size()):
		var bd  : Dictionary = btn_data[i]
		var bb  : Color = U.C_PINK
		if bd["bb_k"] == "C_CYAN": bb = U.C_CYAN
		elif bd["bb_k"] == "C_PURPLE": bb = U.C_PURPLE
		elif bd["bb_k"] == "C_WHITE":
			bb = Color(0.70, 0.20, 0.20) if i == 4 else Color(0.55, 0.50, 0.75)
		var b : Button = U.btn("  " + bd["t"], Vector2(U.WIN_W / 2.0 - 180, 390 + i * 58), Vector2(360, 48), 18)
		b.add_theme_stylebox_override("normal", U.flat(bd["bn"], bb, 2, 8))
		b.add_theme_stylebox_override("hover",  U.flat(Color(bd["bn"].r*1.8, bd["bn"].g*1.8, bd["bn"].b*1.8), bb, 2, 8))
		b.add_theme_color_override("font_color", U.C_WHITE)
		b.pressed.connect(bd["fn"])
		main_menu.add_child(b)

	# Boutons langue
	var lang_codes  : Array[String] = ["fr", "en", "es"]
	var lang_labels : Array[String] = ["FR", "EN", "ES"]
	var cur_lang : String = U.get_lang()
	for i in range(3):
		var lc : String = lang_codes[i]
		var lb : Button = U.btn(lang_labels[i], Vector2(U.WIN_W - 195 + i * 64, 18), Vector2(58, 32), 11)
		var active : bool = lc == cur_lang
		lb.add_theme_stylebox_override("normal",
			U.flat(Color(0.35,0.08,0.25) if active else Color(0.12,0.05,0.12),
				   U.C_PINK if active else Color(0.40,0.15,0.35), 2, 6))
		lb.pressed.connect(func(captured_lc: String = lc):
			var lang : Node = _parent.get_node_or_null("/root/Lang")
			if lang: lang.current = captured_lc
			_rebuild())
		main_menu.add_child(lb)

	# Étoiles flottantes
	var shapes   : Array[String] = ["*","+","x","o","#"]
	var s_colors : Array[Color]  = [U.C_PINK, U.C_CYAN, U.C_GOLD, U.C_PURPLE]
	for i in range(18):
		var star := Label.new()
		star.text = shapes[i % shapes.size()]
		star.add_theme_font_size_override("font_size", 8 + (i % 5) * 4)
		star.modulate = s_colors[i % s_colors.size()]
		var bx : float = float((i * 57 + 30) % U.WIN_W)
		var by : float = float((i * 83 + 40) % 680)
		star.position = Vector2(bx, by)
		star.set_meta("bx", bx)
		star.set_meta("by", by)
		main_menu.add_child(star)
		_sparkles.append(star)

	var ft : Label = U.lbl(U.lt("footer"), Vector2(0, 698), 10, Color(0.40, 0.30, 0.55))
	ft.size = Vector2(U.WIN_W, 20)
	ft.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_menu.add_child(ft)


func _build_setup_screen() -> void:
	setup_screen = U.make_screen(false)
	_parent.add_child(setup_screen)
	U.add_header(setup_screen, U.lt("new_game"), U.C_PINK)

	setup_screen.add_child(U.lbl(U.lt("mode_title") + " :", Vector2(55, 140), 13, U.C_PINK))
	var btn2p : Button = U.btn(U.lt("mode_2p"), Vector2(55, 165), Vector2(200, 42), 15)
	var btn1p : Button = U.btn(U.lt("mode_1p_short"), Vector2(265, 165), Vector2(200, 42), 15)
	btn2p.add_theme_stylebox_override("normal", U.flat(Color(0.05,0.18,0.05), U.C_GREEN, 2, 8))
	btn1p.add_theme_stylebox_override("normal", U.flat(Color(0.08,0.05,0.22), U.C_CYAN, 2, 8))
	btn2p.add_theme_color_override("font_color", U.C_WHITE)
	btn1p.add_theme_color_override("font_color", U.C_WHITE)
	setup_screen.add_child(btn2p)
	setup_screen.add_child(btn1p)

	var mode_ind := Label.new()
	mode_ind.name = "ModeInd"
	mode_ind.text = U.lt("mode_2p")
	mode_ind.position = Vector2(55, 215)
	mode_ind.add_theme_font_size_override("font_size", 11)
	mode_ind.add_theme_color_override("font_color", U.C_GREEN)
	setup_screen.add_child(mode_ind)

	var diff_panel := Panel.new()
	diff_panel.name    = "DiffPanel"
	diff_panel.position = Vector2(55, 232)
	diff_panel.size    = Vector2(440, 52)
	diff_panel.visible = false
	diff_panel.add_theme_stylebox_override("panel", U.flat(Color(0.06,0.04,0.18), U.C_CYAN, 1, 8))
	setup_screen.add_child(diff_panel)
	diff_panel.add_child(U.lbl(U.lt("diff_title") + " :", Vector2(8, 14), 12, U.C_CYAN))

	var diff_data : Array = [
		{"t": U.lt("diff_easy"),   "col": U.C_GREEN, "k": "easy"},
		{"t": U.lt("diff_med"),    "col": U.C_GOLD,  "k": "medium"},
		{"t": U.lt("diff_hard"),   "col": U.C_PINK,  "k": "hard"},
	]
	for i in range(3):
		var dd : Dictionary = diff_data[i]
		var db : Button = U.btn(dd["t"], Vector2(95 + i * 112, 9), Vector2(104, 34), 13)
		db.add_theme_stylebox_override("normal",
			U.flat(Color(dd["col"].r*0.18, dd["col"].g*0.18, dd["col"].b*0.18), dd["col"], 2, 6))
		db.add_theme_color_override("font_color", U.C_WHITE)
		var dk : String = dd["k"]
		var dt : String = dd["t"]
		db.pressed.connect(func():
			_ai_difficulty  = dk
			mode_ind.text   = "Mode : IA (%s)" % dt
			mode_ind.modulate = U.C_CYAN)
		diff_panel.add_child(db)

	btn2p.pressed.connect(func():
		_is_ai_mode = false
		diff_panel.visible = false
		mode_ind.text = U.lt("mode_2p")
		mode_ind.modulate = U.C_GREEN)
	btn1p.pressed.connect(func():
		_is_ai_mode = true
		diff_panel.visible = true
		mode_ind.text = U.lt("mode_1p_short")
		mode_ind.modulate = U.C_CYAN)

	var names_y : int = 298
	setup_screen.add_child(U.lbl(U.lt("player_names") + " :", Vector2(55, names_y), 13, U.C_PINK))
	_player_row(setup_screen, U.lt("player1"), U.C_PINK, Vector2(55, names_y + 24), "P1Edit")
	_player_row(setup_screen, U.lt("player2"), U.C_CYAN, Vector2(55, names_y + 82), "P2Edit")

	var next_btn : Button = U.btn(U.lt("next_map"), Vector2(U.WIN_W - 320, 638), Vector2(280, 50), 18)
	next_btn.add_theme_stylebox_override("normal", U.flat(Color(0.28,0.05,0.18), U.C_PINK, 2, 10))
	next_btn.add_theme_color_override("font_color", U.C_WHITE)
	next_btn.pressed.connect(func():
		var p1e : Node = setup_screen.find_child("P1Edit", true, false)
		var p2e : Node = setup_screen.find_child("P2Edit", true, false)
		var p1n : String = p1e.text.strip_edges() if p1e else U.lt("player1")
		var p2n : String = "IA" if _is_ai_mode else (p2e.text.strip_edges() if p2e else U.lt("player2"))
		if p1n.is_empty(): p1n = U.lt("player1")
		if p2n.is_empty(): p2n = U.lt("player2") if not _is_ai_mode else "IA"
		mode_selected.emit(_is_ai_mode, _ai_difficulty)
		squads_selected.emit(p1n, p2n)
		UIUtils.goto(setup_screen, map_screen))
	setup_screen.add_child(next_btn)
	setup_screen.add_child(U.back_btn(func(): UIUtils.goto(setup_screen, main_menu)))


func _player_row(parent: Control, pname: String, col: Color, pos: Vector2, edit_name: String) -> Panel:
	var row := Panel.new()
	row.position = pos
	row.size = Vector2(520, 50)
	row.add_theme_stylebox_override("panel", U.flat(Color(col.r*0.10, col.g*0.10, col.b*0.10), col, 1, 8))
	parent.add_child(row)
	var bar := ColorRect.new()
	bar.color = col; bar.position = Vector2(0, 0); bar.size = Vector2(5, 50)
	row.add_child(bar)
	row.add_child(U.lbl(pname, Vector2(14, 12), 13, col))
	var edit := LineEdit.new()
	edit.name = edit_name; edit.text = pname
	edit.position = Vector2(115, 9); edit.size = Vector2(200, 32)
	row.add_child(edit)
	return row


func _build_map_screen() -> void:
	map_screen = U.make_screen(false)
	_parent.add_child(map_screen)
	U.add_header(map_screen, U.lt("map_title"), U.C_GOLD)

	var map_data : Array = [
		{"name": "Beverly Hills  (Clover)", "desc": "Urbain - Riviere - Pont",     "col": U.C_PINK},
		{"name": "Jungle Techno  (Sam)",    "desc": "Foret dense - Hauts revenus", "col": U.C_GREEN},
		{"name": "Ile Tropicale  (Alex)",   "desc": "Ile - Ocean - Ports",         "col": U.C_CYAN},
	]

	for i in range(map_data.size()):
		var md : Dictionary = map_data[i]
		var card := Panel.new()
		card.position = Vector2(55, 140 + i * 148)
		card.size = Vector2(U.WIN_W - 110, 130)
		card.add_theme_stylebox_override("panel",
			U.flat(Color(md["col"].r*0.10, md["col"].g*0.10, md["col"].b*0.10), md["col"], 1, 10))
		map_screen.add_child(card)
		card.add_child(U.lbl("0%d" % (i+1), Vector2(18, 28), 32,
			Color(md["col"].r, md["col"].g, md["col"].b, 0.30)))
		card.add_child(U.lbl(md["name"], Vector2(70, 22), 22, U.C_WHITE))
		card.add_child(U.lbl(md["desc"], Vector2(70, 52), 13,
			Color(md["col"].r, md["col"].g, md["col"].b, 0.85)))
		var play : Button = U.btn(U.lt("play_btn"),
			Vector2(card.size.x - 130, 40), Vector2(110, 50), 16)
		play.add_theme_stylebox_override("normal",
			U.flat(Color(md["col"].r*0.22, md["col"].g*0.22, md["col"].b*0.22), md["col"], 2, 8))
		play.add_theme_stylebox_override("hover",
			U.flat(Color(md["col"].r*0.40, md["col"].g*0.40, md["col"].b*0.40), md["col"], 2, 8))
		play.add_theme_color_override("font_color", U.C_WHITE)
		play.pressed.connect(func(idx: int = i):
			map_screen.visible = false
			map_selected.emit(idx))
		card.add_child(play)

	map_screen.add_child(U.back_btn(func(): UIUtils.goto(map_screen, setup_screen)))


func hide_map_screen() -> void:
	if map_screen:
		map_screen.visible = false


func _open_multiplayer() -> void:
	SceneLoader.goto("res://scenes/online/Login.tscn")


func _open_leaderboard() -> void:
	_open_overlay(U.lt("leaderboard"), U.C_PURPLE, func(scr: Panel):
		var headers : Array[String] = ["#", U.lt("player_col"), "ELO", U.lt("wins"), U.lt("losses")]
		var cols_x  : Array[int]    = [55, 110, 380, 550, 680]
		for i in range(headers.size()):
			scr.add_child(U.lbl(headers[i], Vector2(cols_x[i], 148), 13, U.C_PURPLE))
		var div := ColorRect.new()
		div.color = Color(U.C_PURPLE.r, U.C_PURPLE.g, U.C_PURPLE.b, 0.5)
		div.position = Vector2(55, 168); div.size = Vector2(U.WIN_W - 110, 1)
		scr.add_child(div)
		var rows : Array = [
			["1","Champion","1850","42","8"],
			["2","Stratege","1720","35","12"],
			["3","Conquerant","1680","30","10"],
		]
		for r in range(rows.size()):
			for c in range(rows[r].size()):
				scr.add_child(U.lbl(rows[r][c], Vector2(cols_x[c], 184 + r * 44), 14,
					U.C_GOLD if r == 0 else Color(0.88, 0.85, 0.92))))


func _open_settings() -> void:
	_open_overlay(U.lt("settings"), Color(0.55, 0.50, 0.75), func(scr: Panel):
		scr.add_child(U.lbl(U.lt("lang_title") + " :", Vector2(55, 130), 13, U.C_PINK))
		var lang_codes  : Array[String] = ["fr", "en", "es"]
		var lang_labels : Array[String] = ["Français", "English", "Español"]
		for i in range(3):
			var lc : String = lang_codes[i]
			var lb : Button = U.btn(lang_labels[i], Vector2(55 + i * 148, 154), Vector2(134, 36), 13)
			lb.add_theme_stylebox_override("normal", U.flat(Color(0.12,0.05,0.18), U.C_PINK, 2, 8))
			lb.add_theme_color_override("font_color", U.C_WHITE)
			lb.pressed.connect(func(captured_lc: String = lc):
				var lang : Node = _parent.get_node_or_null("/root/Lang")
				if lang: lang.current = captured_lc
				_rebuild())
			scr.add_child(lb)
		scr.add_child(U.lbl(U.lt("volume") + " :", Vector2(55, 210), 13, U.C_CYAN))
		var sv : HSlider = HSlider.new()
		sv.position = Vector2(55, 232); sv.size = Vector2(350, 22)
		sv.min_value = 0; sv.max_value = 100; sv.value = 80
		sv.value_changed.connect(func(v: float):
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(v / 100.0)))
		scr.add_child(sv))


func _open_overlay(title: String, col: Color, builder: Callable) -> void:
	main_menu.visible = false
	var scr : Panel = U.make_screen(true)
	_parent.add_child(scr)
	U.add_header(scr, title, col)
	builder.call(scr)
	scr.add_child(U.back_btn(func():
		scr.queue_free()
		main_menu.visible = true))


func _build_compat_screens() -> void:
	mode_screen       = U.make_screen(false); _parent.add_child(mode_screen)
	difficulty_screen = U.make_screen(false); _parent.add_child(difficulty_screen)
	squad_screen      = U.make_screen(false); _parent.add_child(squad_screen)


class _GridNode extends Node2D:
	func _draw() -> void:
		var col := Color(1.00, 0.20, 0.58, 0.04)
		var x : int = 0
		while x <= 1152:
			draw_line(Vector2(x, 0), Vector2(x, 720), col, 1.0)
			x += 48
		var y : int = 0
		while y <= 720:
			draw_line(Vector2(0, y), Vector2(1152, y), col, 1.0)
			y += 48
		var dc := Color(0.00, 0.90, 0.88, 0.025)
		var i : int = 0
		while i < 1900:
			draw_line(Vector2(i, 0), Vector2(0, i), dc, 1.0)
			i += 96