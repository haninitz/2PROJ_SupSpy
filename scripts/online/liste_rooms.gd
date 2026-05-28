extends Control
# liste_rooms.gd — SupKonQuest · Totally Spies
# Connexion directe par IP — pas besoin de serveur Matchmaker externe

const C_BG     := Color(0.04, 0.02, 0.10)
const C_PINK   := Color(1.00, 0.20, 0.58)
const C_PURPLE := Color(0.55, 0.15, 0.85)
const C_CYAN   := Color(0.00, 0.90, 0.88)
const C_GOLD   := Color(1.00, 0.85, 0.20)
const C_WHITE  := Color(1.00, 1.00, 1.00)

var _status    : Label
var _ip_input  : LineEdit
var _room_list : VBoxContainer

func _ready() -> void:
	_build()
	# Écouter les signaux réseau
	if not NetworkManager.connected_to_server.is_connected(_on_connected):
		NetworkManager.connected_to_server.connect(_on_connected)
	if not NetworkManager.connection_failed.is_connected(_on_connection_fail):
		NetworkManager.connection_failed.connect(_on_connection_fail)
	# Écouter les rooms reçues via RPC
	if not RoomManager.player_list_updated.is_connected(_on_room_list_received):
		RoomManager.player_list_updated.connect(_on_room_list_received)
	# Essayer aussi le Matchmaker distant (best-effort)
	if not Matchmaker.room_list_received.is_connected(_on_matchmaker_list):
		Matchmaker.room_list_received.connect(_on_matchmaker_list, CONNECT_ONE_SHOT)
	Matchmaker.get_room_list()


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = C_BG; bg.size = Vector2(1152, 720)
	add_child(bg)

	var panel := Panel.new()
	panel.position = Vector2(1152.0/2 - 320, 40)
	panel.size     = Vector2(640, 620)
	panel.add_theme_stylebox_override("panel", _flat(C_BG, C_CYAN, 2, 14))
	add_child(panel)

	var title := Label.new()
	title.text = "✦  REJOINDRE UNE MISSION  ✦"
	title.position = Vector2(0, 22); title.size = Vector2(640, 45)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", C_CYAN)
	panel.add_child(title)

	# ── Connexion directe par IP ─────────────────────────────────────────────
	var ip_lbl := Label.new()
	ip_lbl.text = "IP de l'hôte :"
	ip_lbl.position = Vector2(20, 74); ip_lbl.size = Vector2(140, 22)
	ip_lbl.add_theme_font_size_override("font_size", 12)
	ip_lbl.add_theme_color_override("font_color", C_GOLD)
	panel.add_child(ip_lbl)

	_ip_input = LineEdit.new()
	_ip_input.placeholder_text = "127.0.0.1  ou  192.168.x.x"
	_ip_input.text = "127.0.0.1"
	_ip_input.position = Vector2(160, 70); _ip_input.size = Vector2(280, 34)
	_ip_input.add_theme_font_size_override("font_size", 13)
	panel.add_child(_ip_input)

	var btn_connect := Button.new()
	btn_connect.text = "→ Connecter"
	btn_connect.position = Vector2(452, 70); btn_connect.size = Vector2(160, 34)
	btn_connect.add_theme_stylebox_override("normal", _flat(Color(0.20,0.04,0.12), C_PINK, 2, 6))
	btn_connect.add_theme_stylebox_override("hover",  _flat(Color(0.35,0.08,0.20), C_PINK, 2, 6))
	btn_connect.add_theme_color_override("font_color", C_WHITE)
	btn_connect.pressed.connect(_on_connect_pressed)
	panel.add_child(btn_connect)

	var div := ColorRect.new()
	div.color = Color(C_CYAN.r, C_CYAN.g, C_CYAN.b, 0.25)
	div.position = Vector2(20, 112); div.size = Vector2(600, 1)
	panel.add_child(div)

	# ── Liste des rooms (Matchmaker distant si dispo) ─────────────────────────
	var list_lbl := Label.new()
	list_lbl.text = "Ou rejoindre une mission visible :"
	list_lbl.position = Vector2(20, 120); list_lbl.size = Vector2(400, 20)
	list_lbl.add_theme_font_size_override("font_size", 11)
	list_lbl.add_theme_color_override("font_color", Color(0.60, 0.80, 0.90))
	panel.add_child(list_lbl)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(20, 144); scroll.size = Vector2(600, 310)
	panel.add_child(scroll)
	_room_list = VBoxContainer.new()
	_room_list.custom_minimum_size = Vector2(580, 0)
	scroll.add_child(_room_list)

	var hb := HBoxContainer.new()
	hb.position = Vector2(20, 462); hb.size = Vector2(600, 46)
	panel.add_child(hb)

	var btn_refresh := Button.new()
	btn_refresh.text = "⟳  Actualiser"
	btn_refresh.custom_minimum_size = Vector2(190, 44)
	btn_refresh.add_theme_stylebox_override("normal", _flat(Color(0,0.18,0.18), C_CYAN, 2, 8))
	btn_refresh.add_theme_color_override("font_color", C_WHITE)
	btn_refresh.pressed.connect(func():
		for c in _room_list.get_children(): c.queue_free()
		if not Matchmaker.room_list_received.is_connected(_on_matchmaker_list):
			Matchmaker.room_list_received.connect(_on_matchmaker_list, CONNECT_ONE_SHOT)
		Matchmaker.get_room_list())
	hb.add_child(btn_refresh)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(20, 0)
	hb.add_child(spacer)

	var btn_back := Button.new()
	btn_back.text = "← Retour"
	btn_back.custom_minimum_size = Vector2(190, 44)
	btn_back.add_theme_stylebox_override("normal", _flat(Color(0.12,0.08,0.18), C_PURPLE, 2, 8))
	btn_back.add_theme_color_override("font_color", C_WHITE)
	btn_back.pressed.connect(func(): SceneLoader.goto("res://scenes/Main.tscn"))
	hb.add_child(btn_back)

	_status = Label.new()
	_status.position = Vector2(20, 514); _status.size = Vector2(600, 22)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 11)
	_status.add_theme_color_override("font_color", C_GOLD)
	panel.add_child(_status)


