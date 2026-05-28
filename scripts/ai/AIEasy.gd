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
		if _camp_is_producing(camp):
			continue
		if player.can_afford(50):
			produce_unit_at(camp, "infantry")

func _attack_random() -> void:
	var my_camps : Array = get_my_camps()
	if my_camps.is_empty():
		return

	var targets : Array = get_enemy_camps() + get_neutral_camps()
	if targets.is_empty():
		return

	var sources : Array = my_camps.filter(func(c): return c.units > 1)
	if sources.is_empty():
		return

	var source = sources[randi() % sources.size()]
	var target = targets[randi() % targets.size()]

	Combat.resolve(source, target)
