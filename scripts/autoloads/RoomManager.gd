extends Node

signal player_list_updated(room_id: String, data: Array)
signal room_full(room_id: String)
signal host_left(room_id: String)
signal client_timeout(peer_id: int)

var rooms:       Dictionary = {}
var player_room: Dictionary = {}

# ── Helper : remplace multiplayer.is_server() ─────────────────────────────────
func _is_host() -> bool:
	return GameConfig.is_host

# ── Rejoindre une room ────────────────────────────────────────────────────────

@rpc("any_peer", "reliable")
func request_join_room(room_id: String, mode: String,
		format: String, diff: String, map: String, player_name: String) -> void:
	if not _is_host():
		return
	var sender: int = multiplayer.get_remote_sender_id()
	_register_player(sender, room_id, mode, format, diff, map, player_name)

func join_room_local(room_id: String, mode: String,
		format: String, diff: String, map: String, player_name: String) -> void:
	_register_player(GameConfig.my_peer_id, room_id, mode, format, diff, map, player_name)

func _register_player(sender: int, room_id: String, mode: String,
		format: String, diff: String, map: String, player_name: String) -> void:
	if not rooms.has(room_id):
		_create_room(room_id, mode, format, diff, map)
	var room:  Dictionary = rooms[room_id]
	var max_p: int        = _format_to_max(room.format)
	if room.players.size() >= max_p:
		if sender != GameConfig.my_peer_id:
			_notify_full.rpc_id(sender, room_id)
		return
	var join_order: int = room.players.size()
	var team: String    = "a" if join_order % 2 == 0 else "b"
	room.players[sender] = {
		"id": sender, "name": player_name, "team": team,
		"join_order": join_order, "ready": false
	}
	player_room[sender] = room_id
	clear_client_timeout(sender)
	print("[RoomManager] Joueur %d '%s' -> room '%s' (team %s, ordre %d)" \
		% [sender, player_name, room_id, team, join_order])
	if sender == GameConfig.my_peer_id:
		GameConfig.room_name = room_id; GameConfig.mode = mode
		GameConfig.format = format; GameConfig.diff = diff
		GameConfig.map = map; GameConfig.is_host = true
	else:
		_confirm_join.rpc_id(sender, room_id, team, join_order,
			room.mode, room.format, room.diff, room.map)
	_broadcast_list(room_id)

@rpc("any_peer", "reliable")
func set_player_ready(room_id: String, is_ready: bool) -> void:
	if not _is_host():
		return
	var sender: int = multiplayer.get_remote_sender_id()
	if rooms.has(room_id) and rooms[room_id].players.has(sender):
		rooms[room_id].players[sender]["ready"] = is_ready
	_broadcast_list(room_id)

func remove_player(peer_id: int) -> void:
	if not player_room.has(peer_id):
		return
	var rid: String = player_room[peer_id]
	if rooms.has(rid):
		rooms[rid].players.erase(peer_id)
		print("[RoomManager] Joueur %d retiré de '%s'" % [peer_id, rid])
		_broadcast_list(rid)
		if rooms[rid].players.is_empty():
			rooms.erase(rid)
			Matchmaker.delete_room(rid)
	player_room.erase(peer_id)

func _create_room(room_id: String, mode: String, format: String,
		diff: String, map: String) -> void:
	rooms[room_id] = {
		"id": room_id, "mode": mode, "format": format,
		"diff": diff, "map": map, "players": {}
	}
	print("[RoomManager] Room '%s' créée" % room_id)

