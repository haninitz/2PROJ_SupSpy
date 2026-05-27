extends Node2D
# =============================================================================
#  map_beverly_painter.gd -- Clover's Beverly Hills Mall
#
#  Style : draw_colored_polygon() comme map_tropical
#  Layout :
#    - Eau bleue en fond avec vagues animees
#    - Ile centrale : grand mall + boutiques + jardin
#    - 4 petites iles autour : boutiques de luxe
#    - Ponts entre les iles
#    - Arbres et decorations
# =============================================================================

const MAP_W : int = 1152
const MAP_H : int = 620

# ── Couleurs ──────────────────────────────────────────────────────────────────
const C_OCEAN      := Color(0.10, 0.38, 0.75)
const C_OCEAN_DARK := Color(0.06, 0.22, 0.55)
const C_SAND       := Color(0.92, 0.82, 0.60)
const C_SAND_WET   := Color(0.75, 0.65, 0.42)
const C_GRASS      := Color(0.38, 0.68, 0.22)
const C_GRASS_DARK := Color(0.26, 0.50, 0.14)
const C_GRASS_LITE := Color(0.48, 0.80, 0.28)
const C_PATH       := Color(0.72, 0.68, 0.58)
const C_PATH_LINE  := Color(0.60, 0.56, 0.46)
const C_MALL_WALL  := Color(0.90, 0.85, 0.78)
const C_MALL_ROOF  := Color(0.88, 0.28, 0.35)
const C_MALL_ROOF2 := Color(0.95, 0.45, 0.20)
const C_SHOP_WALL  := Color(0.95, 0.88, 0.75)
const C_SHOP_ROOF  := Color(0.30, 0.55, 0.90)
const C_SHOP_ROOF2 := Color(0.90, 0.60, 0.20)
const C_WINDOW     := Color(0.55, 0.80, 1.00, 0.80)
const C_BRIDGE     := Color(0.55, 0.42, 0.28)
const C_BRIDGE_D   := Color(0.40, 0.30, 0.18)
const C_FOUNTAIN   := Color(0.40, 0.72, 1.00)

# ── Ile centrale ─────────────────────────────────────────────────────────────
const MAIN_CX := 576.0
const MAIN_CY := 310.0
const MAIN_RX := 220.0
const MAIN_RY := 175.0

# ── Petites iles ─────────────────────────────────────────────────────────────
const ISLANDS := [
	{"cx": 145.0,  "cy": 130.0,  "rx": 72.0, "ry": 58.0},
	{"cx": 1007.0, "cy": 130.0,  "rx": 72.0, "ry": 58.0},
	{"cx": 145.0,  "cy": 490.0,  "rx": 72.0, "ry": 58.0},
	{"cx": 1007.0, "cy": 490.0,  "rx": 72.0, "ry": 58.0},
]

var _tex_plant : Texture2D = null
var NavBaker = load("res://scripts/NavBaker.gd")

func _ready() -> void:
	_tex_plant = load("res://assets/tilesets/cainos/TX Plant.png")
	_spawn_trees()
	_setup_nav()


func _process(_delta: float) -> void:
	queue_redraw()


# =============================================================================
#  DESSIN PRINCIPAL
# =============================================================================

func _draw() -> void:
	var t : float = Time.get_ticks_msec() / 1000.0
	# Detecte le zoom via la camera
	var zoom : float = 1.0
	var cam : Node = get_viewport().get_camera_2d()
	if cam:
		zoom = cam.zoom.x

	_draw_ocean(t)
	_draw_small_islands()
	_draw_bridges()
	_draw_main_island()
	_draw_mall()
	_draw_small_island_buildings()
	_draw_fountain(t)
	_draw_paths()

	# Details visibles seulement au zoom
	if zoom >= 1.3:
		_draw_zoom_details(t, zoom)


