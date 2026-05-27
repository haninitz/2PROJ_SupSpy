class_name MapBackground
extends Node2D

# ─────────────────────────────────────────────────────────────────────────────
#  MapBackground.gd
#
#  Ce Node2D se place EN DESSOUS du GameCanvas (Renderer) dans la scène.
#  Il charge la bonne scène TileMap selon l'index de map choisi.
#
#  Structure attendue dans la scène main.tscn :
#
#    Main (Node2D)
#    ├── MapBackground   ← CE SCRIPT (z_index = 0)
#    ├── GameCanvas      ← Renderer.gd  (z_index = 1)
#    └── UI              ← UI.gd CanvasLayer
#
#  Chaque map a sa propre scène TileMap dans scenes/maps/ :
#    scenes/maps/map_beverly.tscn
#    scenes/maps/map_jungle.tscn
#    scenes/maps/map_tropical.tscn
#    scenes/maps/map_woohp.tscn
# ─────────────────────────────────────────────────────────────────────────────

# Chemins vers les scènes TileMap de chaque map
# L'index correspond à MapDefs.MAPS
const MAP_SCENES : Array = [
	"res://scenes/maps/map_beverly.tscn",    # 0 — Beverly Hills (Clover)
	"res://scenes/maps/map_jungle.tscn",     # 1 — Jungle Techno (Sam)
	"res://scenes/maps/MapTropical.tscn",   # 2 — Île Tropicale (Alex)
]

var _current_map : Node = null


func load_map(map_index: int) -> void:
	# Supprime l'ancienne map si elle existe
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
	# Fallback minimaliste si la TileMap n'existe pas encore :
	# fond uni coloré selon la map — sera remplacé par la vraie TileMap
	var fallback     := ColorRect.new()
	fallback.name     = "MapTileMap"
	fallback.position = Vector2.ZERO
	fallback.size     = Vector2(1152, 620)

	match map_index:
		0: fallback.color = Color(0.18, 0.32, 0.14)   # Beverly Hills — vert ville
		1: fallback.color = Color(0.10, 0.22, 0.08)   # Jungle — vert sombre
		2: fallback.color = Color(0.10, 0.30, 0.52)   # Île tropicale — bleu océan
		3: fallback.color = Color(0.12, 0.10, 0.20)   # QG WOOHP — violet sombre
		_: fallback.color = Color(0.15, 0.15, 0.15)

	_current_map = fallback
	add_child(fallback)
