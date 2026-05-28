class_name Fantassin
extends Unit

# ─────────────────────────────────────────────────────────────────────────────
# Fantassin — unité de base, pas cher, corps à corps
# Bon marché et rapide à produire. Efficace en groupe.
# Faible contre TirDistance et Anti-Blindage.
# ─────────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	unit_type    = UnitType.FANTASSIN
	max_hp       = 100.0
	damage       = 15.0
	attack_range = 40.0    # corps à corps
	speed        = 120.0
	hit_speed    = 1.0     # attaque toutes les secondes
	build_time   = 3.0
	price        = 50
	super._ready()         # appelle _ready() de Unit.gd

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed:
		print("Clic détecté à : ", get_global_mouse_position())
		move_to(get_global_mouse_position())
