extends Node2D
class_name Camp

signal owner_changed(camp: Node, old_owner_id: int, new_owner_id: int)
signal unit_spawned(unit: Node, camp: Node)
signal production_started(unit_type: String, duration: float)
signal production_cancelled()
signal camp_empty(camp: Node, killer_owner_id: int, killer_unit: Node)

@export var camp_id   : int    = 0
@export var camp_name : String = "WOOHP Outpost"
@export var region_id : int    = 0

@export var max_hp       : int   = 100
@export var income_value : int   = 10

@export var is_port         : bool = false
@export var is_neutral_hard : bool = false

@export var turret_damage : int   = 8
@export var turret_range  : float = 90.0
@export var turret_speed  : float = 1.5
@export var capture_radius : float = 78.0

@export var team_color: Color = Color(0.55, 0.55, 0.55)

var current_hp : int  = 0
var owner_id   : int  = 0
var units: int = 0
var unit_type: String = "infantry"
var garrison_units: Array = []

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

var production_queue  : Array      = []
var _production_timer : float      = 0.0
var is_producing      : bool       = false
var unit_catalogue    : Dictionary = {}

@onready var sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
@onready var health_bar: ProgressBar = get_node_or_null("HealthBar") as ProgressBar
@onready var turret_area: Area2D = (
	get_node_or_null("TurretRange") if has_node("TurretRange")
	else get_node_or_null("Tourelle/RangeArea")
) as Area2D
@onready var owner_label: Label = get_node_or_null("OwnerLabel") as Label
@onready var production_bar: ProgressBar = get_node_or_null("ProductionBar") as ProgressBar
@onready var spawn_point: Marker2D = get_node_or_null("SpawnPoint") as Marker2D

const BASIC_LAND_UNITS := ["infantry", "range", "support", "healer"]
const ADVANCED_LAND_UNITS := ["heavy", "anti_armor", "mortar"]
const SEA_UNITS := ["spy_yacht", "woohp_cruiser", "shadow_vessel"]

func _ready() -> void:
	current_hp = max_hp
	add_to_group("camps")
	_setup_turret_area()
	_refresh_visuals()
	_update_health_bar()

func _process(delta: float) -> void:
	# En multijoueur, seul l'hôte simule tourelles et production.
	# Le client reçoit tout l'état depuis l'hôte (Main._apply_sync_state).
	if GameConfig.mode == "multi" and not GameConfig.is_host:
		return
	_process_turret(delta)
	_process_production(delta)

func _setup_turret_area() -> void:
	if turret_area == null:
		return
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
	else:
		var col = turret_area.get_child(0)
		if col is CollisionShape2D and col.shape is CircleShape2D:
			col.shape.radius = turret_range

