extends Node

# ── Config ────────────────────────────────────────────────────────────────────
# Connexion via RELAY WebSocket en ligne. L'hôte ET le client sont tous les deux
# des clients WebSocket du relay (wss://…onrender.com). Le relay a été rendu
# "Godot-compatible" : il envoie à chaque nouveau peer 4 octets (int32 LE) avec
# son peer ID (≥ 2), ce qu'attend WebSocketMultiplayerPeer pour passer CONNECTED.
# GameConfig.is_host = seule source de vérité pour "qui est l'hôte" (pas peer ID).
# Le Matchmaker Render reste utilisé pour la liste des rooms uniquement.
const RELAY_URL := "wss://sup-kon-quest-server.onrender.com"
# PORT conservé pour compat. avec d'autres scripts (Matchmaker.gd) — non utilisé
# pour la connexion relay.
const PORT      := 7777

# ── Signaux (identiques à avant — aucun script à changer) ─────────────────────
signal connected_to_server
signal connection_failed
signal player_connected(peer_id: int)
signal player_disconnected(peer_id: int)
signal host_disconnected
# Signal OPTIONNEL : message d'avancement de connexion pour l'UI.
signal connection_progress(message: String)

# ── État interne ──────────────────────────────────────────────────────────────
var _peer : WebSocketMultiplayerPeer = null
var _connected_room : String = ""

# ── Timeout de connexion ──────────────────────────────────────────────────────
# Le relay Render peut être en cold-start (plusieurs secondes). On laisse un
# délai généreux avant d'abandonner avec un message clair.
const CONNECT_TIMEOUT := 20.0
var _connecting      := false
var _connect_elapsed := 0.0

# ── Heartbeat hôte → client (détection du départ de l'hôte) ───────────────────
const HEARTBEAT_INTERVAL : float = 0.5   # l'hôte envoie un ping toutes les 0.5 s
const HOST_TIMEOUT       : float = 2.0   # client : aucun ping pendant 2 s = hôte parti
var _heartbeat_send_t : float = 0.0
var _heartbeat_recv_t : float = 0.0
var _watch_host       : bool  = false

# ── API publique (même signature qu'avant) ────────────────────────────────────

func create_server() -> void:
	# L'hôte n'est PLUS un serveur Godot : il se connecte au relay comme client.
	# GameConfig.is_host (déjà posé avant l'appel) reste la source de vérité.
	GameConfig.is_host = true
	connection_progress.emit("Connexion au serveur de jeu…")
	_connect_to_relay()

func join_server(ip: String) -> void:
	# ip est ignoré : la connexion passe par le relay en ligne (plus d'ENet LAN).
	join_server_with_port(ip, PORT)

func join_server_with_port(_ip: String, _port: int) -> void:
	GameConfig.is_host = false
	connection_progress.emit("Connexion à la mission…")
	_connect_to_relay()

func _connect_to_relay() -> void:
	var want_room := GameConfig.room_name

	# Auto-réparation du désync : du code externe (nom_room / liste_rooms) a pu
	# faire multiplayer.multiplayer_peer = null sans nettoyer _peer. La connexion
	# est alors morte → on repart proprement.
	if _peer != null and multiplayer.multiplayer_peer == null:
		_peer = null
		_connected_room = ""

	if _peer != null:
		var st := _peer.get_connection_status()
		if _connected_room != want_room:
			# Mauvaise room (ex. connexion parasite room="") → reconnexion propre.
			print("[NetworkManager] Room différente ('%s'→'%s'), reconnexion." \
				% [_connected_room, want_room])
			_teardown()
		elif st == MultiplayerPeer.CONNECTION_CONNECTED:
			# Bonne room, déjà connecté : ré-émettre pour débloquer l'appelant
			# (salle d'attente) qui attend connected_to_server.
			print("[NetworkManager] Déjà connecté à '%s', ré-émission." % want_room)
			GameConfig.my_peer_id = multiplayer.get_unique_id()
			connected_to_server.emit()
			return
		else:
			# Bonne room, connexion encore en cours : _on_connected_ok s'en charge.
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

	# Brancher les signaux une seule fois (évite les fuites au re-clic).
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
	
