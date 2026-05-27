class_name SpyYacht
extends Unit

func _ready() -> void:
	unit_type    = UnitType.TRANSPORT
	max_hp       = 120.0
	damage       = 0.0
	attack_range = 0.0
	speed        = 130.0
	hit_speed    = 99.0
	build_time   = 6.0
	price        = 100
	super._ready()