class_name Transport
extends Unit

# ─────────────────────────────────────────────────────────────────────────────
# Transport — bateau de transport, ne combat pas
# Sert uniquement à traverser l'eau avec des unités terrestres à bord
# Si coulé → toutes les unités embarquées sont perdues
# ─────────────────────────────────────────────────────────────────────────────

@export var capacite_max: int = 6           # nombre max d'unités embarquées

var unites_embarquees: Array[Unit] = []     # unités actuellement à bord

func _ready() -> void:
	unit_type    = UnitType.TRANSPORT
	max_hp       = 120.0
	damage       = 0.0     # ne combat pas
	attack_range = 0.0
	speed        = 80.0
	hit_speed    = 99.0    # n'attaque jamais
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
	unit.hide()            # cache l'unité pendant le transport
	return true

# Débarque toutes les unités à destination
func debarquer() -> void:
	for unit in unites_embarquees:
		if is_instance_valid(unit):
			unit.global_position = global_position
			unit.show()
	unites_embarquees.clear()

# Override die() — si coulé, toutes les unités embarquées meurent aussi
func die() -> void:
	for unit in unites_embarquees:
		if is_instance_valid(unit):
			unit.die()    # les unités à bord sont perdues
	unites_embarquees.clear()
	super.die()
