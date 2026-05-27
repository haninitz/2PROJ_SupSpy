extends Node2D
# =============================================================================
#  map_tropical_painter.gd -- Alex's Secret Archipelago
#
#  Archipel d'iles isolees :
#  - Grande ile principale avec base secrete
#  - 6 petites iles dispersees
#  - Ocean avec vagues, profondeur variee
#  - Forets denses, plages, ports
#  - Ambiance aventure/tropicale
# =============================================================================

const MAP_W : int = 1152
const MAP_H : int = 620

const C_OCEAN_DEEP := Color(0.05, 0.20, 0.48)
const C_OCEAN      := Color(0.08, 0.32, 0.65)
const C_OCEAN_SHAL := Color(0.15, 0.48, 0.75)
const C_OCEAN_LITE := Color(0.25, 0.62, 0.85)
const C_SAND_WET   := Color(0.65, 0.55, 0.35)
const C_SAND       := Color(0.82, 0.72, 0.48)
const C_SAND_DRY   := Color(0.90, 0.82, 0.58)
const C_GRASS      := Color(0.20, 0.45, 0.10)
const C_GRASS_D    := Color(0.13, 0.30, 0.06)
const C_GRASS_L    := Color(0.28, 0.55, 0.15)
const C_JUNGLE     := Color(0.08, 0.20, 0.04)
const C_WALL       := Color(0.30, 0.28, 0.22)
const C_ROOF       := Color(0.42, 0.22, 0.12)
const C_ROOF2      := Color(0.20, 0.35, 0.28)
const C_WOOD       := Color(0.45, 0.32, 0.18)
const C_WOOD_D     := Color(0.35, 0.24, 0.12)

# Iles : cx, cy, rx, ry, seed
const ISLANDS := [
	# Ile principale (centre-gauche)
	{"cx": 380.0, "cy": 290.0, "rx": 240.0, "ry": 175.0, "seed": 0.0, "main": true},
	# Ile Nord-Est
	{"cx": 820.0, "cy": 120.0, "rx": 110.0, "ry": 80.0,  "seed": 1.2, "main": false},
	# Ile Est
	{"cx": 1020.0,"cy": 310.0, "rx": 95.0,  "ry": 120.0, "seed": 2.4, "main": false},
	# Ile Sud-Est
	{"cx": 850.0, "cy": 510.0, "rx": 105.0, "ry": 75.0,  "seed": 3.6, "main": false},
	# Ile Sud
	{"cx": 540.0, "cy": 560.0, "rx": 80.0,  "ry": 45.0,  "seed": 4.8, "main": false},
	# Ile Nord
	{"cx": 600.0, "cy": 60.0,  "rx": 90.0,  "ry": 48.0,  "seed": 6.0, "main": false},
	# Ile Nord-Ouest
	{"cx": 100.0, "cy": 100.0, "rx": 70.0,  "ry": 55.0,  "seed": 7.2, "main": false},
]

var _tex_plant : Texture2D = null
var NavBaker = load("res://scripts/NavBaker.gd")


func _ready() -> void:
	_tex_plant = load("res://assets/tilesets/cainos/TX Plant.png")
	_spawn_trees()
	_setup_nav()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var t : float = Time.get_ticks_msec() / 1000.0
	_draw_ocean(t)
	_draw_shallow_water()
	_draw_islands()
	_draw_buildings(t)
	_draw_ports(t)
	_draw_details(t)


# ── Ocean ─────────────────────────────────────────────────────────────────────
func _draw_ocean(t: float) -> void:
	draw_rect(Rect2(0, 0, MAP_W, MAP_H), C_OCEAN_DEEP)
	# Zones plus claires
	_draw_blob(300, 350, 500, 400, C_OCEAN)
	_draw_blob(800, 300, 400, 320, C_OCEAN)

	# Vagues
	for i in range(20):
		var wy    : float = 15.0 + float(i) * 30.0
		var alpha : float = 0.06 + sin(t*0.8 + float(i)*0.6) * 0.03
		var x : int = 0
		while x < MAP_W:
			var y1 : float = wy + sin(float(x)*0.016 + t*0.9 + float(i)*0.5) * 5.0
			var y2 : float = wy + sin(float(x+35)*0.016 + t*0.9 + float(i)*0.5) * 5.0
			draw_line(Vector2(x, y1), Vector2(x+35, y2),
				Color(0.55, 0.85, 1.0, alpha), 1.5)
			x += 35

	# Reflets soleil
	for i in range(10):
		var sx : float = 100.0 + float(i) * 100.0
		var sy : float = 50.0 + sin(t*0.4 + float(i))*15.0
		draw_line(Vector2(sx, sy), Vector2(sx+25, sy+2),
			Color(1.0, 1.0, 0.85, 0.12), 2.0)


