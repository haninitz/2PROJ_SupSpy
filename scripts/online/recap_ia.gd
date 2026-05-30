extends Control
# recap_ia.gd — SupKonQuest · Totally Spies

const C_BG := Color(0.04, 0.02, 0.10); const C_PINK := Color(1.00, 0.20, 0.58)
const C_PURPLE := Color(0.55, 0.15, 0.85); const C_GOLD := Color(1.00, 0.85, 0.20)
const C_WHITE := Color(1.00, 1.00, 1.00)

func _lt(key: String) -> String:
	var u := get_node_or_null("/root/UIUtils")
	if u and u.has_method("lt"):
		return u.lt(key)
	return key

func _ready() -> void: _build()

func _build() -> void:
	var bg := ColorRect.new(); bg.color = C_BG; bg.size = Vector2(1152, 720); add_child(bg)
	var panel := Panel.new()
	panel.position = Vector2(1152.0/2-220, 720.0/2-220); panel.size = Vector2(440, 420)
	panel.add_theme_stylebox_override("panel", _flat(C_BG, C_GOLD, 2, 14)); add_child(panel)

	var title := Label.new(); title.text = _lt("recap_title")
	title.position = Vector2(0, 30); title.size = Vector2(440, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", C_GOLD); panel.add_child(title)

	var div := ColorRect.new(); div.color = Color(C_GOLD.r,C_GOLD.g,C_GOLD.b,0.30)
	div.position = Vector2(30, 88); div.size = Vector2(380, 1); panel.add_child(div)

	var diff_label := _get_diff_label()
	var rows := [
		[_lt("recap_mode"), _lt("recap_vs_ai"), C_PURPLE],
		[_lt("recap_diff"), diff_label,          C_PINK],
		[_lt("recap_map"),  GameConfig.map.to_upper(), C_GOLD],
	]
	var y := 108
	for row in rows:
		var key := Label.new(); key.text = row[0]
		key.position = Vector2(40, y); key.size = Vector2(150, 30)
		key.add_theme_font_size_override("font_size", 14)
		key.add_theme_color_override("font_color", Color(0.65,0.50,0.80)); panel.add_child(key)
		var val := Label.new(); val.text = row[1]
		val.position = Vector2(200, y); val.size = Vector2(200, 30)
		val.add_theme_font_size_override("font_size", 16)
		val.add_theme_color_override("font_color", row[2]); panel.add_child(val)
		y += 42

	_btn(panel, _lt("recap_launch"), Vector2(30, 290), C_PINK).pressed.connect(
		func(): _on_lancer_pressed())
	_btn(panel, _lt("back"), Vector2(30, 352), Color(0.30, 0.20, 0.45)).pressed.connect(
		func(): SceneLoader.goto("res://scenes/online/ChoixMap.tscn"))

func _get_diff_label() -> String:
	match GameConfig.diff:
		"easy": return _lt("diff_easy_label")
		"med":  return _lt("diff_med_label")
		"hard": return _lt("diff_hard_label")
	return GameConfig.diff

func _flat(bg: Color, border: Color, bw: int, cr: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new(); s.bg_color = bg; s.border_color = border
	s.border_width_left = bw; s.border_width_right = bw
	s.border_width_top  = bw; s.border_width_bottom = bw
	s.corner_radius_top_left = cr; s.corner_radius_top_right = cr
	s.corner_radius_bottom_left = cr; s.corner_radius_bottom_right = cr; return s

func _btn(parent: Control, text: String, pos: Vector2, col: Color) -> Button:
	var b := Button.new(); b.text = text; b.position = pos; b.size = Vector2(380, 50)
	b.add_theme_font_size_override("font_size", 15)
	b.add_theme_stylebox_override("normal", _flat(Color(col.r*.18,col.g*.18,col.b*.18), col, 2, 8))
	b.add_theme_stylebox_override("hover",  _flat(Color(col.r*.32,col.g*.32,col.b*.32), col, 2, 8))
	b.add_theme_color_override("font_color", C_WHITE); parent.add_child(b); return b


func _on_lancer_pressed() -> void:
	GameConfig.mode = "ai"
	match GameConfig.map:
		"clover": GameConfig.map = "clover"
		"sam":    GameConfig.map = "sam"
		"alex":   GameConfig.map = "alex"
	SceneLoader.goto("res://scenes/Main.tscn")
