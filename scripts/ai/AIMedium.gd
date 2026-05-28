class_name AIMedium
extends AIController

# ─────────────────────────────────────────
#  MEDIUM AI — balanced, defends regions, mixed units
#  Prioritizes completing regions for bonus income
# ─────────────────────────────────────────

func _ready() -> void:
	think_interval = 2.0
	super._ready()

func think() -> void:
	_produce_units()
	_decide_action()

func _produce_units() -> void:
	for camp in get_my_camps():
		if _camp_is_producing(camp):
			continue
		var unit_type : String = "infantry" if randf() < 0.6 else "range"
		var price : int = 50 if unit_type == "infantry" else 75
		if player.can_afford(price):
			produce_unit_at(camp, unit_type)

func _decide_action() -> void:
	var my_camps : Array = get_my_camps()
	if my_camps.is_empty():
		return
		
	var sources : Array = my_camps.filter(func(c): return c.units > 1)
	if sources.is_empty():
		return
		
	# Priority 1 — complete a region for bonus
	var region_target = _find_region_completion_target()
	if region_target != null:
		var best_source = _get_strongest_camp(sources)
		if best_source:
			Combat.resolve(best_source, region_target)
		return

	# Priority 2 — attack nearest enemy camp
	var neutral_targets : Array = get_neutral_camps()
	if not neutral_targets.is_empty():
		var weakest_neutral = _get_weakest_camp(neutral_targets)
		var nearest_source  = _get_nearest_source(sources, _camp_pos(weakest_neutral))
		if nearest_source:
			Combat.resolve(nearest_source, weakest_neutral)
		return

	# Priorité 3 — attaquer le camp ennemi le plus faible
	var enemy_targets : Array = get_enemy_camps()
	if enemy_targets.is_empty():
		return

	var weakest_enemy = _get_weakest_camp(enemy_targets)
	if weakest_enemy == null:
		return

	# N'attaque que si on a clairement l'avantage (plus d'unités que l'ennemi)
	var best_source = _get_strongest_camp(sources)
	if best_source == null:
		return

	if best_source.units > weakest_enemy.units:
		Combat.resolve(best_source, weakest_enemy)

func _find_region_completion_target():
	var gm = get_node_or_null("/root/GameManager")
	if not gm:
		return null
	for region_name in gm.regions:
		var region_camps : Array = gm.regions[region_name]
		var missing : Array = []
		for camp in region_camps:
			var owner : int = camp["owner_id"] if camp is Dictionary else camp.owner_id
			if owner != player.id:
				missing.append(camp)
		if missing.size() in [1, 2] and missing.size() < region_camps.size():
			return missing[0]
	return null

func _get_weakest_camp(camps: Array):
	var weakest = null
	var min_units : int = INF
	for camp in camps:
		if is_instance_valid(camp) and camp.units < min_units:
			min_units = camp.units
			weakest = camp
	return weakest
	
func _get_strongest_camp(camps: Array):
	var best = null
	var best_units : int = 0
	for camp in camps:
		if is_instance_valid(camp) and camp.units > best_units:
			best_units = camp.units
			best = camp
	return best
	
func _get_nearest_source(sources: Array, target_pos: Vector2):
	var nearest = null
	var nearest_dist : float = INF
	for camp in sources:
		if is_instance_valid(camp):
			var dist : float = _camp_pos(camp).distance_to(target_pos)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest = camp
	return nearest
