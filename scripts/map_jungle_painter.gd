extends Node2D
# =============================================================================
#  map_jungle_painter.gd -- Sam's Jungle Tech Base
#  Jungle dense avec bases tech cachees, rivieres, forets
# =============================================================================

const MAP_W : int = 1152
const MAP_H : int = 620

const C_JUNGLE_BG  := Color(0.08, 0.20, 0.05)
const C_GRASS_D    := Color(0.12, 0.28, 0.06)
const C_GRASS_M    := Color(0.18, 0.38, 0.10)
const C_GRASS_L    := Color(0.24, 0.48, 0.14)
const C_GRASS_LIT  := Color(0.30, 0.58, 0.18)
const C_TREE_DARK  := Color(0.06, 0.16, 0.03)
const C_TREE_MID   := Color(0.10, 0.24, 0.05)
const C_TREE_LIT   := Color(0.16, 0.34, 0.08)
const C_RIVER      := Color(0.10, 0.30, 0.48)
const C_RIVER_L    := Color(0.14, 0.38, 0.58)
const C_SAND       := Color(0.65, 0.58, 0.38)
const C_CONCRETE   := Color(0.25, 0.28, 0.24)
const C_WALL       := Color(0.30, 0.34, 0.28)
const C_ROOF       := Color(0.20, 0.24, 0.18)
const C_NEON_G     := Color(0.20, 0.95, 0.45)
const C_NEON_B     := Color(0.15, 0.60, 1.00)
const C_WINDOW     := Color(0.35, 0.88, 0.55, 0.85)
const C_PATH       := Color(0.22, 0.25, 0.20)
const C_SHADOW     := Color(0.0, 0.0, 0.0, 0.22)

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
	_draw_terrain()
	_draw_rivers(t)
	_draw_clearings()
	_draw_bases(t)
	_draw_details(t)

# ── Terrain jungle ────────────────────────────────────────────────────────────
func _draw_terrain() -> void:
	draw_rect(Rect2(0, 0, MAP_W, MAP_H), C_JUNGLE_BG)
	# Zones herbe variees
	var patches : Array = [
		{"cx":200,"cy":150,"rx":180,"ry":130,"c":C_GRASS_M},
		{"cx":600,"cy":100,"rx":220,"ry":100,"c":C_GRASS_D},
		{"cx":950,"cy":180,"rx":160,"ry":140,"c":C_GRASS_M},
		{"cx":150,"cy":380,"rx":170,"ry":150,"c":C_GRASS_D},
		{"cx":500,"cy":350,"rx":280,"ry":180,"c":C_GRASS_M},
		{"cx":900,"cy":400,"rx":200,"ry":160,"c":C_GRASS_D},
		{"cx":350,"cy":530,"rx":200,"ry":80, "c":C_GRASS_M},
		{"cx":750,"cy":520,"rx":180,"ry":90, "c":C_GRASS_M},
		{"cx":576,"cy":310,"rx":350,"ry":220,"c":C_GRASS_L},
	]
	for p in patches:
		_draw_blob(p["cx"], p["cy"], p["rx"], p["ry"], p["c"])
	# Zone centrale eclairee
	_draw_blob(576, 310, 200, 140, C_GRASS_LIT)

# ── Rivieres ──────────────────────────────────────────────────────────────────
func _draw_rivers(t: float) -> void:
	# Lacs/mares dans la jungle
	_draw_lake(280, 180, 65, 40, t, 0.0)
	_draw_lake(820, 160, 55, 35, t, 1.0)
	_draw_lake(500, 470, 70, 38, t, 2.0)
	_draw_lake(180, 440, 50, 32, t, 3.0)
	_draw_lake(900, 430, 55, 35, t, 4.0)

func _draw_lake(cx: float, cy: float, rx: float, ry: float, t: float, seed: float) -> void:
	var steps : int = 40
	var pts_sand := PackedVector2Array()
	var pts_water := PackedVector2Array()
	var pts_lite  := PackedVector2Array()
	for i in range(steps):
		var angle : float = float(i) / float(steps) * TAU
		var noise : float = sin(angle*3+seed)*0.08 + cos(angle*5+seed)*0.05
		pts_sand.append(Vector2(cx+cos(angle)*(rx+6)*(1+noise), cy+sin(angle)*(ry+6)*(1+noise)))
		pts_water.append(Vector2(cx+cos(angle)*rx*(1+noise), cy+sin(angle)*ry*(1+noise)))
		pts_lite.append(Vector2(cx+cos(angle)*rx*0.55, cy+sin(angle)*ry*0.55))
	draw_colored_polygon(pts_sand, C_SAND)
	draw_colored_polygon(pts_water, C_RIVER)
	# Reflet anime
	var alpha : float = 0.18 + sin(t*1.2+seed)*0.08
	draw_colored_polygon(pts_lite, Color(C_RIVER_L.r, C_RIVER_L.g, C_RIVER_L.b, alpha))
	# Ride sur l'eau
	draw_arc(Vector2(cx-rx*0.2, cy-ry*0.2), rx*0.25, 0.3, 1.8,
		12, Color(C_RIVER_L.r, C_RIVER_L.g, C_RIVER_L.b, 0.30+sin(t*2+seed)*0.10), 1.5)

