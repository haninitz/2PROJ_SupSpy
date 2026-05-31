extends Node2D
# =============================================================================
#  Minimap.gd — SupKonQuest · Totally Spies Edition
#  Affiche : camps (cercles colorés) + unités (points) + rectangle caméra
# =============================================================================

const MAP_W   : float = 1152.0
const MAP_H   : float = 620.0
const MINI_W  : float = 180.0
const MINI_H  : float = 98.0
const POS_X   : float = MAP_W - MINI_W - 8.0
const POS_Y   : float = MAP_H - MINI_H - 8.0
const SCALE_X : float = MINI_W / MAP_W
const SCALE_Y : float = MINI_H / MAP_H

# Couleurs joueurs
const C_P1      := Color(0.22, 0.45, 0.90)
const C_P2      := Color(0.88, 0.22, 0.22)
const C_NEUTRAL := Color(0.55, 0.55, 0.55)
const C_PINK    := Color(1.00, 0.20, 0.58)
const C_GOLD    := Color(1.00, 0.85, 0.20)
const C_CAM     := Color(1.00, 1.00, 1.00, 0.55)  # rectangle caméra


func setup() -> void:
	position = Vector2(POS_X, POS_Y)
	z_index  = 10
	visible  = false


func show_minimap() -> void:
	visible = true


func hide_minimap() -> void:
	visible = false


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	var font : Font = ThemeDB.fallback_font

	# ── Fond + bordure ────────────────────────────────────────────────────────
	draw_rect(Rect2(0, 0, MINI_W, MINI_H), Color(0.05, 0.08, 0.05, 0.92))
	draw_rect(Rect2(0, 0, MINI_W, MINI_H), C_PINK, false, 1.5)

	# Label titre
	draw_string(font, Vector2(2, -3), "MINIMAP",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(C_PINK.r, C_PINK.g, C_PINK.b, 0.55))

	# ── Grille légère ─────────────────────────────────────────────────────────
	var grid_col := Color(0.20, 0.30, 0.20, 0.18)
	var gx : float = 0.0
	while gx <= MINI_W:
		draw_line(Vector2(gx, 0), Vector2(gx, MINI_H), grid_col, 0.4)
		gx += MINI_W / 6.0
	var gy : float = 0.0
	while gy <= MINI_H:
		draw_line(Vector2(0, gy), Vector2(MINI_W, gy), grid_col, 0.4)
		gy += MINI_H / 3.0

	# ── Données depuis Main ───────────────────────────────────────────────────
	var main : Node = get_tree().get_first_node_in_group("main_node")
	if main == null:
		main = get_node_or_null("/root/Main")

	var has_camps : bool = main != null and main.get("camps") != null \
		and main.camps.size() > 0

	# ── Camps ─────────────────────────────────────────────────────────────────
	if has_camps:
		for camp in main.camps:
			if not is_instance_valid(camp):
				continue
			var pos   : Vector2 = camp.global_position
			var mx    : float   = clamp(pos.x * SCALE_X, 0, MINI_W)
			var my    : float   = clamp(pos.y * SCALE_Y, 0, MINI_H)
			var owner : int     = camp.get("owner_id") if "owner_id" in camp \
				else camp.get("owner", -1)

			var col : Color = _owner_color(owner, main)

			# Point rempli + halo semi-transparent
			draw_circle(Vector2(mx, my), 3.5, col)
			draw_arc(Vector2(mx, my), 4.5, 0, TAU, 12,
				Color(col.r, col.g, col.b, 0.30), 1.0)

			# Petit point blanc si camp sélectionné
			if main.get("_selected") and main._selected == camp:
				draw_circle(Vector2(mx, my), 1.5, Color.WHITE)

	# ── Unités (petits points) ────────────────────────────────────────────────
	var units := get_tree().get_nodes_in_group("units")
	for unit in units:
		if not is_instance_valid(unit):
			continue
		if unit.get("is_alive") == false:
			continue
		var upos : Vector2 = unit.global_position
		var ux   : float   = clamp(upos.x * SCALE_X, 0, MINI_W)
		var uy   : float   = clamp(upos.y * SCALE_Y, 0, MINI_H)
		var uid  : int     = unit.get("owner_id") if "owner_id" in unit else -1
		var ucol : Color   = _owner_color(uid, main)
		draw_circle(Vector2(ux, uy), 1.5, ucol)

	# ── Rectangle caméra ─────────────────────────────────────────────────────
	_draw_camera_rect()