# Vrai seulement si le peer réseau existe ET est réellement connecté.
func _peer_connected_ok() -> bool:
	return multiplayer.multiplayer_peer != null \
		and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED

func _return_to_main_menu() -> void:
	if GameConfig.is_host:
		return  # l'hôte gère son quit dans PauseMenu
	host_disconnected.emit()
	_teardown()
	GameConfig.reset()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
	
# Appelé par l'HÔTE juste avant de quitter la partie (bouton Menu / Quitter) :
# prévient les clients immédiatement, sans attendre le timeout du heartbeat.
func notify_host_leaving() -> void:
	if GameConfig.mode == "multi" and GameConfig.is_host and _peer_connected_ok():
		_rpc_host_left.rpc()
	
# Coupe la connexion en gardant _peer et multiplayer.multiplayer_peer
# synchronisés, SANS toucher à GameConfig (room_name/is_host/agent_name conservés).
func reset_connection() -> void:
	_teardown()

func _teardown() -> void:
	_connecting      = false
	_connect_elapsed = 0.0
	_connected_room  = ""
	if _peer != null:
		multiplayer.multiplayer_peer = null
		_peer = null

# ── Cycle de vie ──────────────────────────────────────────────────────────────

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Signaux stables sur toute la durée de vie du node.
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	# Réveiller relay + Matchmaker Render — ils peuvent être en veille (cold-start).
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
	# Heartbeat hôte <-> client
	if _peer_connected_ok() and GameConfig.mode == "multi":
		if GameConfig.is_host:
			_heartbeat_send_t += delta
			if _heartbeat_send_t >= HEARTBEAT_INTERVAL:
				_heartbeat_send_t = 0.0
				_rpc_heartbeat.rpc()
		elif _watch_host:
			_heartbeat_recv_t += delta
			if _heartbeat_recv_t >= HOST_TIMEOUT:
				_watch_host = false
				print("[NetworkManager] Hôte injoignable (heartbeat) — retour au menu")
				_return_to_main_menu()
				return
	
	# WebSocketMultiplayerPeer est pollé automatiquement par la SceneTree : on
	# surveille juste le timeout de connexion.
	if not _connecting:
		return
	_connect_elapsed += delta
	if _connect_elapsed >= CONNECT_TIMEOUT:
		push_error("[NetworkManager] Timeout : relay injoignable (%s)" % RELAY_URL)
		_teardown()
		connection_progress.emit("Le serveur ne répond pas. Réessaie dans un instant.")
		connection_failed.emit()

# ── Callbacks Godot multiplayer ───────────────────────────────────────────────

func _on_connected_ok() -> void:
	_connecting      = false
	_connect_elapsed = 0.0
	GameConfig.my_peer_id = multiplayer.get_unique_id()
	print("[NetworkManager] Connecté ! ID = %d (hôte=%s)" \
		% [GameConfig.my_peer_id, GameConfig.is_host])
	connection_progress.emit("Connecté !")
	connected_to_server.emit()
	_heartbeat_recv_t = 0.0
	_watch_host = not GameConfig.is_host

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
		_return_to_main_menu()
	else:
		# L'hôte ignore la déco du client — il gère son propre quit dans PauseMenu
		var scene := get_tree().current_scene
		if scene.has_method("on_player_left"):
			scene.on_player_left(id)
		if RoomManager.player_room.has(id):
			RoomManager.remove_player(id)

### RPCs de synchronisation de jeu (inchangés)

@rpc("any_peer", "reliable")
func _rpc_heartbeat() -> void:
	# Reçu par le client : l'hôte est vivant → on remet le compteur à zéro.
	_heartbeat_recv_t = 0.0
	
@rpc("any_peer", "reliable")
func _rpc_host_left() -> void:
	# Reçu par le client : l'hôte a quitté volontairement → retour menu immédiat.
	if GameConfig.is_host:
		return
	_watch_host = false
	print("[NetworkManager] L'hôte a quitté la partie — retour à l'application")
	_return_to_main_menu()

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
	
