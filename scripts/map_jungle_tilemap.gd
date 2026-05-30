extends Node2D

const MAP_INDEX : int = 1
const MAP_W     : float = 1152.0
const MAP_H     : float = 620.0
const MARGIN    : float = 32.0

var NavBaker = load("res://scripts/NavBaker.gd")

func _ready() -> void:
	_setup_nav()

func _setup_nav() -> void:
	var map_data : Dictionary = MapDefs.MAPS[MAP_INDEX]
	var zones : Array = map_data.get("land_zones", [])
	if zones.is_empty():
		var b = NavBaker.new()
		add_child(b)
		var outline : PackedVector2Array = NavBaker.make_rect(
			MARGIN, MARGIN, MAP_W - MARGIN * 2, MAP_H - MARGIN * 2
		)
		b.bake(outline, [])
	else:
		for zone in zones:
			var b = NavBaker.new()
			add_child(b)
			var outline : PackedVector2Array = NavBaker.make_rect(
				zone.x, zone.y, zone.w, zone.h
			)
			b.bake(outline, [])
