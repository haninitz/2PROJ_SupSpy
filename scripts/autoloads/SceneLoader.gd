extends CanvasLayer

const C_BG     := Color(0.04, 0.02, 0.10)
const C_PINK   := Color(1.00, 0.20, 0.58)
const C_PURPLE := Color(0.55, 0.15, 0.85)
const C_CYAN   := Color(0.00, 0.90, 0.88)
const C_GOLD   := Color(1.00, 0.85, 0.20)

var _overlay   : ColorRect
var _title     : Label
var _dots      : Label
var _stars     : Array = []
var _target    : String = ""
var _phase     : String = "idle"  
var _alpha     : float  = 0.0
var _dot_timer : float  = 0.0
var _dot_count : int    = 0
var _load_timer: float  = 0.0

func _ready() -> void:
	layer   = 100
	visible = false
	_build()

func _build() -> void:
	_overlay          = ColorRect.new()
	_overlay.color    = C_BG
	_overlay.size     = Vector2(1152, 720)
	_overlay.modulate = Color(1, 1, 1, 0)
	add_child(_overlay)

	for i in range(12):
		var s := Label.new()
		s.text = ["✦","✧","★","◆"][i % 4]
		s.position = Vector2(80.0 + i * 90.0, 40.0 + sin(i * 1.2) * 25.0)
		s.add_theme_font_size_override("font_size", 10 + i % 8)
		s.modulate = [C_PINK, C_PURPLE, C_CYAN, C_GOLD][i % 4]
		s.modulate.a = 0.0
		_overlay.add_child(s)
		_stars.append(s)

	_title          = Label.new()
	_title.text     = "SUPSPY"
	_title.position = Vector2(0, 280)
	_title.size     = Vector2(1152, 100)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 52)
	_title.add_theme_color_override("font_color", C_PINK)
	_title.modulate.a = 0.0
	_overlay.add_child(_title)

	var line        := ColorRect.new()
	line.color       = Color(C_PINK.r, C_PINK.g, C_PINK.b, 0.5)
	line.size        = Vector2(300, 2)
	line.position    = Vector2(1152.0/2 - 150, 390)
	_overlay.add_child(line)

	_dots          = Label.new()
	_dots.text     = "Chargement"
	_dots.position = Vector2(0, 400)
	_dots.size     = Vector2(1152, 40)
	_dots.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dots.add_theme_font_size_override("font_size", 16)
	_dots.add_theme_color_override("font_color", C_PURPLE)
	_dots.modulate.a = 0.0
	_overlay.add_child(_dots)

func goto(scene_path: String) -> void:
	if _phase != "idle":
		return
	_target    = scene_path
	_phase     = "fade_in"
	_alpha     = 0.0
	visible    = true

func _process(delta: float) -> void:
	if _phase == "idle":
		return

	var t : float = Time.get_ticks_msec() / 1000.0

	match _phase:
		"fade_in":
			_alpha = minf(_alpha + delta * 3.0, 1.0)
			_apply_alpha(_alpha, t)
			if _alpha >= 1.0:
				_phase      = "loading"
				_load_timer = 0.0
				get_tree().change_scene_to_file(_target)

		"loading":
			_load_timer += delta
			_apply_alpha(1.0, t)
			_dot_timer += delta
			if _dot_timer >= 0.35:
				_dot_timer  = 0.0
				_dot_count  = (_dot_count + 1) % 4
				_dots.text  = "Chargement" + ".".repeat(_dot_count)
			if _load_timer >= 0.6:
				_phase = "fade_out"

		"fade_out":
			_alpha = maxf(_alpha - delta * 3.0, 0.0)
			_apply_alpha(_alpha, t)
			if _alpha <= 0.0:
				_phase   = "idle"
				visible  = false

func _apply_alpha(a: float, t: float) -> void:
	_overlay.modulate.a = a
	_title.modulate.a   = a
	_dots.modulate.a    = a
	for i in range(_stars.size()):
		var s : Label = _stars[i]
		s.modulate.a  = a * ((sin(t * 1.5 + float(i) * 0.6) + 1.0) * 0.4 + 0.1)
		s.position.y  = (40.0 + sin(t * 0.8 + float(i) * 1.2) * 25.0)