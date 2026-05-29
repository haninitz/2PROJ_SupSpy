class_name Tourelle
extends Node2D

# ─────────────────────────────────────────────────────────────────────────────
# Tourelle — défense automatique du camp
# Attaque les unités ennemies qui entrent dans sa portée
# S'arrête si le camp change de propriétaire
# ─────────────────────────────────────────────────────────────────────────────

@export var damage: float      = 10.0   # dégâts par tir
@export var attack_range: float = 150.0  # portée en pixels
@export var hit_speed: float   = 2.0    # secondes entre chaque tir

var current_target: Unit = null
var camp: Camp = null          # référence au camp parent

@onready var attack_timer: Timer = $AttackTimer
@onready var range_area: Area2D  = $RangeArea

# ─────────────────────────────────────────────────────────────────────────────
# INITIALISATION
# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	# Récupère le camp parent
	var _p = get_parent()
	camp = _p if _p is Camp else null

	attack_timer.wait_time = hit_speed
	attack_timer.one_shot  = false

	range_area.body_entered.connect(_on_range_entered)
	range_area.body_exited.connect(_on_range_exited)
	attack_timer.timeout.connect(_on_attack_timer)

	# Ajuste le rayon de la zone de portée
	var shape    = CircleShape2D.new()
	shape.radius = attack_range
	var col      = range_area.get_child(0) as CollisionShape2D
	if col:
		col.shape = shape

# ─────────────────────────────────────────────────────────────────────────────
# DÉTECTION DES ENNEMIS
# ─────────────────────────────────────────────────────────────────────────────
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
	# Cherche une autre cible dans la zone
	for b in range_area.get_overlapping_bodies():
		if _is_enemy(b):
			current_target = b as Unit
			attack_timer.start()
			break

# ─────────────────────────────────────────────────────────────────────────────
# ATTAQUE
# ─────────────────────────────────────────────────────────────────────────────
func _on_attack_timer() -> void:
	if current_target == null or not current_target.is_alive:
		current_target = null
		attack_timer.stop()
		return
	_fire(current_target)

func _fire(target: Unit) -> void:
	if camp == null:
		return
	# La tourelle n'attaque que si le camp a un propriétaire (pas neutre)
	# Les camps neutres attaquent aussi selon les règles du sujet
	target.take_damage(damage)
	print(camp.camp_name, " tourelle tire sur Joueur ", target.owner_id, " | dégâts: ", damage)

# ─────────────────────────────────────────────────────────────────────────────
# UTILITAIRES
# ─────────────────────────────────────────────────────────────────────────────

# Vérifie si un body est une unité ennemie
func _is_enemy(body: Node) -> bool:
	if not body is Unit:
		return false
	if camp == null:
		return false
	var unit = body as Unit
	if not unit.is_alive:
		return false
	# Si le camp est neutre → attaque tout le monde dans sa portée
	if camp.is_neutral():
		return true
	# Sinon → attaque uniquement les ennemis du propriétaire
	return unit.owner_id != camp.owner_id
