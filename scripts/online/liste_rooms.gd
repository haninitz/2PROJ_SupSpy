extends Control
# liste_rooms.gd — SupKonQuest · Totally Spies

const C_BG := Color(0.04, 0.02, 0.10); const C_PINK := Color(1.00, 0.20, 0.58)
const C_PURPLE := Color(0.55, 0.15, 0.85); const C_CYAN := Color(0.00, 0.90, 0.88)
const C_GOLD := Color(1.00, 0.85, 0.20); const C_WHITE := Color(1.00, 1.00, 1.00)
const PLAYIT_PORT := 61177

var _room_list : VBoxContainer; var _status : Label

func _ready() -> void:
	_build()
	GameConfig.is_host = false
	Matchmaker.room_list_received.connect(_on_list_received)
	Matchmaker.room_found.connect(_on_room_found)
	Matchmaker.room_not_found.connect(_on_room_not_found)
	if not NetworkManager.connected_to_server.is_connected(_on_connected):
		NetworkManager.connected_to_server.connect(_on_connected)
	if not NetworkManager.connection_failed.is_connected(_on_connection_fail):
		NetworkManager.connection_failed.connect(_on_connection_fail)
	_refresh()

func _build() -> void:
	var bg := ColorRect.new(); bg.color = C_BG; bg.size = Vector2(1152, 720); add_child(bg)

	var panel := Panel.new()
	panel.position = Vector2(1152.0/2-320, 60); panel.size = Vector2(640, 580)
	panel.add_theme_stylebox_override("panel", _flat(C_BG, C_CYAN, 2, 14)); add_child(panel)

	var title := Label.new(); title.text = "✦  MISSIONS DISPONIBLES  ✦"
	title.position = Vector2(0, 22); title.size = Vector2(640, 45)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", C_CYAN); panel.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(20, 78); scroll.size = Vector2(600, 380)
	panel.add_child(scroll)
	_room_list = VBoxContainer.new()
	_room_list.custom_minimum_size = Vector2(580, 0)
	scroll.add_child(_room_list)

	var hb := HBoxContainer.new()
	hb.position = Vector2(20, 470); hb.size = Vector2(600, 50); panel.add_child(hb)

	var btn_refresh := Button.new(); btn_refresh.text = "⟳  Actualiser"
	btn_refresh.custom_minimum_size = Vector2(190, 46)
	btn_refresh.add_theme_stylebox_override("normal", _flat(Color(0,0.18,0.18), C_CYAN, 2, 8))
	btn_refresh.add_theme_color_override("font_color", C_WHITE)
	btn_refresh.pressed.connect(_refresh); hb.add_child(btn_refresh)

	var spacer := Control.new(); spacer.custom_minimum_size = Vector2(20, 0); hb.add_child(spacer)

	var btn_back := Button.new(); btn_back.text = "← Retour"
	btn_back.custom_minimum_size = Vector2(190, 46)
	btn_back.add_theme_stylebox_override("normal", _flat(Color(0.12,0.08,0.18), C_PURPLE, 2, 8))
	btn_back.add_theme_color_override("font_color", C_WHITE)
	btn_back.pressed.connect(func(): SceneLoader.goto("res://scenes/online/OnlineMenu.tscn"))
	hb.add_child(btn_back)

	_status = Label.new(); _status.position = Vector2(20, 530); _status.size = Vector2(600, 22)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 11)
	_status.add_theme_color_override("font_color", C_GOLD); panel.add_child(_status)

func _refresh() -> void:
	_status.text = "Chargement des missions..."
	for c in _room_list.get_children(): c.queue_free()
	Matchmaker.get_room_list()

