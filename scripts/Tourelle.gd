class_name Tourelle
extends Node2D

@export var damage: float      = 10.0   
@export var attack_range: float = 150.0 
@export var hit_speed: float   = 2.0   
const DEBUG_TURRET := false   
var current_target: Unit = null
var camp: Camp = null      
@onready var attack_timer: Timer = $AttackTimer
@onready var range_area: Area2D  = $RangeArea

func _ready() -> void:
	var _p = get_parent()
	camp = _p if _p is Camp else null
	attack_timer.wait_time = hit_speed
	attack_timer.one_shot  = false
	range_area.body_entered.connect(_on_range_entered)
	range_area.body_exited.connect(_on_range_exited)
	attack_timer.timeout.connect(_on_attack_timer)

	var shape    = CircleShape2D.new()
	shape.radius = attack_range
	var col      = range_area.get_child(0) as CollisionShape2D
	if col:
		col.shape = shape

func _on_range_entered(body: Node) -> void:
	if not _is_enemy(body):
		return
	if current_target == null:
		current_target = body as Unit
		attack_timer.start()

func _on_range_exited(body: Node) -> void:
	if body != current_target:
		return
	current_target = null
	attack_timer.stop()
	for b in range_area.get_overlapping_bodies():
		if _is_enemy(b):
			current_target = b as Unit
			attack_timer.start()
			break

func _on_attack_timer() -> void:
	if current_target == null or not current_target.is_alive:
		current_target = null
		attack_timer.stop()
		return
	_fire(current_target)

func _fire(target: Unit) -> void:
	if GameConfig.mode == "multi" and not GameConfig.is_host:
		return
	if camp == null:
		return
	target.take_damage(damage)
	if DEBUG_TURRET:
		print(camp.camp_name, " tourelle tire sur Joueur ", target.owner_id, " | dégâts: ", damage)

func _is_enemy(body: Node) -> bool:
	if not body is Unit:
		return false
	if camp == null:
		return false
	var unit = body as Unit
	if not unit.is_alive:
		return false
	if camp.is_neutral():
		return true
	return unit.owner_id != camp.owner_id
