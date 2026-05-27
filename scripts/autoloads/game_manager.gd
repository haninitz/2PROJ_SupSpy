extends Node

signal camp_captured(camp, old_owner_id: int, new_owner_id: int)
signal player_defeated(player: Object)
signal game_over(winner: Object)
signal income_distributed(player: Object, amount: int)
signal region_captured(region_name: String, player: Object)

const PlayerScript = preload("res://scripts/Player.gd")

var player_count    := 2
var income_interval := 30.0
var region_bonus    := 200

var available_teams := [
	{ "name": "Neon Squad",    "color": Color(0.0,  1.0,  1.0)  },
	{ "name": "Shadow Squad",  "color": Color(0.08, 0.08, 0.15) },
	{ "name": "Crimson Squad", "color": Color(1.0,  0.0,  0.0)  },
	{ "name": "Cyber Squad",   "color": Color(0.0,  0.8,  0.27) },
	{ "name": "Phantom Squad", "color": Color(0.55, 0.0,  1.0)  },
	{ "name": "Eclipse Squad", "color": Color(0.0,  0.12, 0.36) },
	{ "name": "Nova Squad",    "color": Color(1.0,  0.55, 0.0)  },
	{ "name": "Ghost Squad",   "color": Color(0.94, 0.94, 0.94) },
]

var players      : Array      = []
var camps        : Array      = []
var regions      : Dictionary = {}
var game_started : bool       = false
var income_timer : float      = 0.0

const NEUTRAL_ID : int = 0

func _process(delta: float) -> void:
	if not game_started:
		return
	income_timer += delta
	if income_timer >= income_interval:
		income_timer = 0.0
		_distribute_income()

func start_game_with_camps(render_camps: Array) -> void:
	_create_players()
	camps = render_camps
	_assign_starting_camps()
	game_started = true
	print("[GameManager] Partie lancee - ", players.size(), " joueurs, ", camps.size(), " camps.")

func start_game() -> void:
	_create_players()
	game_started = true
	print("[GameManager] Partie lancee - ", players.size(), " joueurs.")

func _create_players() -> void:
	players.clear()
	player_count = mini(player_count, available_teams.size())
	for i in range(player_count):
		var team : Dictionary = available_teams[i]
		var p = PlayerScript.new()
		p.setup(i + 1, team["name"], team["color"])
		players.append(p)

func _assign_starting_camps() -> void:
	if camps.size() < players.size():
		push_error("[GameManager] Pas assez de camps.")
		return
	var shuffled : Array = camps.duplicate()
	shuffled.shuffle()
	var cpp : int = int(shuffled.size()) / int(players.size())
	for i in range(players.size()):
		for j in range(i * cpp, (i + 1) * cpp):
			_set_camp_owner(shuffled[j], players[i].id)
			players[i].add_camp(shuffled[j])
	for k in range(cpp * players.size(), shuffled.size()):
		_set_camp_owner(shuffled[k], NEUTRAL_ID)

func capture_camp(camp, new_owner_id: int) -> void:
	var old_id : int = _get_camp_owner(camp)
	var old_owner    = find_player_by_id(old_id)
	var new_owner    = find_player_by_id(new_owner_id)
	if old_owner:
		old_owner.remove_camp(camp)
	_set_camp_owner(camp, new_owner_id)
	if new_owner:
		new_owner.add_camp(camp)
	camp_captured.emit(camp, old_id, new_owner_id)
	if old_owner and old_owner.is_defeated():
		_on_player_defeated(old_owner)
	_check_region_bonus(new_owner_id)
	_check_game_over()

func _distribute_income() -> void:
	for player in players:
		if player.is_defeated():
			continue
		var amount : int = _calculate_income(player)
		player.add_gold(amount)
		income_distributed.emit(player, amount)

func _calculate_income(player) -> int:
	var total : int = 0
	for camp in camps:
		if _get_camp_owner(camp) == player.id:
			total += camp.get("income_value", 10) if camp is Dictionary else camp.get_income()
	for region_name in regions:
		if _player_owns_region(player, region_name):
			total += region_bonus
	return total

func register_region(region_name: String, region_camps: Array) -> void:
	regions[region_name] = region_camps

func _player_owns_region(player, region_name: String) -> bool:
	for camp in regions[region_name]:
		if _get_camp_owner(camp) != player.id:
			return false
	return true

func _check_region_bonus(player_id: int) -> void:
	var player = find_player_by_id(player_id)
	if not player:
		return
	for region_name in regions:
		if _player_owns_region(player, region_name):
			region_captured.emit(region_name, player)

func _on_player_defeated(player) -> void:
	player_defeated.emit(player)
	print("[GameManager] ", player.player_name, " elimine!")

func _check_game_over() -> void:
	var alive : Array = get_alive_players()
	if alive.size() == 1:
		game_started = false
		game_over.emit(alive[0])
		print("[GameManager] Victoire de ", alive[0].player_name)

func _get_camp_owner(camp) -> int:
	if camp is Dictionary:
		return camp.get("owner_id", NEUTRAL_ID)
	if is_instance_valid(camp):
		return camp.owner_id
	return NEUTRAL_ID

func _set_camp_owner(camp, new_id: int) -> void:
	if camp is Dictionary:
		camp["owner_id"] = new_id
	elif is_instance_valid(camp):
		camp.change_owner(new_id)

func find_player_by_id(player_id: int):
	if player_id == NEUTRAL_ID:
		return null
	for player in players:
		if player.id == player_id:
			return player
	return null

func get_alive_players() -> Array:
	return players.filter(func(p): return not p.is_defeated())

func get_player_camps(player_id: int) -> Array:
	return camps.filter(func(c): return _get_camp_owner(c) == player_id)

func get_team_color(player_id: int) -> Color:
	if player_id == NEUTRAL_ID:
		return Color(0.5, 0.5, 0.5)
	var player = find_player_by_id(player_id)
	return player.color if player else Color.WHITE