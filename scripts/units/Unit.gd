class_name Unit
extends CharacterBody2D

# ─────────────────────────────────────────────────────────────────────────────
# SIGNAUX
# ─────────────────────────────────────────────────────────────────────────────
signal unit_died(unit)          # émis quand l'unité meurt → P1 écoute pour la capture
signal unit_damaged(unit, amount) # émis à chaque dégât → utile pour la barre de vie (P3)

# ─────────────────────────────────────────────────────────────────────────────
# ENUM — types d'unités (correspond au diagramme de classes)
# ─────────────────────────────────────────────────────────────────────────────
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

# ─────────────────────────────────────────────────────────────────────────────
# STATS — à surcharger dans chaque sous-classe
# ─────────────────────────────────────────────────────────────────────────────
@export var unit_type: UnitType = UnitType.FANTASSIN
@export var max_hp: float       = 100.0
@export var damage: float       = 15.0
@export var attack_range: float = 0.0     # 0 = corps à corps
@export var speed: float        = 120.0   # pixels par seconde
@export var hit_speed: float    = 1.0     # secondes entre chaque attaque
@export var build_time: float   = 3.0     # secondes pour produire cette unité
@export var price: int          = 50      # coût en or (compatible avec le système gold de Main.gd)

# ─────────────────────────────────────────────────────────────────────────────
# ÉTAT — géré en cours de jeu
# ─────────────────────────────────────────────────────────────────────────────
var hp: float = max_hp
var owner_id: int = -1       # -1 = neutre, 0 = Joueur 1, 1 = Joueur 2 (cohérent avec Main.gd)
var current_target: Unit = null
var is_alive: bool = true

# ─────────────────────────────────────────────────────────────────────────────
# MODIFICATEURS DE TYPE
# Clé : [attaquant, cible] → multiplicateur de dégâts
# ─────────────────────────────────────────────────────────────────────────────
const DAMAGE_MODIFIERS := {
	[UnitType.ANTI_BLINDAGE, UnitType.LOURD]:        3.0,  # AntiBlindage × 3 vs Lourd
	[UnitType.MORTIER,        UnitType.FANTASSIN]:   1.5,  # Mortier efficace vs infanterie groupée
	[UnitType.TIR_DISTANCE,   UnitType.FANTASSIN]:   1.2,  # Avantage portée vs corps à corps
	[UnitType.LOURD,          UnitType.TIR_DISTANCE]:1.5,  # Tank résiste bien aux tireurs
	[UnitType.FREGATE,        UnitType.TRANSPORT]:   2.0,  # Frégate détruit les transports
	[UnitType.DESTROYER,      UnitType.FREGATE]:     1.8,  # Destroyer domine en mer
}

# ─────────────────────────────────────────────────────────────────────────────
# NŒUDS GODOT — récupérés ou créés dans _ready()
# ─────────────────────────────────────────────────────────────────────────────
var nav_agent   : NavigationAgent2D = null
var attack_timer: Timer             = null
var range_area  : Area2D            = null

# Barre de vie flottante (créée par code)
var _hp_bar_bg  : ColorRect = null
var _hp_bar_fg  : ColorRect = null
var _hp_label   : Label     = null

const DAMAGE_NUMBER_SCENE := preload("res://scripts/ui/DamageNumber.gd")

const HP_BAR_W  : float = 36.0
const HP_BAR_H  : float = 5.0
const HP_BAR_Y  : float = -28.0  # au-dessus de l'unité

# ─────────────────────────────────────────────────────────────────────────────
# INITIALISATION
# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	hp = max_hp
	add_to_group("units")  # pour minimap et Soigneur

	# ── Récupère ou crée les nœuds requis (défensif : fonctionne même si la
	#    scène .tscn n'a pas encore tous les nœuds) ──────────────────────────
	nav_agent = get_node_or_null("NavigationAgent2D")
	if nav_agent == null:
		nav_agent = NavigationAgent2D.new()
		nav_agent.name = "NavigationAgent2D"
		add_child(nav_agent)

	attack_timer = get_node_or_null("AttackTimer")
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

	# Connecter les signaux de la zone de portée
	if not range_area.body_entered.is_connected(_on_range_entered):
		range_area.body_entered.connect(_on_range_entered)
	if not range_area.body_exited.is_connected(_on_range_exited):
		range_area.body_exited.connect(_on_range_exited)
	if not attack_timer.timeout.is_connected(_on_attack_timer):
		attack_timer.timeout.connect(_on_attack_timer)

	# Connecter le signal dégâts à la mise à jour de la barre + label flottant
	unit_damaged.connect(_on_unit_damaged)

	# Ajuster le rayon de la zone de portée selon attack_range
	var shape2 = CircleShape2D.new()
	shape2.radius = attack_range if attack_range > 0 else 40.0
	var collision = range_area.get_child(0) if range_area.get_child_count() > 0 else CollisionShape2D.new()
	if collision is CollisionShape2D:
		collision.shape = shape2

	# Créer la barre de vie flottante
	_build_hp_bar()