# ── Eaux peu profondes autour des iles ────────────────────────────────────────
func _draw_shallow_water() -> void:
	var layers := [
		{"offset": 55.0, "col": Color(0.07, 0.28, 0.58, 0.85)},
		{"offset": 42.0, "col": Color(0.10, 0.36, 0.66, 0.90)},
		{"offset": 30.0, "col": Color(0.14, 0.44, 0.72, 0.92)},
		{"offset": 18.0, "col": Color(0.20, 0.54, 0.78, 0.95)},
		{"offset":  8.0, "col": Color(0.28, 0.65, 0.84, 1.00)},
	]
	for isl in ISLANDS:
		var steps : int = 52
		for layer in layers:
			var pts := PackedVector2Array()
			for i in range(steps):
				var angle : float = float(i) / float(steps) * TAU
				var noise : float = _noise(angle + isl["seed"])
				var rx : float = isl["rx"] * (1.0 + noise) + layer["offset"]
				var ry : float = isl["ry"] * (1.0 + noise) + layer["offset"]
				pts.append(Vector2(isl["cx"] + cos(angle) * rx,
					isl["cy"] + sin(angle) * ry))
			draw_colored_polygon(pts, layer["col"])
		var pts_foam := PackedVector2Array()
		for i in range(steps):
			var angle : float = float(i) / float(steps) * TAU
			var noise : float = _noise(angle + isl["seed"])
			pts_foam.append(Vector2(isl["cx"] + cos(angle) * (isl["rx"]*(1.0+noise)+3.0),
				isl["cy"] + sin(angle) * (isl["ry"]*(1.0+noise)+3.0)))
		draw_polyline(pts_foam, Color(0.85, 0.95, 1.00, 0.55), 2.5, true)


# ── Iles ──────────────────────────────────────────────────────────────────────
func _draw_islands() -> void:
	for isl in ISLANDS:
		var steps : int = 60
		var pts_wet  := PackedVector2Array()
		var pts_sand := PackedVector2Array()
		var pts_dry  := PackedVector2Array()
		var pts_grass := PackedVector2Array()
		var pts_dark  := PackedVector2Array()
		var pts_jungle := PackedVector2Array()

		for i in range(steps):
			var angle : float = float(i) / float(steps) * TAU
			var noise : float = _noise(angle + isl["seed"])
			var rx : float = isl["rx"] * (1.0 + noise)
			var ry : float = isl["ry"] * (1.0 + noise)
			pts_wet.append(Vector2(isl["cx"]+cos(angle)*(rx+10), isl["cy"]+sin(angle)*(ry+10)))
			pts_sand.append(Vector2(isl["cx"]+cos(angle)*(rx+4), isl["cy"]+sin(angle)*(ry+4)))
			pts_dry.append(Vector2(isl["cx"]+cos(angle)*rx, isl["cy"]+sin(angle)*ry))
			pts_grass.append(Vector2(isl["cx"]+cos(angle)*rx*0.88, isl["cy"]+sin(angle)*ry*0.88))
			pts_dark.append(Vector2(isl["cx"]+cos(angle)*rx*0.72, isl["cy"]+sin(angle)*ry*0.72))
			if isl["main"]:
				pts_jungle.append(Vector2(isl["cx"]+cos(angle)*rx*0.50, isl["cy"]+sin(angle)*ry*0.50))

		draw_colored_polygon(pts_wet, C_SAND_WET)
		draw_colored_polygon(pts_sand, C_SAND)
		draw_colored_polygon(pts_dry, C_SAND_DRY)
		draw_colored_polygon(pts_grass, C_GRASS)
		draw_colored_polygon(pts_dark, C_GRASS_D)
		if isl["main"]:
			draw_colored_polygon(pts_jungle, C_JUNGLE)
		# Centre clair
		draw_circle(Vector2(isl["cx"], isl["cy"]),
			isl["rx"] * 0.25, Color(C_GRASS_L.r, C_GRASS_L.g, C_GRASS_L.b, 0.35))