# ── Connexion directe par IP ──────────────────────────────────────────────────
func _on_connect_pressed() -> void:
	var ip : String = _ip_input.text.strip_edges()
	if ip.is_empty():
		ip = "127.0.0.1"
	_status.text = "Connexion à %s..." % ip
	GameConfig.server_ip = ip
	GameConfig.is_host   = false
	# S assurer que le mode est multi pour que Main.gd démarre bien la partie
	if GameConfig.mode == "":
		GameConfig.mode = "multi"
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	NetworkManager.join_server_with_port(ip, NetworkManager.LOCAL_PORT)


func _on_connected() -> void:
	_status.text = "Connecté !"
	# SalleAttente._ready() s occupe de request_join_room — pas besoin de le faire ici
	SceneLoader.goto("res://scenes/online/SalleAttente.tscn")


func _on_connection_fail() -> void:
	_status.text = "Connexion échouée — vérifie l'IP"


# ── Liste Matchmaker (best-effort) ────────────────────────────────────────────
func _on_matchmaker_list(rooms: Array) -> void:
	for c in _room_list.get_children(): c.queue_free()
	if rooms.is_empty():
		_status.text = "Aucune mission visible — entre l'IP directement"
		return
	_status.text = "%d mission(s) visible(s)" % rooms.size()
	for room in rooms:
		if room.get("started", false) or room.get("full", false):
			continue
		var btn := Button.new()
		var rname : String = room.get("name", "?")
		var map_n : String = room.get("map", "?")
		var fmt   : String = room.get("format", "1v1")
		var plrs  : int    = room.get("players", 0)
		var maxp  : int    = room.get("max_players", 2)
		var ip    : String = room.get("ip", "127.0.0.1")
		btn.text = "✦  %s  |  %s  |  %s  |  %d/%d" % [rname, map_n.to_upper(), fmt, plrs, maxp]
		btn.custom_minimum_size = Vector2(0, 48)
		btn.add_theme_stylebox_override("normal", _flat(Color(0.08,0.02,0.16), C_PINK, 2, 8))
		btn.add_theme_stylebox_override("hover",  _flat(Color(0.18,0.05,0.28), C_PINK, 2, 8))
		btn.add_theme_color_override("font_color", C_WHITE)
		btn.pressed.connect(func():
			_ip_input.text = ip
			GameConfig.room_name = rname
			GameConfig.map       = room.get("map", "clover")
			GameConfig.format    = fmt
			GameConfig.mode      = room.get("mode", "multi")
			GameConfig.diff      = room.get("diff", "med")
			_on_connect_pressed())
		_room_list.add_child(btn)


func _on_room_list_received(_rid: String, _data: Array) -> void:
	pass  # géré par _on_connected → SalleAttente


# ── Helpers ───────────────────────────────────────────────────────────────────
func _flat(bg: Color, border: Color, bw: int, cr: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg; s.border_color = border
	s.border_width_left = bw; s.border_width_right = bw
	s.border_width_top  = bw; s.border_width_bottom = bw
	s.corner_radius_top_left = cr; s.corner_radius_top_right = cr
	s.corner_radius_bottom_left = cr; s.corner_radius_bottom_right = cr
	return s