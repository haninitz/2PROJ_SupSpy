class_name AntiBlindage
extends Unit

func _ready() -> void:
	unit_type    = UnitType.ANTI_BLINDAGE
	max_hp       = 80.0
	damage       = 10.0
	attack_range = 80.0
	speed        = 90.0
	hit_speed    = 1.2
	build_time   = 5.0
	price        = 80
	super._ready()
