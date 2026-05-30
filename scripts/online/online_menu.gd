extends Control
# online_menu.gd — plus utilisé directement (on passe par Mainmenu.gd)
# Redirige simplement vers Main.tscn

func _ready() -> void:
	# On NE PEUT PAS utiliser SceneLoader.goto() ici : il est encore en phase
	# "loading" (non-idle) → l'appel serait ignoré. On change donc directement.
	call_deferred("_redirect")

func _redirect() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
