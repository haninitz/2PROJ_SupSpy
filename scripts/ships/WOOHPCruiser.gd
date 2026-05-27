class_name WOOHPCruiser
extends Unit

func _ready() -> void:
	unit_type    = UnitType.FRIGATE
	max_hp       = 150.0
	damage       = 25.0
	attack_range = 220.0
	speed        = 110.0
	hit_speed    = 1.3
	build_time   = 8.0
	price        = 130
	super._ready()