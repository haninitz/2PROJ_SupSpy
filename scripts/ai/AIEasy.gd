class_name AIEasy
extends AIController

func _ready() -> void:
	think_interval = 3.0
	super._ready()

func think() -> void:
	_produce_units()
	_attack_random()

func _produce_units() -> void:
	for camp in get_my_camps():
		produce_unit_at(camp, "infantry")

func _attack_random() -> void:
	var my_units : Array = get_my_units()
	if my_units.is_empty():
		return

	var targets : Array = get_enemy_camps() + get_neutral_camps()
	if targets.is_empty():
		return

	var target_camp = targets[randi() % targets.size()]
	var pos : Vector2 = _camp_pos(target_camp)

	for unit in my_units:
		if is_instance_valid(unit):
			unit.move_to(pos)