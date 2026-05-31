extends Node
class_name AIController

var ai_player_id: int = 2
var think_interval: float = 2.0
var recruit_choices: Array[String] = ["infantry"]
var units_per_attack: int = 1
var min_garrison_left: int = 1
var neutral_penalty: float = 0.0
var enemy_bonus: float = 0.0
var attack_chance: float = 1.0
var recruit_chance: float = 1.0
var prefer_neutral: bool = true
var difficulty_name: String = "medium"

func setup(p_ai_player_id: int = 2) -> void:
	ai_player_id = p_ai_player_id

func tick(main: Node) -> void:
	if main == null:
		return
	if randf() <= recruit_chance:
		_recruit(main)
	if randf() <= attack_chance:
		_attack(main)

func _get_ai_player():
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("find_player_by_id"):
		return gm.find_player_by_id(ai_player_id)
	return null

func _get_camps(main: Node) -> Array:
	if "_camps" in main:
		return main._camps
	if "camps" in main:
		return main.camps
	return []

func _get_ai_camps(main: Node) -> Array:
	var result: Array = []
	for camp in _get_camps(main):
		if is_instance_valid(camp) and camp.owner_id == ai_player_id:
			result.append(camp)
	return result

func _get_targets(main: Node) -> Array:
	var result: Array = []
	for camp in _get_camps(main):
		if is_instance_valid(camp) and camp.owner_id != ai_player_id:
			result.append(camp)
	return result

func _recruit(main: Node) -> void:
	var ai_player = _get_ai_player()
	if ai_player == null:
		return

	var available_camps: Array = []
	for camp in _get_ai_camps(main):
		if not is_instance_valid(camp):
			continue
		if camp.production_queue.size() < main.MAX_QUEUE:
			available_camps.append(camp)

	if available_camps.is_empty():
		return

	available_camps.shuffle()

	for camp in available_camps:
		var choices: Array = _get_choices_for_camp(camp)
		var affordable: Array[String] = []

		for unit_type in choices:
			var price: int = UnitDefs.TYPES.get(unit_type, {}).get("price", 50)
			if ai_player.gold >= price:
				affordable.append(unit_type)

		if affordable.is_empty():
			continue

		var chosen_unit: String = _choose_recruit_unit(affordable)
		var chosen_price: int = UnitDefs.TYPES.get(chosen_unit, {}).get("price", 50)

		if ai_player.has_method("spend_gold"):
			if not ai_player.spend_gold(chosen_price):
				continue
		else:
			ai_player.gold -= chosen_price

		var build_time: float = 5.0
		if main.has_method("_build_time"):
			build_time = main._build_time(chosen_unit)

		camp.production_queue.append({"unit_type": chosen_unit, "remaining": build_time})
		camp.unit_type = chosen_unit

		if main.has_method("_log"):
			main._log("IA %s recrute %s à %s" % [difficulty_name, chosen_unit, camp.camp_name])
		if main.has_method("_refresh_ui"):
			main._refresh_ui()
		return

func _get_choices_for_camp(camp: Node) -> Array[String]:
	var choices: Array[String] = recruit_choices.duplicate()

	if camp != null and camp.has_method("get_available_unit_types"):
		var available_from_camp: Array = camp.get_available_unit_types()
		var filtered: Array[String] = []
		for unit_type in choices:
			if available_from_camp.has(unit_type):
				filtered.append(unit_type)
		if not filtered.is_empty():
			choices = filtered

	return choices

func _choose_recruit_unit(affordable: Array[String]) -> String:
	return affordable.pick_random()

func _attack(main: Node) -> void:
	var ai_camps: Array = _get_ai_camps(main)
	var targets: Array = _get_targets(main)

	if ai_camps.is_empty() or targets.is_empty():
		return

	var attackers: Array = []
	for camp in ai_camps:
		if not is_instance_valid(camp):
			continue
		if not camp.has_method("get_available_garrison"):
			continue
		if camp.get_available_garrison().size() > min_garrison_left:
			attackers.append(camp)

	if attackers.is_empty():
		return

	var attacker: Node = _pick_attacker(attackers)
	var target: Node = _find_best_target(attacker, targets)

	if target == null:
		return

	var garrison: Array = attacker.get_available_garrison()
	var send_count: int = mini(units_per_attack, max(0, garrison.size() - min_garrison_left))
	if send_count <= 0:
		return

	var units_to_send: Array = garrison.slice(0, send_count)
	for i in range(units_to_send.size()):
		var unit = units_to_send[i]
		if not is_instance_valid(unit):
			continue
		if not unit is Unit:
			continue
		if not unit.is_alive:
			continue

		if main.has_method("_detach_unit_from_home"):
			main._detach_unit_from_home(unit)

		var offset: Vector2 = _formation_offset(i, units_to_send.size())
		unit.move_to_camp(target, offset)

	if main.has_method("_log"):
		main._log("IA %s envoie %d unité(s) vers %s" % [difficulty_name, units_to_send.size(), target.camp_name])

func _pick_attacker(attackers: Array) -> Node:
	var best: Node = null
	var best_size: int = -1
	for camp in attackers:
		var size: int = camp.get_available_garrison().size() if camp.has_method("get_available_garrison") else 0
		if size > best_size:
			best_size = size
			best = camp
	return best

func _find_best_target(attacker: Node, targets: Array) -> Node:
	var best_target: Node = null
	var best_score: float = INF

	for target in targets:
		if not is_instance_valid(target):
			continue
		if target.owner_id == ai_player_id:
			continue

		var distance: float = attacker.global_position.distance_to(target.global_position)
		var defense_score: float = float(target.units) * 45.0
		var score: float = distance + defense_score

		if target.owner_id == 0:
			score += neutral_penalty
			if prefer_neutral:
				score -= 120.0
		else:
			score -= enemy_bonus

		if target.is_neutral_hard:
			score += 120.0
		if target.is_port:
			score += 40.0

		if score < best_score:
			best_score = score
			best_target = target

	return best_target

func _formation_offset(index: int, total: int) -> Vector2:
	var per_row: int = 4
	var row: int = index / per_row
	var col: int = index % per_row
	var row_count: int = mini(total - row * per_row, per_row)
	var x: float = (float(col) - float(row_count - 1) / 2.0) * 30.0
	var y: float = float(row) * 30.0
	return Vector2(x, y)
