class_name AIEasy
extends AIController

func _ready() -> void:
	difficulty_name = "facile"
	think_interval = 4.0
	recruit_choices = ["infantry"]
	units_per_attack = 1
	min_garrison_left = 2
	neutral_penalty = -80.0
	enemy_bonus = 0.0
	attack_chance = 0.55
	recruit_chance = 0.80
	prefer_neutral = true
