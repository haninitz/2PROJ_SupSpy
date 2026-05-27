class_name TirDistance
extends Unit

# ─────────────────────────────────────────────────────────────────────────────
# TirDistance — attaque de loin, fragile au corps à corps
# Grande portée mais peu de PV. Efficace contre les Fantassins.
# Vulnérable si un ennemi l'approche de trop près.
# ─────────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	unit_type    = UnitType.TIR_DISTANCE
	max_hp       = 70.0
	damage       = 20.0
	attack_range = 200.0   # attaque à distance
	speed        = 90.0    # plus lent que le Fantassin
	hit_speed    = 1.2     # cadence légèrement plus lente
	build_time   = 4.0
	price        = 80
	super._ready()
