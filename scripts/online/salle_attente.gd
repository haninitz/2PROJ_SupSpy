extends Control

func _lt(key: String) -> String:
	var u := get_node_or_null("/root/UIUtils")
	return u.lt(key) if u and u.has_method("lt") else key

# ── Couleurs ──────────────────────────────────────────────────────────────────
const C_BG     := Color(0.04, 0.02, 0.10)
const C_PINK   := Color(1.00, 0.20, 0.58)
const C_PURPLE := Color(0.55, 0.15, 0.85)
const C_CYAN   := Color(0.00, 0.90, 0.88)
const C_GOLD   := Color(1.00, 0.85, 0.20)
const C_WHITE  := Color(1.00, 1.00, 1.00)

var _slots_a    : VBoxContainer
var _slots_b    : VBoxContainer
var _btn_lancer : Button
var _status     : Label

# Garde-fou : l'hôte ne s'enregistre qu'une seule fois
var _host_registered := false
# Garde-fou : évite un double _leave_room
var _leaving := false

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_build()
	_btn_lancer.disabled = true
	_btn_lancer.visible  = GameConfig.is_host
	_update_labels()

	RoomManager.player_list_updated.connect(_on_list_updated)
	RoomManager.room_full.connect(_on_room_full)
	NetworkManager.player_disconnected.connect(_on_player_disconnected)
	# Sécurité : si l'hôte disparaît sans signal player_disconnected
	NetworkManager.host_disconnected.connect(_on_host_force_quit)
	# Messages d'avancement de connexion (cold-start Render) — signal optionnel.
	NetworkManager.connection_progress.connect(_on_connection_progress)

	if GameConfig.is_host:
		# NB : on n'enregistre PAS l'hôte ici — my_peer_id vaut encore 0 avant
		# create_server(). L'enregistrement se fait dans _on_host_ws_ready(),
		# une fois my_peer_id définitivement fixé à 1.
		if multiplayer.multiplayer_peer == null:
			_status.text = _lt("lobby_connecting_srv")
			NetworkManager.connected_to_server.connect(_on_host_ws_ready, CONNECT_ONE_SHOT)
			NetworkManager.connection_failed.connect(_on_host_ws_fail,    CONNECT_ONE_SHOT)
			NetworkManager.create_server()
		else:
			_on_host_ws_ready()
	else:
		_status.text = _lt("lobby_connecting_miss")
		NetworkManager.connection_failed.connect(_on_connect_failed,    CONNECT_ONE_SHOT)
		NetworkManager.connected_to_server.connect(_on_client_ws_ready, CONNECT_ONE_SHOT)

		if multiplayer.multiplayer_peer != null and \
				multiplayer.multiplayer_peer.get_connection_status() \
				== MultiplayerPeer.CONNECTION_CONNECTED:
			_on_client_ws_ready()
		else:
			NetworkManager.join_server("")

# ── Enregistrement hôte (une seule fois) ─────────────────────────────────────
func _register_host_once() -> void:
	if _host_registered:
		return
	_host_registered = true
	RoomManager.join_room_local(
		GameConfig.room_name, GameConfig.mode,
		GameConfig.format,    GameConfig.diff,
		GameConfig.map,       GameConfig.steam_name)
	_refresh_slots()

# ── Callbacks hôte ───────────────────────────────────────────────────────────
func _on_host_ws_ready() -> void:
	_status.text = _lt("lobby_waiting_agents") % GameConfig.get_max_players()
	# Récupérer l'IP locale pour le Matchmaker
	var local_ip := _get_local_ip()
	# 1) Déclarer la room sur le matchmaker (action "create" en premier dans la file).
	Matchmaker.create_room(
		GameConfig.room_name,
		local_ip,
		GameConfig.format,
		GameConfig.map,
		GameConfig.get_max_players())
	# 2) Enregistrer l'hôte localement APRÈS que my_peer_id == 1 (fixé par
	#    create_server()). _refresh_slots() enverra ensuite l'action "update".
	_register_host_once()

func _on_host_ws_fail() -> void:
	_status.text = _lt("lobby_server_fail")

# ── Callbacks client ─────────────────────────────────────────────────────────
func _on_client_ws_ready() -> void:
	GameConfig.my_peer_id = multiplayer.get_unique_id()
	_status.text = _lt("lobby_waiting_host_con")
	# L'hôte n'est plus peer 1 (les deux sont clients du relay, IDs ≥ 2). Un RPC
	# ciblé rpc_id(1) serait rejeté côté hôte (unique_id ≠ 1). On diffuse donc en
	# broadcast : en 1v1, .rpc() atteint l'unique autre joueur (l'hôte).
	_send_join_request()

func _send_join_request() -> void:
	_status.text = _lt("lobby_join_sent")
	RoomManager.request_join_room.rpc(
		GameConfig.room_name, GameConfig.mode,
		GameConfig.format,    GameConfig.diff,
		GameConfig.map,       GameConfig.steam_name)

