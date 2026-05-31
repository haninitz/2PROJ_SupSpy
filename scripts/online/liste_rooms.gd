extends Control

func _lt(key: String) -> String:
	var u := get_node_or_null("/root/UIUtils")
	return u.lt(key) if u and u.has_method("lt") else key

const C_BG     := Color(0.04, 0.02, 0.10)
const C_PINK   := Color(1.00, 0.20, 0.58)
const C_PURPLE := Color(0.55, 0.15, 0.85)
const C_CYAN   := Color(0.00, 0.90, 0.88)
const C_GOLD   := Color(1.00, 0.85, 0.20)
const C_WHITE  := Color(1.00, 1.00, 1.00)

var _status    : Label
var _room_list : VBoxContainer
var _all_rooms : Array = []
var _joining := false

const REFRESH_DELAY := 5.0
var _refresh_timer  := 0.0

func _ready() -> void:
	_build()
	Matchmaker.room_list_received.connect(_on_list_received)
	Matchmaker.room_not_found.connect(_on_room_not_found)
	NetworkManager.connected_to_server.connect(_on_connected, CONNECT_ONE_SHOT)
	NetworkManager.connection_failed.connect(_on_connection_fail, CONNECT_ONE_SHOT)
	NetworkManager.connection_progress.connect(_on_connection_progress)
	_refresh()

func _process(delta: float) -> void:
	if _joining:
		return
	_refresh_timer += delta
	if _refresh_timer >= REFRESH_DELAY:
		_refresh_timer = 0.0
		Matchmaker.get_room_list()

func _refresh() -> void:
	_refresh_timer = 0.0
	_status.text   = _lt("listrooms_loading")
	for c in _room_list.get_children(): c.queue_free()
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
	title.text = _lt("listrooms_title")
	title.position = Vector2(0, 22); title.size = Vector2(640, 45)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", C_CYAN)
	panel.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(20, 74); scroll.size = Vector2(600, 430)
	panel.add_child(scroll)

	_room_list = VBoxContainer.new()
	_room_list.custom_minimum_size = Vector2(580, 0)
	scroll.add_child(_room_list)

	var hb := HBoxContainer.new()
	hb.position = Vector2(20, 514); hb.size = Vector2(600, 46)
	panel.add_child(hb)

	var btn_refresh := Button.new()
	btn_refresh.text = _lt("listrooms_refresh")
	btn_refresh.custom_minimum_size = Vector2(190, 44)
	btn_refresh.add_theme_stylebox_override("normal", _flat(Color(0,0.18,0.18), C_CYAN, 2, 8))
	btn_refresh.add_theme_color_override("font_color", C_WHITE)
	btn_refresh.pressed.connect(_refresh)
	hb.add_child(btn_refresh)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(20, 0)
	hb.add_child(spacer)

	var btn_back := Button.new()
	btn_back.text = _lt("back")
	btn_back.custom_minimum_size = Vector2(190, 44)
	btn_back.add_theme_stylebox_override("normal", _flat(Color(0.12,0.08,0.18), C_PURPLE, 2, 8))
	btn_back.add_theme_color_override("font_color", C_WHITE)
	btn_back.pressed.connect(func(): SceneLoader.goto("res://scenes/online/OnlineMenu.tscn"))
	hb.add_child(btn_back)

	_status = Label.new()
	_status.position = Vector2(20, 568); _status.size = Vector2(600, 22)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 11)
	_status.add_theme_color_override("font_color", C_GOLD)
	panel.add_child(_status)

func _on_list_received(rooms: Array) -> void:
	_all_rooms = rooms
	_populate_list(rooms)

func _populate_list(rooms: Array) -> void:
	for c in _room_list.get_children(): c.queue_free()

	var visibles := rooms.filter(func(r): return not r.get("started", false))

	if visibles.is_empty():
		_status.text = _lt("listrooms_empty")
		return

	var nb_dispo := 0

	for room in visibles:
		var rname  : String = room.get("name",        "?")
		var map_n  : String = room.get("map",         "?")
		var fmt    : String = room.get("format",      "1v1")
		var plrs   : int    = room.get("players",     0)
		var maxp   : int    = room.get("max_players", 2)
		var mode   : String = room.get("mode",        "multi")
		var diff   : String = room.get("diff",        "med")
		var ip     : String = room.get("ip",          "127.0.0.1")
		var is_full : bool = Matchmaker.is_room_full(room)
		var col : Color = Color(0.45, 0.30, 0.40) if is_full else C_PINK
		var btn := Button.new()
		btn.text = "✦  %s  |  %s  |  %s  |  %d/%d %s%s" % [
			rname, map_n.to_upper(), fmt, plrs, maxp,
			_lt("listrooms_players"),
			"    " + _lt("listrooms_full") if is_full else ""]
		btn.custom_minimum_size = Vector2(0, 52)
		btn.add_theme_font_size_override("font_size", 13)
		btn.add_theme_stylebox_override("normal", _flat(Color(0.08,0.02,0.16), col, 2, 8))
		btn.add_theme_stylebox_override("hover",  _flat(Color(0.18,0.05,0.28), col, 2, 8))
		btn.add_theme_color_override("font_color",
			C_WHITE if not is_full else Color(0.60, 0.55, 0.60))
		btn.disabled = is_full
		if not is_full:
			nb_dispo += 1
			btn.pressed.connect(func(): _join_room(rname, map_n, fmt, mode, diff, ip))
		_room_list.add_child(btn)

	_status.text = _lt("listrooms_count") % nb_dispo

func _join_room(room_name: String, map: String, format: String,
		mode: String, diff: String, ip: String) -> void:
	if _joining:
		return
	_joining = true
	_set_room_buttons_disabled(true)
	_status.text         = _lt("listrooms_connecting") % room_name
	GameConfig.room_name = room_name
	GameConfig.map       = map
	GameConfig.format    = format
	GameConfig.mode      = mode
	GameConfig.diff      = diff
	GameConfig.is_host   = false
	GameConfig.server_ip = ip     

	NetworkManager.reset_connection()

	if not NetworkManager.connected_to_server.is_connected(_on_connected):
		NetworkManager.connected_to_server.connect(_on_connected, CONNECT_ONE_SHOT)
	if not NetworkManager.connection_failed.is_connected(_on_connection_fail):
		NetworkManager.connection_failed.connect(_on_connection_fail, CONNECT_ONE_SHOT)

	NetworkManager.join_server(ip)

func _on_connected() -> void:
	_joining = false
	_status.text = _lt("listrooms_connected")
	SceneLoader.goto("res://scenes/online/SalleAttente.tscn")

func _on_connection_fail() -> void:
	_joining = false
	_set_room_buttons_disabled(false)
	_status.text = _lt("listrooms_timeout")

func _on_connection_progress(message: String) -> void:
	if _joining:
		_status.text = message

func _set_room_buttons_disabled(disabled: bool) -> void:
	for c in _room_list.get_children():
		if c is Button:
			c.disabled = disabled

func _on_room_not_found() -> void:
	_status.text = _lt("listrooms_notfound")

func _flat(bg: Color, border: Color, bw: int, cr: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg; s.border_color = border
	s.border_width_left = bw; s.border_width_right = bw
	s.border_width_top  = bw; s.border_width_bottom = bw
	s.corner_radius_top_left = cr; s.corner_radius_top_right = cr
	s.corner_radius_bottom_left = cr; s.corner_radius_bottom_right = cr
	return s
