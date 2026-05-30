extends Control
# login.gd — SupKonQuest · Totally Spies Online

func _lt(key: String) -> String:
	var u := get_node_or_null("/root/UIUtils")
	return u.lt(key) if u and u.has_method("lt") else key

const C_BG     := Color(0.04, 0.02, 0.10)
const C_PINK   := Color(1.00, 0.20, 0.58)
const C_PURPLE := Color(0.55, 0.15, 0.85)
const C_CYAN   := Color(0.00, 0.90, 0.88)
const C_GOLD   := Color(1.00, 0.85, 0.20)
const C_WHITE  := Color(1.00, 1.00, 1.00)

var _input_username : LineEdit
var _input_password : LineEdit
var _btn_login      : Button
var _status         : Label

func _ready() -> void:
	_build()
	Matchmaker.login_success.connect(_on_login_success)
	Matchmaker.auth_error.connect(_on_auth_error)
	Matchmaker.token_valid.connect(_on_token_valid)
	var saved := _load_token()
	if not saved.is_empty():
		_status.text = "Connexion automatique..."
		Matchmaker.verify_token(saved)

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = C_BG; bg.size = Vector2(1152, 720)
	add_child(bg)

	# Étoiles décoratives
	for i in range(18):
		var s := Label.new()
		s.text = ["✦","✧","★","◆"][i % 4]
		s.position = Vector2(60.0 + i * 62.0, 30.0 + sin(i * 0.8) * 20.0)
		s.add_theme_font_size_override("font_size", 10 + i % 6)
		s.modulate = [C_PINK, C_PURPLE, C_CYAN, C_GOLD][i % 4]
		s.modulate.a = 0.35
		add_child(s)

	var panel := Panel.new()
	panel.position = Vector2(1152.0/2 - 220, 720.0/2 - 250)
	panel.size     = Vector2(440, 480)
	panel.add_theme_stylebox_override("panel", _flat(C_BG, C_PINK, 2, 14))
	add_child(panel)

	# Badge
	var badge := Label.new()
	badge.text = _lt("login_badge")
	badge.position = Vector2(0, 22); badge.size = Vector2(440, 22)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 11)
	badge.add_theme_color_override("font_color", C_PURPLE)
	panel.add_child(badge)

	var title := Label.new()
	title.text = _lt("login_title")
	title.position = Vector2(0, 46); title.size = Vector2(440, 55)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", C_PINK)
	panel.add_child(title)

	var div := ColorRect.new()
	div.color = Color(C_PINK.r, C_PINK.g, C_PINK.b, 0.35)
	div.position = Vector2(30, 108); div.size = Vector2(380, 1)
	panel.add_child(div)

	_lbl(panel, _lt("login_username"), Vector2(30, 122))
	_input_username = _make_input(panel, "username", Vector2(30, 142), false)

	_lbl(panel, _lt("login_password"), Vector2(30, 200))
	_input_password = _make_input(panel, "••••••••", Vector2(30, 220), true)

	_btn_login = _btn(panel, _lt("login_btn"), Vector2(30, 295), C_PINK)
	_btn_login.pressed.connect(_on_login_pressed)

	_btn(panel, _lt("login_register"), Vector2(30, 360), C_PURPLE).pressed.connect(
		func(): SceneLoader.goto("res://scenes/online/Register.tscn"))

	_btn(panel, _lt("back"), Vector2(30, 415), Color(0.30, 0.20, 0.45)).pressed.connect(
		func(): SceneLoader.goto("res://scenes/Main.tscn"))

	_status = Label.new()
	_status.position = Vector2(30, 458); _status.size = Vector2(380, 20)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 11)
	_status.add_theme_color_override("font_color", C_GOLD)
	panel.add_child(_status)

func _flat(bg: Color, border: Color, bw: int, cr: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg; s.border_color = border
	s.border_width_left = bw; s.border_width_right = bw
	s.border_width_top  = bw; s.border_width_bottom = bw
	s.corner_radius_top_left    = cr; s.corner_radius_top_right    = cr
	s.corner_radius_bottom_left = cr; s.corner_radius_bottom_right = cr
	return s

func _lbl(parent: Control, text: String, pos: Vector2) -> void:
	var l := Label.new()
	l.text = text; l.position = pos; l.size = Vector2(380, 18)
	l.add_theme_font_size_override("font_size", 11)
	l.add_theme_color_override("font_color", Color(0.80, 0.55, 0.75))
	parent.add_child(l)

func _make_input(parent: Control, ph: String, pos: Vector2, secret: bool) -> LineEdit:
	var le := LineEdit.new()
	le.placeholder_text = ph; le.secret = secret
	le.position = pos; le.size = Vector2(380, 40)
	le.add_theme_font_size_override("font_size", 14)
	parent.add_child(le)
	return le

func _btn(parent: Control, text: String, pos: Vector2, col: Color) -> Button:
	var b := Button.new()
	b.text = text; b.position = pos; b.size = Vector2(380, 46)
	b.add_theme_font_size_override("font_size", 14)
	b.add_theme_stylebox_override("normal",
		_flat(Color(col.r*.18,col.g*.18,col.b*.18), col, 2, 8))
	b.add_theme_stylebox_override("hover",
		_flat(Color(col.r*.32,col.g*.32,col.b*.32), col, 2, 8))
	b.add_theme_color_override("font_color", C_WHITE)
	parent.add_child(b)
	return b

func _on_login_pressed() -> void:
	var u := _input_username.text.strip_edges()
	var p := _input_password.text.strip_edges()
	if u.is_empty() or p.is_empty():
		_status.text = "Remplis tous les champs !"; return
	_status.text = "Connexion en cours..."; _btn_login.disabled = true
	Matchmaker.login(u, p)

func _on_login_success(token: String, pseudo: String, username: String, wins: int, losses: int) -> void:
	GameConfig.token = token; GameConfig.username = username
	GameConfig.steam_name = pseudo; GameConfig.wins = wins; GameConfig.losses = losses
	_save_token(token)
	SceneLoader.goto("res://scenes/online/OnlineMenu.tscn")

func _on_token_valid(pseudo: String, username: String, wins: int, losses: int) -> void:
	GameConfig.token = _load_token(); GameConfig.username = username
	GameConfig.steam_name = pseudo; GameConfig.wins = wins; GameConfig.losses = losses
	SceneLoader.goto("res://scenes/online/OnlineMenu.tscn")

func _on_auth_error(message: String) -> void:
	_status.text = "Erreur : %s" % message; _btn_login.disabled = false

func _save_token(token: String) -> void:
	var f := FileAccess.open("user://token.dat", FileAccess.WRITE)
	if f: f.store_string(token); f.close()

func _load_token() -> String:
	if not FileAccess.file_exists("user://token.dat"): return ""
	var f := FileAccess.open("user://token.dat", FileAccess.READ)
	if f:
		var t := f.get_as_text().strip_edges(); f.close()
		if not "." in t: return ""
		return t
	return ""
