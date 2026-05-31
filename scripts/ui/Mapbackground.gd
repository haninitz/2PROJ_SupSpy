class_name MapBackground
extends Node2D

const MAP_SCENES : Array = [
	"res://scenes/maps/map_beverly.tscn",    
	"res://scenes/maps/map_jungle.tscn",    
	"res://scenes/maps/MapTropical.tscn",  
]

var _current_map : Node = null

func load_map(map_index: int) -> void:
	if _current_map != null and is_instance_valid(_current_map):
		_current_map.queue_free()
		_current_map = null

	if map_index < 0 or map_index >= MAP_SCENES.size():
		push_error("MapBackground: index de map invalide : %d" % map_index)
		return

	var path : String = MAP_SCENES[map_index]

	if not ResourceLoader.exists(path):
		push_warning("MapBackground: scène introuvable : %s — fallback procédural actif" % path)
		_draw_fallback(map_index)
		return

	var scene    : PackedScene = load(path)
	_current_map = scene.instantiate()
	_current_map.name = "MapTileMap"
	add_child(_current_map)


func _draw_fallback(map_index: int) -> void:
	var fallback     := ColorRect.new()
	fallback.name     = "MapTileMap"
	fallback.position = Vector2.ZERO
	fallback.size     = Vector2(1152, 620)

	match map_index:
		0: fallback.color = Color(0.18, 0.32, 0.14) 
		1: fallback.color = Color(0.10, 0.22, 0.08)   
		2: fallback.color = Color(0.10, 0.30, 0.52)  
		_: fallback.color = Color(0.15, 0.15, 0.15)

	_current_map = fallback
	add_child(fallback)
