extends Node

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
				print("[Matchmaker] Connecte au serveur")
				_send_pending()
			while socket.get_available_packet_count() > 0:
				_on_message(socket.get_packet().get_string_from_utf8())
		WebSocketPeer.STATE_CLOSED:
			if connected:
				connected = false
				print("[Matchmaker] Deconnecte")

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
			print("[Matchmaker] Connexion au matchmaker...")

# ── COMPTES ───────────────────────────────────────────────────────────────────

func register(username: String, password: String, pseudo: String) -> void:
	pending_action = JSON.stringify({
		"action":   "register",
		"username": username,
		"password": password,
		"pseudo":   pseudo
	})
	_connect_to_server()

func login(username: String, password: String) -> void:
	pending_action = JSON.stringify({
		"action":   "login",
		"username": username,
		"password": password
	})
	_connect_to_server()

func verify_token(token: String) -> void:
	pending_action = JSON.stringify({
		"action": "verify_token",
		"token":  token
	})
	_connect_to_server()

func logout(token: String) -> void:
	pending_action = JSON.stringify({
		"action": "logout",
		"token":  token
	})
	_connect_to_server()

func update_stats(token: String, won: bool) -> void:
	pending_action = JSON.stringify({
		"action": "update_stats",
		"token":  token,
		"won":    won
	})
	_connect_to_server()

# ── ROOMS ─────────────────────────────────────────────────────────────────────

func create_room(room_name: String, ip: String, format: String,
		map: String, max_players: int) -> void:
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
	pending_action = JSON.stringify({
		"action": "find",
		"room":   room_name
	})
	_connect_to_server()

func get_room_list() -> void:
	pending_action = JSON.stringify({ "action": "list" })
	_connect_to_server()

func update_room(room_name: String, players: int, started: bool) -> void:
	pending_action = JSON.stringify({
		"action":  "update",
		"room":    room_name,
		"players": players,
		"started": started
	})
	_connect_to_server()

func delete_room(room_name: String) -> void:
	pending_action = JSON.stringify({
		"action": "delete",
		"room":   room_name
	})
	_connect_to_server()

func _send_pending() -> void:
	if pending_action.is_empty():
		return
	socket.send_text(pending_action)
	print("[Matchmaker] Envoye : ", pending_action)
	pending_action = ""

func _on_message(msg: String) -> void:
	print("[Matchmaker] Message recu : ", msg)
	var data: Dictionary = JSON.parse_string(msg)
	if data == null:
		return
	match data.get("status", ""):
		"registered":
			register_success.emit(
				data.get("token", ""),
				data.get("pseudo", ""),
				data.get("username", "")
			)
		"logged_in":
			login_success.emit(
				data.get("token", ""),
				data.get("pseudo", ""),
				data.get("username", ""),
				data.get("wins", 0),
				data.get("losses", 0)
			)
		"valid_token":
			token_valid.emit(
				data.get("pseudo", ""),
				data.get("username", ""),
				data.get("wins", 0),
				data.get("losses", 0)
			)
		"invalid_token":
			token_invalid.emit()
		"error":
			auth_error.emit(data.get("message", "Erreur inconnue"))
		"stats_updated":
			stats_updated.emit()
		"created":
			room_created.emit(data.get("room", ""))
		"found":
			room_found.emit(data.get("ip", ""))
		"not_found":
			room_not_found.emit()
		"list":
			room_list_received.emit(data.get("rooms", []))
