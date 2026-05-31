extends Control

func _ready() -> void:
	call_deferred("_redirect")

func _redirect() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