func _draw_zoom_details(t: float, zoom: float) -> void:
	var alpha : float = clamp((zoom - 1.3) / 0.7, 0.0, 1.0)

	# Personnes dans le mall (petits points)
	var people_pos : Array[Vector2] = [
		Vector2(500, 360), Vector2(530, 375), Vector2(560, 355),
		Vector2(600, 370), Vector2(630, 360), Vector2(660, 375),
		Vector2(510, 395), Vector2(590, 390), Vector2(650, 395),
	]
	for i in range(people_pos.size()):
		var p : Vector2 = people_pos[i]
		var bob : float = sin(t * 2.0 + float(i) * 0.8) * 2.0
		# Corps
		draw_circle(p + Vector2(0, bob), 4.0,
			Color(0.85, 0.60, 0.40, alpha))
		# Tete
		draw_circle(p + Vector2(0, bob - 7.0), 3.0,
			Color(0.90, 0.72, 0.55, alpha))
		# Ombre
		draw_circle(p + Vector2(1, 3), 3.5,
			Color(0.0, 0.0, 0.0, 0.15 * alpha))

	# Vehicules sur les chemins
	var car_x : float = fmod(t * 30.0, 300.0) + 430.0
	draw_rect(Rect2(car_x, 405, 20, 10),
		Color(0.90, 0.20, 0.20, alpha))
	draw_rect(Rect2(car_x + 3, 402, 14, 7),
		Color(0.70, 0.15, 0.15, alpha))
	draw_circle(Vector2(car_x + 4, 415), 3.5,
		Color(0.20, 0.20, 0.20, alpha))
	draw_circle(Vector2(car_x + 16, 415), 3.5,
		Color(0.20, 0.20, 0.20, alpha))

	# Panneaux boutiques sur les iles
	for isl in ISLANDS:
		var cx : float = isl["cx"]
		var cy : float = isl["cy"]
		draw_rect(Rect2(cx - 8, cy - 5, 16, 8),
			Color(C_MALL_ROOF.r, C_MALL_ROOF.g, C_MALL_ROOF.b, alpha))

	# Details fontaine (petits reflets)
	if zoom >= 1.6:
		var alpha2 : float = clamp((zoom - 1.6) / 0.4, 0.0, 1.0)
		var fc := Vector2(MAIN_CX, MAIN_CY + 80.0)
		for i in range(12):
			var angle : float = float(i) / 12.0 * TAU + t * 0.5
			var rp : Vector2 = fc + Vector2(cos(angle), sin(angle)) * 22.0
			draw_circle(rp, 1.5,
				Color(0.80, 0.95, 1.0, 0.60 * alpha2))


# ── Ocean ─────────────────────────────────────────────────────────────────────
func _draw_ocean(t: float) -> void:
	draw_rect(Rect2(0, 0, MAP_W, MAP_H), C_OCEAN)
	draw_rect(Rect2(0, 0, MAP_W, 20), C_OCEAN_DARK)
	draw_rect(Rect2(0, MAP_H - 20, MAP_W, 20), C_OCEAN_DARK)
	draw_rect(Rect2(0, 0, 20, MAP_H), C_OCEAN_DARK)
	draw_rect(Rect2(MAP_W - 20, 0, 20, MAP_H), C_OCEAN_DARK)

	# Vagues animees
	for i in range(18):
		var wy    : float = 16.0 + float(i) * 34.0
		var alpha : float = 0.08 + sin(t * 0.8 + float(i) * 0.6) * 0.04
		var col   : Color = Color(0.60, 0.88, 1.0, alpha)
		var x : int = 0
		while x < MAP_W:
			var y1 : float = wy + sin(float(x) * 0.015 + t * 0.9 + float(i) * 0.5) * 6.0
			var y2 : float = wy + sin(float(x + 40) * 0.015 + t * 0.9 + float(i) * 0.5) * 6.0
			draw_line(Vector2(x, y1), Vector2(x + 40, y2), col, 1.5)
			x += 40

	# Reflets soleil
	for i in range(8):
		var sx : float = 200.0 + float(i) * 110.0
		var sy : float = 60.0 + sin(t * 0.5 + float(i)) * 20.0
		draw_line(Vector2(sx, sy), Vector2(sx + 30, sy + 3),
			Color(1.0, 1.0, 0.8, 0.15), 2.0)


# ── Ile principale ───────────────────────────────────────────────────────────
func _draw_main_island() -> void:
	_draw_island_shape(MAIN_CX, MAIN_CY, MAIN_RX, MAIN_RY, 0.0)


# ── Petites iles ─────────────────────────────────────────────────────────────
func _draw_small_islands() -> void:
	for isl in ISLANDS:
		_draw_island_shape(isl["cx"], isl["cy"], isl["rx"], isl["ry"], 1.0)


