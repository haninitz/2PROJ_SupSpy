extends Node
# =============================================================================
#  NavBaker.gd  —  res://scripts/NavBaker.gd
#
#  Génère une NavigationRegion2D simple SANS trous.
#  On utilise add_polygon() directement au lieu de make_polygons_from_outlines.
#  Les obstacles sont gérés par avoidance sur les unités.
# =============================================================================

func bake(outline: PackedVector2Array, _holes: Array = []) -> void:
	var nav_poly := NavigationPolygon.new()

	# Ajoute le contour
	nav_poly.add_outline(outline)

	# Génère les polygones depuis les contours
	# (sans trous pour éviter l'erreur de winding)
	nav_poly.make_polygons_from_outlines()

	var region := NavigationRegion2D.new()
	region.navigation_polygon = nav_poly
	get_parent().add_child(region)


# ── Helpers géométriques ──────────────────────────────────────────────────────

static func make_ellipse(cx: float, cy: float, rx: float, ry: float,
		steps: int = 32) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(steps):
		var a := float(i) / float(steps) * TAU
		pts.append(Vector2(cx + cos(a) * rx, cy + sin(a) * ry))
	return pts


static func make_rect(x: float, y: float, w: float, h: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(x,     y),
		Vector2(x + w, y),
		Vector2(x + w, y + h),
		Vector2(x,     y + h),
	])


static func make_circle(cx: float, cy: float, r: float,
		steps: int = 16) -> PackedVector2Array:
	return make_ellipse(cx, cy, r, r, steps)