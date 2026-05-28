class_name Support
extends Unit

func _ready() -> void:
	unit_type    = UnitType.SOUTIEN
	max_hp       = 85.0
	damage       = 10.0
	attack_range = 80.0
	speed        = 110.0
	hit_speed    = 1.2
	build_time   = 5.0
	price        = 90
	super._ready()