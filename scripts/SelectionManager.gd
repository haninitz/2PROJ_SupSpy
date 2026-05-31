extends Node2D
class_name SelectionManager

var selected_units: Array[Unit] = []  
var current_player_id: int = 0        
var is_dragging: bool = false
var drag_start: Vector2 = Vector2.ZERO
var drag_end: Vector2 = Vector2.ZERO

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				drag_start = get_global_mouse_position()
				is_dragging = false

			else:
				if is_dragging:
					_select_units_in_rect()
				else:
					_select_single_unit(get_global_mouse_position())
				is_dragging = false
				queue_redraw()

		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_move_selected_units(get_global_mouse_position())

	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			drag_end = get_global_mouse_position()
			var dist = drag_start.distance_to(drag_end)
			if dist > 10.0:   
				is_dragging = true
				queue_redraw()  

func _select_single_unit(pos: Vector2) -> void:
	var clicked_unit = _get_unit_at(pos)
	_deselect_all()

	if clicked_unit != null and clicked_unit.owner_id == current_player_id:
		selected_units.append(clicked_unit)
		_highlight_unit(clicked_unit, true)

func _select_units_in_rect() -> void:
	_deselect_all()

	var rect = Rect2(drag_start, drag_end - drag_start).abs()
	var all_units = get_tree().get_nodes_in_group("units")
	for unit in all_units:
		if unit is Unit and unit.owner_id == current_player_id and unit.is_alive:
			if rect.has_point(unit.global_position):
				selected_units.append(unit)
				_highlight_unit(unit, true)

func _move_selected_units(target_pos: Vector2) -> void:
	if selected_units.is_empty():
		return

	var count = selected_units.size()
	for i in range(count):
		var unit = selected_units[i]
		if is_instance_valid(unit) and unit.is_alive:
			var offset = Vector2(
				(i % 3 - 1) * 40.0,
				(i / 3) * 40.0
			)
			unit.move_to(target_pos + offset)
func _deselect_all() -> void:
	for unit in selected_units:
		if is_instance_valid(unit):
			_highlight_unit(unit, false)
	selected_units.clear()

func _get_unit_at(pos: Vector2) -> Unit:
	var all_units = get_tree().get_nodes_in_group("units")
	for unit in all_units:
		if unit is Unit and unit.is_alive:
			if unit.global_position.distance_to(pos) <= 30.0:
				return unit
	return null

func _highlight_unit(unit: Unit, selected: bool) -> void:
	if selected:
		unit.modulate = Color(1.5, 1.5, 0.5) 
	else:
		unit.modulate = Color(1.0, 1.0, 1.0)

func _draw() -> void:
	if not is_dragging:
		return
	var rect = Rect2(drag_start, drag_end - drag_start).abs()
	draw_rect(rect, Color(0.2, 0.8, 0.2, 0.15), true)
	draw_rect(rect, Color(0.2, 0.8, 0.2, 0.8), false, 1.5)
