class_name AIHard
extends AIController

func _ready() -> void:
	difficulty_name = "difficile"
	think_interval = 1.6
	recruit_choices = ["infantry", "range", "support", "healer", "heavy", "anti_armor", "mortar"]
	units_per_attack = 4
	min_garrison_left = 1
	neutral_penalty = 60.0
	enemy_bonus = 220.0
	attack_chance = 1.0
	recruit_chance = 1.0
	prefer_neutral = false

func _choose_recruit_unit(affordable: Array[String]) -> String:
	var priority: Array[String] = ["anti_armor", "mortar", "heavy", "healer", "range", "support", "infantry"]
	for unit_type in priority:
		if affordable.has(unit_type):
			return unit_type
	return affordable.pick_random()

func _pick_attacker(attackers: Array) -> Node:
	var best: Node = null
	var best_score: float = -INF
	for camp in attackers:
		var size: int = camp.get_available_garrison().size() if camp.has_method("get_available_garrison") else 0
		var income: int = camp.income_value if "income_value" in camp else 0
		var score: float = float(size * 100 + income)
		if score > best_score:
			best_score = score
			best = camp
	return best
