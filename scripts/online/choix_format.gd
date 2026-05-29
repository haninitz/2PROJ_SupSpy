extends Control
# choix_format.gd — SupKonQuest · Totally Spies
# Choix du nombre de joueurs pour la room (2 à 8)

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

	# Décorations étoiles
	for i in range(18):
		var s := Label.new()
		s.text = ["✦","✧","★","◆"][i % 4]
		s.position = Vector2(60.0 + i * 62.0, 30.0 + sin(i * 0.8) * 20.0)
		s.add_theme_font_size_override("font_size", 10 + i % 6)
		s.modulate = [C_PINK, C_PURPLE, C_CYAN, C_GOLD][i % 4]
		s.modulate.a = 0.35
		add_child(s)

	var panel := Panel.new()
	panel.position = Vector2(1152.0/2 - 260, 720.0/2 - 280)
	panel.size = Vector2(520, 520)
	panel.add_theme_stylebox_override("panel", _flat(C_BG, C_PINK, 2, 14))
	add_child(panel)

	var title := Label.new()
	title.text = "✦  NOMBRE DE JOUEURS  ✦"
	title.position = Vector2(0, 36)
	title.size = Vector2(520, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", C_PINK)
	panel.add_child(title)

	var sub := Label.new()
	sub.text = "Choisis combien de joueurs participent à la mission"
	sub.position = Vector2(0, 84)
	sub.size = Vector2(520, 20)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 11)
	sub.add_theme_color_override("font_color", Color(0.65, 0.50, 0.80))
	panel.add_child(sub)

	var div := ColorRect.new()
	div.color = Color(C_PINK.r, C_PINK.g, C_PINK.b, 0.30)
	div.position = Vector2(30, 110)
	div.size = Vector2(460, 1)
	panel.add_child(div)

	# Boutons 2 à 8 joueurs — 2 rangées : [2,3,4,5] et [6,7,8]
	var colors : Array[Color] = [
		C_CYAN, C_PINK, C_PURPLE, C_GOLD,
		C_CYAN, C_PINK, C_PURPLE
	]
	var descs : Array[String] = [
		"2 joueurs", "3 joueurs", "4 joueurs", "5 joueurs",
		"6 joueurs", "7 joueurs", "8 joueurs"
	]

	for i in range(7):
		var nb : int = i + 2  # 2..8
		var col : Color = colors[i]
		var row : int = i / 4
		var col_i : int = i % 4
		var btn_w : float = 104.0
		var btn_x : float = 30.0 + col_i * 115.0
		# Centrer la dernière rangée (3 boutons)
		if row == 1:
			btn_x = 30.0 + (col_i * 115.0) + 57.0

		var b := Button.new()
		b.text = "%d\njoueurs" % nb
		b.position = Vector2(btn_x, 128 + row * 148)
		b.size = Vector2(btn_w, 80)
		b.add_theme_font_size_override("font_size", 20)
		b.add_theme_stylebox_override("normal",
			_flat(Color(col.r*0.18, col.g*0.18, col.b*0.18), col, 2, 8))
		b.add_theme_stylebox_override("hover",
			_flat(Color(col.r*0.32, col.g*0.32, col.b*0.32), col, 2, 8))
		b.add_theme_color_override("font_color", C_WHITE)
		var n : int = nb
		b.pressed.connect(func(): _select(n))
		panel.add_child(b)

		var desc_lbl := Label.new()
		desc_lbl.text = descs[i]
		desc_lbl.position = Vector2(btn_x, 128 + row * 148 + 84)
		desc_lbl.size = Vector2(btn_w, 16)
		desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_lbl.add_theme_font_size_override("font_size", 9)
		desc_lbl.add_theme_color_override("font_color", Color(col.r, col.g, col.b, 0.80))
		panel.add_child(desc_lbl)

	var btn_back := _btn(panel, "← Retour", Vector2(30, 452), Color(0.30, 0.20, 0.45))
	btn_back.pressed.connect(_on_back_pressed)

func _select(nb: int) -> void:
	GameConfig.format = str(nb)
	SceneLoader.goto("res://scenes/online/ChoixMap.tscn")

func _on_back_pressed() -> void:
	SceneLoader.goto("res://scenes/online/ChoixMode.tscn")

func _flat(bg: Color, border: Color, bw: int, cr: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.border_width_left = bw; s.border_width_right = bw
	s.border_width_top = bw; s.border_width_bottom = bw
	s.corner_radius_top_left = cr; s.corner_radius_top_right = cr
	s.corner_radius_bottom_left = cr; s.corner_radius_bottom_right = cr
	return s

func _btn(parent: Control, text: String, pos: Vector2, col: Color) -> Button:
	var b := Button.new()
	b.text = text; b.position = pos; b.size = Vector2(460, 46)
	b.add_theme_font_size_override("font_size", 14)
	b.add_theme_stylebox_override("normal", _flat(Color(col.r*0.18,col.g*0.18,col.b*0.18), col, 2, 8))
	b.add_theme_stylebox_override("hover",  _flat(Color(col.r*0.32,col.g*0.32,col.b*0.32), col, 2, 8))
	b.add_theme_color_override("font_color", C_WHITE)
	parent.add_child(b)
	return b
