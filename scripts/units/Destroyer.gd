class_name Destroyer
extends Unit

@export var zone_radius: float = 60.0      
@export var min_damage_ratio: float = 0.4   

func _ready() -> void:
	unit_type    = UnitType.DESTROYER
	max_hp       = 300.0
	damage       = 40.0
	attack_range = 100.0
	speed        = 50.0   
	hit_speed    = 2.5
	build_time   = 12.0
	price        = 150
	super._ready()

func attack(target: Unit) -> void:
	if not is_alive or target == null:
		return

	var final_damage := _calculate_damage(target)
	target.take_damage(final_damage)

	var enemies = get_tree().get_nodes_in_group("units")
	for enemy in enemies:
		if enemy is Unit and enemy.owner_id != owner_id and enemy.is_alive and enemy != target:
			var dist = enemy.global_position.distance_to(target.global_position)
			if dist <= zone_radius:
				var ratio = 1.0 - (dist / zone_radius)
				ratio = max(ratio, min_damage_ratio)
				enemy.take_damage(final_damage * ratio)
