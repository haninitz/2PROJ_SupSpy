class_name Destroyer
extends Unit

# ─────────────────────────────────────────────────────────────────────────────
# Destroyer — équivalent du Lourd sur l'eau avec dégâts de zone
# Très puissant, lent, dégâts de zone autour de sa cible
# Domine les Frégates et Transports
# ─────────────────────────────────────────────────────────────────────────────

@export var zone_radius: float = 60.0       # rayon des dégâts de zone
@export var min_damage_ratio: float = 0.4   # dégâts minimum en bord de zone (40%)

func _ready() -> void:
	unit_type    = UnitType.DESTROYER
	max_hp       = 300.0
	damage       = 40.0
	attack_range = 100.0
	speed        = 50.0    # très lent
	hit_speed    = 2.5
	build_time   = 12.0
	price        = 150
	super._ready()

# Override attack() — attaque avec dégâts de zone autour de la cible
func attack(target: Unit) -> void:
	if not is_alive or target == null:
		return

	# Dégâts directs sur la cible principale
	var final_damage := _calculate_damage(target)
	target.take_damage(final_damage)

	# Dégâts de zone autour de la cible
	var enemies = get_tree().get_nodes_in_group("units")
	for enemy in enemies:
		if enemy is Unit and enemy.owner_id != owner_id and enemy.is_alive and enemy != target:
			var dist = enemy.global_position.distance_to(target.global_position)
			if dist <= zone_radius:
				var ratio = 1.0 - (dist / zone_radius)
				ratio = max(ratio, min_damage_ratio)
				enemy.take_damage(final_damage * ratio)
