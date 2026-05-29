extends Node2D
class_name Camp

# ─────────────────────────────────────────
#  SIGNAUX
# ─────────────────────────────────────────
signal owner_changed(camp: Node, old_owner_id: int, new_owner_id: int)
signal unit_spawned(unit: Node, camp: Node)
signal production_started(unit_type: String, duration: float)
signal production_cancelled()

# ─────────────────────────────────────────
#  EXPORTS
# ─────────────────────────────────────────
@export var camp_id   : int    = 0
@export var camp_name : String = "WOOHP Outpost"
@export var region_id : int    = 0

@export var max_hp       : int   = 100
@export var income_value : int   = 10

@export var is_port         : bool = false
@export var is_neutral_hard : bool = false

@export var turret_damage : int   = 8
@export var turret_range  : float = 180.0
@export var turret_speed  : float = 1.5

# ─────────────────────────────────────────
#  ÉTAT
# ─────────────────────────────────────────
var current_hp : int  = 0
var owner_id   : int  = 0
var units: int = 0
var unit_type: String = "infantry"

var income: int:
	get:
		return income_value

var pos: Vector2:
	get:
		return global_position

var type: String:
	get:
		return "port" if is_port else "normal"

var queue: Array:
	get:
		return production_queue
	set(value):
		production_queue = value

var _turret_timer  : float = 0.0
var _turret_target : Node  = null

# ─────────────────────────────────────────
#  PRODUCTION
# ─────────────────────────────────────────
var production_queue  : Array      = []
var _production_timer : float      = 0.0
var is_producing      : bool       = false
var unit_catalogue    : Dictionary = {}

# ─────────────────────────────────────────
#  NOEUDS
# ─────────────────────────────────────────
@onready var sprite: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D
@onready var health_bar: ProgressBar = get_node_or_null("HealthBar") as ProgressBar
@onready var turret_area: Area2D = (
	get_node_or_null("TurretRange") if has_node("TurretRange")
	else get_node_or_null("Tourelle/RangeArea")
) as Area2D
@onready var owner_label: Label = get_node_or_null("OwnerLabel") as Label
@onready var production_bar: ProgressBar = get_node_or_null("ProductionBar") as ProgressBar
@onready var spawn_point: Marker2D = get_node_or_null("SpawnPoint") as Marker2D
# ─────────────────────────────────────────
#  INIT
# ─────────────────────────────────────────
func _ready() -> void:
	current_hp = max_hp
	add_to_group("camps")

	if is_port:
		camp_name = "Marina HQ"
	elif is_neutral_hard:
		camp_name = "VILE Stronghold"

	if turret_area:

		if not turret_area.body_entered.is_connected(_on_enemy_entered_range):
			turret_area.body_entered.connect(_on_enemy_entered_range)
		if not turret_area.body_exited.is_connected(_on_enemy_exited_range):
			turret_area.body_exited.connect(_on_enemy_exited_range)

		if turret_area.get_child_count() == 0:
			var shape := CircleShape2D.new()
			shape.radius = turret_range
			var col := CollisionShape2D.new()
			col.shape = shape
			turret_area.add_child(col)

	_refresh_visuals()
	_update_health_bar()

# ─────────────────────────────────────────
#  BOUCLE
# ─────────────────────────────────────────
func _process(delta: float) -> void:
	_process_turret(delta)
	_process_production(delta)

# ─────────────────────────────────────────
#  TURRET
# ─────────────────────────────────────────
func _process_turret(delta: float) -> void:
	if turret_area == null:
		return
	if _turret_target == null or not is_instance_valid(_turret_target):
		_turret_target = _find_nearest_enemy()
		if _turret_target == null:
			return

	_turret_timer += delta
	if _turret_timer >= turret_speed:
		_turret_timer = 0.0
		_fire_at(_turret_target)

