extends Control
# salle_attente.gd — SupKonQuest · Totally Spies

const C_BG := Color(0.04, 0.02, 0.10); const C_PINK := Color(1.00, 0.20, 0.58)
const C_PURPLE := Color(0.55, 0.15, 0.85); const C_CYAN := Color(0.00, 0.90, 0.88)
const C_GOLD := Color(1.00, 0.85, 0.20); const C_WHITE := Color(1.00, 1.00, 1.00)

var _slots_a : VBoxContainer; var _slots_b : VBoxContainer
var _btn_lancer : Button; var _status : Label

func _ready() -> void:
	_build()
	_btn_lancer.disabled = true; _btn_lancer.visible = GameConfig.is_host
	_update_labels()
	RoomManager.player_list_updated.connect(_on_list_updated)
	RoomManager.room_full.connect(_on_room_full)
	NetworkManager.player_disconnected.connect(func(_id): _refresh_slots())
	if GameConfig.is_host:
		_refresh_slots()
		_status.text = "En attente des agentes… %d/%d" % [GameConfig.players.size(), GameConfig.get_max_players()]
	else:
		_status.text = "Connexion à la mission…"
		await get_tree().create_timer(0.5).timeout
		RoomManager.request_join_room.rpc_id(1, GameConfig.room_name,
			GameConfig.mode, GameConfig.format, GameConfig.diff, GameConfig.map, GameConfig.steam_name)

func _build() -> void:
	var bg := ColorRect.new(); bg.color = C_BG; bg.size = Vector2(1152, 720); add_child(bg)

	var panel := Panel.new()
	panel.position = Vector2(1152.0/2-300, 60); panel.size = Vector2(600, 580)
	panel.add_theme_stylebox_override("panel", _flat(C_BG, C_PINK, 2, 14)); add_child(panel)

	var title := Label.new(); title.text = "✦  SALLE D'ATTENTE  ✦"
	title.position = Vector2(0, 22); title.size = Vector2(600, 46)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", C_PINK); panel.add_child(title)

	# Info room
	var info := Label.new(); info.name = "InfoRoom"
	info.position = Vector2(0, 70); info.size = Vector2(600, 22)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_font_size_override("font_size", 13)
	info.add_theme_color_override("font_color", C_GOLD); panel.add_child(info)

	var div := ColorRect.new(); div.color = Color(C_PINK.r,C_PINK.g,C_PINK.b,0.30)
	div.position = Vector2(30, 98); div.size = Vector2(540, 1); panel.add_child(div)

	# Équipes
	var team_a_lbl := Label.new(); team_a_lbl.text = "✦ Équipe A"
	team_a_lbl.position = Vector2(30, 110); team_a_lbl.size = Vector2(240, 28)
	team_a_lbl.add_theme_font_size_override("font_size", 16)
	team_a_lbl.add_theme_color_override("font_color", C_PINK); panel.add_child(team_a_lbl)

	var team_b_lbl := Label.new(); team_b_lbl.text = "✦ Équipe B"
	team_b_lbl.position = Vector2(330, 110); team_b_lbl.size = Vector2(240, 28)
	team_b_lbl.add_theme_font_size_override("font_size", 16)
	team_b_lbl.add_theme_color_override("font_color", C_PURPLE); panel.add_child(team_b_lbl)

	_slots_a = VBoxContainer.new(); _slots_a.position = Vector2(30, 144); _slots_a.size = Vector2(240, 200); panel.add_child(_slots_a)
	_slots_b = VBoxContainer.new(); _slots_b.position = Vector2(330, 144); _slots_b.size = Vector2(240, 200); panel.add_child(_slots_b)

	_btn_lancer = Button.new(); _btn_lancer.text = "→  LANCER LA MISSION"
	_btn_lancer.position = Vector2(30, 420); _btn_lancer.size = Vector2(540, 52)
	_btn_lancer.add_theme_font_size_override("font_size", 16)
	_btn_lancer.add_theme_stylebox_override("normal", _flat(Color(0.20,0.04,0.12), C_PINK, 2, 8))
	_btn_lancer.add_theme_stylebox_override("hover",  _flat(Color(0.35,0.08,0.20), C_PINK, 2, 8))
	_btn_lancer.add_theme_color_override("font_color", C_WHITE)
	_btn_lancer.pressed.connect(_on_lancer_pressed); panel.add_child(_btn_lancer)

	var btn_quitter := Button.new(); btn_quitter.text = "← Quitter la mission"
	btn_quitter.position = Vector2(30, 484); btn_quitter.size = Vector2(540, 44)
	btn_quitter.add_theme_stylebox_override("normal", _flat(Color(0.12,0.08,0.18), C_PURPLE, 2, 8))
	btn_quitter.add_theme_color_override("font_color", C_WHITE)
	btn_quitter.pressed.connect(_on_quitter_pressed); panel.add_child(btn_quitter)

	_status = Label.new(); _status.position = Vector2(30, 536); _status.size = Vector2(540, 22)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 11)
	_status.add_theme_color_override("font_color", C_GOLD); panel.add_child(_status)

