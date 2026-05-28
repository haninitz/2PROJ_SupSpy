extends Control
# online_menu.gd — plus utilisé directement (on passe par Mainmenu.gd)
# Redirige simplement vers Main.tscn

func _ready() -> void:
	SceneLoader.goto("res://scenes/Main.tscn")