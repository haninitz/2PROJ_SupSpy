class_name AIHard
extends AIController

const DEFENSE_THRESHOLD : int   = 2
const ATTACK_UNIT_RATIO : float = 0.7

func _ready() -> void:
	think_interval = 1.5
	super._ready()

func think() -> void:
	_produce_smart_units()
	_defend_weak_camps()
	_attack_strategically()
	_activate_spells()

func _produce_smart_units() -> void:
	var my_camps    : Array = get_my_camps()
	var enemy_camps : Array = get_enemy_camps()
	for camp in my_camps:
		if _camp_is_producing(camp):
			continue
		var unit_type : String = _choose_unit_type(enemy_camps)
		if player.can_afford(_get_unit_cost(unit_type)):
			produce_unit_at(camp, unit_type)

func _choose_unit_type(enemy_camps: Array) -> String:
	for camp in enemy_camps:
		var owner : int = _camp_owner(camp)
		for unit in get_tree().get_nodes_in_group("units"):
			if unit.owner_id == owner and unit.unit_type == Unit.UnitType.HEAVY:
				return "anti_armor"
	var roll : float = randf()
	if roll < 0.3:   return "infantry"
	elif roll < 0.55: return "range"
	elif roll < 0.7:  return "heavy"
	elif roll < 0.82: return "support"
	elif roll < 0.92: return "healer"
	else:             return "mortar"

func _get_unit_cost(unit_type: String) -> int:
	match unit_type:
		"infantry"   : return 50
		"range"      : return 75
		"heavy"      : return 150
		"anti_armor" : return 80
		"mortar"     : return 120
		"support"    : return 90
		"healer"     : return 90
		_            : return 50

func _defend_weak_camps() -> void:
	var my_units : Array = get_my_units()
	if my_units.is_empty():
		return
	for camp in get_my_camps():
		var pos : Vector2 = _camp_pos(camp)
		var nearby : int  = _count_units_near(pos, 200.0, player.id)
		if nearby < DEFENSE_THRESHOLD:
			var defender = _get_idle_unit(my_units)
			if defender:
				defender.move_to(pos)

func _attack_strategically() -> void:
	var my_units     : Array = get_my_units()
	if my_units.is_empty():
		return
	var attack_count : int   = int(my_units.size() * ATTACK_UNIT_RATIO)
	var attack_units : Array = my_units.slice(0, attack_count)

	var target = _find_weakest_enemy_camp()
	if target == null:
		target = get_nearest_camp(_get_center(get_my_camps()), get_neutral_camps())
	if target == null:
		return

	var target_pos : Vector2 = _camp_pos(target)
	for unit in attack_units:
		if is_instance_valid(unit):
			unit.move_to(target_pos)

func _activate_spells() -> void:
	for unit in get_my_units():
		if not is_instance_valid(unit) or unit.spell_cooldown > 0.0:
			continue
		match unit.unit_type:
			Unit.UnitType.SUPPORT:
				if _count_enemies_near(unit.global_position, 200.0) > 0:
					unit.activate_turbo_boost()
			Unit.UnitType.HEALER:
				if _has_hurt_allies_near(unit.global_position, 150.0):
					unit.activate_compowder_heal()

func _find_weakest_enemy_camp():
	var weakest    = null
	var weakest_hp : float = INF
	for camp in get_enemy_camps() + get_neutral_camps():
		var hp : float = camp.get("current_hp", 100) if camp is Dictionary else camp.current_hp
		if hp < weakest_hp:
			weakest_hp = hp
			weakest    = camp
	return weakest

func _count_units_near(pos: Vector2, radius: float, owner: int) -> int:
	var count : int = 0
	for unit in get_tree().get_nodes_in_group("units"):
		if unit.owner_id == owner and unit.is_alive:
			if unit.global_position.distance_to(pos) <= radius:
				count += 1
	return count

func _count_enemies_near(pos: Vector2, radius: float) -> int:
	var count : int = 0
	for unit in get_tree().get_nodes_in_group("units"):
		if unit.owner_id != player.id and unit.is_alive:
			if unit.global_position.distance_to(pos) <= radius:
				count += 1
	return count

func _has_hurt_allies_near(pos: Vector2, radius: float) -> bool:
	for unit in get_tree().get_nodes_in_group("units"):
		if unit.owner_id == player.id and unit.is_alive:
			if unit.global_position.distance_to(pos) <= radius:
				if unit.get_hp_ratio() < 0.6:
					return true
	return false

func _get_idle_unit(units: Array):
	for unit in units:
		if is_instance_valid(unit) and unit.current_target == null:
			return unit
	return null

func _get_center(camps: Array) -> Vector2:
	var sum   := Vector2.ZERO
	var count : int = 0
	for camp in camps:
		sum   += _camp_pos(camp)
		count += 1
	return sum / count if count > 0 else Vector2.ZERO