func _draw_island_shape(cx: float, cy: float, rx: float, ry: float, seed_off: float) -> void:
	var steps : int = 80

	var pts_wet  := PackedVector2Array()
	var pts_sand := PackedVector2Array()
	var pts      := PackedVector2Array()
	var pts_dark := PackedVector2Array()
	var pts_lite := PackedVector2Array()

	for i in range(steps + 1):
		var angle : float = float(i) / float(steps) * TAU
		var noise : float = _noise(angle + seed_off)

		pts_wet.append(Vector2(cx + cos(angle) * (rx + 22.0) * (1.0 + noise * 0.5),
			cy + sin(angle) * (ry + 22.0) * (1.0 + noise * 0.5)))
		pts_sand.append(Vector2(cx + cos(angle) * (rx + 12.0) * (1.0 + noise * 0.6),
			cy + sin(angle) * (ry + 12.0) * (1.0 + noise * 0.6)))
		var r : float = rx * (1.0 + noise)
		var rr : float = ry * (1.0 + noise)
		pts.append(Vector2(cx + cos(angle) * r, cy + sin(angle) * rr))
		pts_dark.append(Vector2(cx + cos(angle) * r * 0.92, cy + sin(angle) * rr * 0.92))
		pts_lite.append(Vector2(cx + cos(angle) * rx * 0.55, cy + sin(angle) * ry * 0.55))

	draw_colored_polygon(pts_wet, C_SAND_WET)
	draw_colored_polygon(pts_sand, C_SAND)
	draw_colored_polygon(pts, C_GRASS)
	draw_colored_polygon(pts_dark, C_GRASS_DARK)
	draw_colored_polygon(pts_lite, C_GRASS_LITE)
	draw_circle(Vector2(cx, cy), rx * 0.28, Color(C_GRASS_LITE.r, C_GRASS_LITE.g, C_GRASS_LITE.b, 0.35))


# ── Mall central ─────────────────────────────────────────────────────────────
func _draw_mall() -> void:
	# Esplanade pavee
	_draw_rect_rounded(Vector2(430, 240), Vector2(292, 175), C_PATH)
	# Lignes du pave
	var x : int = 440
	while x < 720:
		draw_line(Vector2(x, 240), Vector2(x, 415), C_PATH_LINE, 1.0)
		x += 18
	var y : int = 250
	while y < 415:
		draw_line(Vector2(430, y), Vector2(722, y), C_PATH_LINE, 1.0)
		y += 18

	# Batiment principal du mall
	var mall_rect := Rect2(468, 255, 216, 100)
	draw_rect(mall_rect, C_MALL_WALL)
	# Toit en plusieurs triangles (style arcs)
	for i in range(4):
		var rx2 : float = 468.0 + float(i) * 54.0
		draw_colored_polygon(PackedVector2Array([
			Vector2(rx2, 255), Vector2(rx2 + 27, 235), Vector2(rx2 + 54, 255)
		]), C_MALL_ROOF if i % 2 == 0 else C_MALL_ROOF2)
	# Fenetres du mall
	for i in range(5):
		draw_rect(Rect2(476 + i * 40, 270, 22, 30), C_WINDOW)
	# Porte centrale
	draw_rect(Rect2(561, 320, 30, 35), Color(0.35, 0.60, 0.90))
	draw_rect(Rect2(563, 322, 12, 33), C_WINDOW)
	draw_rect(Rect2(577, 322, 12, 33), C_WINDOW)
	# Enseigne du mall
	draw_rect(Rect2(490, 242, 172, 16), C_MALL_ROOF)
	draw_string(ThemeDB.fallback_font, Vector2(518, 254),
		"BEVERLY MALL", HORIZONTAL_ALIGNMENT_LEFT, -1, 10,
		Color(1.0, 1.0, 1.0))

	# Petites boutiques autour
	_draw_shop(435, 270, 30, 60, C_SHOP_ROOF,  C_SHOP_WALL)
	_draw_shop(687, 270, 30, 60, C_SHOP_ROOF,  C_SHOP_WALL)
	_draw_shop(435, 340, 30, 60, C_SHOP_ROOF2, C_SHOP_WALL)
	_draw_shop(687, 340, 30, 60, C_SHOP_ROOF2, C_SHOP_WALL)


# ── Batiments petites iles ────────────────────────────────────────────────────
func _draw_small_island_buildings() -> void:
	# Ile NW (145, 130) -- boutique luxe rose
	_draw_luxury_shop(115, 100, 60, 55, C_MALL_ROOF, C_SHOP_WALL)
	# Ile NE (1007, 130) -- boutique luxe bleue
	_draw_luxury_shop(977, 100, 60, 55, C_SHOP_ROOF, C_SHOP_WALL)
	# Ile SW (145, 490) -- boutique luxe orange
	_draw_luxury_shop(115, 460, 60, 55, C_MALL_ROOF2, C_SHOP_WALL)
	# Ile SE (1007, 490) -- boutique luxe verte
	_draw_luxury_shop(977, 460, 60, 55, C_SHOP_ROOF2, C_SHOP_WALL)


# ── Ponts ─────────────────────────────────────────────────────────────────────
func _draw_bridges() -> void:
	pass  # Pas de ponts -- iles separees


