extends Node2D
class_name SelectionManager

# ─────────────────────────────────────────────────────────────────────────────
# SelectionManager — gère la sélection des unités à la souris
# - Clic gauche sur une unité → la sélectionner
# - Clic gauche + drag → rectangle de sélection (groupe)
# - Clic droit → déplacer les unités sélectionnées
# ─────────────────────────────────────────────────────────────────────────────

var selected_units: Array[Unit] = []   # unités actuellement sélectionnées
var current_player_id: int = 0         # id du joueur qui joue (0 = J1, 1 = J2)

# Variables pour le rectangle de sélection
var is_dragging: bool = false
var drag_start: Vector2 = Vector2.ZERO
var drag_end: Vector2 = Vector2.ZERO

# ─────────────────────────────────────────────────────────────────────────────
# ENTRÉES SOURIS
# ─────────────────────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	# ── Clic gauche pressé ──────────────────────────────────────────────────
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				drag_start = get_global_mouse_position()
				is_dragging = false

			else:
				# Relâchement clic gauche
				if is_dragging:
					# Fin du drag → sélectionner tout ce qui est dans le rectangle
					_select_units_in_rect()
				else:
					# Simple clic → sélectionner l'unité sous la souris
					_select_single_unit(get_global_mouse_position())
				is_dragging = false
				queue_redraw()

		# ── Clic droit → déplacer les unités sélectionnées ─────────────────
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_move_selected_units(get_global_mouse_position())

	# ── Mouvement souris → détecter le drag ────────────────────────────────
	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			drag_end = get_global_mouse_position()
			var dist = drag_start.distance_to(drag_end)
			if dist > 10.0:   # seuil pour éviter les micro-drags
				is_dragging = true
				queue_redraw()  # redessine le rectangle

# ─────────────────────────────────────────────────────────────────────────────
# SÉLECTION — un seul clic
# ─────────────────────────────────────────────────────────────────────────────
func _select_single_unit(pos: Vector2) -> void:
	var clicked_unit = _get_unit_at(pos)

	# Désélectionne tout d'abord
	_deselect_all()

	if clicked_unit != null and clicked_unit.owner_id == current_player_id:
		selected_units.append(clicked_unit)
		_highlight_unit(clicked_unit, true)

# ─────────────────────────────────────────────────────────────────────────────
# SÉLECTION — rectangle de sélection (drag)
# ─────────────────────────────────────────────────────────────────────────────
func _select_units_in_rect() -> void:
	_deselect_all()

	var rect = Rect2(drag_start, drag_end - drag_start).abs()

	var all_units = get_tree().get_nodes_in_group("units")
	for unit in all_units:
		if unit is Unit and unit.owner_id == current_player_id and unit.is_alive:
			if rect.has_point(unit.global_position):
				selected_units.append(unit)
				_highlight_unit(unit, true)

# ─────────────────────────────────────────────────────────────────────────────
# DÉPLACEMENT — clic droit
# ─────────────────────────────────────────────────────────────────────────────
func _move_selected_units(target_pos: Vector2) -> void:
	if selected_units.is_empty():
		return

	# Si plusieurs unités sélectionnées → les déplacer en formation
	var count = selected_units.size()
	for i in range(count):
		var unit = selected_units[i]
		if is_instance_valid(unit) and unit.is_alive:
			# Décale légèrement chaque unité pour éviter qu'elles se superposent
			var offset = Vector2(
				(i % 3 - 1) * 40.0,
				(i / 3) * 40.0
			)
			unit.move_to(target_pos + offset)

# ─────────────────────────────────────────────────────────────────────────────
# DÉSÉLECTION
# ─────────────────────────────────────────────────────────────────────────────
func _deselect_all() -> void:
	for unit in selected_units:
		if is_instance_valid(unit):
			_highlight_unit(unit, false)
	selected_units.clear()

# ─────────────────────────────────────────────────────────────────────────────
# UTILITAIRES
# ─────────────────────────────────────────────────────────────────────────────

# Trouve l'unité sous la position cliquée
func _get_unit_at(pos: Vector2) -> Unit:
	var all_units = get_tree().get_nodes_in_group("units")
	for unit in all_units:
		if unit is Unit and unit.is_alive:
			if unit.global_position.distance_to(pos) <= 30.0:
				return unit
	return null

# Surligne ou désurligne une unité (modulate = teinte de couleur)
func _highlight_unit(unit: Unit, selected: bool) -> void:
	if selected:
		unit.modulate = Color(1.5, 1.5, 0.5)  # teinte jaune = sélectionné
	else:
		unit.modulate = Color(1.0, 1.0, 1.0)  # couleur normale

# ─────────────────────────────────────────────────────────────────────────────
# DESSIN DU RECTANGLE DE SÉLECTION
# ─────────────────────────────────────────────────────────────────────────────
func _draw() -> void:
	if not is_dragging:
		return
	var rect = Rect2(drag_start, drag_end - drag_start).abs()
	# Fond semi-transparent
	draw_rect(rect, Color(0.2, 0.8, 0.2, 0.15), true)
	# Bordure verte
	draw_rect(rect, Color(0.2, 0.8, 0.2, 0.8), false, 1.5)