# ── Clairières (zones ouvertes) ───────────────────────────────────────────────
func _draw_clearings() -> void:
	var clearings : Array = [
		{"cx":576, "cy":310, "rx":160, "ry":110},
		{"cx":150, "cy":150, "rx":90,  "ry":70},
		{"cx":980, "cy":200, "rx":95,  "ry":75},
		{"cx":200, "cy":520, "rx":85,  "ry":60},
		{"cx":950, "cy":500, "rx":90,  "ry":65},
	]
	for cl in clearings:
		_draw_blob(cl["cx"], cl["cy"], cl["rx"], cl["ry"], C_GRASS_LIT)
		# Sol beton de la clairiere
		_draw_blob(cl["cx"], cl["cy"], cl["rx"]*0.75, cl["ry"]*0.75, C_CONCRETE)

# ── Bases tech ────────────────────────────────────────────────────────────────
func _draw_bases(t: float) -> void:
	# Base centrale
	_draw_base(506, 255, 140, 110, "SAM'S LAB", C_NEON_G, t, 0)
	# Base Nord-Ouest
	_draw_base(90, 100, 110, 85, "ALPHA", C_NEON_B, t, 1)
	# Base Nord-Est
	_draw_base(920, 130, 110, 85, "BETA", C_NEON_G, t, 2)
	# Base Sud-Ouest
	_draw_base(110, 460, 100, 80, "DELTA", C_NEON_B, t, 3)
	# Base Sud-Est
	_draw_base(930, 445, 105, 80, "SIGMA", C_NEON_G, t, 4)

func _draw_base(x: float, y: float, w: float, h: float,
		label: String, nc: Color, t: float, seed: int) -> void:
	var pulse : float = 0.55 + sin(t * 1.4 + float(seed) * 1.1) * 0.25

	# Ombre
	draw_rect(Rect2(x+4, y+4, w, h), C_SHADOW)
	# Corps beton
	draw_rect(Rect2(x, y, w, h), C_WALL)
	# Toit
	draw_rect(Rect2(x, y, w, 14), C_ROOF)
	# Bordure neon
	draw_rect(Rect2(x, y, w, h),
		Color(nc.r, nc.g, nc.b, pulse), false, 2.0)
	# Coins lumineux
	draw_circle(Vector2(x, y),     4.0, Color(nc.r, nc.g, nc.b, pulse))
	draw_circle(Vector2(x+w, y),   4.0, Color(nc.r, nc.g, nc.b, pulse))
	draw_circle(Vector2(x, y+h),   4.0, Color(nc.r, nc.g, nc.b, pulse))
	draw_circle(Vector2(x+w, y+h), 4.0, Color(nc.r, nc.g, nc.b, pulse))
	# Label
	draw_string(ThemeDB.fallback_font, Vector2(x+5, y+11),
		label, HORIZONTAL_ALIGNMENT_LEFT, -1, 9,
		Color(nc.r, nc.g, nc.b, 0.85))
	# Fenetres
	var cols : int = int((w - 16) / 20)
	var rows : int = int((h - 22) / 18)
	for row in range(rows):
		for col in range(cols):
			var wx : float = x + 8 + col * 20
			var wy : float = y + 17 + row * 18
			var on : bool  = (seed*5 + col*3 + row*7) % 4 != 0
			var fl : float = 0.75 + sin(t*3.5 + float(seed+col+row)*1.3) * 0.15
			if on:
				draw_rect(Rect2(wx, wy, 14, 11),
					Color(C_WINDOW.r, C_WINDOW.g, C_WINDOW.b, fl))
			else:
				draw_rect(Rect2(wx, wy, 14, 11),
					Color(0.10, 0.18, 0.12, 0.50))
	# Antenne
	draw_line(Vector2(x+w/2, y), Vector2(x+w/2, y-22),
		Color(0.45, 0.50, 0.40), 2.0)
	draw_circle(Vector2(x+w/2, y-22), 4.0,
		Color(nc.r, nc.g, nc.b, pulse))
	# Porte
	draw_rect(Rect2(x+w/2-8, y+h-18, 16, 18),
		Color(0.18, 0.45, 0.28))

# ── Chemins dans la jungle ────────────────────────────────────────────────────
func _draw_paths() -> void:
	var paths : Array = [
		[Vector2(200, 185), Vector2(350, 260), Vector2(506, 310)],
		[Vector2(1030, 215), Vector2(850, 265), Vector2(646, 310)],
		[Vector2(210, 540), Vector2(380, 420), Vector2(506, 365)],
		[Vector2(1035, 525), Vector2(860, 400), Vector2(646, 365)],
	]
	for path in paths:
		for i in range(path.size() - 1):
			var p1 : Vector2 = path[i]
			var p2 : Vector2 = path[i+1]
			var dir  : Vector2 = (p2 - p1).normalized()
			var perp : Vector2 = Vector2(-dir.y, dir.x) * 5.0
			draw_colored_polygon(PackedVector2Array([
				p1+perp, p1-perp, p2-perp, p2+perp
			]), C_PATH)