func _process_turret(delta: float) -> void:
	if turret_area == null:
		return
	if _turret_target == null or not is_instance_valid(_turret_target) or not _is_enemy_unit(_turret_target):
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
		if not _is_enemy_unit(body):
			continue
		var dist : float = global_position.distance_to(body.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest      = body
	return nearest

func _is_enemy_unit(body: Node) -> bool:
	if body == null or not body.is_in_group("units"):
		return false
	if not (body is Unit):
		return false
	if not body.is_alive:
		return false

	if owner_id == 0:
		return body.owner_id > 0 and body.target_camp == self

	return body.owner_id > 0 and body.owner_id != owner_id

func _fire_at(target: Node) -> void:
	if not is_instance_valid(target) or not target.has_method("take_damage"):
		_turret_target = null
		return
	target.take_damage(float(turret_damage), owner_id, null)

func _on_enemy_entered_range(body: Node) -> void:
	if _is_enemy_unit(body) and _turret_target == null:
		_turret_target = body

func _on_enemy_exited_range(body: Node) -> void:
	if body == _turret_target:
		_turret_target = null

func change_owner(new_owner_id: int, new_color: Color = Color(-1, -1, -1)) -> void:
	owner_id = new_owner_id

	if new_color.r >= 0.0:
		team_color = new_color

	_refresh_visuals()

func is_neutral() -> bool:
	return owner_id == 0

func take_damage(damage: int, attacker_id: int) -> void:
	current_hp -= damage
	_update_health_bar()
	if current_hp <= 0:
		current_hp = 0
		camp_empty.emit(self, attacker_id, null)

func heal(amount: int) -> void:
	current_hp = mini(current_hp + amount, max_hp)
	_update_health_bar()

func get_income() -> int:
	if is_neutral():
		return 0
	return income_value

func register_unit(unit: Node, count_unit: bool = true) -> void:
	if unit == null or not is_instance_valid(unit):
		return
	var was_new := false
	if not garrison_units.has(unit):
		garrison_units.append(unit)
		was_new = true
	if unit is Unit:
		unit.home_camp = self
		unit.owner_id = owner_id
	if count_unit and was_new:
		units += 1
	_refresh_visuals()

func unregister_unit(unit: Node, neutralize_if_empty: bool = false) -> void:
	if garrison_units.has(unit):
		garrison_units.erase(unit)
		units = maxi(units - 1, 0)
	if unit is Unit and unit.home_camp == self:
		unit.home_camp = null
	_cleanup_garrison()
	if neutralize_if_empty and units <= 0 and owner_id != 0:
		var gm = get_node_or_null("/root/GameManager")
		if gm and gm.has_method("capture_camp"):
			gm.capture_camp(self, 0)
		else:
			change_owner(0)
	_refresh_visuals()

func on_garrison_unit_died(unit: Node, killer_owner_id: int, killer_unit: Node) -> void:
	if garrison_units.has(unit):
		garrison_units.erase(unit)
		units = maxi(units - 1, 0)
	_cleanup_garrison()
	if units <= 0:
		camp_empty.emit(self, killer_owner_id, killer_unit)
	_refresh_visuals()

func has_living_garrison() -> bool:
	_cleanup_garrison()
	return units > 0 and not garrison_units.is_empty()

func get_available_garrison() -> Array:
	_cleanup_garrison()
	return garrison_units.duplicate()

func _cleanup_garrison() -> void:
	var alive : Array = []
	for unit in garrison_units:
		if is_instance_valid(unit) and unit.is_alive:
			alive.append(unit)
	garrison_units = alive
	units = garrison_units.size()

func get_available_unit_types() -> Array:
	if is_port:
		return SEA_UNITS.duplicate()
	if is_neutral_hard and owner_id != 0:
		return ADVANCED_LAND_UNITS.duplicate()
	return BASIC_LAND_UNITS.duplicate()

func queue_unit(unit_type: String) -> bool:
	if not get_available_unit_types().has(unit_type):
		print("[Camp] ", unit_type, " indisponible à ", camp_name)
		return false
	if not unit_catalogue.has(unit_type):
		return false
	var data : Dictionary = unit_catalogue[unit_type]
	var gm = get_node_or_null("/root/GameManager")
	if gm == null:
		return false
	var player = gm.find_player_by_id(owner_id)
	if player == null or not player.spend_gold(data["cost"]):
		print("[Camp] Fonds insuffisants pour ", unit_type)
		return false
	production_queue.append({"unit_type" : unit_type, "build_time": data["build_time"]})
	if not is_producing:
		_start_next_production()
	return true

func _start_next_production() -> void:
	if production_queue.is_empty():
		is_producing = false
		if production_bar:
			production_bar.visible = false
		return
	is_producing = true
	_production_timer = 0.0
	var current : Dictionary = production_queue[0]
	if production_bar:
		production_bar.visible = true
		production_bar.max_value = current["build_time"]
	production_started.emit(current["unit_type"], current["build_time"])

func _process_production(delta: float) -> void:
	if not is_producing or production_queue.is_empty():
		return
	_production_timer += delta
	if production_bar:
		production_bar.value = _production_timer
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
	unit.setup(owner_id, self, entry["unit_type"])
	register_unit(unit, true)
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
	is_producing = false
	if production_bar:
		production_bar.visible = false
	production_cancelled.emit()

func _refresh_visuals() -> void:
	if sprite:
		sprite.modulate = team_color

	modulate = team_color

	if owner_label:
		owner_label.text = _get_owner_label()

func set_team_color(new_color: Color) -> void:
	team_color = new_color
	_refresh_visuals()

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
		health_bar.value = current_hp
