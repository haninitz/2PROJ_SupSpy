extends Control
# nom_room.gd — SupKonQuest · Totally Spies

func _lt(key: String) -> String:
	var u := get_node_or_null("/root/UIUtils")
	return u.lt(key) if u and u.has_method("lt") else key

const C_BG := Color(0.04, 0.02, 0.10); const C_PINK := Color(1.00, 0.20, 0.58)
const C_PURPLE := Color(0.55, 0.15, 0.85); const C_GOLD := Color(1.00, 0.85, 0.20)
const C_WHITE := Color(1.00, 1.00, 1.00)

var _input_room : LineEdit; var _btn_create : Button; var _status : Label

func _ready() -> void:
	_build()
	Matchmaker.room_created.connect(_on_room_registered, CONNECT_ONE_SHOT)
	Matchmaker.matchmaker_error.connect(_on_matchmaker_error)

func _build() -> void:
	var bg := ColorRect.new(); bg.color = C_BG; bg.size = Vector2(1152, 720); add_child(bg)
	var panel := Panel.new()
	panel.position = Vector2(1152.0/2-220, 720.0/2-200); panel.size = Vector2(440, 380)
	panel.add_theme_stylebox_override("panel", _flat(C_BG, C_PINK, 2, 14)); add_child(panel)

	var title := Label.new(); title.text = _lt("nomroom_title")
	title.position = Vector2(0, 36); title.size = Vector2(440, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", C_PINK); panel.add_child(title)

	var lbl := Label.new(); lbl.text = _lt("nomroom_label")
	lbl.position = Vector2(30, 108); lbl.size = Vector2(380, 18)
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color(0.80, 0.55, 0.75)); panel.add_child(lbl)

	_input_room = LineEdit.new(); _input_room.placeholder_text = "MissionImpossible"
	_input_room.position = Vector2(30, 126); _input_room.size = Vector2(380, 42)
	_input_room.add_theme_font_size_override("font_size", 16); panel.add_child(_input_room)

	_btn_create = _btn(panel, _lt("nomroom_launch"), Vector2(30, 195), C_PINK)
	_btn_create.pressed.connect(_on_create_pressed)
	_btn(panel, _lt("back"), Vector2(30, 258), Color(0.30, 0.20, 0.45)).pressed.connect(
		func(): SceneLoader.goto("res://scenes/online/ChoixMap.tscn"))

	_status = Label.new(); _status.position = Vector2(30, 318); _status.size = Vector2(380, 20)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 11)
	_status.add_theme_color_override("font_color", C_GOLD); panel.add_child(_status)

func _on_create_pressed() -> void:
	var room_name := _input_room.text.strip_edges()
	if room_name.is_empty(): _status.text = "Entre un nom de mission !"; return
	if room_name.length() < 3: _status.text = "Minimum 3 caractères !"; return
	if room_name.length() > 20: _status.text = "Nom trop long (20 max) !"; return

	GameConfig.room_name = room_name
	GameConfig.is_host   = true
	GameConfig.mode      = "multi"
	_btn_create.disabled = true
	_status.text         = "Enregistrement de la room…"

	# Nettoyer toute connexion résiduelle via NetworkManager pour garder
	# _peer et multiplayer.multiplayer_peer synchronisés (évite le désync).
	NetworkManager.reset_connection()
	await get_tree().create_timer(0.15).timeout

	# Étape 1 : enregistrer sur le matchmaker (rapide)
	# La connexion au serveur de jeu se fait en salle d'attente
	var local_ip := "127.0.0.1"
	for addr in IP.get_local_addresses():
		if addr.begins_with("192.168.") or addr.begins_with("10.") or addr.begins_with("172."):
			local_ip = addr; break

	Matchmaker.create_room(
		room_name, local_ip,
		GameConfig.format, GameConfig.map,
		GameConfig.get_max_players())

	# Timeout 12s si le matchmaker ne répond pas
	await get_tree().create_timer(12.0).timeout
	if is_inside_tree() and _status.text == "Enregistrement de la room…":
		_status.text         = "Timeout — le serveur ne répond pas, réessaie."
		_btn_create.disabled = false

func _on_room_registered(_room_name: String) -> void:
	_status.text = "Room créée ! Connexion en cours…"
	# NB : on n'enregistre PAS l'hôte ici. my_peer_id vaut encore 0 avant
	# create_server() ; l'enregistrer maintenant créerait un slot fantôme
	# (Joueur 0) en plus du vrai (Joueur 1). L'enregistrement se fait
	# uniquement en salle d'attente, une fois my_peer_id fixé à 1.
	# Lancer la connexion WebSocket en arrière-plan (fixe my_peer_id = 1)
	NetworkManager.create_server()
	# Aller en salle d'attente immédiatement sans attendre la connexion
	SceneLoader.goto("res://scenes/online/SalleAttente.tscn")

func _on_matchmaker_error() -> void:
	_status.text         = "Erreur réseau — réessaie."
	_btn_create.disabled = false

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
