extends Control
# choix_diff.gd — SupKonQuest · Totally Spies

const C_BG     := Color(0.04, 0.02, 0.10)
const C_PINK   := Color(1.00, 0.20, 0.58)
const C_PURPLE := Color(0.55, 0.15, 0.85)
const C_CYAN   := Color(0.00, 0.90, 0.88)
const C_GOLD   := Color(1.00, 0.85, 0.20)
const C_WHITE  := Color(1.00, 1.00, 1.00)

func _ready() -> void: _build()

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = C_BG
	bg.size = Vector2(1152, 720)
	add_child(bg)

	var panel := Panel.new()
	panel.position = Vector2(1152.0 / 2 - 220, 720.0 / 2 - 240)
	panel.size = Vector2(440, 460)
	panel.add_theme_stylebox_override("panel", _flat(C_BG, C_GOLD, 2, 14))
	add_child(panel)

	var title := Label.new()
	title.text = "✦  NIVEAU DE L'IA  ✦"
	title.position = Vector2(0, 36)
	title.size = Vector2(440, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", C_GOLD)
	panel.add_child(title)

	var easy_btn := _btn(panel, "★  RECRUE  (Facile)", Vector2(30, 120), C_CYAN)
	easy_btn.pressed.connect(func():
		GameConfig.diff = "easy"
		SceneLoader.goto("res://scenes/online/ChoixMap.tscn")
	)
	_desc(panel, "L'IA attaque rarement et recrute peu", Vector2(30, 174))

	var med_btn := _btn(panel, "★★  AGENTE  (Moyen)", Vector2(30, 200), C_PURPLE)
	med_btn.pressed.connect(func():
		GameConfig.diff = "med"
		SceneLoader.goto("res://scenes/online/ChoixMap.tscn")
	)
	_desc(panel, "L'IA gère ses troupes et sait attaquer", Vector2(30, 254))

	var hard_btn := _btn(panel, "★★★  SUPER AGENTE  (Difficile)", Vector2(30, 280), C_PINK)
	hard_btn.pressed.connect(func():
		GameConfig.diff = "hard"
		SceneLoader.goto("res://scenes/online/ChoixMap.tscn")
	)
	_desc(panel, "L'IA est agressive et optimise ses revenus", Vector2(30, 334))

	var back_btn := _btn(panel, "← Retour", Vector2(30, 370), Color(0.30, 0.20, 0.45))
	back_btn.pressed.connect(func():
		SceneLoader.goto("res://scenes/online/ChoixMode.tscn")
	)
	
func _desc(parent: Control, text: String, pos: Vector2) -> void:
	var l := Label.new()
	l.text = text; l.position = pos; l.size = Vector2(380, 20)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 11)
	l.add_theme_color_override("font_color", Color(0.65, 0.55, 0.75))
	parent.add_child(l)

func _flat(bg: Color, border: Color, bw: int, cr: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg; s.border_color = border
	s.border_width_left = bw; s.border_width_right = bw
	s.border_width_top  = bw; s.border_width_bottom = bw
	s.corner_radius_top_left = cr; s.corner_radius_top_right = cr
	s.corner_radius_bottom_left = cr; s.corner_radius_bottom_right = cr
	return s

func _btn(parent: Control, text: String, pos: Vector2, col: Color) -> Button:
	var b := Button.new()
	b.text = text; b.position = pos; b.size = Vector2(380, 52)
	b.add_theme_font_size_override("font_size", 14)
	b.add_theme_stylebox_override("normal", _flat(Color(col.r*.18,col.g*.18,col.b*.18), col, 2, 8))
	b.add_theme_stylebox_override("hover",  _flat(Color(col.r*.32,col.g*.32,col.b*.32), col, 2, 8))
	b.add_theme_color_override("font_color", C_WHITE)
	parent.add_child(b)
	return b