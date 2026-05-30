class_name Unit
extends CharacterBody2D

signal unit_died(unit: Unit, killer_owner_id: int, killer_unit: Node)
signal unit_damaged(unit: Unit, amount: float)

enum UnitType {
	FANTASSIN,
	TIR_DISTANCE,
	LOURD,
	ANTI_BLINDAGE,
	MORTIER,
	SOUTIEN,
	SOIGNEUR,
	TRANSPORT,
	FREGATE,
	DESTROYER
}

@export var unit_type: UnitType = UnitType.FANTASSIN
@export var max_hp: float       = 100.0
@export var damage: float       = 15.0
@export var attack_range: float = 0.0
@export var speed: float        = 120.0
@export var hit_speed: float    = 1.0
@export var build_time: float   = 3.0
@export var price: int          = 50

var hp: float = max_hp
var owner_id: int = 0
var unit_type_key: String = "infantry"
var home_camp: Node = null
var target_camp: Node = null
var target_offset: Vector2 = Vector2.ZERO
var current_target: Unit = null
var is_alive: bool = true
var is_selected: bool = false
var move_target: Vector2 = Vector2.ZERO
var has_move_target: bool = false

const DAMAGE_MODIFIERS := {
	[UnitType.ANTI_BLINDAGE, UnitType.LOURD]:         3.0,
	[UnitType.MORTIER,       UnitType.FANTASSIN]:    1.5,
	[UnitType.TIR_DISTANCE,  UnitType.FANTASSIN]:    1.2,
	[UnitType.LOURD,         UnitType.TIR_DISTANCE]: 1.5,
	[UnitType.FREGATE,       UnitType.TRANSPORT]:    2.0,
	[UnitType.DESTROYER,     UnitType.FREGATE]:      1.8,
}

var nav_agent   : NavigationAgent2D = null
var attack_timer: Timer             = null
var range_area  : Area2D            = null

var _hp_bar_bg  : ColorRect = null
var _hp_bar_fg  : ColorRect = null

const DAMAGE_NUMBER_SCENE := preload("res://scripts/ui/DamageNumber.gd")
const HP_BAR_W  : float = 36.0
const HP_BAR_H  : float = 5.0
const HP_BAR_Y  : float = -28.0

func _ready() -> void:
	hp = max_hp
	add_to_group("units")
	add_to_group("player_%d_units" % owner_id)

	nav_agent = get_node_or_null("NavigationAgent2D")
	if nav_agent == null:
		nav_agent = NavigationAgent2D.new()
		nav_agent.name = "NavigationAgent2D"
		add_child(nav_agent)

	attack_timer = get_node_or_null("AttackTimer")
	if attack_timer == null:
		attack_timer = get_node_or_null("AttckeTimer")
	if attack_timer == null:
		attack_timer = Timer.new()
		attack_timer.name = "AttackTimer"
		add_child(attack_timer)

	range_area = get_node_or_null("RangeArea")
	if range_area == null:
		range_area = Area2D.new()
		range_area.name = "RangeArea"
		var col := CollisionShape2D.new()
		var shape := CircleShape2D.new()
		shape.radius = attack_range if attack_range > 0 else 40.0
		col.shape = shape
		range_area.add_child(col)
		add_child(range_area)

	attack_timer.wait_time = hit_speed
	attack_timer.one_shot  = false

	if not range_area.body_entered.is_connected(_on_range_entered):
		range_area.body_entered.connect(_on_range_entered)
	if not range_area.body_exited.is_connected(_on_range_exited):
		range_area.body_exited.connect(_on_range_exited)
	if not attack_timer.timeout.is_connected(_on_attack_timer):
		attack_timer.timeout.connect(_on_attack_timer)
	if not unit_damaged.is_connected(_on_unit_damaged):
		unit_damaged.connect(_on_unit_damaged)

	var shape2 := CircleShape2D.new()
	shape2.radius = attack_range if attack_range > 0 else 40.0
	var collision = range_area.get_child(0) if range_area.get_child_count() > 0 else null
	if collision is CollisionShape2D:
		collision.shape = shape2

	var sprite := get_sprite()
	if sprite:
		sprite.visible = true
		sprite.z_index = 10
		if sprite.sprite_frames and sprite.sprite_frames.has_animation("idle"):
			sprite.play("idle")

	_build_hp_bar()
	queue_redraw()

func setup(p_owner_id: int, p_home_camp: Node = null, p_unit_type_key: String = "") -> void:
	owner_id = p_owner_id
	home_camp = p_home_camp
	unit_type_key = p_unit_type_key
	hp = max_hp
	is_alive = true
	add_to_group("units")	
	add_to_group("player_%d_units" % owner_id)

func move_to(target_pos: Vector2) -> void:
	if not is_alive:
		return
	target_camp = null
	move_target = target_pos
	has_move_target = true
	if nav_agent:
		nav_agent.target_position = target_pos

func move_to_camp(camp: Node, offset: Vector2 = Vector2.ZERO) -> void:
	if not is_alive or camp == null:
		return
	target_camp = camp
	target_offset = offset
	move_target = camp.global_position + offset
	has_move_target = true
	if nav_agent:
		nav_agent.target_position = move_target