func _on_connect_failed() -> void:
	_status.text = _lt("lobby_conn_failed")

# Avancement de connexion : n'écraser le statut que tant qu'on attend encore
# la connexion (hôte avant enregistrement, ou client avant le join).
func _on_connection_progress(message: String) -> void:
	if not _host_registered or not GameConfig.is_host:
		_status.text = message

# ── Déconnexion d'un joueur ───────────────────────────────────────────────────
func _on_player_disconnected(_peer_id: int) -> void:
	# L'hôte n'est plus le peer 1 (les deux sont clients du relay, IDs ≥ 2). Côté
	# client en 1v1, tout peer qui se déconnecte = l'hôte (l'unique autre joueur).
	if not GameConfig.is_host:
		_on_host_force_quit()
		return
	_refresh_slots()

func _on_host_force_quit() -> void:
	if _leaving:
		return
	_status.text = _lt("lobby_host_left")
	await get_tree().create_timer(1.5).timeout
	_leave_room(false)

# ── Nettoyage de la room ──────────────────────────────────────────────────────
func _leave_room(do_disconnect: bool) -> void:
	if _leaving:
		return
	_leaving = true
	if GameConfig.is_host:
		Matchmaker.delete_room(GameConfig.room_name)
		if RoomManager.rooms.has(GameConfig.room_name):
			RoomManager.rooms.erase(GameConfig.room_name)
	if do_disconnect:
		NetworkManager.disconnect_from_server()
	GameConfig.reset()
	SceneLoader.goto("res://scenes/online/OnlineMenu.tscn")

# ── Sécurité fermeture forcée ─────────────────────────────────────────────────
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if GameConfig.is_host and GameConfig.room_name != "" and not _leaving:
			Matchmaker.delete_room(GameConfig.room_name)

# ── UI callbacks ──────────────────────────────────────────────────────────────
func _on_list_updated(_rid: String, _data: Array) -> void:
	_update_labels()
	_btn_lancer.visible = GameConfig.is_host
	_refresh_slots()
	var total   := GameConfig.get_max_players()
	var current := GameConfig.players.size()
	if GameConfig.is_host:
		_btn_lancer.disabled = current < total
		_status.text = _lt("lobby_all_ready") if not _btn_lancer.disabled \
			else _lt("lobby_waiting") % [current, total]
	else:
		_status.text = _lt("lobby_waiting_host") % [current, total]

func _on_room_full(_rid: String) -> void:
	_status.text = _lt("lobby_room_full")

func _refresh_slots() -> void:
	# Autorité hôte : le format de la room publiée fait foi. Évite qu'un
	# GameConfig.format local périmé (ex. "2v2" résiduel) n'affiche trop de slots.
	if GameConfig.is_host and RoomManager.rooms.has(GameConfig.room_name):
		GameConfig.format = RoomManager.rooms[GameConfig.room_name].get("format", GameConfig.format)
	for c in _slots_a.get_children(): c.queue_free()
	for c in _slots_b.get_children(): c.queue_free()

	var per_team := GameConfig.get_players_per_team()
	var all_p    := GameConfig.players.values()
	all_p.sort_custom(func(a, b): return a.join_order < b.join_order)

	var team_a := all_p.filter(func(p): return p.team == "a")
	var team_b := all_p.filter(func(p): return p.team == "b")

	for i in per_team:
		var l := Label.new()
		l.text = ("%s%s" % [team_a[i].name,
			" (vous)" if team_a[i].id == GameConfig.my_peer_id else ""]) \
			if i < team_a.size() else "[ Slot vide ]"
		l.add_theme_color_override("font_color",
			C_PINK if i < team_a.size() else Color(0.45, 0.35, 0.55))
		_slots_a.add_child(l)

	for i in per_team:
		var l := Label.new()
		l.text = ("%s%s" % [team_b[i].name,
			" (vous)" if team_b[i].id == GameConfig.my_peer_id else ""]) \
			if i < team_b.size() else "[ Slot vide ]"
		l.add_theme_color_override("font_color",
			C_PURPLE if i < team_b.size() else Color(0.45, 0.35, 0.55))
		_slots_b.add_child(l)

	if GameConfig.is_host:
		Matchmaker.update_room(GameConfig.room_name, GameConfig.players.size(), false)

func _on_lancer_pressed() -> void:
	if not GameConfig.is_host: return
	GameConfig.mode = "multi"
	if RoomManager.rooms.has(GameConfig.room_name):
		Matchmaker.update_room(GameConfig.room_name, GameConfig.players.size(), true)
		RoomManager._start_game(GameConfig.room_name)
	else:
		_status.text = _lt("listrooms_notfound")

