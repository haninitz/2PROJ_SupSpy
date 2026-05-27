extends Node
class_name AIController

# ─────────────────────────────────────────
#  BASE CLASS — all AI levels inherit this
# ─────────────────────────────────────────

var player         : Object = null
var think_interval : float  = 2.0
var _think_timer   : float  = 0.0

func _ready() -> void:
	add_to_group("ai_controllers")

func setup(p: Object) -> void:
	player = p

func _process(delta: float) -> void:
	if not _can_act():
		return
	_think_timer += delta
	if _think_timer >= think_interval:
		_think_timer = 0.0
		think()

func _can_act() -> bool:
	if player == null:
		return false
	if player.is_defeated():
		return false
	var gm = get_node_or_null("/root/GameManager")
	if not gm or not gm.game_started:
		return false
	return true

# Override in subclasses
func think() -> void:
	pass

# ─────────────────────────────────────────
#  UTILITAIRES — compatibles Dictionary ET Node
# ─────────────────────────────────────────

# Retourne l'owner_id d'un camp (Dictionary ou Node)
func _camp_owner(camp) -> int:
	if camp is Dictionary:
		return camp.get("owner_id", 0)
	if is_instance_valid(camp):
		return camp.owner_id
	return 0

# Retourne la position d'un camp (Dictionary ou Node)
func _camp_pos(camp) -> Vector2:
	if camp is Dictionary:
		return camp.get("pos", Vector2.ZERO)
	if is_instance_valid(camp):
		return camp.global_position
	return Vector2.ZERO

# Retourne si un camp est en cours de production
func _camp_is_producing(camp) -> bool:
	if camp is Dictionary:
		return false   # les render_camps ne produisent pas directement
	if is_instance_valid(camp):
		return camp.is_producing
	return false

# ─────────────────────────────────────────
#  CAMPS
# ─────────────────────────────────────────
func get_my_camps() -> Array:
	var gm = get_node_or_null("/root/GameManager")
	if not gm:
		return []
	# Cherche dans render_camps de Main si disponible
	var main = get_tree().current_scene
	if main and main.has_method("_camp_at"):
		return main.render_camps.filter(func(c): return _camp_owner(c) == player.id)
	# Fallback sur les vrais Camp nodes
	return gm.camps.filter(func(c): return _camp_owner(c) == player.id)

func get_enemy_camps() -> Array:
	var gm = get_node_or_null("/root/GameManager")
	if not gm:
		return []
	var main = get_tree().current_scene
	if main and main.has_method("_camp_at"):
		return main.render_camps.filter(func(c):
			return _camp_owner(c) != player.id and _camp_owner(c) != gm.NEUTRAL_ID
		)
	return gm.camps.filter(func(c):
		return c.owner_id != player.id and c.owner_id != gm.NEUTRAL_ID
	)

func get_neutral_camps() -> Array:
	var gm = get_node_or_null("/root/GameManager")
	if not gm:
		return []
	var main = get_tree().current_scene
	if main and main.has_method("_camp_at"):
		return main.render_camps.filter(func(c): return _camp_owner(c) == gm.NEUTRAL_ID)
	return gm.camps.filter(func(c): return c.owner_id == gm.NEUTRAL_ID)

func get_my_units() -> Array:
	return get_tree().get_nodes_in_group("units").filter(
		func(u): return u.owner_id == player.id and u.is_alive
	)

func get_nearest_camp(from_pos: Vector2, camp_list: Array):
	var nearest      = null
	var nearest_dist : float = INF
	for camp in camp_list:
		var pos  : Vector2 = _camp_pos(camp)
		var dist : float   = from_pos.distance_to(pos)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest      = camp
	return nearest

func produce_unit_at(camp, unit_type: String) -> void:
	# Les render_camps (Dictionary) ne peuvent pas produire directement
	# On trouve le vrai Camp node correspondant via la position
	if camp is Dictionary:
		var gm = get_node_or_null("/root/GameManager")
		if not gm:
			return
		for real_camp in gm.camps:
			if is_instance_valid(real_camp) and real_camp.owner_id == player.id:
				if not real_camp.is_producing:
					real_camp.queue_unit(unit_type)
					return
	elif is_instance_valid(camp) and not camp.is_producing:
		camp.queue_unit(unit_type)