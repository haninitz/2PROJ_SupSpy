class_name TirDistance
extends Unit

func _ready() -> void:
	unit_type    = UnitType.TIR_DISTANCE
	max_hp       = 70.0
	damage       = 20.0
	attack_range = 200.0
	speed        = 90.0 
	hit_speed    = 1.2  
	build_time   = 4.0
	price        = 80
	super._ready()
