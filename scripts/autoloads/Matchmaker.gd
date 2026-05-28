extends Node
# =============================================================================
#  Matchmaker.gd — SupSpy
#  Registre LOCAL des rooms en mémoire.
#  Tente aussi de synchroniser avec le serveur WebSocket distant (best-effort).
#  Si le serveur est hors ligne, tout fonctionne quand même en local/LAN.
# =============================================================================

const SERVER_URL := "wss://sup-kon-quest-matchmaker.onrender.com"

signal room_created(room_name: String)
signal room_found(ip: String)
signal room_not_found
signal room_list_received(rooms: Array)

signal register_success(token: String, pseudo: String, username: String)
signal login_success(token: String, pseudo: String, username: String, wins: int, losses: int)
signal token_valid(pseudo: String, username: String, wins: int, losses: int)
signal token_invalid
signal auth_error(message: String)
signal stats_updated
signal matchmaker_error

# ── Registre local des rooms ──────────────────────────────────────────────────
# Structure : { "room_name": { "name", "ip", "port", "format", "map", "mode",
#                              "diff", "players", "max_players", "started", "full" } }
var _local_rooms : Dictionary = {}

# ── WebSocket (best-effort) ───────────────────────────────────────────────────
var socket         := WebSocketPeer.new()
var connected      := false
var pending_action := ""


func _ready() -> void:
	set_process(true)


func _process(_delta: float) -> void:
	socket.poll()
	match socket.get_ready_state():
		WebSocketPeer.STATE_OPEN:
			if not connected:
				connected = true
				print("[Matchmaker] Connecté au serveur distant")
				_send_pending()
			while socket.get_available_packet_count() > 0:
				_on_message(socket.get_packet().get_string_from_utf8())
		WebSocketPeer.STATE_CLOSED:
			if connected:
				connected = false
				print("[Matchmaker] Déconnecté du serveur distant")


func _connect_to_server() -> void:
	match socket.get_ready_state():
		WebSocketPeer.STATE_OPEN:
			_send_pending()
		WebSocketPeer.STATE_CONNECTING:
			pass
		_:
			socket    = WebSocketPeer.new()
			connected = false
			socket.connect_to_url(SERVER_URL)


# =============================================================================
#  ROOMS — API publique
# =============================================================================

func create_room(room_name: String, ip: String, format: String,
		map: String, max_players: int) -> void:
	# 1. Enregistrer localement IMMÉDIATEMENT
	_local_rooms[room_name] = {
		"name":        room_name,
		"ip":          ip,
		"port":        NetworkManager.LOCAL_PORT,
		"format":      format,
		"map":         map,
		"mode":        GameConfig.mode,
		"diff":        GameConfig.diff,
		"players":     1,
		"max_players": max_players,
		"started":     false,
		"full":        false,
	}
	print("[Matchmaker] Room '%s' créée localement (ip=%s)" % [room_name, ip])
	# Émettre immédiatement — pas besoin d'attendre le serveur
	room_created.emit(room_name)
	# 2. Tenter de synchroniser avec le serveur distant (best-effort)
	pending_action = JSON.stringify({
		"action":      "create",
		"room":        room_name,
		"ip":          ip,
		"format":      format,
		"map":         map,
		"mode":        GameConfig.mode,
		"diff":        GameConfig.diff,
		"players":     1,
		"max_players": max_players
	})
	_connect_to_server()


func find_room(room_name: String) -> void:
	# 1. Chercher dans le registre local d'abord
	if _local_rooms.has(room_name):
		var room : Dictionary = _local_rooms[room_name]
		print("[Matchmaker] Room '%s' trouvée localement (ip=%s)" % [room_name, room["ip"]])
		room_found.emit(room["ip"])
		return
	# 2. Fallback sur le serveur distant
	pending_action = JSON.stringify({"action": "find", "room": room_name})
	_connect_to_server()
	# Si pas connecté dans 3s → not_found
	get_tree().create_timer(3.0).timeout.connect(func():
		if not _local_rooms.has(room_name):
			room_not_found.emit(), CONNECT_ONE_SHOT)


