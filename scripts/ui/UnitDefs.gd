extends Node

# ─────────────────────────────────────────
#  UNIT DEFINITIONS
#  Utilisé par UI.gd (barre de recrutement) et Renderer.gd (label sur les camps)
#  Les clés correspondent aux unit_type String passés à Camp.queue_unit()
# ─────────────────────────────────────────
const TYPES : Dictionary = {
	"infantry"   : {"label": "Field Agent",    "hp": 100, "damage": 15, "range": 1, "speed": 3, "price": 50,  "build_time": 3.0},
	"range"      : {"label": "Laser Agent",    "hp": 75,  "damage": 20, "range": 3, "speed": 2, "price": 75,  "build_time": 4.0},
	"heavy"      : {"label": "Titanium Guard", "hp": 250, "damage": 35, "range": 1, "speed": 1, "price": 150, "build_time": 8.0},
	"anti_armor" : {"label": "Gadget Breaker", "hp": 80,  "damage": 10, "range": 2, "speed": 2, "price": 80,  "build_time": 5.0},
	"mortar"     : {"label": "Boom Compact",   "hp": 90,  "damage": 40, "range": 4, "speed": 1, "price": 120, "build_time": 7.0},
	"support"    : {"label": "Tech Specialist","hp": 85,  "damage": 10, "range": 2, "speed": 3, "price": 90,  "build_time": 5.0},
	"healer"     : {"label": "Medic Spy",      "hp": 80,  "damage": 8,  "range": 2, "speed": 2, "price": 90,  "build_time": 5.0},
	# Bateaux — disponibles uniquement dans les ports
	"spy_yacht"      : {"label": "Spy Yacht",      "hp": 120, "damage": 0,  "range": 0, "speed": 2, "price": 100, "build_time": 6.0},
	"woohp_cruiser"  : {"label": "WOOHP Cruiser",  "hp": 150, "damage": 25, "range": 3, "speed": 2, "price": 130, "build_time": 8.0},
	"shadow_vessel"  : {"label": "Shadow Vessel",  "hp": 280, "damage": 45, "range": 2, "speed": 1, "price": 200, "build_time": 12.0},
}

# Retourne les clés terrestres uniquement (pour la barre de recrutement des camps normaux)
func get_land_units() -> Array:
	return ["infantry", "range", "heavy", "anti_armor", "mortar", "support", "healer"]

# Retourne les clés maritimes uniquement (pour les ports)
func get_sea_units() -> Array:
	return ["spy_yacht", "woohp_cruiser", "shadow_vessel"]

# Retourne le label traduit si Lang est disponible
func get_label(unit_type: String) -> String:
	var lang = Engine.get_singleton("Lang") if Engine.has_singleton("Lang") else null
	if TYPES.has(unit_type):
		return TYPES[unit_type]["label"]
	return unit_type
