class_name Player

var id          : int    = 0
var player_name : String = ""
var color       : Color  = Color.WHITE
var is_ai       : bool   = false
var ai_level    : int    = 0

var gold         : int = 300
var total_earned : int = 0

var owned_camps    : Array = []
var units_produced : int   = 0
var units_lost     : int   = 0
var units_killed   : int   = 0
var camps_captured : int   = 0
var camps_lost     : int   = 0

func setup(new_id: int, new_name: String, new_color: Color, new_is_ai: bool = false, new_ai_level: int = 0) -> void:
	id          = new_id
	player_name = new_name
	color       = new_color
	is_ai       = new_is_ai
	ai_level    = new_ai_level
	gold        = 300

func add_gold(amount: int) -> void:
	gold         += amount
	total_earned += amount

func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	return true

func can_afford(amount: int) -> bool:
	return gold >= amount

func add_camp(camp) -> void:
	if not owned_camps.has(camp):
		owned_camps.append(camp)
		camps_captured += 1

func remove_camp(camp) -> void:
	if owned_camps.has(camp):
		owned_camps.erase(camp)
		camps_lost += 1

func get_camp_count() -> int:
	return owned_camps.size()

func get_income() -> int:
	var total : int = 0
	for camp in owned_camps:
		if camp is Dictionary:
			total += camp.get("income_value", 10)
		elif is_instance_valid(camp):
			total += camp.get_income()
	return total

func is_defeated() -> bool:
	return owned_camps.size() == 0

func on_unit_produced() -> void:
	units_produced += 1

func on_unit_lost() -> void:
	units_lost += 1

func on_unit_killed() -> void:
	units_killed += 1

func get_summary() -> Dictionary:
	return {
		"id"             : id,
		"name"           : player_name,
		"gold"           : gold,
		"total_earned"   : total_earned,
		"camps"          : get_camp_count(),
		"camps_captured" : camps_captured,
		"camps_lost"     : camps_lost,
		"units_produced" : units_produced,
		"units_killed"   : units_killed,
		"units_lost"     : units_lost,
	}

func get_display_string() -> String:
	return "[%s | %d gold | %d camps]" % [player_name, gold, get_camp_count()]