func clear_target_camp() -> void:
	target_camp = null
	target_offset = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	if target_camp != null and is_instance_valid(target_camp):
		move_target = target_camp.global_position + target_offset
		has_move_target = true

	if not has_move_target:
		velocity = Vector2.ZERO
		_play_anim("idle")
		return

	var distance: float = global_position.distance_to(move_target)

	if distance <= 8.0:
		global_position = move_target
		velocity = Vector2.ZERO
		has_move_target = false
		_play_anim("idle")
		return

	var direction: Vector2 = global_position.direction_to(move_target)

	if abs(direction.x) > abs(direction.y):
		_play_anim("walk_right" if direction.x > 0 else "walk_left")
	else:
		_play_anim("walk_down" if direction.y > 0 else "walk_up")

	velocity = direction * speed
	move_and_slide()

func _on_range_entered(body: Node) -> void:
	if body == self:
		return
	if body is Unit and body.owner_id != owner_id and body.is_alive:
		if current_target == null:
			current_target = body
			attack_timer.start()

func _on_range_exited(body: Node) -> void:
	if body == current_target:
		current_target = null
		attack_timer.stop()
		_find_next_target_in_range()

func _find_next_target_in_range() -> void:
	if range_area == null:
		return
	for b in range_area.get_overlapping_bodies():
		if b is Unit and b.owner_id != owner_id and b.is_alive:
			current_target = b
			attack_timer.start()
			return

func _on_attack_timer() -> void:
	if current_target != null and is_instance_valid(current_target) and current_target.is_alive:
		attack(current_target)
	else:
		current_target = null
		attack_timer.stop()
		_find_next_target_in_range()

func attack(target: Unit) -> void:
	if not is_alive or target == null:
		return
	var final_damage := _calculate_damage(target)
	target.take_damage(final_damage, owner_id, self)

func _calculate_damage(target: Unit) -> float:
	var multiplier := 1.0
	var key := [unit_type, target.unit_type]
	if DAMAGE_MODIFIERS.has(key):
		multiplier = DAMAGE_MODIFIERS[key]
	return damage * multiplier

func take_damage(amount: float, attacker_owner_id: int = -1, attacker_unit: Node = null) -> void:
	if not is_alive:
		return
	hp -= amount
	emit_signal("unit_damaged", self, amount)
	if hp <= 0:
		hp = 0
		die(attacker_owner_id, attacker_unit)

func die(killer_owner_id: int = -1, killer_unit: Node = null) -> void:
	if not is_alive:
		return
	is_alive = false
	if attack_timer:
		attack_timer.stop()
	if home_camp != null and is_instance_valid(home_camp) and home_camp.has_method("on_garrison_unit_died"):
		home_camp.on_garrison_unit_died(self, killer_owner_id, killer_unit)
	emit_signal("unit_died", self, killer_owner_id, killer_unit)
	queue_free()

func select() -> void:
	is_selected = true
	queue_redraw()

func deselect() -> void:
	is_selected = false
	queue_redraw()

func can_be_controlled_by(player_id: int) -> bool:
	return owner_id == player_id and is_alive

func get_hp_ratio() -> float:
	return hp / max_hp if max_hp > 0 else 0.0

func belongs_to_camp(camp: Dictionary) -> bool:
	return camp.has("owner") and camp["owner"] == owner_id

func _build_hp_bar() -> void:
	_hp_bar_bg = ColorRect.new()
	_hp_bar_bg.color = Color(0.15, 0.15, 0.15, 0.85)
	_hp_bar_bg.size = Vector2(HP_BAR_W, HP_BAR_H)
	_hp_bar_bg.position = Vector2(-HP_BAR_W / 2.0, HP_BAR_Y)
	_hp_bar_bg.z_index = 20
	add_child(_hp_bar_bg)

	_hp_bar_fg = ColorRect.new()
	_hp_bar_fg.color = Color(0.20, 0.90, 0.35)
	_hp_bar_fg.size = Vector2(HP_BAR_W, HP_BAR_H)
	_hp_bar_fg.position = Vector2(-HP_BAR_W / 2.0, HP_BAR_Y)
	_hp_bar_fg.z_index = 21
	add_child(_hp_bar_fg)

func _update_hp_bar() -> void:
	if _hp_bar_fg == null:
		return
	var ratio : float = clamp(get_hp_ratio(), 0.0, 1.0)
	_hp_bar_fg.size.x = HP_BAR_W * ratio
	if ratio > 0.5:
		_hp_bar_fg.color = Color(0.20, 0.90, 0.35)
	elif ratio > 0.25:
		_hp_bar_fg.color = Color(1.00, 0.65, 0.10)
	else:
		_hp_bar_fg.color = Color(0.90, 0.15, 0.15)

func _on_unit_damaged(_unit: Unit, amount: float) -> void:
	_update_hp_bar()
	_spawn_damage_number(amount)

func _spawn_damage_number(amount: float) -> void:
	var dn : DamageNumber = DAMAGE_NUMBER_SCENE.new()
	dn.position = Vector2(randf_range(-6.0, 6.0), HP_BAR_Y - 8.0)
	var is_critical : bool = amount > damage * 1.1
	add_child(dn)
	dn.setup(amount, is_critical)

func _play_anim(anim_name: String) -> void:
	var sprite := get_sprite()
	if sprite == null:
		return
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(anim_name):
		if sprite.animation != anim_name:
			sprite.play(anim_name)

func get_sprite() -> AnimatedSprite2D:
	for child in get_children():
		if child is AnimatedSprite2D:
			return child
	return null

func _draw() -> void:
	if is_selected:
		draw_arc(Vector2.ZERO, 24.0, 0.0, TAU, 48, Color(0.1, 0.9, 1.0, 0.95), 3.0)