func get_room_list() -> void:
	# Toujours émettre la liste locale immédiatement
	var local_list : Array = _local_rooms.values()
	if not local_list.is_empty():
		print("[Matchmaker] %d room(s) locale(s)" % local_list.size())
		room_list_received.emit(local_list)
	# Tenter aussi de récupérer la liste distante
	pending_action = JSON.stringify({"action": "list"})
	_connect_to_server()
	# Si pas de réponse dans 2s et liste locale vide → émettre liste vide
	if local_list.is_empty():
		get_tree().create_timer(2.0).timeout.connect(func():
			if not connected:
				room_list_received.emit([]), CONNECT_ONE_SHOT)


func update_room(room_name: String, players: int, started: bool) -> void:
	if _local_rooms.has(room_name):
		_local_rooms[room_name]["players"] = players
		_local_rooms[room_name]["started"] = started
		_local_rooms[room_name]["full"]    = (players >= _local_rooms[room_name].get("max_players", 2))
	pending_action = JSON.stringify({
		"action":  "update",
		"room":    room_name,
		"players": players,
		"started": started
	})
	_connect_to_server()


func delete_room(room_name: String) -> void:
	_local_rooms.erase(room_name)
	print("[Matchmaker] Room '%s' supprimée localement" % room_name)
	pending_action = JSON.stringify({"action": "delete", "room": room_name})
	_connect_to_server()


# =============================================================================
#  COMPTES (inchangé — best-effort)
# =============================================================================

func register(username: String, password: String, pseudo: String) -> void:
	pending_action = JSON.stringify({
		"action": "register", "username": username,
		"password": password, "pseudo": pseudo
	})
	_connect_to_server()


func login(username: String, password: String) -> void:
	pending_action = JSON.stringify({
		"action": "login", "username": username, "password": password
	})
	_connect_to_server()


func verify_token(token: String) -> void:
	pending_action = JSON.stringify({"action": "verify_token", "token": token})
	_connect_to_server()


func logout(token: String) -> void:
	pending_action = JSON.stringify({"action": "logout", "token": token})
	_connect_to_server()


func update_stats(token: String, won: bool) -> void:
	pending_action = JSON.stringify({"action": "update_stats", "token": token, "won": won})
	_connect_to_server()


# =============================================================================
#  MESSAGES SERVEUR DISTANT
# =============================================================================

func _send_pending() -> void:
	if pending_action.is_empty():
		return
	socket.send_text(pending_action)
	print("[Matchmaker] Envoyé : ", pending_action)
	pending_action = ""


func _on_message(msg: String) -> void:
	print("[Matchmaker] Reçu : ", msg)
	var data : Dictionary = JSON.parse_string(msg)
	if data == null:
		return
	match data.get("status", ""):
		"registered":
			register_success.emit(data.get("token",""), data.get("pseudo",""), data.get("username",""))
		"logged_in":
			login_success.emit(data.get("token",""), data.get("pseudo",""), data.get("username",""), data.get("wins",0), data.get("losses",0))
		"valid_token":
			token_valid.emit(data.get("pseudo",""), data.get("username",""), data.get("wins",0), data.get("losses",0))
		"invalid_token":
			token_invalid.emit()
		"error":
			auth_error.emit(data.get("message","Erreur inconnue"))
		"stats_updated":
			stats_updated.emit()
		"created":
			# Serveur a confirmé — mettre à jour si pas déjà en local
			var rn : String = data.get("room", "")
			if not _local_rooms.has(rn):
				room_created.emit(rn)
		"found":
			var ip : String = data.get("ip", "")
			# Le serveur distant a trouvé → mettre à jour le registre local
			var rn : String = data.get("room", "")
			if rn != "" and not _local_rooms.has(rn):
				_local_rooms[rn] = {"ip": ip, "name": rn}
			room_found.emit(ip)
		"not_found":
			if not _local_rooms.has(pending_action):
				room_not_found.emit()
		"list":
			var remote_rooms : Array = data.get("rooms", [])
			# Fusionner avec les rooms locales
			var merged : Dictionary = {}
			for r in remote_rooms:
				merged[r.get("name", "")] = r
			for rn in _local_rooms:
				if not merged.has(rn):
					merged[rn] = _local_rooms[rn]
			room_list_received.emit(merged.values())