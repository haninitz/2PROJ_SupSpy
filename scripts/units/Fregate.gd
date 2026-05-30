class_name Fregate
extends Unit

func _ready() -> void:
	unit_type    = UnitType.FREGATE
	max_hp       = 90.0
	damage       = 22.0
	attack_range = 220.0
	speed        = 85.0
	hit_speed    = 1.3
	build_time   = 9.0
	price        = 110
	super._ready()
