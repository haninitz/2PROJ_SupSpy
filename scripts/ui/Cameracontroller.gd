extends Camera2D

# ─────────────────────────────────────────────────────────────────────────────
#  CameraController.gd
#  Zoom molette + pan clic-milieu ou clic-droit maintenu
# ─────────────────────────────────────────────────────────────────────────────

const ZOOM_MIN    : float = 1.0
const ZOOM_MAX    : float = 3.0
const ZOOM_STEP   : float = 0.1
const PAN_BUTTON  : int   = MOUSE_BUTTON_MIDDLE   # clic molette pour pan

var _panning      : bool    = false
var _pan_origin   : Vector2 = Vector2.ZERO
var _cam_origin   : Vector2 = Vector2.ZERO


func _unhandled_input(event: InputEvent) -> void:
	# ── Zoom molette ─────────────────────────────────────────────────────────
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				_zoom_toward(event.position, 1)
				get_viewport().set_input_as_handled()
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_zoom_toward(event.position, -1)
				get_viewport().set_input_as_handled()
			elif event.button_index == PAN_BUTTON:
				_panning   = true
				_pan_origin = event.position
				_cam_origin = position
		else:
			if event.button_index == PAN_BUTTON:
				_panning = false

	# ── Pan (déplacement caméra) ─────────────────────────────────────────────
	if event is InputEventMouseMotion and _panning:
		position = _cam_origin - (event.position - _pan_origin) / zoom.x


func _zoom_toward(mouse_screen: Vector2, direction: int) -> void:
	var old_zoom  : float   = zoom.x
	var new_zoom  : float   = clamp(old_zoom + direction * ZOOM_STEP, ZOOM_MIN, ZOOM_MAX)
	if new_zoom == old_zoom:
		return

	# Zoome vers la position souris (pas le centre)
	var mouse_world : Vector2 = get_canvas_transform().affine_inverse() * mouse_screen
	position += (mouse_world - position) * (1.0 - old_zoom / new_zoom)
	zoom = Vector2(new_zoom, new_zoom)
