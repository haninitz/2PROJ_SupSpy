class_name Soigneur
extends Unit

const HEAL_DURATION : float = 6.0
const HEAL_COOLDOWN : float = 18.0
const HEAL_RADIUS   : float = 100.0
const HEAL_AMOUNT   : float = 15.0

var _spell_active : bool  = false
var _spell_ready  : bool  = true
var _spell_timer  : float = 0.0

func _ready() -> void:
	unit_type    = UnitType.SOIGNEUR
	max_hp       = 80.0
	damage       = 8.0
	attack_range = 80.0
	speed        = 90.0
	hit_speed    = 1.2
	build_time   = 5.0
	price        = 90
	super._ready()

func _process(delta: float) -> void:
	if not is_alive:
		return
	if _spell_active:
		_spell_timer -= delta
		# Soigne les alliés proches chaque frame
		for unit in get_tree().get_nodes_in_group("units"):
			if unit is Unit and unit.owner_id == owner_id and unit != self:
				var dist : float = global_position.distance_to(unit.global_position)
				if dist <= HEAL_RADIUS:
					unit.hp = minf(unit.hp + HEAL_AMOUNT * delta, unit.max_hp)
					unit._update_hp_bar()
		if _spell_timer <= 0.0:
			_spell_active = false
			_spell_ready  = false
			_spell_timer  = HEAL_COOLDOWN
	elif not _spell_ready:
		_spell_timer -= delta
		if _spell_timer <= 0.0:
			_spell_ready = true

func activate_spell() -> void:
	if not _spell_ready or not is_alive:
		return
	_spell_active = true
	_spell_ready  = false
	_spell_timer  = HEAL_DURATION
