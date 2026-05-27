extends Control
# online_menu.gd — Menu principal online · Totally Spies

const C_BG     := Color(0.04, 0.02, 0.10)
const C_PINK   := Color(1.00, 0.20, 0.58)
const C_PURPLE := Color(0.55, 0.15, 0.85)
const C_CYAN   := Color(0.00, 0.90, 0.88)
const C_GOLD   := Color(1.00, 0.85, 0.20)
const C_WHITE  := Color(1.00, 1.00, 1.00)

func _ready() -> void:
	_build()

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = C_BG; bg.size = Vector2(1152, 720)
	add_child(bg)

	for i in range(18):
		var s := Label.new()
		s.text = ["✦","✧","★","◆"][i % 4]
		s.position = Vector2(60.0 + i * 62.0, 30.0 + sin(i * 0.8) * 20.0)
		s.add_theme_font_size_override("font_size", 10 + i % 6)
		s.modulate = [C_PINK, C_PURPLE, C_CYAN, C_GOLD][i % 4]
		s.modulate.a = 0.35
		add_child(s)

	var panel := Panel.new()
	panel.position = Vector2(1152.0/2 - 220, 720.0/2 - 240)
	panel.size     = Vector2(440, 460)
	panel.add_theme_stylebox_override("panel", _flat(C_BG, C_PINK, 2, 14))
	add_child(panel)

	var badge := Label.new()
	badge.text = "W.O.O.H.P · OPERATIONS EN LIGNE"
	badge.position = Vector2(0, 20); badge.size = Vector2(440, 22)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 11)
	badge.add_theme_color_override("font_color", C_PURPLE)
	panel.add_child(badge)

	var title := Label.new()
	title.text = "✦  SUPKONQUEST  ✦"
	title.position = Vector2(0, 44); title.size = Vector2(440, 55)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", C_PINK)
	panel.add_child(title)

	# Welcome
	var welcome := Label.new()
	welcome.text = "Bienvenue, %s !" % GameConfig.steam_name
	welcome.position = Vector2(0, 100); welcome.size = Vector2(440, 28)
	welcome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	welcome.add_theme_font_size_override("font_size", 16)
	welcome.add_theme_color_override("font_color", C_GOLD)
	panel.add_child(welcome)

	# Stats
	var stats := Label.new()
	stats.text = "Victoires : %d   •   Défaites : %d" % [GameConfig.wins, GameConfig.losses]
	stats.position = Vector2(0, 128); stats.size = Vector2(440, 22)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_theme_font_size_override("font_size", 12)
	stats.add_theme_color_override("font_color", Color(0.75, 0.60, 0.85))
	panel.add_child(stats)

	var div := ColorRect.new()
	div.color = Color(C_PINK.r, C_PINK.g, C_PINK.b, 0.35)
	div.position = Vector2(30, 158); div.size = Vector2(380, 1)
	panel.add_child(div)

	_btn(panel, "✦  CRÉER UNE MISSION", Vector2(30, 175), C_PINK).pressed.connect(
		func():
			GameConfig.is_host = true
			NetworkManager.create_server()
			SceneLoader.goto("res://scenes/online/ChoixMode.tscn"))

	_btn(panel, "⟳  REJOINDRE UNE MISSION", Vector2(30, 240), C_PURPLE).pressed.connect(
		func(): SceneLoader.goto("res://scenes/online/ListeRooms.tscn"))

	_btn(panel, "← Retour au menu principal", Vector2(30, 305), Color(0.30, 0.20, 0.45)).pressed.connect(
		func(): SceneLoader.goto("res://scenes/Main.tscn"))

	_btn(panel, "Déconnexion", Vector2(30, 370), Color(0.40, 0.10, 0.20)).pressed.connect(
		func():
			Matchmaker.logout(GameConfig.token)
			if FileAccess.file_exists("user://token.dat"):
				DirAccess.remove_absolute("user://token.dat")
			GameConfig.reset()
			SceneLoader.goto("res://scenes/online/Login.tscn"))

func _flat(bg: Color, border: Color, bw: int, cr: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg; s.border_color = border
	s.border_width_left = bw; s.border_width_right = bw
	s.border_width_top  = bw; s.border_width_bottom = bw
	s.corner_radius_top_left    = cr; s.corner_radius_top_right    = cr
	s.corner_radius_bottom_left = cr; s.corner_radius_bottom_right = cr
	return s

func _btn(parent: Control, text: String, pos: Vector2, col: Color) -> Button:
	var b := Button.new()
	b.text = text; b.position = pos; b.size = Vector2(380, 52)
	b.add_theme_font_size_override("font_size", 15)
	b.add_theme_stylebox_override("normal",
		_flat(Color(col.r*.18,col.g*.18,col.b*.18), col, 2, 8))
	b.add_theme_stylebox_override("hover",
		_flat(Color(col.r*.32,col.g*.32,col.b*.32), col, 2, 8))
	b.add_theme_color_override("font_color", C_WHITE)
	parent.add_child(b)
	return b
