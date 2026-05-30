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
signal leaderboard_received(players: Array)
signal matchmaker_error

# ── Registre local des rooms ──────────────────────────────────────────────────
var _local_rooms : Dictionary = {}

# ── WebSocket (best-effort) ───────────────────────────────────────────────────
var socket         := WebSocketPeer.new()
var connected      := false
# File des actions en attente d'envoi. Plusieurs appels successifs (ex. create
# puis update) ne s'écrasent plus : ils sont tous empilés et envoyés dans
# l'ordre dès que la connexion est ouverte.
var _pending_queue : Array[String] = []


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

# Empile une action et s'assure que la connexion est (ou va être) ouverte.
func _queue_action(payload: Dictionary) -> void:
	_pending_queue.append(JSON.stringify(payload))
	_connect_to_server()

func _connect_to_server() -> void:
	match socket.get_ready_state():
		WebSocketPeer.STATE_OPEN:
			_send_pending()
		WebSocketPeer.STATE_CONNECTING:
			# Connexion en cours : on ne fait rien, la file sera vidée à
			# l'ouverture (dans _process → STATE_OPEN).
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
	# Éviter de recréer une room qui existe déjà (double appel hôte)
	if _local_rooms.has(room_name):
		print("[Matchmaker] Room '%s' déjà enregistrée — création ignorée" % room_name)
		return

	_local_rooms[room_name] = {
		"name":        room_name,
		"ip":          ip,
		"port":        NetworkManager.PORT,
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
	room_created.emit(room_name)

	_queue_action({
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

func find_room(room_name: String) -> void:
	if _local_rooms.has(room_name):
		var room : Dictionary = _local_rooms[room_name]
		print("[Matchmaker] Room '%s' trouvée localement (ip=%s)" % [room_name, room["ip"]])
		room_found.emit(room["ip"])
		return
	_queue_action({"action": "find", "room": room_name})
	get_tree().create_timer(3.0).timeout.connect(func():
		if not _local_rooms.has(room_name):
			room_not_found.emit(), CONNECT_ONE_SHOT)

func get_room_list() -> void:
	var local_list : Array = _local_rooms.values()
	if not local_list.is_empty():
		print("[Matchmaker] %d room(s) locale(s)" % local_list.size())
		room_list_received.emit(local_list)
	_queue_action({"action": "list"})
	if local_list.is_empty():
		get_tree().create_timer(2.0).timeout.connect(func():
			if not connected:
				room_list_received.emit([]), CONNECT_ONE_SHOT)

func update_room(room_name: String, players: int, started: bool) -> void:
	if _local_rooms.has(room_name):
		_local_rooms[room_name]["players"] = players
		_local_rooms[room_name]["started"] = started
		_local_rooms[room_name]["full"]    = (players >= _local_rooms[room_name].get("max_players", 2))
	_queue_action({
		"action":  "update",
		"room":    room_name,
		"players": players,
		"started": started
	})

func delete_room(room_name: String) -> void:
	if not _local_rooms.has(room_name):
		print("[Matchmaker] delete_room : '%s' inconnue, ignorée" % room_name)
		return
	_local_rooms.erase(room_name)
	print("[Matchmaker] Room '%s' supprimée localement" % room_name)
	_queue_action({"action": "delete", "room": room_name})
	
# Indique si une room (dictionnaire renvoyé par le serveur ou le registre local)
# est pleine. Calcul local : on ne fait pas confiance au champ "full" du serveur.
func is_room_full(room: Dictionary) -> bool:
	return int(room.get("players", 0)) >= int(room.get("max_players", 2))

# =============================================================================
#  COMPTES
# =============================================================================

func register(username: String, password: String, pseudo: String) -> void:
	_queue_action({
		"action": "register", "username": username,
		"password": password, "pseudo": pseudo
	})

func login(username: String, password: String) -> void:
	_queue_action({
		"action": "login", "username": username, "password": password
	})

func verify_token(token: String) -> void:
	_queue_action({"action": "verify_token", "token": token})

func logout(token: String) -> void:
	_queue_action({"action": "logout", "token": token})

func update_stats(token: String, won: bool) -> void:
	_queue_action({"action": "update_stats", "token": token, "won": won})
	
func get_leaderboard() -> void:
	_queue_action({"action": "leaderboard"})

# =============================================================================
#  MESSAGES SERVEUR DISTANT
# =============================================================================

func _send_pending() -> void:
	# Vide TOUTE la file, pas seulement le premier élément.
	while not _pending_queue.is_empty():
		var action: String = _pending_queue.pop_front()
		socket.send_text(action)
		print("[Matchmaker] Envoyé : ", action)

func _on_message(msg: String) -> void:
	print("[Matchmaker] Reçu : ", msg)
	var data : Dictionary = JSON.parse_string(msg)
	if data == null:
		return
	match data.get("status", ""):
		"registered":
			register_success.emit(data.get("token",""), data.get("pseudo",""), data.get("username",""))
		"logged_in":
			login_success.emit(data.get("token",""), data.get("pseudo",""), data.get("username",""),
				data.get("wins",0), data.get("losses",0))
		"valid_token":
			token_valid.emit(data.get("pseudo",""), data.get("username",""),
				data.get("wins",0), data.get("losses",0))
		"invalid_token":
			token_invalid.emit()
		"error":
			auth_error.emit(data.get("message","Erreur inconnue"))
		"stats_updated":
			stats_updated.emit()
		"leaderboard":
			leaderboard_received.emit(data.get("players", []))
		"created":
			var rn : String = data.get("room", "")
			if not _local_rooms.has(rn):
				room_created.emit(rn)
		"found":
			var ip : String = data.get("ip", "")
			var rn : String = data.get("room", "")
			if rn != "" and not _local_rooms.has(rn):
				_local_rooms[rn] = {"ip": ip, "name": rn}
			room_found.emit(ip)
		"not_found":
			room_not_found.emit()
		"list":
			var remote_rooms : Array = data.get("rooms", [])
			var merged : Dictionary = {}
			for r in remote_rooms:
				merged[r.get("name", "")] = r
			# Les rooms locales priment sur les rooms distantes
			for rn in _local_rooms:
				merged[rn] = _local_rooms[rn]
			room_list_received.emit(merged.values())
		"deleted":
			# Confirmation serveur — rien à faire, déjà supprimé localement
			pass
