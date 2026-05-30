class_name Fantassin
extends Unit

func _ready() -> void:
	unit_type    = UnitType.FANTASSIN
	max_hp       = 100.0
	damage       = 15.0
	attack_range = 40.0
	speed        = 120.0
	hit_speed    = 1.0
	build_time   = 3.0
	price        = 50
	super._ready()
