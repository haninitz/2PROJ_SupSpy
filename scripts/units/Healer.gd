class_name Healer
extends Unit

func _ready() -> void:
	unit_type    = UnitType.SOIGNEUR
	max_hp       = 80.0
	damage       = 8.0
	attack_range = 60.0
	speed        = 105.0
	hit_speed    = 1.5
	build_time   = 5.0
	price        = 90
	super._ready()