extends Control
# register.gd — SupKonQuest · Totally Spies Online

const C_BG     := Color(0.04, 0.02, 0.10)
const C_PINK   := Color(1.00, 0.20, 0.58)
const C_PURPLE := Color(0.55, 0.15, 0.85)
const C_CYAN   := Color(0.00, 0.90, 0.88)
const C_GOLD   := Color(1.00, 0.85, 0.20)
const C_WHITE  := Color(1.00, 1.00, 1.00)

var _input_username : LineEdit
var _input_pseudo   : LineEdit
var _input_password : LineEdit
var _input_confirm  : LineEdit
var _btn_register   : Button
var _status         : Label

func _ready() -> void:
	_build()
	Matchmaker.register_success.connect(_on_register_success)
	Matchmaker.auth_error.connect(_on_auth_error)

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = C_BG; bg.size = Vector2(1152, 720)
	add_child(bg)

	for i in range(18):
		var s := Label.new()
		s.text = ["✦","✧","★","◆"][i % 4]
		s.position = Vector2(60.0 + i * 62.0, 30.0 + sin(i * 0.8) * 20.0)
		s.add_theme_font_size_override("font_size", 10 + i % 6)
		s.modulate = [C_PINK, C_PURPLE, C_CYAN, C_GOLD][i % 4]
		s.modulate.a = 0.35
		add_child(s)

	var panel := Panel.new()
	panel.position = Vector2(1152.0/2 - 220, 720.0/2 - 290)
	panel.size     = Vector2(440, 560)
	panel.add_theme_stylebox_override("panel", _flat(C_BG, C_PURPLE, 2, 14))
	add_child(panel)

	var badge := Label.new()
	badge.text = "W.O.O.H.P · RECRUTEMENT"
	badge.position = Vector2(0, 20); badge.size = Vector2(440, 22)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 11)
	badge.add_theme_color_override("font_color", C_PINK)
	panel.add_child(badge)

	var title := Label.new()
	title.text = "✦  NOUVELLE AGENTE  ✦"
	title.position = Vector2(0, 44); title.size = Vector2(440, 52)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", C_PURPLE)
	panel.add_child(title)

	var div := ColorRect.new()
	div.color = Color(C_PURPLE.r, C_PURPLE.g, C_PURPLE.b, 0.35)
	div.position = Vector2(30, 103); div.size = Vector2(380, 1)
	panel.add_child(div)

	_lbl(panel, "Nom d'utilisateur", Vector2(30, 114))
	_input_username = _make_input(panel, "agent007", Vector2(30, 132), false)

	_lbl(panel, "Nom de code (affiché)", Vector2(30, 184))
	_input_pseudo = _make_input(panel, "Clover", Vector2(30, 202), false)

	_lbl(panel, "Mot de passe secret", Vector2(30, 254))
	_input_password = _make_input(panel, "••••••••", Vector2(30, 272), true)

	_lbl(panel, "Confirmer le mot de passe", Vector2(30, 324))
	_input_confirm = _make_input(panel, "••••••••", Vector2(30, 342), true)

	_btn_register = _btn(panel, "→  REJOINDRE W.O.O.H.P", Vector2(30, 400), C_PURPLE)
	_btn_register.pressed.connect(_on_register_pressed)

	_btn(panel, "← Retour connexion", Vector2(30, 458), Color(0.30, 0.20, 0.45)).pressed.connect(
		func(): SceneLoader.goto("res://scenes/online/Login.tscn"))

	_status = Label.new()
	_status.position = Vector2(30, 515); _status.size = Vector2(380, 20)
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
	l.add_theme_color_override("font_color", Color(0.75, 0.50, 0.90))
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

func _on_register_pressed() -> void:
	var u := _input_username.text.strip_edges()
	var p := _input_pseudo.text.strip_edges()
	var pw := _input_password.text.strip_edges()
	var co := _input_confirm.text.strip_edges()
	if u.is_empty() or p.is_empty() or pw.is_empty():
		_status.text = "Remplis tous les champs !"; return
	if u.length() < 3:
		_status.text = "Nom trop court (min 3 caractères) !"; return
	if pw.length() < 6:
		_status.text = "Mot de passe trop court (min 6) !"; return
	if pw != co:
		_status.text = "Les mots de passe ne correspondent pas !"; return
	_status.text = "Création du compte..."; _btn_register.disabled = true
	Matchmaker.register(u, pw, p)

func _on_register_success(token: String, pseudo: String, username: String) -> void:
	GameConfig.token = token; GameConfig.username = username; GameConfig.steam_name = pseudo
	var f := FileAccess.open("user://token.dat", FileAccess.WRITE)
	if f: f.store_string(token); f.close()
	_status.text = "Bienvenue agente %s !" % pseudo
	await get_tree().create_timer(1.0).timeout
	SceneLoader.goto("res://scenes/online/OnlineMenu.tscn")

func _on_auth_error(message: String) -> void:
	_status.text = "Erreur : %s" % message; _btn_register.disabled = false