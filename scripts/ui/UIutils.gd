extends Node

const WIN_W : int = 1152
const WIN_H : int = 720
const MAP_H : int = 620
const BTN_W : int = 134
const C_BG        := Color(0.04, 0.02, 0.10)
const C_PINK      := Color(1.00, 0.20, 0.58)
const C_PINK_LITE := Color(1.00, 0.55, 0.80)
const C_CYAN      := Color(0.00, 0.90, 0.88)
const C_GOLD      := Color(1.00, 0.85, 0.20)
const C_PURPLE    := Color(0.55, 0.15, 0.85)
const C_GREEN     := Color(0.20, 0.78, 0.30)
const C_WHITE     := Color(1.00, 1.00, 1.00)
const C_PANEL     := Color(0.06, 0.03, 0.14, 0.95)

func flat(bg: Color, border: Color, bw: int, cr: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color     = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(cr)
	return s

func lbl(text: String, pos: Vector2, size: int, col: Color) -> Label:
	var l := Label.new()
	l.text     = text
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	return l

func btn(text: String, pos: Vector2, sz: Vector2, fsize: int) -> Button:
	var b := Button.new()
	b.text     = text
	b.position = pos
	b.size     = sz
	b.add_theme_font_size_override("font_size", fsize)
	b.add_theme_color_override("font_color", C_WHITE)
	return b

func back_btn(action: Callable) -> Button:
	var b := btn(lt("back"), Vector2(28, 658), Vector2(140, 38), 14)
	b.add_theme_stylebox_override("normal",
		flat(Color(0.10, 0.08, 0.18), Color(0.45, 0.38, 0.60), 1, 8))
	b.add_theme_color_override("font_color", Color(0.78, 0.72, 0.90))
	b.pressed.connect(action)
	return b

func make_screen(visible_: bool = true) -> Panel:
	var p := Panel.new()
	p.position = Vector2.ZERO
	p.size     = Vector2(WIN_W, WIN_H)
	p.visible  = visible_
	p.add_theme_stylebox_override("panel", flat(C_BG, C_BG, 0, 0))
	return p

func goto(from: Panel, to: Panel) -> void:
	from.visible = false
	to.visible   = true

func add_header(parent: Control, title: String, col: Color) -> void:
	var top := ColorRect.new()
	top.color    = col
	top.position = Vector2.ZERO
	top.size     = Vector2(WIN_W, 3)
	parent.add_child(top)
	add_badge(parent, "✦ CLASSIFIED ✦", Vector2(WIN_W - 158, 14), Vector2(140, 22), col)
	var tl := lbl(title, Vector2(0, 55), 36, col)
	tl.size = Vector2(WIN_W, 60)
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(tl)
	var div := ColorRect.new()
	div.color    = Color(col.r, col.g, col.b, 0.50)
	div.position = Vector2(55, 112)
	div.size     = Vector2(WIN_W - 110, 2)
	parent.add_child(div)
	parent.add_child(lbl("✦", Vector2(18, 60), 28, Color(col.r, col.g, col.b, 0.50)))


func add_badge(parent: Control, text: String, pos: Vector2, sz: Vector2, col: Color) -> void:
	var bg := Panel.new()
	bg.position = pos
	bg.size     = sz
	bg.add_theme_stylebox_override("panel",
		flat(Color(col.r * 0.15, col.g * 0.15, col.b * 0.15), col, 1, 4))
	parent.add_child(bg)
	var l := lbl(text, pos, 9, col)
	l.size = sz
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(l)

func lt(key: String) -> String:
	var lang := get_node_or_null("/root/Lang")
	if lang and lang.has_method("t"):
		return lang.t(key)
	return key

func get_lang() -> String:
	var lang := get_node_or_null("/root/Lang")
	if lang and lang.get("current"):
		return lang.current
	return "fr"