# ── Batiments sur les iles ────────────────────────────────────────────────────
func _draw_buildings(t: float) -> void:
	# Ile principale -- base secrete
	_draw_hut(320, 245, 70, 55, "BASE", C_ROOF2, t, 0)
	_draw_hut(420, 260, 55, 45, "CACHE", C_ROOF, t, 1)
	_draw_hut(350, 330, 60, 48, "STORE", C_ROOF2, t, 2)

	# Petites iles -- avant-postes
	_draw_hut(790, 100, 45, 38, "NE POST", C_ROOF, t, 3)
	_draw_hut(990, 280, 45, 38, "E POST",  C_ROOF2, t, 4)
	_draw_hut(820, 490, 45, 38, "SE POST", C_ROOF, t, 5)
	_draw_hut(520, 545, 42, 35, "S POST",  C_ROOF2, t, 6)
	_draw_hut(570, 42,  42, 35, "N POST",  C_ROOF,  t, 7)
	_draw_hut(70,  80,  42, 35, "NW POST", C_ROOF2, t, 8)


func _draw_hut(x: float, y: float, w: float, h: float,
		label: String, roof: Color, t: float, seed: int) -> void:
	var pulse : float = 0.6 + sin(t * 1.3 + float(seed) * 1.2) * 0.25
	# Ombre
	draw_rect(Rect2(x+3, y+3, w, h), Color(0,0,0,0.20))
	# Mur
	draw_rect(Rect2(x, y, w, h), C_WALL)
	# Toit triangulaire
	draw_colored_polygon(PackedVector2Array([
		Vector2(x-4, y+h*0.35),
		Vector2(x+w/2, y-8),
		Vector2(x+w+4, y+h*0.35)
	]), roof)
	# Bord toit
	draw_polyline(PackedVector2Array([
		Vector2(x-4, y+h*0.35),
		Vector2(x+w/2, y-8),
		Vector2(x+w+4, y+h*0.35),
		Vector2(x-4, y+h*0.35)
	]), Color(roof.r*0.75, roof.g*0.75, roof.b*0.75), 1.5)
	# Fenetres
	draw_rect(Rect2(x+8, y+h*0.38, w*0.28, h*0.25), Color(0.80, 0.75, 0.45, 0.80))
	draw_rect(Rect2(x+w*0.55, y+h*0.38, w*0.28, h*0.25), Color(0.80, 0.75, 0.45, 0.80))
	# Porte
	draw_rect(Rect2(x+w/2-7, y+h-16, 14, 16), C_WOOD_D)
	# Label
	draw_string(ThemeDB.fallback_font, Vector2(x+3, y-2),
		label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8,
		Color(1.0, 0.92, 0.65, 0.90))
	# Fumee / signal
	if seed % 2 == 0:
		draw_circle(Vector2(x+w/2, y-10), 3.0,
			Color(0.90, 0.85, 0.70, pulse * 0.60))


# ── Ports ─────────────────────────────────────────────────────────────────────
func _draw_ports(t: float) -> void:
	var ports : Array = [
		# Ile principale
		{"pos": Vector2(175, 290), "dir": Vector2(-1, 0)},
		{"pos": Vector2(380, 470), "dir": Vector2(0, 1)},
		# Ile Est
		{"pos": Vector2(1118, 310), "dir": Vector2(1, 0)},
		# Ile Sud-Est
		{"pos": Vector2(860, 580), "dir": Vector2(0, 1)},
	]
	for p in ports:
		var pos : Vector2 = p["pos"]
		var dir : Vector2 = p["dir"]
		var perp : Vector2 = Vector2(-dir.y, dir.x)
		# Quai en bois
		draw_colored_polygon(PackedVector2Array([
			pos + perp*14, pos - perp*14,
			pos + dir*35 - perp*14,
			pos + dir*35 + perp*14
		]), C_WOOD)
		# Planches
		for j in range(4):
			var pp : Vector2 = pos + dir * (7.0 + float(j)*7.0)
			draw_line(pp + perp*14, pp - perp*14, C_WOOD_D, 1.5)
		# Anneau port
		var pulse : float = 0.7 + sin(t*2.0)*0.25
		draw_arc(pos + dir*35, 14.0, 0, TAU, 20,
			Color(0.25, 0.75, 1.0, pulse), 3.0)