func _draw_bridge(from: Vector2, to: Vector2, width: int) -> void:
	var dir  : Vector2 = (to - from).normalized()
	var perp : Vector2 = Vector2(-dir.y, dir.x) * float(width) * 0.5
	draw_colored_polygon(PackedVector2Array([
		from + perp, from - perp, to - perp, to + perp
	]), C_BRIDGE)
	# Planches
	var dist  : float = from.distance_to(to)
	var steps : int   = int(dist / 16.0)
	for i in range(steps):
		var p : Vector2 = from.lerp(to, float(i) / float(steps))
		draw_line(p + perp, p - perp, C_BRIDGE_D, 1.0)


# ── Fontaine centrale ─────────────────────────────────────────────────────────
func _draw_fountain(t: float) -> void:
	var fc := Vector2(MAIN_CX, MAIN_CY + 80.0)
	draw_circle(fc, 28.0, Color(0.55, 0.72, 0.88))
	draw_circle(fc, 20.0, C_FOUNTAIN)
	draw_circle(fc, 8.0, Color(0.80, 0.95, 1.0))
	# Jet d'eau anime
	for i in range(6):
		var angle : float = float(i) / 6.0 * TAU + t * 1.5
		var jet   : Vector2 = fc + Vector2(cos(angle), sin(angle)) * 12.0
		var tip   : Vector2 = jet + Vector2(cos(angle), sin(angle) - 0.8) * 14.0
		draw_line(jet, tip, Color(0.70, 0.90, 1.0, 0.80), 2.0)
	# Anneau pulsant
	var pulse : float = sin(t * 2.0) * 0.1
	draw_arc(fc, 30.0 + pulse * 5.0, 0, TAU, 32,
		Color(C_FOUNTAIN.r, C_FOUNTAIN.g, C_FOUNTAIN.b, 0.40), 2.0)


# ── Chemins decoratifs sur l'ile centrale ─────────────────────────────────────
func _draw_paths() -> void:
	# Allee centrale nord-sud
	draw_rect(Rect2(MAIN_CX - 10, MAIN_CY - MAIN_RY + 20, 20, 60), C_PATH)
	draw_rect(Rect2(MAIN_CX - 10, MAIN_CY + 50, 20, 50), C_PATH)
	# Allee est-ouest
	draw_rect(Rect2(MAIN_CX - MAIN_RX + 20, MAIN_CY - 8, 60, 16), C_PATH)
	draw_rect(Rect2(MAIN_CX + MAIN_RX - 80, MAIN_CY - 8, 60, 16), C_PATH)


# =============================================================================
#  ARBRES
# =============================================================================

func _spawn_trees() -> void:
	if _tex_plant == null:
		return

	var tree_pos : Array[Vector2] = [
		# Ile centrale
		Vector2(420, 290), Vector2(740, 290),
		Vector2(420, 380), Vector2(740, 380),
		Vector2(490, 420), Vector2(660, 420),
		Vector2(510, 200), Vector2(640, 200),
		# Petites iles
		Vector2(106, 148), Vector2(162, 145),
		Vector2(968, 148), Vector2(1022, 145),
		Vector2(106, 508), Vector2(162, 505),
		Vector2(968, 508), Vector2(1022, 505),
	]

	for i in range(tree_pos.size()):
		var pos : Vector2 = tree_pos[i]
		var shadow := ColorRect.new()
		shadow.color    = Color(0, 0, 0, 0.18)
		shadow.size     = Vector2(36, 10)
		shadow.position = pos + Vector2(-18, 20)
		add_child(shadow)

		var sprite             := Sprite2D.new()
		sprite.texture         = _tex_plant
		sprite.region_enabled  = true
		sprite.region_rect     = Rect2((i % 3) * 160, 0, 140, 160)
		sprite.scale           = Vector2(0.36, 0.36)
		sprite.position        = pos
		sprite.centered        = true
		sprite.modulate        = Color(0.90, 1.0, 0.72)
		add_child(sprite)


# =============================================================================
#  HELPERS
# =============================================================================

func _draw_shop(x: float, y: float, w: float, h: float,
		roof_col: Color, wall_col: Color) -> void:
	# Mur
	draw_rect(Rect2(x, y + h * 0.35, w, h * 0.65), wall_col)
	# Toit triangle
	draw_colored_polygon(PackedVector2Array([
		Vector2(x - 4, y + h * 0.35),
		Vector2(x + w * 0.5, y),
		Vector2(x + w + 4, y + h * 0.35)
	]), roof_col)
	# Fenetre
	draw_rect(Rect2(x + w * 0.2, y + h * 0.45, w * 0.28, h * 0.25), C_WINDOW)
	draw_rect(Rect2(x + w * 0.55, y + h * 0.45, w * 0.28, h * 0.25), C_WINDOW)