# ── Details ───────────────────────────────────────────────────────────────────
func _draw_details(t: float) -> void:
	# Rochers
	var rocks : Array[Vector2] = [
		Vector2(320,200), Vector2(780,250), Vector2(420,450),
		Vector2(700,480), Vector2(250,350), Vector2(880,350),
	]
	for pos in rocks:
		draw_circle(pos, 9.0, Color(0.28,0.30,0.24))
		draw_circle(pos+Vector2(4,-3), 6.0, Color(0.35,0.37,0.30))

	# Lueurs bases dans la jungle
	var bases : Array = [
		{"p":Vector2(576,310),"c":C_NEON_G},
		{"p":Vector2(145,142),"c":C_NEON_B},
		{"p":Vector2(975,172),"c":C_NEON_G},
		{"p":Vector2(160,500),"c":C_NEON_B},
		{"p":Vector2(982,485),"c":C_NEON_G},
	]
	for b in bases:
		var pu : float = 0.04 + sin(t*1.1)*0.02
		draw_circle(b["p"], 55.0,
			Color(b["c"].r, b["c"].g, b["c"].b, pu))

# ── Blob helper ───────────────────────────────────────────────────────────────
func _draw_blob(cx: float, cy: float, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	var steps : int = 32
	for i in range(steps):
		var angle : float = float(i) / float(steps) * TAU
		var noise : float = sin(angle*4)*0.08 + cos(angle*7)*0.05 + sin(angle*11)*0.03
		pts.append(Vector2(cx+cos(angle)*rx*(1+noise), cy+sin(angle)*ry*(1+noise)))
	draw_colored_polygon(pts, col)

# ── Arbres ────────────────────────────────────────────────────────────────────
func _spawn_trees() -> void:
	if _tex_plant == null:
		return
	var tree_pos : Array[Vector2] = [
		Vector2(60,50),Vector2(130,30),Vector2(250,60),
		Vector2(380,30),Vector2(520,50),Vector2(680,40),
		Vector2(820,55),Vector2(960,35),Vector2(1090,60),
		Vector2(40,200),Vector2(100,300),Vector2(60,420),
		Vector2(1110,200),Vector2(1060,320),Vector2(1100,430),
		Vector2(280,580),Vector2(420,600),Vector2(580,590),
		Vector2(740,595),Vector2(900,580),Vector2(1040,590),
		Vector2(300,160),Vector2(700,130),Vector2(860,180),
		Vector2(320,400),Vector2(480,160),Vector2(820,380),
		Vector2(420,500),Vector2(680,510),
	]
	for i in range(tree_pos.size()):
		var pos : Vector2 = tree_pos[i]
		var sh := ColorRect.new()
		sh.color = Color(0,0,0,0.20)
		sh.size  = Vector2(38,11)
		sh.position = pos + Vector2(-19,22)
		add_child(sh)
		var sp := Sprite2D.new()
		sp.texture = _tex_plant
		sp.region_enabled = true
		sp.region_rect = Rect2((i%3)*160, 0, 140, 160)
		sp.scale = Vector2(0.44, 0.44)
		sp.position = pos
		sp.centered = true
		sp.modulate = Color(0.75, 1.0, 0.60)
		add_child(sp)


# =============================================================================
#  NAVIGATION
# =============================================================================
func _setup_nav() -> void:
	var m : float = 30.0
	var outline : PackedVector2Array = NavBaker.make_rect(m, m, MAP_W - m * 2.0, MAP_H - m * 2.0)
	var holes : Array = []

	# Lacs
	holes.append(NavBaker.make_ellipse(280, 180, 65, 40))
	holes.append(NavBaker.make_ellipse(820, 160, 55, 35))
	holes.append(NavBaker.make_ellipse(500, 470, 70, 38))
	holes.append(NavBaker.make_ellipse(180, 440, 50, 32))
	holes.append(NavBaker.make_ellipse(900, 430, 55, 35))

	# Bases tech
	holes.append(NavBaker.make_rect(436, 200, 140, 110))
	holes.append(NavBaker.make_rect(35,   58, 110,  85))
	holes.append(NavBaker.make_rect(865,  88, 110,  85))
	holes.append(NavBaker.make_rect(60,  420, 100,  80))
	holes.append(NavBaker.make_rect(878, 405, 105,  80))

	# Arbres de bordure
	for p in [Vector2(60,50),Vector2(130,30),Vector2(250,60),Vector2(380,30),
			  Vector2(520,50),Vector2(680,40),Vector2(820,55),Vector2(960,35),
			  Vector2(1090,60),Vector2(40,200),Vector2(100,300),Vector2(60,420),
			  Vector2(1110,200),Vector2(1060,320),Vector2(1100,430),
			  Vector2(280,580),Vector2(420,600),Vector2(580,590),
			  Vector2(740,595),Vector2(900,580),Vector2(1040,590)]:
		holes.append(NavBaker.make_circle(p.x, p.y, 28.0))

	var b = load("res://scripts/NavBaker.gd").new()
	add_child(b)
	b.bake(outline, holes)
