extends Node
class_name UnitSelection

signal selection_changed(selected_units: Array)

var selected_units : Array = []  
var local_player_id : int  = 1  
var _is_dragging      : bool    = false
var _drag_start       : Vector2 = Vector2.ZERO
var _drag_end         : Vector2 = Vector2.ZERO
var _groups : Dictionary = {
	1: [], 2: [], 3: [], 4: [], 5: [],
	6: [], 7: [], 8: [], 9: []
}

@onready var selection_rect : ColorRect = $SelectionRect  

func _ready() -> void:
	if selection_rect:
		selection_rect.visible = false
		selection_rect.color   = Color(0.2, 0.8, 0.2, 0.15) 

func _input(_event: InputEvent) -> void:
	return

func _handle_mouse_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton

		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_drag_start  = mb.position
				_drag_end    = mb.position
				_is_dragging = false
			else:
				if _is_dragging:
					_finish_rubber_band_selection()
				else:
					_handle_single_click(mb.position, mb.shift_pressed)
				_is_dragging = false
				if selection_rect:
					selection_rect.visible = false

		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			_move_selected_units(mb.position)

	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_drag_end = (event as InputEventMouseMotion).position
			var drag_dist := _drag_start.distance_to(_drag_end)
			if drag_dist > 5.0:  
				_is_dragging = true
				_update_selection_rect()

func _handle_keyboard_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return

	var key := event as InputEventKey

	if key.ctrl_pressed:
		match key.keycode:
			KEY_1: _assign_group(1)
			KEY_2: _assign_group(2)
			KEY_3: _assign_group(3)
			KEY_4: _assign_group(4)
			KEY_5: _assign_group(5)
			KEY_6: _assign_group(6)
			KEY_7: _assign_group(7)
			KEY_8: _assign_group(8)
			KEY_9: _assign_group(9)
	else:
		match key.keycode:
			KEY_1: _select_group(1)
			KEY_2: _select_group(2)
			KEY_3: _select_group(3)
			KEY_4: _select_group(4)
			KEY_5: _select_group(5)
			KEY_6: _select_group(6)
			KEY_7: _select_group(7)
			KEY_8: _select_group(8)
			KEY_9: _select_group(9)
			KEY_ESCAPE: deselect_all()

		match key.keycode:
			KEY_Q: _activate_spell_on_selected()

func _handle_single_click(click_pos: Vector2, shift_held: bool) -> void:
	var space_state := get_viewport().get_world_2d().direct_space_state
	var params      := PhysicsPointQueryParameters2D.new()
	params.position  = get_viewport().get_canvas_transform().affine_inverse() * click_pos
	params.collision_mask = 1

	var results := space_state.intersect_point(params, 10)

	var clicked_unit : Node = null
	for result in results:
		var body = result["collider"]
		if body.is_in_group("units") and body.owner_id == local_player_id:
			clicked_unit = body
			break

	if clicked_unit == null:
		if not shift_held:
			deselect_all()
		return

	if shift_held:
		if selected_units.has(clicked_unit):
			_remove_from_selection(clicked_unit)
		else:
			_add_to_selection(clicked_unit)
	else:
		deselect_all()
		_add_to_selection(clicked_unit)

func _update_selection_rect() -> void:
	if not selection_rect:
		return
	var rect               := _get_drag_rect()
	selection_rect.position = rect.position
	selection_rect.size     = rect.size
	selection_rect.visible  = true

func _finish_rubber_band_selection() -> void:
	var drag_rect   := _get_drag_rect()
	var world_rect  := _screen_rect_to_world(drag_rect)

	deselect_all()

	for unit in get_tree().get_nodes_in_group("units"):
		if unit.owner_id != local_player_id:
			continue
		if world_rect.has_point(unit.global_position):
			_add_to_selection(unit)

func _get_drag_rect() -> Rect2:
	var min_x := minf(_drag_start.x, _drag_end.x)
	var min_y := minf(_drag_start.y, _drag_end.y)
	var max_x := maxf(_drag_start.x, _drag_end.x)
	var max_y := maxf(_drag_start.y, _drag_end.y)
	return Rect2(min_x, min_y, max_x - min_x, max_y - min_y)

func _screen_rect_to_world(screen_rect: Rect2) -> Rect2:
	var transform  := get_viewport().get_canvas_transform().affine_inverse()
	var top_left   := transform * screen_rect.position
	var bot_right  := transform * (screen_rect.position + screen_rect.size)
	return Rect2(top_left, bot_right - top_left)

func _add_to_selection(unit: Node) -> void:
	if selected_units.has(unit):
		return
	selected_units.append(unit)
	unit.select()
	Sound.play("select")
	selection_changed.emit(selected_units)

func _remove_from_selection(unit: Node) -> void:
	if not selected_units.has(unit):
		return
	selected_units.erase(unit)
	unit.deselect()
	selection_changed.emit(selected_units)

func deselect_all() -> void:
	for unit in selected_units:
		if is_instance_valid(unit):
			unit.deselect()
	selected_units.clear()
	selection_changed.emit(selected_units)

func _move_selected_units(click_pos: Vector2) -> void:
	if selected_units.is_empty():
		return

	var world_pos := get_viewport().get_canvas_transform().affine_inverse() * click_pos
	var count     := selected_units.size()

	for i in range(count):
		var unit = selected_units[i]
		if not is_instance_valid(unit):
			continue
		var offset := _formation_offset(i, count)
		unit.move_to(world_pos + offset)

func _formation_offset(index: int, total: int) -> Vector2:
	const SPACING : float = 40.0
	const PER_ROW : int   = 5
	var col := index % PER_ROW
	var row := index / PER_ROW
	var row_count := mini(total - row * PER_ROW, PER_ROW)
	var offset_x  := (col - (row_count - 1) / 2.0) * SPACING
	var offset_y  := row * SPACING
	return Vector2(offset_x, offset_y)

func _assign_group(group_num: int) -> void:
	if selected_units.is_empty():
		return
	var alive_now : Array = []
	for u in selected_units:
		if is_instance_valid(u):
			alive_now.append(u)
	_groups[group_num] = alive_now
	print("[Selection] Groupe ", group_num, " assigné — ", _groups[group_num].size(), " unités")

func _select_group(group_num: int) -> void:
	if not _groups.has(group_num):
		return
	var alive : Array = []
	for u in _groups[group_num]:
		if is_instance_valid(u) and u.is_alive:
			alive.append(u)
	_groups[group_num] = alive

	if alive.is_empty():
		return

	deselect_all()
	for unit in alive:
		_add_to_selection(unit)

func _activate_spell_on_selected() -> void:
	for unit in selected_units:
		if not is_instance_valid(unit):
			continue
		match unit.unit_type:
			Unit.UnitType.SOUTIEN:
				unit.activate_turbo_boost()
			Unit.UnitType.SOIGNEUR:
				unit.activate_compowder_heal()

func get_selected_count() -> int:
	return selected_units.size()

func get_selected_of_type(unit_type: Unit.UnitType) -> Array:
	var result : Array = []
	for u in selected_units:
		if is_instance_valid(u) and u.unit_type == unit_type:
			result.append(u)
	return result