func _on_quitter_pressed() -> void:
	_leave_room(true)

# ── Utilitaire IP locale ──────────────────────────────────────────────────────
func _get_local_ip() -> String:
	for addr in IP.get_local_addresses():
		if addr.begins_with("10.") or addr.begins_with("192.168.") \
				or addr.begins_with("172."):
			return addr
	return "127.0.0.1"

# ── Construction UI ───────────────────────────────────────────────────────────
func _build() -> void:
	var bg := ColorRect.new()
	bg.color = C_BG; bg.size = Vector2(1152, 720); add_child(bg)

	var panel := Panel.new()
	panel.position = Vector2(1152.0 / 2 - 300, 60)
	panel.size     = Vector2(600, 580)
	panel.add_theme_stylebox_override("panel", _flat(C_BG, C_PINK, 2, 14))
	add_child(panel)

	var title := Label.new(); title.text = _lt("lobby_title")
	title.position = Vector2(0, 22); title.size = Vector2(600, 46)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", C_PINK)
	panel.add_child(title)

	var info := Label.new(); info.name = "InfoRoom"
	info.position = Vector2(0, 70); info.size = Vector2(600, 22)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_font_size_override("font_size", 13)
	info.add_theme_color_override("font_color", C_GOLD)
	panel.add_child(info)

	var div := ColorRect.new()
	div.color    = Color(C_PINK.r, C_PINK.g, C_PINK.b, 0.30)
	div.position = Vector2(30, 98); div.size = Vector2(540, 1)
	panel.add_child(div)

	var team_a_lbl := Label.new(); team_a_lbl.text = _lt("lobby_team_a")
	team_a_lbl.position = Vector2(30, 110); team_a_lbl.size = Vector2(240, 28)
	team_a_lbl.add_theme_font_size_override("font_size", 16)
	team_a_lbl.add_theme_color_override("font_color", C_PINK)
	panel.add_child(team_a_lbl)

	var team_b_lbl := Label.new(); team_b_lbl.text = _lt("lobby_team_b")
	team_b_lbl.position = Vector2(330, 110); team_b_lbl.size = Vector2(240, 28)
	team_b_lbl.add_theme_font_size_override("font_size", 16)
	team_b_lbl.add_theme_color_override("font_color", C_PURPLE)
	panel.add_child(team_b_lbl)

	_slots_a = VBoxContainer.new()
	_slots_a.position = Vector2(30, 144); _slots_a.size = Vector2(240, 200)
	panel.add_child(_slots_a)

	_slots_b = VBoxContainer.new()
	_slots_b.position = Vector2(330, 144); _slots_b.size = Vector2(240, 200)
	panel.add_child(_slots_b)

	_btn_lancer = Button.new(); _btn_lancer.text = _lt("lobby_launch")
	_btn_lancer.position = Vector2(30, 420); _btn_lancer.size = Vector2(540, 52)
	_btn_lancer.add_theme_font_size_override("font_size", 16)
	_btn_lancer.add_theme_stylebox_override("normal", _flat(Color(0.20, 0.04, 0.12), C_PINK,   2, 8))
	_btn_lancer.add_theme_stylebox_override("hover",  _flat(Color(0.35, 0.08, 0.20), C_PINK,   2, 8))
	_btn_lancer.add_theme_color_override("font_color", C_WHITE)
	_btn_lancer.pressed.connect(_on_lancer_pressed)
	panel.add_child(_btn_lancer)

	var btn_quitter := Button.new(); btn_quitter.text = _lt("lobby_quit")
	btn_quitter.position = Vector2(30, 484); btn_quitter.size = Vector2(540, 44)
	btn_quitter.add_theme_stylebox_override("normal", _flat(Color(0.12, 0.08, 0.18), C_PURPLE, 2, 8))
	btn_quitter.add_theme_color_override("font_color", C_WHITE)
	btn_quitter.pressed.connect(_on_quitter_pressed)
	panel.add_child(btn_quitter)

	_status = Label.new()
	_status.position = Vector2(30, 536); _status.size = Vector2(540, 22)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 11)
	_status.add_theme_color_override("font_color", C_GOLD)
	panel.add_child(_status)

func _update_labels() -> void:
	var info := get_node_or_null("Panel/InfoRoom")
	if info:
		info.text = "Mission : %s  •  Map : %s  •  Format : %s" % [
			GameConfig.room_name, GameConfig.map.to_upper(), GameConfig.format]

func _flat(bg: Color, border: Color, bw: int, cr: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color      = bg
	s.border_color  = border
	s.border_width_left     = bw; s.border_width_right  = bw
	s.border_width_top      = bw; s.border_width_bottom = bw
	s.corner_radius_top_left     = cr; s.corner_radius_top_right    = cr
	s.corner_radius_bottom_left  = cr; s.corner_radius_bottom_right = cr
	return s
