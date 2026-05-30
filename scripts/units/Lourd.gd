class_name Lourd
extends Unit

func _ready() -> void:
	unit_type    = UnitType.LOURD
	max_hp       = 250.0
	damage       = 35.0
	attack_range = 80.0
	speed        = 55.0    
	hit_speed    = 2.0     
	build_time   = 8.0     
	price        = 120
	super._ready()
