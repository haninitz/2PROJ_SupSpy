class_name Transport
extends Unit

@export var capacite_max: int = 6           

var unites_embarquees: Array[Unit] = []     

func _ready() -> void:
	unit_type    = UnitType.TRANSPORT
	max_hp       = 120.0
	damage       = 0.0    
	attack_range = 0.0
	speed        = 80.0
	hit_speed    = 99.0   
	build_time   = 8.0
	price        = 100
	super._ready()

# Embarque une unité terrestre dans le transport
func embarquer(unit: Unit) -> bool:
	if unites_embarquees.size() >= capacite_max:
		return false
	if not unit is Unit:
		return false
	unites_embarquees.append(unit)
	unit.hide()            
	return true

# Débarque toutes les unités à destination
func debarquer() -> void:
	for unit in unites_embarquees:
		if is_instance_valid(unit):
			unit.global_position = global_position
			unit.show()
	unites_embarquees.clear()

func die(killer_owner_id: int = -1, killer_unit: Node = null) -> void:
	for unit in unites_embarquees:
		if is_instance_valid(unit):
			unit.die(killer_owner_id, killer_unit)

	unites_embarquees.clear()
	super.die(killer_owner_id, killer_unit)
