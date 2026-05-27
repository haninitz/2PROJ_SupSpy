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

# ─────────────────────────────────────────────
#  CRÉER LE SERVEUR  (hôte uniquement)
# ─────────────────────────────────────────────
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

func _on_peer_disconnected(id: int) -> void:
	print("[NetworkManager] Peer déconnecté : %d" % id)
	player_disconnected.emit(id)
