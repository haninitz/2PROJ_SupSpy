extends Node

signal player_list_updated(room_id: String, data: Array)
signal room_full(room_id: String)

var rooms:       Dictionary = {}
var player_room: Dictionary = {}

@rpc("any_peer", "reliable")
func request_join_room(room_id: String, mode: String,
		format: String, diff: String, map: String, player_name: String) -> void:
	if not multiplayer.is_server():
		return
	var sender: int = multiplayer.get_remote_sender_id()
	_register_player(sender, room_id, mode, format, diff, map, player_name)

func join_room_local(room_id: String, mode: String,
		format: String, diff: String, map: String, player_name: String) -> void:
	_register_player(1, room_id, mode, format, diff, map, player_name)

func _register_player(sender: int, room_id: String, mode: String,
		format: String, diff: String, map: String, player_name: String) -> void:

	# Si room_id vide ou inconnue, rejoindre la première room disponible
	var rid_final : String = room_id
	if rid_final == "" or not rooms.has(rid_final):
		for rid in rooms:
			var r = rooms[rid]
			if not r.get("started", false) and r.players.size() < _format_to_max(r.format):
				rid_final = rid
				break

	if not rooms.has(rid_final):
		_create_room(rid_final, mode, format, diff, map)

	var room:  Dictionary = rooms[rid_final]
	var max_p: int        = _format_to_max(room.format)

	if room.players.size() >= max_p:
		if sender != 1:
			_notify_full.rpc_id(sender, rid_final)
		return

	var join_order: int = room.players.size()
	var team: String    = "a" if join_order % 2 == 0 else "b"

	room.players[sender] = {
		"id":         sender,
		"name":       player_name,
		"team":       team,
		"join_order": join_order,
		"ready":      false
	}
	player_room[sender] = rid_final

	print("[RoomManager] Joueur %d '%s' → room '%s' (team %s, ordre %d)" \
		% [sender, player_name, rid_final, team, join_order])

	if sender == 1:
		GameConfig.room_name = rid_final
		GameConfig.mode      = mode
		GameConfig.format    = format
		GameConfig.diff      = diff
		GameConfig.map       = map
		GameConfig.is_host   = true
	else:
		_confirm_join.rpc_id(sender,
			rid_final, team, join_order,
			room.mode, room.format, room.diff, room.map
		)

	_broadcast_list(rid_final)

	# ─ SUPPRIMÉ : plus de lancement automatique quand la room est pleine ─
	# C'est l'hôte qui lance manuellement depuis SalleAttente via _start_game()

@rpc("any_peer", "reliable")
func set_player_ready(room_id: String, is_ready: bool) -> void:
	if not multiplayer.is_server():
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
		print("[RoomManager] Joueur %d retire de '%s'" % [peer_id, rid])
		_broadcast_list(rid)
		if rooms[rid].players.is_empty():
			rooms.erase(rid)
			# Supprimer du matchmaker
			Matchmaker.delete_room(rid)
			print("[RoomManager] Room '%s' detruite et supprimee du matchmaker" % rid)
	player_room.erase(peer_id)

func _create_room(room_id: String, mode: String, format: String,
		diff: String, map: String) -> void:
	rooms[room_id] = {
		"id":      room_id,
		"mode":    mode,
		"format":  format,
		"diff":    diff,
		"map":     map,
		"players": {}
	}
	print("[RoomManager] Room '%s' créée" % room_id)

func _start_game(room_id: String) -> void:
	if not rooms.has(room_id):
		return

	Matchmaker.update_room(room_id, rooms[room_id].players.size(), true)
	var room: Dictionary = rooms[room_id]
	print("[RoomManager]  Lancement room '%s'" % room_id)

	var players_array: Array = room.players.values()

	# 1. Preparer le GameConfig de l hote
	GameConfig.mode   = room.mode
	GameConfig.format = room.format
	GameConfig.diff   = room.diff
	GameConfig.map    = room.map
	GameConfig.players.clear()
	for p in players_array:
		GameConfig.players[p.id] = p

	# 2. Envoyer les RPC a TOUS les clients d abord
	for pid in room.players:
		if pid != 1:
			_do_start.rpc_id(pid,
				room.mode, room.format, room.diff,
				room.map, players_array
			)

	# 3. Attendre 2 frames pour que les paquets soient envoyes,
	#    puis l hote change de scene
	await get_tree().process_frame
	await get_tree().process_frame
	SceneLoader.goto("res://scenes/Main.tscn")

func _broadcast_list(room_id: String) -> void:
	if not rooms.has(room_id):
		return
	var data: Array = rooms[room_id].players.values()
	data.sort_custom(func(a, b): return a.join_order < b.join_order)

	for pid in rooms[room_id].players:
		if pid == 1:
			GameConfig.players.clear()
			for p in data:
				GameConfig.players[p.id] = p
			player_list_updated.emit(room_id, data)
		else:
			_receive_list.rpc_id(pid, room_id, data)

@rpc("authority", "reliable")
func _confirm_join(room_id: String, team: String, join_order: int,
		mode: String, format: String, diff: String, map: String) -> void:
	GameConfig.room_name = room_id
	GameConfig.mode      = mode
	GameConfig.format    = format
	GameConfig.diff      = diff
	GameConfig.map       = map
	GameConfig.is_host   = false
	print("[RoomManager]  Rejoint '%s' équipe %s (ordre %d) map %s" \
		% [room_id, team, join_order, map])

@rpc("authority", "reliable")
func _notify_full(room_id: String) -> void:
	print("[RoomManager]  Room '%s' pleine" % room_id)
	room_full.emit(room_id)

@rpc("authority", "reliable")
func _receive_list(room_id: String, data: Array) -> void:
	GameConfig.players.clear()
	for p in data:
		GameConfig.players[p.id] = p
	player_list_updated.emit(room_id, data)

@rpc("authority", "reliable")
func _do_start(mode: String, format: String, diff: String,
		map: String, players_data: Array) -> void:
	GameConfig.mode   = mode
	GameConfig.format = format
	GameConfig.diff   = diff
	GameConfig.map    = map
	GameConfig.players.clear()
	for p in players_data:
		GameConfig.players[p.id] = p
	SceneLoader.goto("res://scenes/Main.tscn")

func _format_to_max(format: String) -> int:
	match format:
		"1v1": return 2
		"2v2": return 4
		"3v3": return 6
	return 2