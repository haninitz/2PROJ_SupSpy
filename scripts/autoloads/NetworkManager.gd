extends Node

const RELAY_URL := "wss://sup-kon-quest-server.onrender.com"
const PORT      := 7777

signal connected_to_server
signal connection_failed
signal player_connected(peer_id: int)
signal player_disconnected(peer_id: int)
signal host_disconnected
signal connection_progress(message: String)

var _peer : WebSocketMultiplayerPeer = null
var _connected_room : String = ""
const CONNECT_TIMEOUT := 20.0
var _connecting      := false
var _connect_elapsed := 0.0

func create_server() -> void:
	GameConfig.is_host = true
	connection_progress.emit("Connexion au serveur de jeu…")
	_connect_to_relay()

func join_server(ip: String) -> void:
	join_server_with_port(ip, PORT)

func join_server_with_port(_ip: String, _port: int) -> void:
	GameConfig.is_host = false
	connection_progress.emit("Connexion à la mission…")
	_connect_to_relay()

func _connect_to_relay() -> void:
	var want_room := GameConfig.room_name
	if _peer != null and multiplayer.multiplayer_peer == null:
		_peer = null
		_connected_room = ""

	if _peer != null:
		var st := _peer.get_connection_status()
		if _connected_room != want_room:
			print("[NetworkManager] Room différente ('%s'→'%s'), reconnexion." \
				% [_connected_room, want_room])
			_teardown()
		elif st == MultiplayerPeer.CONNECTION_CONNECTED:
			print("[NetworkManager] Déjà connecté à '%s', ré-émission." % want_room)
			GameConfig.my_peer_id = multiplayer.get_unique_id()
			connected_to_server.emit()
			return
		else:
			print("[NetworkManager] Connexion à '%s' déjà en cours." % want_room)
			return

	var url := RELAY_URL + "/?room=" + want_room
	_peer = WebSocketMultiplayerPeer.new()
	var err := _peer.create_client(url)
	if err != OK:
		push_error("[NetworkManager] create_client WebSocket échoué (err=%d) vers %s" % [err, url])
		_peer = null
		connection_failed.emit()
		return
	multiplayer.multiplayer_peer = _peer
	_connected_room = want_room

	if not multiplayer.connected_to_server.is_connected(_on_connected_ok):
		multiplayer.connected_to_server.connect(_on_connected_ok, CONNECT_ONE_SHOT)
	if not multiplayer.connection_failed.is_connected(_on_connection_fail):
		multiplayer.connection_failed.connect(_on_connection_fail, CONNECT_ONE_SHOT)

	_connecting      = true
	_connect_elapsed = 0.0
	print("[NetworkManager] Connexion WebSocket vers %s…" % url)

func disconnect_from_server() -> void:
	_teardown()
	GameConfig.reset()
func reset_connection() -> void:
	_teardown()

func _teardown() -> void:
	_connecting      = false
	_connect_elapsed = 0.0
	_connected_room  = ""
	if _peer != null:
		multiplayer.multiplayer_peer = null
		_peer = null

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	_wake_servers()

func _wake_servers() -> void:
	for url in [
		"https://sup-kon-quest-server.onrender.com",
		"https://sup-kon-quest-matchmaker.onrender.com",
	]:
		var h := HTTPRequest.new()
		add_child(h)
		h.request_completed.connect(func(_r, _c, _hh, _b): h.queue_free())
		h.request(url)
	print("[NetworkManager] Réveil du relay et du Matchmaker Render…")

func _process(delta: float) -> void:
	if not _connecting:
		return
	_connect_elapsed += delta
	if _connect_elapsed >= CONNECT_TIMEOUT:
		push_error("[NetworkManager] Timeout : relay injoignable (%s)" % RELAY_URL)
		_teardown()
		connection_progress.emit("Le serveur ne répond pas. Réessaie dans un instant.")
		connection_failed.emit()

func _on_connected_ok() -> void:
	_connecting      = false
	_connect_elapsed = 0.0
	GameConfig.my_peer_id = multiplayer.get_unique_id()
	print("[NetworkManager] Connecté ! ID = %d (hôte=%s)" \
		% [GameConfig.my_peer_id, GameConfig.is_host])
	connection_progress.emit("Connecté !")
	connected_to_server.emit()

func _on_connection_fail() -> void:
	_connecting = false
	push_error("[NetworkManager] Connexion au relay WebSocket échouée")
	_teardown()
	connection_progress.emit("Connexion échouée. Réessaie.")
	connection_failed.emit()

func _on_peer_connected(id: int) -> void:
	print("[NetworkManager] Peer connecté : %d" % id)
	player_connected.emit(id)
	if GameConfig.is_host:
		RoomManager.start_client_timeout(id)

func _on_peer_disconnected(id: int) -> void:
	print("[NetworkManager] Peer déconnecté : %d" % id)
	player_disconnected.emit(id)
	if not GameConfig.is_host:
		print("[NetworkManager] L'hôte s'est déconnecté !")
		host_disconnected.emit()
		disconnect_from_server()
		get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
	else:
		var scene := get_tree().current_scene
		if scene.has_method("on_player_left"):
			scene.on_player_left(id)
		if RoomManager.player_room.has(id):
			RoomManager.remove_player(id)

@rpc("any_peer", "reliable")
func sync_initial_state(state: Dictionary) -> void:
	GameConfig.initial_state = state
	print("[NetworkManager] État initial reçu")

func send_initial_state(state: Dictionary) -> void:
	if not GameConfig.is_host:
		return
	sync_initial_state.rpc(state)
	print("[NetworkManager] État initial envoyé à tous les clients")

@rpc("any_peer", "unreliable_ordered")
func sync_unit_move(unit_id: int, target_pos: Vector2) -> void:
	var scene := get_tree().current_scene
	if scene.has_method("on_unit_move"):
		scene.on_unit_move(unit_id, target_pos)

@rpc("any_peer", "reliable")
func sync_unit_spawn(camp_id: int, unit_type: String) -> void:
	var scene := get_tree().current_scene
	if scene.has_method("on_unit_spawn"):
		scene.on_unit_spawn(camp_id, unit_type)

@rpc("any_peer", "reliable")
func sync_camp_captured(camp_id: int, new_owner: int) -> void:
	var scene := get_tree().current_scene
	if scene.has_method("on_camp_captured"):
		scene.on_camp_captured(camp_id, new_owner)

@rpc("any_peer", "reliable")
func sync_unit_death(unit_id: int) -> void:
	var scene := get_tree().current_scene
	if scene.has_method("on_unit_death"):
		scene.on_unit_death(unit_id)

@rpc("any_peer", "reliable")
func sync_attack(src_camp: int, tgt_camp: int) -> void:
	var scene := get_tree().current_scene
	if scene.has_method("on_attack"):
		scene.on_attack(src_camp, tgt_camp)

@rpc("any_peer", "reliable")
func sync_income(player_id: int, amount: int) -> void:
	if multiplayer.get_unique_id() == player_id:
		GameConfig.gold += amount
		var scene := get_tree().current_scene
		if scene.has_method("on_income_received"):
			scene.on_income_received(GameConfig.gold)

@rpc("any_peer", "reliable")
func sync_game_over(winner_id: int) -> void:
	var i_won := (winner_id == multiplayer.get_unique_id())
	Matchmaker.update_stats(GameConfig.token, i_won)
	var scene := get_tree().current_scene
	if scene.has_method("on_game_over"):
		scene.on_game_over(winner_id)
	print("[NetworkManager] Fin de partie — gagnant : %d" % winner_id)