extends Control
# choix_mode.gd — SupKonQuest · Totally Spies

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

	var panel := Panel.new()
	panel.position = Vector2(1152.0/2 - 220, 720.0/2 - 220)
	panel.size = Vector2(440, 420)
	panel.add_theme_stylebox_override("panel", _flat(C_BG, C_CYAN, 2, 14))
	add_child(panel)

	_title(panel, "MODE DE MISSION", C_CYAN)

	var btn_multi := _btn(panel, "MULTIJOUEUR EN LIGNE", Vector2(30, 120), C_PINK)
	btn_multi.pressed.connect(_on_multi_pressed)
	_desc(panel, "Affronte des agents du monde entier", Vector2(30, 174))

	var btn_ai := _btn(panel, "VS INTELLIGENCE ARTIFICIELLE", Vector2(30, 200), C_PURPLE)
	btn_ai.pressed.connect(_on_ai_pressed)
	_desc(panel, "Entraine-toi contre notre IA W.O.O.H.P", Vector2(30, 254))

	var btn_back := _btn(panel, "Retour", Vector2(30, 330), Color(0.30, 0.20, 0.45))
	btn_back.pressed.connect(_on_back_pressed)

func _on_multi_pressed() -> void:
	GameConfig.mode = "multi"
	SceneLoader.goto("res://scenes/online/ChoixFormat.tscn")

func _on_ai_pressed() -> void:
	GameConfig.mode = "ai"
	SceneLoader.goto("res://scenes/online/ChoixDiff.tscn")

func _on_back_pressed() -> void:
	NetworkManager.disconnect_from_server()
	SceneLoader.goto("res://scenes/online/OnlineMenu.tscn")

func _title(parent: Control, text: String, col: Color) -> void:
	var l := Label.new()
	l.text = "  %s  " % text
	l.position = Vector2(0, 36)
	l.size = Vector2(440, 50)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 24)
	l.add_theme_color_override("font_color", col)
	parent.add_child(l)

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