# ── Details ───────────────────────────────────────────────────────────────────
func _draw_details(t: float) -> void:
	# Rochers dans l'ocean
	var rocks : Array[Vector2] = [
		Vector2(650, 200), Vector2(700, 380), Vector2(480, 160),
		Vector2(900, 380), Vector2(200, 420), Vector2(750, 240),
	]
	for i in range(rocks.size()):
		var pos : Vector2 = rocks[i]
		draw_circle(pos, 10.0, Color(0.22, 0.25, 0.20))
		draw_circle(pos+Vector2(3,-2), 6.0, Color(0.30, 0.33, 0.28))
		# Mousse marine
		draw_arc(pos, 12.0, 0.5, 2.2, 8,
			Color(0.30, 0.55, 0.35, 0.40), 2.0)

	# Halos mystere sur certaines iles
	for i in range(0, ISLANDS.size(), 2):
		var isl  : Dictionary = ISLANDS[i]
		var pu   : float      = 0.03 + sin(t*0.8 + float(i)*0.9)*0.015
		draw_circle(Vector2(isl["cx"], isl["cy"]),
			isl["rx"]*0.6, Color(0.20, 0.80, 0.40, pu))


# ── Blob helper ───────────────────────────────────────────────────────────────
func _draw_blob(cx: float, cy: float, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(28):
		var angle : float = float(i) / 28.0 * TAU
		var noise : float = sin(angle*3)*0.07 + cos(angle*5)*0.04
		pts.append(Vector2(cx+cos(angle)*rx*(1+noise), cy+sin(angle)*ry*(1+noise)))
	draw_colored_polygon(pts, col)


# ── Arbres ────────────────────────────────────────────────────────────────────
func _spawn_trees() -> void:
	if _tex_plant == null:
		return
	var tree_pos : Array[Vector2] = [
		# Ile principale
		Vector2(240,220), Vector2(300,180), Vector2(360,200),
		Vector2(430,190), Vector2(480,225), Vector2(260,310),
		Vector2(320,350), Vector2(420,360), Vector2(480,300),
		Vector2(350,270), Vector2(290,260), Vector2(450,250),
		# Ile Nord-Est
		Vector2(775,95),  Vector2(835,85),  Vector2(860,130),
		# Ile Est
		Vector2(975,265), Vector2(1035,280),Vector2(1005,335),
		# Ile Sud-Est
		Vector2(815,475), Vector2(875,470), Vector2(850,530),
		# Ile Sud
		Vector2(510,540), Vector2(565,555),
		# Ile Nord
		Vector2(565,38),  Vector2(618,45),
		# Ile Nord-Ouest
		Vector2(62,72),   Vector2(108,90),
	]
	for i in range(tree_pos.size()):
		var pos : Vector2 = tree_pos[i]
		var sh := ColorRect.new()
		sh.color = Color(0,0,0,0.18)
		sh.size  = Vector2(34,10)
		sh.position = pos + Vector2(-17,20)
		add_child(sh)
		var sp := Sprite2D.new()
		sp.texture = _tex_plant
		sp.region_enabled = true
		sp.region_rect = Rect2((i%3)*160, 0, 140, 160)
		sp.scale = Vector2(0.40, 0.40)
		sp.position = pos
		sp.centered = true
		sp.modulate = Color(0.80, 1.0, 0.65)
		add_child(sp)


# ── Noise helper ──────────────────────────────────────────────────────────────
func _noise(angle: float) -> float:
	return (sin(angle*4.0)*0.07 + sin(angle*8.0)*0.04 +
			cos(angle*6.0)*0.05 + cos(angle*11.0)*0.03)


# =============================================================================
#  NAVIGATION
# =============================================================================
func _setup_nav() -> void:
	# Chaque île = sa propre NavigationRegion2D
	for isl in ISLANDS:
		var b = load("res://scripts/NavBaker.gd").new()
		add_child(b)
		var cx : float = isl["cx"]
		var cy : float = isl["cy"]
		var rx : float = isl["rx"]
		var ry : float = isl["ry"]
		var outline : PackedVector2Array = NavBaker.make_ellipse(cx, cy, rx - 12.0, ry - 12.0, 40)
		var holes : Array = []
		if isl["main"]:
			# Bâtiment central + arbres île principale
			holes.append(NavBaker.make_rect(cx - 70, cy - 55, 140, 110))
			for p in [Vector2(240,220),Vector2(300,180),Vector2(360,200),
					  Vector2(430,190),Vector2(480,225),Vector2(260,310),
					  Vector2(320,350),Vector2(420,360),Vector2(480,300)]:
				holes.append(NavBaker.make_circle(p.x, p.y, 18.0))
		else:
			holes.append(NavBaker.make_circle(cx, cy - ry * 0.3, 16.0))
		b.bake(outline, holes)