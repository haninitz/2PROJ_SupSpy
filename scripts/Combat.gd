extends Node

# =============================================================================
#  Combat.gd — résolution d'une attaque camp → camp
#
#  Fonctionne avec Camp_hani (Node2D, owner_id / production_queue)
#  et Camp (RefCounted, owner / queue) grâce aux alias dans Camp_hani.gd
#
#  Formule :
#    force_att = att_units × damage_par_unité  + aléa
#    force_def = def_units × (hp_par_unité/10) + aléa
#
#  Victoire attaquant → capture + transfert d'une partie des troupes
#  Défense réussie    → attaquant perd tout, défenseur perd la moitié de l'attaque
# =============================================================================

func resolve(source, target) -> void:
	var att_units : int = source.units
	var def_units : int = target.units

	# Récupère les stats (garde-fou si unit_type absent de UnitDefs)
	var att_type : String = source.unit_type if source.unit_type != "" else "infantry"
	var def_type : String = target.unit_type if target.unit_type != "" else "infantry"

	var att_stats : Dictionary = UnitDefs.TYPES.get(att_type, UnitDefs.TYPES["infantry"])
	var def_stats : Dictionary = UnitDefs.TYPES.get(def_type, UnitDefs.TYPES["infantry"])

	# Force de frappe avec aléa
	var force_att : int = att_units * att_stats["damage"] + randi() % (att_units * 4 + 1)
	var force_def : int = def_units * (def_stats["hp"] / 10) + randi() % (def_units * 3 + 1)

	if force_att >= force_def:
		# ── Victoire de l'attaquant ───────────────────────────────────────────
		var att_losses : int = maxi(1, att_units / 3)          # attaquant perd ~1/3
		var surviving  : int = maxi(1, att_units - att_losses) # au moins 1 survivant

		# Capture — utilise owner_id (Camp_hani) ou owner (Camp via alias)
		target.owner_id = source.owner_id
		target.units     = surviving
		target.unit_type = source.unit_type
		# Vide la file de production du camp capturé
		target.production_queue = []

		# La source garde 1 unité minimale (le camp reste défendu)
		source.units = 1

	else:
		# ── Défense réussie ───────────────────────────────────────────────────
		var def_losses : int = maxi(0, att_units / 2 - 1)
		target.units = maxi(1, def_units - def_losses)

		# L'attaquant a tout envoyé et perdu — il garde 1 unité
		source.units = 1