func _build_hp_bar() -> void:
	# Fond gris
	_hp_bar_bg          = ColorRect.new()
	_hp_bar_bg.color    = Color(0.15, 0.15, 0.15, 0.85)
	_hp_bar_bg.size     = Vector2(HP_BAR_W, HP_BAR_H)
	_hp_bar_bg.position = Vector2(-HP_BAR_W / 2.0, HP_BAR_Y)
	add_child(_hp_bar_bg)

	# Barre verte (vie restante)
	_hp_bar_fg          = ColorRect.new()
	_hp_bar_fg.color    = Color(0.20, 0.90, 0.35)
	_hp_bar_fg.size     = Vector2(HP_BAR_W, HP_BAR_H)
	_hp_bar_fg.position = Vector2(-HP_BAR_W / 2.0, HP_BAR_Y)
	add_child(_hp_bar_fg)


func _update_hp_bar() -> void:
	if _hp_bar_fg == null:
		return
	var ratio : float = clamp(get_hp_ratio(), 0.0, 1.0)
	_hp_bar_fg.size.x = HP_BAR_W * ratio
	# Couleur : vert → orange → rouge selon les PV
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
	# Légère variation horizontale pour éviter la superposition si plusieurs hits simultanés
	dn.position = Vector2(randf_range(-6.0, 6.0), HP_BAR_Y - 8.0)
	# Dégât critique = multiplicateur appliqué → montant > damage de base
	var is_critical : bool = amount > damage * 1.1
	add_child(dn)
	dn.setup(amount, is_critical)


# ───────────────────────────────────────────────────────────────────────────── — utilise NavigationAgent2D pour le pathfinding
# ─────────────────────────────────────────────────────────────────────────────
func move_to(target_pos: Vector2) -> void:
	if not is_alive:
		return
	nav_agent.target_position = target_pos

func _physics_process(_delta: float) -> void:
	if not is_alive:
		return
	if nav_agent.is_navigation_finished():
		return
	var next_pos: Vector2 = nav_agent.get_next_path_position()
	var direction: Vector2 = global_position.direction_to(next_pos)
	velocity = direction * speed
	move_and_slide()

# ─────────────────────────────────────────────────────────────────────────────
# COMBAT — détection automatique + attaque
# ─────────────────────────────────────────────────────────────────────────────
func _on_range_entered(body: Node) -> void:
	if body is Unit and body.owner_id != owner_id and body.is_alive:
		if current_target == null:
			current_target = body
			attack_timer.start()

func _on_range_exited(body: Node) -> void:
	if body == current_target:
		current_target = null
		attack_timer.stop()
		# Chercher une autre cible dans la zone
		for b in range_area.get_overlapping_bodies():
			if b is Unit and b.owner_id != owner_id and b.is_alive:
				current_target = b
				attack_timer.start()
				break

func _on_attack_timer() -> void:
	if current_target != null and current_target.is_alive:
		attack(current_target)
	else:
		current_target = null
		attack_timer.stop()

func attack(target: Unit) -> void:
	if not is_alive or target == null:
		return
	var final_damage := _calculate_damage(target)
	target.take_damage(final_damage, unit_type)

# ─────────────────────────────────────────────────────────────────────────────
# CALCUL DES DÉGÂTS avec modificateurs de type
# ─────────────────────────────────────────────────────────────────────────────
func _calculate_damage(target: Unit) -> float:
	var multiplier := 1.0
	var key := [unit_type, target.unit_type]
	if DAMAGE_MODIFIERS.has(key):
		multiplier = DAMAGE_MODIFIERS[key]
	return damage * multiplier

# ─────────────────────────────────────────────────────────────────────────────
# RECEVOIR DES DÉGÂTS
# ─────────────────────────────────────────────────────────────────────────────
func take_damage(amount: float, _attacker_type: UnitType = UnitType.FANTASSIN) -> void:
	if not is_alive:
		return
	hp -= amount
	emit_signal("unit_damaged", self, amount)
	if hp <= 0:
		hp = 0
		die()

# ─────────────────────────────────────────────────────────────────────────────
# MORT
# ─────────────────────────────────────────────────────────────────────────────
func die() -> void:
	if not is_alive:
		return
	is_alive = false
	attack_timer.stop()
	emit_signal("unit_died", self)  # P1 écoute ce signal pour gérer la capture du camp
	queue_free()

# ─────────────────────────────────────────────────────────────────────────────
# UTILITAIRES
# ─────────────────────────────────────────────────────────────────────────────

# Retourne les PV sous forme de ratio 0.0 → 1.0 (utile pour la barre de vie de P3)
func get_hp_ratio() -> float:
	return hp / max_hp

# Vérifie si cette unité appartient au même joueur qu'un camp (Dictionary de Main.gd)
func belongs_to_camp(camp: Dictionary) -> bool:
	return camp.has("owner") and camp["owner"] == owner_id

# Initialise l'unité depuis un camp Dictionary (compatible avec Main.gd de P1)
func setup(p_owner_id: int) -> void:
	owner_id = p_owner_id
	hp = max_hp
	is_alive = true
