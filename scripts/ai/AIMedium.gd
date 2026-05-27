class_name AIMedium
extends AIController

# ─────────────────────────────────────────
#  MEDIUM AI — balanced, defends regions, mixed units
#  Prioritizes completing regions for bonus income
# ─────────────────────────────────────────

func _ready() -> void:
	think_interval = 2.0
	super._ready()

func think() -> void:
	_produce_units()
	_decide_action()

func _produce_units() -> void:
	var my_camps : Array = get_my_camps()
	for camp in my_camps:
		if not is_instance_valid(camp) or camp.is_producing:
			continue
		var unit_type : String = "infantry" if randf() < 0.6 else "range"
		produce_unit_at(camp, unit_type)

func _decide_action() -> void:
	var my_units : Array = get_my_units()
	if my_units.is_empty():
		return

	# Priority 1 — complete a region for bonus
	var region_camp = _find_region_completion_target()
	if region_camp != null:
		var target_pos : Vector2 = region_camp["pos"] if region_camp is Dictionary else region_camp.global_position
		_send_units_to(my_units, target_pos)
		return

	# Priority 2 — attack nearest enemy camp
	var my_camps : Array = get_my_camps()
	if my_camps.is_empty():
		return

	var center : Vector2 = _get_center(my_camps)
	var target = get_nearest_camp(center, get_enemy_camps() + get_neutral_camps())
	if target != null:
		var pos : Vector2 = target["pos"] if target is Dictionary else target.global_position
		_send_units_to(my_units, pos)

func _find_region_completion_target():
	var gm = get_node_or_null("/root/GameManager")
	if not gm:
		return null
	for region_name in gm.regions:
		var region_camps : Array = gm.regions[region_name]
		var missing : Array = []
		for camp in region_camps:
			var owner : int = camp["owner_id"] if camp is Dictionary else camp.owner_id
			if owner != player.id:
				missing.append(camp)
		if missing.size() in [1, 2] and missing.size() < region_camps.size():
			return missing[0]
	return null

func _send_units_to(units: Array, pos: Vector2) -> void:
	for unit in units:
		if is_instance_valid(unit):
			unit.move_to(pos)

func _get_center(camps: Array) -> Vector2:
	var sum   := Vector2.ZERO
	var count : int = 0
	for camp in camps:
		if camp is Dictionary:
			sum += camp["pos"]
			count += 1
		elif is_instance_valid(camp):
			sum += camp.global_position
			count += 1
	return sum / count if count > 0 else Vector2.ZERO