func _update_labels() -> void:
	var info := get_node_or_null("Panel/InfoRoom")
	if info: info.text = "Mission : %s  •  Map : %s  •  Format : %s" % [
		GameConfig.room_name, GameConfig.map.to_upper(), GameConfig.format]

func _on_list_updated(_rid: String, _data: Array) -> void:
	_update_labels(); _btn_lancer.visible = GameConfig.is_host; _refresh_slots()
	var total := GameConfig.get_max_players(); var current := GameConfig.players.size()
	if GameConfig.is_host:
		_btn_lancer.disabled = current < total
		_status.text = "Tout le monde est là !" if not _btn_lancer.disabled else "En attente… %d/%d" % [current, total]
	else:
		_status.text = "En attente du lancement… %d/%d" % [current, total]

func _on_room_full(_rid: String) -> void: _status.text = "Room pleine !"

func _refresh_slots() -> void:
	for c in _slots_a.get_children(): c.queue_free()
	for c in _slots_b.get_children(): c.queue_free()
	var per_team := GameConfig.get_players_per_team()
	var all_p := GameConfig.players.values()
	all_p.sort_custom(func(a,b): return a.join_order < b.join_order)
	var team_a := all_p.filter(func(p): return p.team == "a")
	var team_b := all_p.filter(func(p): return p.team == "b")
	for i in per_team:
		var l := Label.new()
		l.text = ("%s%s" % [team_a[i].name, " (vous)" if team_a[i].id == GameConfig.my_peer_id else ""]) if i < team_a.size() else "[ Slot vide ]"
		l.add_theme_color_override("font_color", C_PINK if i < team_a.size() else Color(0.45,0.35,0.55))
		_slots_a.add_child(l)
	for i in per_team:
		var l := Label.new()
		l.text = ("%s%s" % [team_b[i].name, " (vous)" if team_b[i].id == GameConfig.my_peer_id else ""]) if i < team_b.size() else "[ Slot vide ]"
		l.add_theme_color_override("font_color", C_PURPLE if i < team_b.size() else Color(0.45,0.35,0.55))
		_slots_b.add_child(l)
	if GameConfig.is_host:
		Matchmaker.update_room(GameConfig.room_name, GameConfig.players.size(), false)

func _on_lancer_pressed() -> void:
	if not GameConfig.is_host: return
	if RoomManager.rooms.has(GameConfig.room_name): RoomManager._start_game(GameConfig.room_name)
	else: _status.text = "Room introuvable !"

func _on_quitter_pressed() -> void:
	if GameConfig.is_host: Matchmaker.delete_room(GameConfig.room_name)
	NetworkManager.disconnect_from_server()
	GameConfig.reset()
	SceneLoader.goto("res://scenes/Main.tscn")

func _flat(bg: Color, border: Color, bw: int, cr: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new(); s.bg_color = bg; s.border_color = border
	s.border_width_left = bw; s.border_width_right = bw
	s.border_width_top  = bw; s.border_width_bottom = bw
	s.corner_radius_top_left = cr; s.corner_radius_top_right = cr
	s.corner_radius_bottom_left = cr; s.corner_radius_bottom_right = cr; return s
