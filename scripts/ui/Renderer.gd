class_name Renderer
extends RefCounted
# =============================================================================
#  Renderer.gd — SupKonQuest
#
#  Version adaptée TileMap : ne dessine PAS le fond (géré par les TileMaps).
#  Dessine uniquement : camps, connexions, HUD overlay, game over.
# =============================================================================

const WIN_W  = 1152
const MAP_H  = 620
const CAMP_R = 42.0

const C_P1      = Color(0.22, 0.45, 0.90)
const C_P2      = Color(0.88, 0.22, 0.22)
const C_NEUTRAL = Color(0.55, 0.55, 0.55)
const C_SELECT  = Color(1.00, 0.92, 0.15)
const C_PANEL   = Color(0.08, 0.08, 0.08)
const C_GOLD    = Color(1.00, 0.87, 0.30)


func draw(canvas: Node2D, font: Font, camps: Array, selected_idx: int,
		_forests: Array, _river_x: int, _bridge_y: int, _bridge_h: int,
		_has_water: bool, _land_zones: Array,
		game_over: bool, winner: String) -> void:

	var t : float = Time.get_ticks_msec() / 1000.0

	# ── Le fond est géré par les TileMaps — on ne dessine rien ici ────────────

	# ── Connexions entre camps (lignes pointillées) ───────────────────────────
	for i in range(camps.size()):
		for j in range(i + 1, camps.size()):
			var d : float = camps[i].pos.distance_to(camps[j].pos)
			if d < 520.0:
				canvas.draw_line(camps[i].pos, camps[j].pos,
					Color(0.85, 0.85, 0.85, 0.20), 1.5)
				var progress : float = fmod(t * 0.45 + i * 0.4 + j * 0.7, 1.0)
				var ppos : Vector2   = camps[i].pos.lerp(camps[j].pos, progress)
				canvas.draw_circle(ppos, 3.0, Color(1.0, 1.0, 1.0, 0.30))

	# ── Camps ─────────────────────────────────────────────────────────────────
	for i in range(camps.size()):
		_draw_camp(canvas, font, camps[i], i == selected_idx, t)

	# ── Barre HUD en bas ──────────────────────────────────────────────────────
	# canvas.draw_rect(Rect2(0, MAP_H, WIN_W, 100), C_PANEL)  # géré par HUD.gd

	# ── Overlay game over ─────────────────────────────────────────────────────
	if game_over:
		canvas.draw_rect(Rect2(0, 0, WIN_W, MAP_H), Color(0, 0, 0, 0.55))
		if font:
			canvas.draw_string(font, Vector2(WIN_W / 2.0 - 200, MAP_H / 2.0),
				"VICTOIRE : %s" % winner,
				HORIZONTAL_ALIGNMENT_CENTER, 400, 32, Color(1.0, 0.87, 0.20))


# ─────────────────────────────────────────────────────────────────────────────
#  DESSIN D'UN CAMP
# ─────────────────────────────────────────────────────────────────────────────

func _draw_camp(canvas: Node2D, font: Font, camp, is_selected: bool, t: float) -> void:
	# Supporte owner_id (Camp_hani Node2D) et owner (Camp RefCounted)
	var col : Color = _owner_color(camp.get("owner_id") if "owner_id" in camp else camp.get("owner", -1))

	# Ombre
	canvas.draw_circle(camp.pos + Vector2(5, 5), CAMP_R, Color(0, 0, 0, 0.22))

	# Sélection pulsante
	if is_selected:
		var pulse : float = abs(sin(t * 3.5)) * 12.0
		canvas.draw_circle(camp.pos, CAMP_R + 8.0 + pulse, C_SELECT)
		for i in range(4):
			var angle : float = t * 2.8 + i * TAU / 4.0
			var op    : Vector2 = camp.pos + Vector2(cos(angle), sin(angle)) * (CAMP_R + 20.0 + pulse * 0.4)
			canvas.draw_circle(op, 5.0, C_SELECT)

	# Port
	if camp.type == "port":
		canvas.draw_arc(camp.pos, CAMP_R + 5.0, 0, TAU, 48,
			Color(0.0, 0.15, 0.60), 4.0)

	# Corps du camp
	canvas.draw_circle(camp.pos, CAMP_R, col)
	canvas.draw_arc(camp.pos, CAMP_R, 0, TAU, 48, Color.BLACK, 2.5)

	# Labels
	if camp.type == "port":
		canvas.draw_string(font, camp.pos + Vector2(-95, -CAMP_R - 20.0),
			"[ PORT ]", HORIZONTAL_ALIGNMENT_CENTER, 190, 11,
			Color(0.40, 0.70, 1.00))

	# Supporte camp_name (Camp_hani) et name (Camp RefCounted)
	var display_name : String = camp.get("camp_name") if "camp_name" in camp else camp.get("name", "?")
	canvas.draw_string(font, camp.pos + Vector2(-95, -CAMP_R - 6.0),
		display_name, HORIZONTAL_ALIGNMENT_CENTER, 190, 13, Color.WHITE)

	# Unité et nb
	var tlabel : String = ""
	if UnitDefs.TYPES.has(camp.unit_type):
		tlabel = UnitDefs.TYPES[camp.unit_type].get("label", camp.unit_type)
	canvas.draw_string(font, camp.pos + Vector2(-30, -5),
		tlabel, HORIZONTAL_ALIGNMENT_LEFT, 60, 10, Color.WHITE)

	canvas.draw_string(font, camp.pos + Vector2(-30, 16),
		str(camp.units), HORIZONTAL_ALIGNMENT_CENTER, 60, 20, Color.WHITE)

	# Revenu
	canvas.draw_string(font, camp.pos + Vector2(-50, CAMP_R + 18.0),
		"+%d or" % camp.income, HORIZONTAL_ALIGNMENT_CENTER, 100, 12, C_GOLD)

	# File de production
	# Supporte queue (Camp RefCounted) et production_queue (Camp_hani) via alias
	var _queue : Array = camp.get("queue") if "queue" in camp else camp.get("production_queue", [])
	if _queue.size() > 0:
		canvas.draw_string(font, camp.pos + Vector2(-40, CAMP_R + 32.0),
			"[%d en file]" % _queue.size(),
			HORIZONTAL_ALIGNMENT_CENTER, 80, 10, C_GOLD)


func _owner_color(owner: int) -> Color:
	match owner:
		0: return C_P1
		1: return C_P2
	return C_NEUTRAL