func _on_list_received(rooms: Array) -> void:
	for c in _room_list.get_children(): c.queue_free()
	if rooms.is_empty(): _status.text = "Aucune mission disponible"; return
	_status.text = "%d mission(s) disponible(s)" % rooms.size()
	for room in rooms:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 52)
		var players: int = room.get("players", 0); var max_p: int = room.get("max_players", 2)
		var started: bool = room.get("started", false); var full: bool = room.get("full", false)
		var rname: String = room.get("name", ""); var map_n: String = room.get("map", "")
		var fmt: String = room.get("format", "")
		if started:
			btn.text = "EN COURS  |  %s  |  %s  |  %d/%d" % [rname, fmt, players, max_p]
			btn.disabled = true
		elif full:
			btn.text = "PLEINE  |  %s  |  %s  |  %d/%d" % [rname, fmt, players, max_p]
			btn.disabled = true
		else:
			btn.text = "✦  %s  |  %s  |  %s  |  %d/%d agents" % [rname, map_n.to_upper(), fmt, players, max_p]
			var r_name = rname; var r_map = map_n; var r_fmt = fmt
			var r_mode: String = room.get("mode","multi"); var r_diff: String = room.get("diff","med")
			btn.pressed.connect(func(): _join(r_name, r_map, r_fmt, r_mode, r_diff))
		btn.add_theme_stylebox_override("normal", _flat(Color(0.08,0.02,0.16), C_PINK, 2, 8))
		btn.add_theme_stylebox_override("hover",  _flat(Color(0.18,0.05,0.28), C_PINK, 2, 8))
		btn.add_theme_color_override("font_color", C_WHITE)
		_room_list.add_child(btn)

func _join(room_name: String, map: String, format: String, mode: String, diff: String) -> void:
	_status.text = "Connexion à '%s'..." % room_name
	GameConfig.room_name = room_name; GameConfig.map = map
	GameConfig.format = format; GameConfig.mode = mode; GameConfig.diff = diff; GameConfig.is_host = false
	Matchmaker.find_room(room_name)

func _on_room_found(address: String) -> void:
	_status.text = "Résolution de l'adresse..."
	var resolved_ip := ""
	if address.is_valid_ip_address():
		resolved_ip = address
	else:
		var rid := IP.resolve_hostname_queue_item(address)
		while true:
			await get_tree().create_timer(0.1).timeout
			var st := IP.get_resolve_item_status(rid)
			if st == IP.RESOLVER_STATUS_DONE:
				resolved_ip = IP.get_resolve_item_address(rid); IP.erase_resolve_item(rid); break
			elif st == IP.RESOLVER_STATUS_ERROR:
				IP.erase_resolve_item(rid); _status.text = "Erreur DNS"; return
	await _connect_to_host(resolved_ip)

func _connect_to_host(resolved_ip: String) -> void:
	var http := HTTPRequest.new(); add_child(http)
	var holder := ["", false]
	http.request_completed.connect(func(_r,_c,_h, body): holder[0]=body.get_string_from_utf8().strip_edges(); holder[1]=true, CONNECT_ONE_SHOT)
	if http.request("https://api.ipify.org") == OK:
		var elapsed := 0.0
		while not holder[1] and elapsed < 5.0:
			await get_tree().create_timer(0.2).timeout; elapsed += 0.2
	http.queue_free()
	var my_ip: String = holder[0]
	var final_ip: String; var final_port: int
	if my_ip != "" and my_ip == resolved_ip:
		final_ip = "127.0.0.1"; final_port = NetworkManager.LOCAL_PORT
	else:
		final_ip = resolved_ip; final_port = PLAYIT_PORT
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close(); multiplayer.multiplayer_peer = null
		await get_tree().create_timer(0.1).timeout
	_status.text = "Connexion à %s:%d..." % [final_ip, final_port]
	GameConfig.server_ip = final_ip; GameConfig.is_host = false
	NetworkManager.join_server_with_port(final_ip, final_port)

func _on_connected() -> void:
	SceneLoader.goto("res://scenes/online/SalleAttente.tscn")
func _on_connection_fail() -> void: _status.text = "Connexion échouée — réessaie"
func _on_room_not_found() -> void: _status.text = "Mission introuvable !"

func _flat(bg: Color, border: Color, bw: int, cr: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new(); s.bg_color = bg; s.border_color = border
	s.border_width_left = bw; s.border_width_right = bw
	s.border_width_top  = bw; s.border_width_bottom = bw
	s.corner_radius_top_left = cr; s.corner_radius_top_right = cr
	s.corner_radius_bottom_left = cr; s.corner_radius_bottom_right = cr; return s