func _start_game(room_id: String) -> void:
	if not rooms.has(room_id):
		return
	Matchmaker.update_room(room_id, rooms[room_id].players.size(), true)
	var room: Dictionary  = rooms[room_id]
	var players_array: Array = room.players.values()
	print("[RoomManager] Lancement room '%s'" % room_id)
	GameConfig.mode = room.mode; GameConfig.format = room.format
	GameConfig.diff = room.diff; GameConfig.map    = room.map
	GameConfig.players.clear()
	for p in players_array:
		GameConfig.players[p.id] = p
	for pid in room.players:
		if pid != GameConfig.my_peer_id:
			_do_start.rpc_id(pid, room.mode, room.format, room.diff, room.map, players_array)
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _broadcast_list(room_id: String) -> void:
	if not rooms.has(room_id):
		return
	var data: Array = rooms[room_id].players.values()
	data.sort_custom(func(a, b): return a.join_order < b.join_order)
	for pid in rooms[room_id].players:
		if pid == GameConfig.my_peer_id:
			GameConfig.players.clear()
			for p in data: GameConfig.players[p.id] = p
			player_list_updated.emit(room_id, data)
		else:
			_receive_list.rpc_id(pid, room_id, data)

@rpc("authority", "reliable")
func _confirm_join(room_id: String, team: String, join_order: int,
		mode: String, format: String, diff: String, map: String) -> void:
	GameConfig.room_name = room_id; GameConfig.mode = mode
	GameConfig.format = format; GameConfig.diff = diff
	GameConfig.map = map; GameConfig.is_host = false
	print("[RoomManager] Rejoint '%s' équipe %s (ordre %d)" % [room_id, team, join_order])

@rpc("authority", "reliable")
func _notify_full(room_id: String) -> void:
	room_full.emit(room_id)

@rpc("authority", "reliable")
func _receive_list(room_id: String, data: Array) -> void:
	GameConfig.players.clear()
	for p in data: GameConfig.players[p.id] = p
	player_list_updated.emit(room_id, data)

@rpc("authority", "reliable")
func _do_start(mode: String, format: String, diff: String,
		map: String, players_data: Array) -> void:
	GameConfig.mode = mode; GameConfig.format = format
	GameConfig.diff = diff; GameConfig.map    = map
	GameConfig.players.clear()
	for p in players_data: GameConfig.players[p.id] = p
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _format_to_max(format: String) -> int:
	match format:
		"1v1": return 2
		"2v2": return 4
		"3v3": return 6
	return 2

# ── Déconnexion hôte ──────────────────────────────────────────────────────────

func handle_host_left(room_id: String) -> void:
	if not rooms.has(room_id): return
	_notify_host_left.rpc(room_id)
	rooms.erase(room_id)
	Matchmaker.delete_room(room_id)

@rpc("authority", "reliable")
func _notify_host_left(room_id: String) -> void:
	host_left.emit(room_id)
	GameConfig.reset()
	get_tree().change_scene_to_file("res://scenes/online/OnlineMenu.tscn")

# ── Timeout client ────────────────────────────────────────────────────────────

const JOIN_TIMEOUT := 15.0
var _pending_clients: Dictionary = {}

func start_client_timeout(peer_id: int) -> void:
	_pending_clients[peer_id] = 0.0

func _process(delta: float) -> void:
	if multiplayer.multiplayer_peer == null:
		return
	if multiplayer.multiplayer_peer.get_connection_status() \
			!= MultiplayerPeer.CONNECTION_CONNECTED:
		return
	if not _is_host():
		return
	for peer_id in _pending_clients.keys():
		_pending_clients[peer_id] += delta
		if _pending_clients[peer_id] >= JOIN_TIMEOUT:
			_pending_clients.erase(peer_id)
			client_timeout.emit(peer_id)
			remove_player(peer_id)

func clear_client_timeout(peer_id: int) -> void:
	_pending_clients.erase(peer_id)

func all_players_ready(room_id: String) -> bool:
	if not rooms.has(room_id): return false
	for player in rooms[room_id].players.values():
		if not player.get("ready", false): return false
	return true

func get_player_count(room_id: String) -> int:
	return rooms[room_id].players.size() if rooms.has(room_id) else 0

func is_room_full(room_id: String) -> bool:
	if not rooms.has(room_id): return false
	return rooms[room_id].players.size() >= _format_to_max(rooms[room_id].format)
