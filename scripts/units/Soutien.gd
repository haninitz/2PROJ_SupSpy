class_name Soutien
extends Unit

const BOOST_DURATION  : float = 8.0
const BOOST_COOLDOWN  : float = 20.0
const BOOST_RADIUS    : float = 120.0
const BOOST_MULT      : float = 1.5

var _spell_active   : bool  = false
var _spell_ready    : bool  = true
var _spell_timer    : float = 0.0

func _ready() -> void:
	unit_type    = UnitType.SOUTIEN
	max_hp       = 85.0
	damage       = 10.0
	attack_range = 80.0
	speed        = 100.0
	hit_speed    = 1.2
	build_time   = 5.0
	price        = 90
	super._ready()

func _process(delta: float) -> void:
	if not is_alive:
		return
	if _spell_active or not _spell_ready:
		_spell_timer -= delta
		if _spell_timer <= 0.0:
			if _spell_active:
				_deactivate_boost()
			else:
				_spell_ready = true

func activate_spell() -> void:
	if not _spell_ready or not is_alive:
		return
	_spell_active = true
	_spell_ready  = false
	_spell_timer  = BOOST_DURATION
	# Booste toutes les unités alliées proches
	for unit in get_tree().get_nodes_in_group("units"):
		if unit is Unit and unit.owner_id == owner_id and unit != self:
			var dist : float = global_position.distance_to(unit.global_position)
			if dist <= BOOST_RADIUS:
				unit.damage *= BOOST_MULT
				unit.speed  *= BOOST_MULT

func _deactivate_boost() -> void:
	_spell_active = false
	_spell_timer  = BOOST_COOLDOWN
	# Retire le boost
	for unit in get_tree().get_nodes_in_group("units"):
		if unit is Unit and unit.owner_id == owner_id and unit != self:
			var dist : float = global_position.distance_to(unit.global_position)
			if dist <= BOOST_RADIUS:
				unit.damage /= BOOST_MULT
				unit.speed  /= BOOST_MULT
