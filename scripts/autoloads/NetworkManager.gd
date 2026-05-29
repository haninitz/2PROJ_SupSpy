extends Node

# ── Config ────────────────────────────────────────────────────────────────────
const SERVER_URL := "wss://sup-kon-quest-server.onrender.com"
const MAX_PEERS   := 32
# Gardé pour compatibilité avec les scripts qui lisent NetworkManager.PORT
const PORT        := 7777

# ── Signaux (identiques à avant — aucun script à changer) ─────────────────────
signal connected_to_server
signal connection_failed
signal player_connected(peer_id: int)
signal player_disconnected(peer_id: int)
signal host_disconnected

# ── État interne ──────────────────────────────────────────────────────────────
var _ws     : WebSocketMultiplayerPeer = null
var _room_id_pending : String = ""   # room à rejoindre après connexion

# ── API publique (même signature qu'avant) ────────────────────────────────────

func create_server() -> void:
	# Avec le relay Render, "créer un serveur" = se connecter au relay
	# et déclarer sa room. GameConfig.is_host est déjà positionné par l'appelant.
	if _ws != null:
		print("[NetworkManager] Déjà connecté, création ignorée.")
		return
	GameConfig.is_host    = true
	GameConfig.my_peer_id = 1          # l'hôte se considère toujours peer 1
	_connect_to_relay()

func join_server(ip: String) -> void:
	# ip ignoré — on passe par le relay Render
	join_server_with_port(ip, PORT)

func join_server_with_port(_ip: String, _port: int) -> void:
	# Paramètres ignorés, gardés pour compatibilité des appelants
	GameConfig.is_host = false
	_connect_to_relay()

func disconnect_from_server() -> void:
	if _ws != null:
		multiplayer.multiplayer_peer = null
		_ws = null
	GameConfig.reset()

# ── Connexion au relay ────────────────────────────────────────────────────────

func _connect_to_relay() -> void:
	_ws = WebSocketMultiplayerPeer.new()
	var err := _ws.create_client(SERVER_URL)
	if err != OK:
		push_error("[NetworkManager] WebSocket connexion échouée (err=%d)" % err)
		_ws = null
		connection_failed.emit()
		return

	multiplayer.multiplayer_peer = _ws

	# Connecter les signaux haut-niveau de Godot
	if not multiplayer.connected_to_server.is_connected(_on_connected_ok):
		multiplayer.connected_to_server.connect(_on_connected_ok)
	if not multiplayer.connection_failed.is_connected(_on_connection_fail):
		multiplayer.connection_failed.connect(_on_connection_fail)
	if not multiplayer.peer_connected.is_connected(_on_peer_connected):
		multiplayer.peer_connected.connect(_on_peer_connected)
	if not multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	print("[NetworkManager] Connexion WebSocket vers %s…" % SERVER_URL)

func _process(_delta: float) -> void:
	# WebSocketMultiplayerPeer doit être pollé manuellement à chaque frame
	if _ws != null:
		_ws.poll()

# ── Callbacks Godot multiplayer ───────────────────────────────────────────────

func _on_connected_ok() -> void:
	GameConfig.my_peer_id = multiplayer.get_unique_id()
	if GameConfig.is_host:
		GameConfig.my_peer_id = 1      # convention : hôte = peer 1
	print("[NetworkManager] Connecté ! ID = %d (hôte=%s)" \
		% [GameConfig.my_peer_id, GameConfig.is_host])
	connected_to_server.emit()

func _on_connection_fail() -> void:
	push_error("[NetworkManager] Connexion WebSocket échouée")
	_ws = null
	connection_failed.emit()

func _on_peer_connected(id: int) -> void:
	print("[NetworkManager] Peer connecté : %d" % id)
	player_connected.emit(id)
	if GameConfig.is_host:
		RoomManager.start_client_timeout(id)

func _on_peer_disconnected(id: int) -> void:
	print("[NetworkManager] Peer déconnecté : %d" % id)
	player_disconnected.emit(id)
	if id == 1 and not GameConfig.is_host:
		print("[NetworkManager] L'hôte s'est déconnecté !")
		host_disconnected.emit()
		disconnect_from_server()
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	else:
		var scene := get_tree().current_scene
		if scene.has_method("on_player_left"):
			scene.on_player_left(id)
		if RoomManager.player_room.has(id):
			RoomManager.remove_player(id)

# ── RPCs de synchronisation de jeu (inchangés) ───────────────────────────────

@rpc("authority", "reliable")
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

@rpc("authority", "reliable")
func sync_income(player_id: int, amount: int) -> void:
	if multiplayer.get_unique_id() == player_id:
		GameConfig.gold += amount
		var scene := get_tree().current_scene
		if scene.has_method("on_income_received"):
			scene.on_income_received(GameConfig.gold)

@rpc("authority", "reliable")
func sync_game_over(winner_id: int) -> void:
	var i_won := (winner_id == multiplayer.get_unique_id())
	Matchmaker.update_stats(GameConfig.token, i_won)
	var scene := get_tree().current_scene
	if scene.has_method("on_game_over"):
		scene.on_game_over(winner_id)
	print("[NetworkManager] Fin de partie — gagnant : %d" % winner_id)
