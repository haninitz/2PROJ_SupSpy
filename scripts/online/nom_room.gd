extends Control
# nom_room.gd — SupKonQuest · Totally Spies

const C_BG := Color(0.04, 0.02, 0.10); const C_PINK := Color(1.00, 0.20, 0.58)
const C_PURPLE := Color(0.55, 0.15, 0.85); const C_GOLD := Color(1.00, 0.85, 0.20)
const C_WHITE := Color(1.00, 1.00, 1.00)

var _input_room : LineEdit; var _btn_create : Button; var _status : Label

func _ready() -> void: _build()

func _build() -> void:
	var bg := ColorRect.new(); bg.color = C_BG; bg.size = Vector2(1152, 720); add_child(bg)
	var panel := Panel.new()
	panel.position = Vector2(1152.0/2-220, 720.0/2-200); panel.size = Vector2(440, 380)
	panel.add_theme_stylebox_override("panel", _flat(C_BG, C_PINK, 2, 14)); add_child(panel)

	var title := Label.new(); title.text = "✦  NOM DE LA MISSION  ✦"
	title.position = Vector2(0, 36); title.size = Vector2(440, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", C_PINK); panel.add_child(title)

	var lbl := Label.new(); lbl.text = "Nom de la room"
	lbl.position = Vector2(30, 108); lbl.size = Vector2(380, 18)
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color(0.80, 0.55, 0.75)); panel.add_child(lbl)

	_input_room = LineEdit.new(); _input_room.placeholder_text = "MissionImpossible"
	_input_room.position = Vector2(30, 126); _input_room.size = Vector2(380, 42)
	_input_room.add_theme_font_size_override("font_size", 16); panel.add_child(_input_room)

	_btn_create = _btn(panel, "→  LANCER LA MISSION", Vector2(30, 195), C_PINK)
	_btn_create.pressed.connect(_on_create_pressed)
	_btn(panel, "← Retour", Vector2(30, 258), Color(0.30, 0.20, 0.45)).pressed.connect(
		func(): SceneLoader.goto("res://scenes/online/ChoixMap.tscn"))

	_status = Label.new(); _status.position = Vector2(30, 318); _status.size = Vector2(380, 20)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 11)
	_status.add_theme_color_override("font_color", C_GOLD); panel.add_child(_status)

func _on_create_pressed() -> void:
	var room_name := _input_room.text.strip_edges()
	if room_name.is_empty(): _status.text = "Entre un nom de mission !"; return
	if room_name.length() < 3: _status.text = "Minimum 3 caractères !"; return
	GameConfig.room_name = room_name; GameConfig.is_host = true
	GameConfig.mode = "multi"  # toujours multi pour une room en ligne
	_btn_create.disabled = true; _status.text = "Démarrage du serveur…"
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close(); multiplayer.multiplayer_peer = null
		await get_tree().create_timer(0.15).timeout
	NetworkManager.create_server()
	# Enregistrer la room localement IMMÉDIATEMENT — pas besoin d'attendre le Matchmaker
	RoomManager.join_room_local(GameConfig.room_name, GameConfig.mode,
		GameConfig.format, GameConfig.diff, GameConfig.map, GameConfig.steam_name)
	# Notifier le Matchmaker en parallèle (best-effort, non bloquant)
	# Utiliser l'IP locale pour que les joueurs du même réseau puissent se connecter
	var local_ip : String = "127.0.0.1"
	var addrs : Array = IP.get_local_addresses()
	for addr in addrs:
		if addr.begins_with("192.168.") or addr.begins_with("10.") or addr.begins_with("172."):
			local_ip = addr
			break
	Matchmaker.create_room(room_name, local_ip,
		GameConfig.format, GameConfig.map, GameConfig.get_max_players())
	_status.text = "Mission créée !"
	SceneLoader.goto("res://scenes/online/SalleAttente.tscn")

func _on_room_registered(_room_name: String) -> void:
	pass  # Plus utilisé — gardé pour compatibilité signal

func _flat(bg: Color, border: Color, bw: int, cr: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new(); s.bg_color = bg; s.border_color = border
	s.border_width_left = bw; s.border_width_right = bw
	s.border_width_top  = bw; s.border_width_bottom = bw
	s.corner_radius_top_left = cr; s.corner_radius_top_right = cr
	s.corner_radius_bottom_left = cr; s.corner_radius_bottom_right = cr; return s

func _btn(parent: Control, text: String, pos: Vector2, col: Color) -> Button:
	var b := Button.new(); b.text = text; b.position = pos; b.size = Vector2(380, 50)
	b.add_theme_font_size_override("font_size", 14)
	b.add_theme_stylebox_override("normal", _flat(Color(col.r*.18,col.g*.18,col.b*.18), col, 2, 8))
	b.add_theme_stylebox_override("hover",  _flat(Color(col.r*.32,col.g*.32,col.b*.32), col, 2, 8))
	b.add_theme_color_override("font_color", C_WHITE); parent.add_child(b); return b