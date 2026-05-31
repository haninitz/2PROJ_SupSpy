class_name AIMedium
extends AIController

func _ready() -> void:
	difficulty_name = "medium"
	think_interval = 2.8
	recruit_choices = ["infantry", "range", "support"]
	units_per_attack = 2
	min_garrison_left = 1
	neutral_penalty = 40.0
	enemy_bonus = 80.0
	attack_chance = 0.80
	recruit_chance = 1.0
	prefer_neutral = true
