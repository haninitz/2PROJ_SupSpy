class_name ShadowVessel
extends Unit

func _ready() -> void:
	unit_type    = UnitType.DESTROYER
	max_hp       = 280.0
	damage       = 45.0
	attack_range = 150.0
	speed        = 75.0
	hit_speed    = 2.5
	build_time   = 12.0
	price        = 200
	super._ready()

func attack(target: Node) -> void:
	if not is_alive or target == null:
		return
	_area_attack(target.global_position, _calculate_damage(target))