func _owner_color(owner_id: int, main: Node = null) -> Color:
	if owner_id == 0:
		return C_NEUTRAL

	if main and main.has_method("_get_owner_color"):
		return main._get_owner_color(owner_id)

	var gm := get_node_or_null("/root/GameManager")
	if gm and gm.has_method("get_team_color"):
		return gm.get_team_color(owner_id)

	if gm and gm.has_method("find_player_by_id"):
		var player = gm.find_player_by_id(owner_id)
		if player and "color" in player:
			return player.color

	if owner_id == 1:
		return C_P1
	if owner_id == 2:
		return C_P2
	return C_NEUTRAL

func _draw_camera_rect() -> void:
	# Cherche la Camera2D active dans la scène
	var camera : Camera2D = _find_active_camera()
	if camera == null:
		return

	var vp      : Viewport = get_viewport()
	var vp_size : Vector2  = vp.get_visible_rect().size  # ex: 1152 × 720
	var zoom    : Vector2  = camera.zoom                  # ex: Vector2(1,1) ou (1.5,1.5)

	# Taille de la zone visible en pixels monde
	var world_w : float = vp_size.x / zoom.x
	var world_h : float = vp_size.y / zoom.y

	# Position monde du coin supérieur gauche de la caméra
	var cam_world : Vector2 = camera.global_position
	var top_left  : Vector2 = cam_world - Vector2(world_w, world_h) * 0.5

	# Convertit en coordonnées minimap
	var rect_x : float = top_left.x * SCALE_X
	var rect_y : float = top_left.y * SCALE_Y
	var rect_w : float = world_w * SCALE_X
	var rect_h : float = world_h * SCALE_Y

	# Clamp pour rester dans la minimap
	var r := Rect2(
		clamp(rect_x, 0.0, MINI_W),
		clamp(rect_y, 0.0, MINI_H),
		clamp(rect_w, 1.0, MINI_W),
		clamp(rect_h, 1.0, MINI_H)
	)

	# Fond légèrement blanc (zone visible)
	draw_rect(r, Color(1.0, 1.0, 1.0, 0.06))
	# Bordure blanche nette
	draw_rect(r, C_CAM, false, 1.2)

	# Coins marqués (petits L blancs aux 4 coins)
	var corner_len : float = minf(4.0, r.size.x * 0.25)
	# ── coin haut-gauche
	draw_line(r.position,                              r.position + Vector2(corner_len, 0),    C_CAM, 1.5)
	draw_line(r.position,                              r.position + Vector2(0, corner_len),    C_CAM, 1.5)
	# ── coin haut-droit
	draw_line(r.position + Vector2(r.size.x, 0),      r.position + Vector2(r.size.x - corner_len, 0), C_CAM, 1.5)
	draw_line(r.position + Vector2(r.size.x, 0),      r.position + Vector2(r.size.x, corner_len),     C_CAM, 1.5)
	# ── coin bas-gauche
	draw_line(r.position + Vector2(0, r.size.y),      r.position + Vector2(corner_len, r.size.y),     C_CAM, 1.5)
	draw_line(r.position + Vector2(0, r.size.y),      r.position + Vector2(0, r.size.y - corner_len), C_CAM, 1.5)
	# ── coin bas-droit
	draw_line(r.position + r.size,                    r.position + r.size - Vector2(corner_len, 0),   C_CAM, 1.5)
	draw_line(r.position + r.size,                    r.position + r.size - Vector2(0, corner_len),   C_CAM, 1.5)


func _find_active_camera() -> Camera2D:
	# 1. Cherche dans le groupe dédié
	var cams_grp := get_tree().get_nodes_in_group("main_camera")
	if cams_grp.size() > 0 and cams_grp[0] is Camera2D:
		return cams_grp[0] as Camera2D

	# 2. Cherche depuis Main
	var main : Node = get_tree().get_first_node_in_group("main_node")
	if main == null:
		main = get_node_or_null("/root/Main")
	if main:
		var cam_node = main.get_node_or_null("Camera2D")
		if cam_node is Camera2D:
			return cam_node as Camera2D

	# 3. Fallback : cherche récursivement dans la scène
	return _find_camera_recursive(get_tree().root)


func _find_camera_recursive(node: Node) -> Camera2D:
	if node is Camera2D and (node as Camera2D).enabled:
		return node as Camera2D
	for child in node.get_children():
		var found := _find_camera_recursive(child)
		if found:
			return found
	return null
