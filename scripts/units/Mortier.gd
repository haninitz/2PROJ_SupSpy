class_name Mortier
extends Unit

func _ready() -> void:
	unit_type    = UnitType.MORTIER
	max_hp       = 90.0
	damage       = 40.0
	attack_range = 200.0
	speed        = 60.0
	hit_speed    = 2.5
	build_time   = 7.0
	price        = 120
	super._ready()
