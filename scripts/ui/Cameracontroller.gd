extends Camera2D

const ZOOM_MAX   : float = 3.0
const ZOOM_MIN   : float = 0.4
const ZOOM_STEP  : float = 0.1
const PAN_SPEED  : float = 500.0
const PAN_BUTTON : int   = MOUSE_BUTTON_MIDDLE

# Ajuste ces 4 valeurs selon les vraies limites de ta TileMap
# = coordonnées tuile × 16
# Coin haut-gauche de ta map peinte
const MAP_X : float = -304.0   # tuile_x × 16
const MAP_Y : float = -192.0   # tuile_y × 16
const MAP_W : float = 1650.0   # largeur totale en pixels
const MAP_H : float = 900.0    # hauteur totale en pixels

var _panning    : bool    = false
var _pan_origin : Vector2 = Vector2.ZERO
var _cam_origin : Vector2 = Vector2.ZERO


func _ready() -> void:
	zoom     = Vector2(0.8, 0.8)
	position = Vector2(576, 310)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				_zoom_toward(event.position, ZOOM_STEP)
				get_viewport().set_input_as_handled()
			MOUSE_BUTTON_WHEEL_DOWN:
				_zoom_toward(event.position, -ZOOM_STEP)
				get_viewport().set_input_as_handled()
			PAN_BUTTON:
				_panning    = true
				_pan_origin = event.position
				_cam_origin = position

	if event is InputEventMouseButton and not event.pressed:
		if event.button_index == PAN_BUTTON:
			_panning = false

	if event is InputEventMouseMotion and _panning:
		position = _cam_origin - (event.position - _pan_origin) / zoom.x


func _physics_process(delta: float) -> void:
	var dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_LEFT):  dir.x -= 1.0
	if Input.is_key_pressed(KEY_RIGHT): dir.x += 1.0
	if Input.is_key_pressed(KEY_UP):    dir.y -= 1.0
	if Input.is_key_pressed(KEY_DOWN):  dir.y += 1.0
	if dir != Vector2.ZERO:
		position += dir.normalized() * PAN_SPEED * delta / zoom.x


func _zoom_toward(screen_pos: Vector2, step: float) -> void:
	var old_zoom : float = zoom.x
	var new_zoom : float = clamp(old_zoom + step, ZOOM_MIN, ZOOM_MAX)
	if new_zoom == old_zoom:
		return
	var world_pos : Vector2 = get_canvas_transform().affine_inverse() * screen_pos
	position += (world_pos - position) * (1.0 - old_zoom / new_zoom)
	zoom = Vector2(new_zoom, new_zoom)
