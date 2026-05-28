extends Node

const PLAYIT_HOST := "software-reporter.gl.at.ply.gg"
const PLAYIT_PORT := 61177
const LOCAL_PORT  := 7777      # port sur lequel le serveur écoute EN LOCAL
const MAX_PEERS   := 32

# Garde le PORT accessible depuis les autres scripts (comme avant)
const PORT        := LOCAL_PORT

signal connected_to_server
signal connection_failed
signal player_connected(peer_id: int)
signal player_disconnected(peer_id: int)

# Creer le serveur (hote uniquement)

func create_server() -> void:
	# Garde : si un serveur tourne déjà, on ne recrée pas
	if multiplayer.multiplayer_peer != null:
		print("[NetworkManager] Serveur déjà actif, création ignorée.")
		return

	var peer := ENetMultiplayerPeer.new()
	# bind_address "*" = écoute sur toutes les interfaces (IPv4 + IPv6)
	var err  := peer.create_server(LOCAL_PORT, MAX_PEERS, 0, 0)
	if err != OK:
		push_error("[NetworkManager] Impossible de démarrer le serveur port %d (err=%d)" % [LOCAL_PORT, err])
		return
	multiplayer.multiplayer_peer = peer
	if not multiplayer.peer_connected.is_connected(_on_peer_connected):
		multiplayer.peer_connected.connect(_on_peer_connected)
	if not multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	GameConfig.is_host    = true
	GameConfig.my_peer_id = 1
	print("[NetworkManager] Serveur démarré sur le port %d" % LOCAL_PORT)

func join_server(ip: String) -> void:
	join_server_with_port(ip, LOCAL_PORT)

func join_server_with_port(ip: String, port: int) -> void:
	GameConfig.server_ip = ip
	var peer := ENetMultiplayerPeer.new()
	var err  := peer.create_client(ip, port)
	if err != OK:
		push_error("[NetworkManager] Connexion impossible à %s:%d (err=%d)" % [ip, port, err])
		connection_failed.emit()
		return
	multiplayer.multiplayer_peer = peer
	# On déconnecte les signaux existants avant de les reconnecter
	#  (évite les doublons si on reconnecte plusieurs fois)
	if not multiplayer.connected_to_server.is_connected(_on_connected_ok):
		multiplayer.connected_to_server.connect(_on_connected_ok)
	if not multiplayer.connection_failed.is_connected(_on_connection_fail):
		multiplayer.connection_failed.connect(_on_connection_fail)
	if not multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	print("[NetworkManager] Connexion à %s:%d…" % [ip, port])

func disconnect_from_server() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	GameConfig.reset()

func _on_connected_ok() -> void:
	GameConfig.my_peer_id = multiplayer.get_unique_id()
	GameConfig.is_host    = false
	print("[NetworkManager] Connecté ! ID = %d" % GameConfig.my_peer_id)
	connected_to_server.emit()

func _on_connection_fail() -> void:
	push_error("[NetworkManager] Connexion échouée")
	connection_failed.emit()

func _on_peer_connected(id: int) -> void:
	print("[NetworkManager] Peer connecté : %d" % id)
	player_connected.emit(id)
	if multiplayer.is_server():
		RoomManager.start_client_timeout(id)

@rpc("authority", "reliable")
func sync_initial_state(state: Dictionary) -> void:
	# Reçu par les clients quand la partie démarre
	# state contient : camps, leurs propriétaires, unités initiales
	GameConfig.initial_state = state
	print("[NetworkManager] Etat initial recu")

func send_initial_state(state: Dictionary) -> void:
	# Appelé par l'hôte dans Main.gd au lancement
	if not multiplayer.is_server():
		return
	sync_initial_state.rpc(state)
	print("[NetworkManager] Etat initial envoye a tous les clients")

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

# Gestion de deconnexion hote

signal host_disconnected

func _on_peer_disconnected(id: int) -> void:
	print("[NetworkManager] Peer déconnecté : %d" % id)
	player_disconnected.emit(id)
	# Si c'est l'hôte (peer 1) qui se déconnecte côté client
	if id == 1:
		print("[NetworkManager] L'hote s'est deconnecte !")
		host_disconnected.emit()
		# Retourner au menu principal proprement
		disconnect_from_server()
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	else:
		# Un client se déconnecte → ses camps deviennent neutres
		var scene := get_tree().current_scene
		if scene.has_method("on_player_left"):
			scene.on_player_left(id)
		# Retirer de la room si on est encore dans le lobby
		if RoomManager.player_room.has(id):
			RoomManager.remove_player(id)