func _find_nearest_enemy() -> Node:
	if turret_area == null:
		return null
	var nearest      : Node  = null
	var nearest_dist : float = INF
	for body in turret_area.get_overlapping_bodies():
		if not body.is_in_group("units"):
			continue
		var is_enemy : bool = (owner_id == 0) or (body.owner_id != owner_id)
		if not is_enemy:
			continue
		var dist : float = global_position.distance_to(body.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest      = body
	return nearest

func _fire_at(target: Node) -> void:
	if not is_instance_valid(target):
		_turret_target = null
		return
	target.take_damage(turret_damage, owner_id)

func _on_enemy_entered_range(body: Node) -> void:
	if body.is_in_group("units") and _turret_target == null:
		_turret_target = body

func _on_enemy_exited_range(body: Node) -> void:
	if body == _turret_target:
		_turret_target = null

# ─────────────────────────────────────────
#  PROPRIÉTAIRE
# ─────────────────────────────────────────
func change_owner(new_owner_id: int) -> void:
	var old_id : int = owner_id
	owner_id   = new_owner_id
	current_hp = max_hp

	_refresh_visuals()
	_update_health_bar()
	owner_changed.emit(self, old_id, new_owner_id)

	print("[Camp] ", camp_name, " sécurisée par le squad ", new_owner_id)

func is_neutral() -> bool:
	return owner_id == 0

# ─────────────────────────────────────────
#  COMBAT
# ─────────────────────────────────────────
func take_damage(damage: int, attacker_id: int) -> void:
	current_hp -= damage
	_update_health_bar()
	if current_hp <= 0:
		current_hp = 0
		change_owner(attacker_id)

func heal(amount: int) -> void:
	current_hp = mini(current_hp + amount, max_hp)
	_update_health_bar()

func get_income() -> int:
	if is_neutral():
		return 0
	return income_value

# ─────────────────────────────────────────
#  PRODUCTION
# ─────────────────────────────────────────
func queue_unit(unit_type: String) -> bool:
	if not unit_catalogue.has(unit_type):
		return false

	var is_ship : bool = unit_type in ["spy_yacht", "woohp_cruiser", "shadow_vessel"]
	if is_ship and not is_port:
		print("[Camp] ", camp_name, " n'est pas un port.")
		return false
	if not is_ship and is_port:
		print("[Camp] Les ports ne produisent que des bateaux.")
		return false

	var data : Dictionary = unit_catalogue[unit_type]
	var gm = get_node_or_null("/root/GameManager")
	if gm == null:
		return false
	var player = gm.find_player_by_id(owner_id)
	if player == null or not player.spend_gold(data["cost"]):
		print("[Camp] Fonds insuffisants pour ", unit_type)
		return false

	production_queue.append({
		"unit_type" : unit_type,
		"build_time": data["build_time"],
	})

	if not is_producing:
		_start_next_production()

	return true

func _start_next_production() -> void:
	if production_queue.is_empty():
		is_producing           = false
		production_bar.visible = false
		return

	is_producing             = true
	_production_timer        = 0.0
	var current : Dictionary = production_queue[0]
	production_bar.visible   = true
	production_bar.max_value = current["build_time"]
	production_started.emit(current["unit_type"], current["build_time"])

func _process_production(delta: float) -> void:
	if not is_producing or production_queue.is_empty():
		return

	_production_timer    += delta
	production_bar.value  = _production_timer

	if _production_timer >= production_queue[0]["build_time"]:
		_finish_production(production_queue[0])
		production_queue.pop_front()
		_production_timer = 0.0
		_start_next_production()

func _finish_production(entry: Dictionary) -> void:
	if not unit_catalogue.has(entry["unit_type"]):
		return
	var data : Dictionary = unit_catalogue[entry["unit_type"]]
	if data["scene"] == null:
		print("[Camp] Scène null pour ", entry["unit_type"], " — ignoré")
		return
	var unit = data["scene"].instantiate()
	get_tree().current_scene.add_child(unit)
	unit.global_position = spawn_point.global_position if spawn_point else global_position
	unit.setup(owner_id)
	unit_spawned.emit(unit, self)
	
func cancel_production() -> void:
	if production_queue.is_empty():
		return
	var current : Dictionary = production_queue[0]
	var data    : Dictionary = unit_catalogue.get(current["unit_type"], {})
	var gm = get_node_or_null("/root/GameManager")
	if gm and data.has("cost"):
		var player = gm.find_player_by_id(owner_id)
		if player:
			player.add_gold(data["cost"])
	production_queue.clear()
	is_producing           = false
	production_bar.visible = false
	production_cancelled.emit()

# ─────────────────────────────────────────
#  VISUELS
# ─────────────────────────────────────────
func _refresh_visuals() -> void:
	var color := Color(0.5, 0.5, 0.5)
	if is_inside_tree():
		var gm = get_node_or_null("/root/GameManager")
		if gm:
			color = gm.get_team_color(owner_id)
	if sprite:
		sprite.modulate = color
	if owner_label:
		owner_label.text = _get_owner_label()

func _get_owner_label() -> String:
	if owner_id == 0:
		return "Neutre"
	if not is_inside_tree():
		return str(owner_id)
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		var player = gm.find_player_by_id(owner_id)
		if player:
			return player.player_name.split(" ")[0]
	return str(owner_id)

func _update_health_bar() -> void:
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value     = current_hp
