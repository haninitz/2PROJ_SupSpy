extends Control
# choix_format.gd — SupKonQuest · Totally Spies

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
	bg.color = C_BG
	bg.size = Vector2(1152, 720)
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
	panel.size = Vector2(440, 460)
	panel.add_theme_stylebox_override("panel", _flat(C_BG, C_PINK, 2, 14))
	add_child(panel)

	var title := Label.new()
	title.text = "✦  FORMAT DE MISSION  ✦"
	title.position = Vector2(0, 36)
	title.size = Vector2(440, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", C_PINK)
	panel.add_child(title)

	var div := ColorRect.new()
	div.color = Color(C_PINK.r, C_PINK.g, C_PINK.b, 0.30)
	div.position = Vector2(30, 94)
	div.size = Vector2(380, 1)
	panel.add_child(div)

	var btn_1v1 := _btn(panel, "✦  1 VS 1  —  Duel d'agentes", Vector2(30, 115), C_PINK)
	btn_1v1.pressed.connect(func(): _select("1v1"))
	_desc(panel, "Face a face — la mission la plus intense", Vector2(30, 169))

	var btn_2v2 := _btn(panel, "✦  2 VS 2  —  Equipes de choc", Vector2(30, 195), C_PURPLE)
	btn_2v2.pressed.connect(func(): _select("2v2"))
	_desc(panel, "Coordonne-toi avec ton equipiere", Vector2(30, 249))

	var btn_3v3 := _btn(panel, "✦  3 VS 3  —  Guerre totale", Vector2(30, 275), C_CYAN)
	btn_3v3.pressed.connect(func(): _select("3v3"))
	_desc(panel, "Le plus grand affrontement W.O.O.H.P", Vector2(30, 329))

	var btn_back := _btn(panel, "← Retour", Vector2(30, 375), Color(0.30, 0.20, 0.45))
	btn_back.pressed.connect(_on_back_pressed)

func _select(f: String) -> void:
	GameConfig.format = f
	SceneLoader.goto("res://scenes/online/ChoixMap.tscn")

func _on_back_pressed() -> void:
	SceneLoader.goto("res://scenes/online/ChoixMode.tscn")

func _desc(parent: Control, text: String, pos: Vector2) -> void:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.size = Vector2(380, 20)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 11)
	l.add_theme_color_override("font_color", Color(0.65, 0.50, 0.80))
	parent.add_child(l)

func _flat(bg: Color, border: Color, bw: int, cr: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.border_width_left = bw
	s.border_width_right = bw
	s.border_width_top = bw
	s.border_width_bottom = bw
	s.corner_radius_top_left = cr
	s.corner_radius_top_right = cr
	s.corner_radius_bottom_left = cr
	s.corner_radius_bottom_right = cr
	return s

func _btn(parent: Control, text: String, pos: Vector2, col: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = Vector2(380, 52)
	b.add_theme_font_size_override("font_size", 14)
	b.add_theme_stylebox_override("normal", _flat(Color(col.r*0.18, col.g*0.18, col.b*0.18), col, 2, 8))
	b.add_theme_stylebox_override("hover", _flat(Color(col.r*0.32, col.g*0.32, col.b*0.32), col, 2, 8))
	b.add_theme_color_override("font_color", C_WHITE)
	parent.add_child(b)
	return b
