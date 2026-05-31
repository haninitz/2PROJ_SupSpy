extends Control

const C_BG     := Color(0.04, 0.02, 0.10)
const C_PINK   := Color(1.00, 0.20, 0.58)
const C_PURPLE := Color(0.55, 0.15, 0.85)
const C_CYAN   := Color(0.00, 0.90, 0.88)
const C_GOLD   := Color(1.00, 0.85, 0.20)
const C_WHITE  := Color(1.00, 1.00, 1.00)

func _lt(key: String) -> String:
	var u := get_node_or_null("/root/UIUtils")
	return u.lt(key) if u and u.has_method("lt") else key

func _ready() -> void: _build()

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = C_BG; bg.size = Vector2(1152, 720); add_child(bg)

	var panel := Panel.new()
	panel.position = Vector2(1152.0/2 - 220, 720.0/2 - 250)
	panel.size = Vector2(440, 480)
	panel.add_theme_stylebox_override("panel", _flat(C_BG, C_PURPLE, 2, 14))
	add_child(panel)

	var title := Label.new()
	title.text = _lt("choixmap_title")
	title.position = Vector2(0, 36); title.size = Vector2(440, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", C_PURPLE)
	panel.add_child(title)

	var maps := [
		["Beverly Hills Mall", "clover", _lt("omap1_desc"), C_PINK],
		["Jungle Techno",      "sam",    _lt("omap2_desc"), C_CYAN],
		["Île Tropicale",      "alex",   _lt("omap3_desc"), C_GOLD],
	]
	var y := 110
	for m in maps:
		_btn(panel, "✦  %s" % m[0], Vector2(30, y), m[3]).pressed.connect(
			func(map_id = m[1]): _select(map_id))
		var desc := Label.new()
		desc.text = m[2]; desc.position = Vector2(30, y + 54)
		desc.size = Vector2(380, 18)
		desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc.add_theme_font_size_override("font_size", 11)
		desc.add_theme_color_override("font_color", Color(0.65, 0.50, 0.80))
		panel.add_child(desc)
		y += 88

	_btn(panel, _lt("back"), Vector2(30, y + 10), Color(0.30, 0.20, 0.45)).pressed.connect(
		func():
			if GameConfig.mode == "multi":
				SceneLoader.goto("res://scenes/online/ChoixFormat.tscn")
			else:
				SceneLoader.goto("res://scenes/online/ChoixDiff.tscn"))

func _select(map_id: String) -> void:
	GameConfig.map = map_id
	if GameConfig.mode == "multi":
		SceneLoader.goto("res://scenes/online/NomRoom.tscn")
	else:
		SceneLoader.goto("res://scenes/online/RecapIA.tscn")

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
	b.text = text; b.position = pos; b.size = Vector2(380, 48)
	b.add_theme_font_size_override("font_size", 14)
	b.add_theme_stylebox_override("normal", _flat(Color(col.r*.18,col.g*.18,col.b*.18), col, 2, 8))
	b.add_theme_stylebox_override("hover",  _flat(Color(col.r*.32,col.g*.32,col.b*.32), col, 2, 8))
	b.add_theme_color_override("font_color", C_WHITE)
	parent.add_child(b)
	return b
