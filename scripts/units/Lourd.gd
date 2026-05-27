class_name Lourd
extends Unit

# ─────────────────────────────────────────────────────────────────────────────
# Lourd — tank blindé, lent mais très résistant
# Beaucoup de PV et de dégâts. Très lent.
# Faible contre Anti-Blindage (×3 dégâts reçus).
# ─────────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	unit_type    = UnitType.LOURD
	max_hp       = 250.0
	damage       = 35.0
	attack_range = 80.0    # portée courte-moyenne
	speed        = 55.0    # très lent
	hit_speed    = 2.0     # attaque lente mais puissante
	build_time   = 8.0     # long à produire
	price        = 120
	super._ready()
