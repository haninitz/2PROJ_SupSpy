extends CanvasLayer

signal splash_finished

const IMG_PATH := "res://assets/sprites/pixel.jpg"

var _bg      : TextureRect
var _title   : Label
var _prompt  : Label
var _overlay : ColorRect
var _scanlines : Node2D
var _ready_to_continue : bool = false
var _t : float = 0.0

func _ready() -> void:
	layer = 99
	_build()
	_animate_in()

func _build() -> void:
	_bg             = TextureRect.new()
	_bg.texture     = load(IMG_PATH)
	_bg.stretch_mode = TextureRect.STRETCH_SCALE
	_bg.size        = Vector2(1152, 720)
	_bg.position    = Vector2.ZERO
	add_child(_bg)

	var dark := ColorRect.new()
	dark.color    = Color(0.0, 0.0, 0.08, 0.50)
	dark.size     = Vector2(1152, 720)
	dark.position = Vector2.ZERO
	add_child(dark)

	_scanlines = _ScanlinesNode.new()
	add_child(_scanlines)

	_overlay          = ColorRect.new()
	_overlay.color    = Color(0, 0, 0, 1.0)
	_overlay.size     = Vector2(1152, 720)
	_overlay.position = Vector2.ZERO
	add_child(_overlay)

	var shadow : Label = Label.new()
	shadow.text     = "SUPSPY"
	shadow.position = Vector2(8, 238)
	shadow.size     = Vector2(1152, 160)
	shadow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shadow.add_theme_font_size_override("font_size", 110)
	shadow.add_theme_color_override("font_color", Color(0.60, 0.05, 0.30, 0.55))
	shadow.modulate.a = 0.0
	add_child(shadow)

	var glow : Label = Label.new()
	glow.text     = "SUPSPY"
	glow.position = Vector2(0, 228)
	glow.size     = Vector2(1152, 160)
	glow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	glow.add_theme_font_size_override("font_size", 118)
	glow.add_theme_color_override("font_color", Color(1.0, 0.20, 0.58, 0.25))
	glow.modulate.a = 0.0
	add_child(glow)

	_title          = Label.new()
	_title.text     = "SUPSPY"
	_title.position = Vector2(0, 230)
	_title.size     = Vector2(1152, 160)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 110)
	_title.add_theme_color_override("font_color", Color(1.0, 0.20, 0.58))
	_title.modulate.a = 0.0
	add_child(_title)

	shadow.set_meta("fade_with_title", true)
	glow.set_meta("fade_with_title", true)

	var line := ColorRect.new()
	line.color    = Color(1.0, 0.20, 0.58, 0.70)
	line.position = Vector2(1152.0/2.0 - 160, 368)
	line.size     = Vector2(320, 2)
	add_child(line)
	var line2 := ColorRect.new()
	line2.color    = Color(0.00, 0.90, 0.88, 0.35)
	line2.position = Vector2(1152.0/2.0 - 160, 371)
	line2.size     = Vector2(320, 1)
	add_child(line2)

	var badge := Label.new()
	badge.text     = "Hanitea | Dalila | Paola | Asma"
	badge.position = Vector2(0, 385)
	badge.size     = Vector2(1152, 22)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 11)
	badge.add_theme_color_override("font_color", Color(0.55, 0.45, 0.70))
	badge.modulate.a = 0.0
	add_child(badge)

	_prompt          = Label.new()
	var _u := get_node_or_null("/root/UIUtils")
	_prompt.text     = _u.lt("click_to_start") if _u else "CLICK TO START"
	_prompt.position = Vector2(0, 640)
	_prompt.size     = Vector2(1152, 28)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_font_size_override("font_size", 13)
	_prompt.add_theme_color_override("font_color", Color(0.70, 0.60, 0.85))
	_prompt.modulate.a = 0.0
	add_child(_prompt)

	badge.set_meta("fade_target", 1.0)

func _animate_in() -> void:
	var tween : Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_overlay, "color:a", 0.0, 1.8).set_delay(0.2)
	tween.tween_property(_title, "modulate:a", 1.0, 1.0).set_delay(1.2)
	for child in get_children():
		if child is Label and child.has_meta("fade_with_title"):
			tween.tween_property(child, "modulate:a", 1.0, 1.0).set_delay(1.2)
	tween.tween_callback(func(): _ready_to_continue = true).set_delay(2.8)
	for child in get_children():
		if child is Label and child != _title and child != _prompt and child != _overlay:
			tween.tween_property(child, "modulate:a", 1.0, 0.8).set_delay(1.8)
	tween.tween_property(_prompt, "modulate:a", 1.0, 0.6).set_delay(2.5)


func _process(delta: float) -> void:
	_t += delta
	if _scanlines:
		_scanlines.queue_redraw()
	if _title and _title.modulate.a > 0.5:
		var flicker : float = 1.0
		if fmod(_t, 4.0) > 3.7:
			flicker = 0.6 + sin(_t * 40.0) * 0.4
		_title.modulate = Color(flicker, flicker * 0.20, flicker * 0.58)
	if _ready_to_continue and _prompt:
		_prompt.modulate.a = 0.4 + sin(_t * 2.5) * 0.6

func _input(event: InputEvent) -> void:
	if not _ready_to_continue:
		return
	if (event is InputEventMouseButton or event is InputEventKey) and event.pressed:
		_finish()

func _finish() -> void:
	_ready_to_continue = false
	var tween : Tween = create_tween()
	tween.tween_property(_overlay, "color:a", 1.0, 0.5)
	tween.tween_callback(_on_fade_done)

func _on_fade_done() -> void:
	splash_finished.emit()
	queue_free()

class _ScanlinesNode extends Node2D:
	func _draw() -> void:
		var y : int = 0
		while y < 720:
			draw_line(Vector2(0, y), Vector2(1152, y),
				Color(0.0, 0.0, 0.0, 0.12), 1.0)
			y += 3