func _draw_luxury_shop(x: float, y: float, w: float, h: float,
		roof_col: Color, wall_col: Color) -> void:
	# Facade principale
	draw_rect(Rect2(x, y + h * 0.30, w, h * 0.70), wall_col)
	# Soubassement (base plus foncee)
	draw_rect(Rect2(x, y + h * 0.75, w, h * 0.25),
		Color(wall_col.r * 0.85, wall_col.g * 0.85, wall_col.b * 0.85))
	# Toit mansarde arrondi (3 segments)
	draw_colored_polygon(PackedVector2Array([
		Vector2(x - 5, y + h * 0.30),
		Vector2(x + w * 0.5, y - 5),
		Vector2(x + w + 5, y + h * 0.30)
	]), roof_col)
	# Lucarne sur le toit
	draw_rect(Rect2(x + w * 0.35, y + h * 0.08, w * 0.30, h * 0.18),
		Color(roof_col.r * 0.80, roof_col.g * 0.80, roof_col.b * 0.80))
	draw_rect(Rect2(x + w * 0.40, y + h * 0.10, w * 0.20, h * 0.12), C_WINDOW)
	# Grande vitrine (rez-de-chaussee)
	draw_rect(Rect2(x + w * 0.08, y + h * 0.38, w * 0.84, h * 0.28),
		Color(C_WINDOW.r, C_WINDOW.g, C_WINDOW.b, 0.70))
	# Separation vitrine
	draw_line(Vector2(x + w * 0.5, y + h * 0.38),
		Vector2(x + w * 0.5, y + h * 0.66), Color(0.7, 0.7, 0.8), 1.5)
	# Etage : deux fenetres
	draw_rect(Rect2(x + w * 0.12, y + h * 0.50, w * 0.30, h * 0.18), C_WINDOW)
	draw_rect(Rect2(x + w * 0.58, y + h * 0.50, w * 0.30, h * 0.18), C_WINDOW)
	# Porte
	draw_rect(Rect2(x + w * 0.38, y + h * 0.66, w * 0.24, h * 0.34),
		Color(0.30, 0.50, 0.80))
	# Enseigne lumineuse
	draw_rect(Rect2(x + w * 0.10, y + h * 0.27, w * 0.80, h * 0.10), roof_col)
	draw_line(Vector2(x + w * 0.10, y + h * 0.27),
		Vector2(x + w * 0.90, y + h * 0.27),
		Color(1.0, 1.0, 1.0, 0.60), 1.5)


func _draw_rect_rounded(pos: Vector2, size: Vector2, col: Color) -> void:
	draw_rect(Rect2(pos, size), col)


func _noise(angle: float) -> float:
	return (sin(angle * 4.0) * 0.07 +
			sin(angle * 8.0) * 0.04 +
			sin(angle * 13.0) * 0.03 +
			cos(angle * 6.0) * 0.05)


# =============================================================================
#  NAVIGATION
# =============================================================================
func _setup_nav() -> void:
	# ── Île principale ────────────────────────────────────────────────────────
	var outline : PackedVector2Array = NavBaker.make_ellipse(MAIN_CX, MAIN_CY, MAIN_RX - 8.0, MAIN_RY - 8.0, 48)
	var holes : Array = []
	# Bâtiment central mall
	holes.append(NavBaker.make_rect(468, 255, 216, 100))
	# Boutiques latérales
	holes.append(NavBaker.make_rect(435, 270, 30, 130))
	holes.append(NavBaker.make_rect(687, 270, 30, 130))
	# Arbres île centrale
	for p in [Vector2(420,290),Vector2(740,290),Vector2(420,380),
			  Vector2(740,380),Vector2(490,420),Vector2(660,420),
			  Vector2(510,200),Vector2(640,200)]:
		holes.append(NavBaker.make_circle(p.x, p.y, 22.0))
	var b1 = load("res://scripts/NavBaker.gd").new()
	add_child(b1)
	b1.bake(outline, holes)

	# ── Petites îles ─────────────────────────────────────────────────────────
	for isl in ISLANDS:
		var b2 = load("res://scripts/NavBaker.gd").new()
		add_child(b2)
		var ol : PackedVector2Array = NavBaker.make_ellipse(isl["cx"], isl["cy"],
			isl["rx"] - 8.0, isl["ry"] - 8.0, 24)
		var h2 : Array = [NavBaker.make_rect(
			isl["cx"] - 30.0, isl["cy"] - 27.5, 60.0, 55.0)]
		b2.bake(ol, h2)
