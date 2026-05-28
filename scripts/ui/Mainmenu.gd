class_name MainMenu
extends Node
# =============================================================================
#  Mainmenu.gd -- SupSpy · Totally Spies Edition
#  Menu : SupSpy | AI VS TOI | MULTIJOUEUR | Classement | Paramètres | Quitter
#  AI  : choisir ta team (nom) + niveau IA → l'IA prend une team différente
#  Multi : choisir ta team (nom) → Créer mission ou Rejoindre
# =============================================================================

signal map_selected(map_index: int)
signal mode_selected(is_ai: bool, difficulty: String)
signal squads_selected(squad1: String, squad2: String)

var main_menu         : Panel
var setup_screen      : Panel
var map_screen        : Panel
var mode_screen       : Panel
var difficulty_screen : Panel
var squad_screen      : Panel

var title_label : Label
var _sparkles   : Array = []
var _parent     : Node
var U           : Node

# ── État sélection ────────────────────────────────────────────────────────────
var _ai_difficulty  : String = "medium"
var _player_team_idx : int   = 0   # index team joueur
var _context        : String = ""  # "ai" ou "multi"

# ── Écrans inline ─────────────────────────────────────────────────────────────
var _ai_screen    : Panel = null
var _multi_screen : Panel = null
var _play_screen  : Panel = null

# ── Teams (fallback si GameManager absent) ────────────────────────────────────
const FALLBACK_TEAMS := [
	{"name": "Neon Squad",    "color": Color(0.0,  1.0,  1.0 )},
	{"name": "Shadow Squad",  "color": Color(0.55, 0.55, 0.70)},
	{"name": "Crimson Squad", "color": Color(1.0,  0.0,  0.0 )},
	{"name": "Cyber Squad",   "color": Color(0.0,  0.8,  0.27)},
	{"name": "Phantom Squad", "color": Color(0.55, 0.0,  1.0 )},
	{"name": "Eclipse Squad", "color": Color(0.30, 0.45, 0.80)},
	{"name": "Nova Squad",    "color": Color(1.0,  0.55, 0.0 )},
	{"name": "Ghost Squad",   "color": Color(0.90, 0.90, 0.90)},
]


func initialize(parent: Node, u: Node) -> void:
	U = u
	_parent = parent
	_build_main_menu()
	_build_play_screen()
	_build_ai_screen()
	_build_multi_screen()
	_build_map_screen()
	_build_compat_screens()


func _rebuild() -> void:
	for child in [main_menu, setup_screen, map_screen,
			mode_screen, difficulty_screen, squad_screen,
			_ai_screen, _multi_screen, _play_screen]:
		if is_instance_valid(child):
			child.queue_free()
	_sparkles.clear()
	_ai_screen    = null
	_multi_screen = null
	_build_main_menu()
	_build_play_screen()
	_build_ai_screen()
	_build_multi_screen()
	_build_map_screen()
	_build_compat_screens()
	main_menu.visible = true


func animate(t: float) -> void:
	if main_menu and main_menu.visible:
		if title_label:
			var r : float = 0.88 + sin(t * 1.4) * 0.12
			var b : float = 0.65 + sin(t * 1.4 + 0.9) * 0.15
			title_label.modulate = Color(r, 0.20, b)
		for i in range(_sparkles.size()):
			var star : Label = _sparkles[i]
			if not is_instance_valid(star): continue
			var ph : float = float(i) * 0.72
			star.position.y = star.get_meta("by") + sin(t * 0.9 + ph) * 12.0
			star.position.x = star.get_meta("bx") + cos(t * 0.6 + ph) * 6.0
			star.modulate.a = (sin(t * 1.8 + ph) + 1.0) * 0.45 + 0.1
			star.rotation   = t * 0.4 + ph


func _get_teams() -> Array:
	var gm : Node = _parent.get_node_or_null("/root/GameManager")
	if gm and "available_teams" in gm:
		return gm.available_teams
	return FALLBACK_TEAMS


# =============================================================================
#  MENU PRINCIPAL
# =============================================================================
func _build_main_menu() -> void:
	main_menu = U.make_screen()
	_parent.add_child(main_menu)

	main_menu.add_child(_GridNode.new())

	var band_colors : Array[Color] = [U.C_PINK, U.C_CYAN, U.C_GOLD, U.C_PURPLE, U.C_PINK]
	for i in range(5):
		var s := ColorRect.new()
		s.color    = Color(band_colors[i].r, band_colors[i].g, band_colors[i].b, 0.04)
		s.size     = Vector2(300, 720)
		s.position = Vector2(i * 240 - 60, 0)
		s.rotation = deg_to_rad(8.0)
		main_menu.add_child(s)

	# Titre
	title_label          = Label.new()
	title_label.text     = "SupSpy"
	title_label.position = Vector2(0, 190)
	title_label.size     = Vector2(U.WIN_W, 110)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 82)
	title_label.modulate = U.C_PINK
	main_menu.add_child(title_label)

	var sub := Label.new()
	sub.text = "W.O.O.H.P  ·  TOTALLY SPIES EDITION"
	sub.position = Vector2(0, 306)
	sub.size     = Vector2(U.WIN_W, 24)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 12)
	sub.add_theme_color_override("font_color", Color(U.C_PURPLE.r, U.C_PURPLE.g, U.C_PURPLE.b, 0.80))
	main_menu.add_child(sub)

	var d1 := ColorRect.new()
	d1.color    = U.C_PINK
	d1.position = Vector2(U.WIN_W / 2.0 - 220, 338)
	d1.size     = Vector2(440, 2)
	main_menu.add_child(d1)

	# ── Bouton Jouer ────────────────────────────────────────────────────────
	var play_btn : Button = U.btn("  ▶  JOUER",
		Vector2(U.WIN_W / 2.0 - 180, 356), Vector2(360, 58), 22)
	play_btn.add_theme_stylebox_override("normal", U.flat(Color(0.28,0.05,0.18), U.C_PINK, 2, 12))
	play_btn.add_theme_stylebox_override("hover",  U.flat(Color(0.42,0.10,0.28), U.C_PINK, 2, 12))
	play_btn.add_theme_color_override("font_color", U.C_WHITE)
	play_btn.pressed.connect(func(): UIUtils.goto(main_menu, _play_screen))
	main_menu.add_child(play_btn)

	# ── Boutons secondaires ─────────────────────────────────────────────────
	var sec_data : Array = [
		{"t": U.lt("leaderboard"), "col": U.C_PURPLE,             "fn": func(): _open_leaderboard()},
		{"t": U.lt("settings"),    "col": Color(0.55, 0.50, 0.75),"fn": func(): _open_settings()},
		{"t": U.lt("quit"),        "col": Color(0.70, 0.20, 0.20),"fn": func(): _parent.get_tree().quit()},
	]
	for i in range(sec_data.size()):
		var sd : Dictionary = sec_data[i]
		var b : Button = U.btn("  " + sd["t"],
			Vector2(U.WIN_W / 2.0 - 180, 430 + i * 50), Vector2(360, 42), 15)
		b.add_theme_stylebox_override("normal",
			U.flat(Color(sd["col"].r*0.12, sd["col"].g*0.12, sd["col"].b*0.12), sd["col"], 1, 8))
		b.add_theme_stylebox_override("hover",
			U.flat(Color(sd["col"].r*0.25, sd["col"].g*0.25, sd["col"].b*0.25), sd["col"], 2, 8))
		b.add_theme_color_override("font_color", U.C_WHITE)
		b.pressed.connect(sd["fn"])
		main_menu.add_child(b)

	# Boutons langue
	var lang_codes  : Array[String] = ["fr", "en", "es"]
	var lang_labels : Array[String] = ["FR", "EN", "ES"]
	for i in range(3):
		var lc : String = lang_codes[i]
		var active : bool = lc == U.get_lang()
		var lb : Button = U.btn(lang_labels[i], Vector2(U.WIN_W - 195 + i * 64, 18), Vector2(58, 32), 11)
		lb.add_theme_stylebox_override("normal",
			U.flat(Color(0.35,0.08,0.25) if active else Color(0.12,0.05,0.12),
				   U.C_PINK if active else Color(0.40,0.15,0.35), 2, 6))
		lb.pressed.connect(func(captured_lc: String = lc):
			var lang : Node = _parent.get_node_or_null("/root/Lang")
			if lang: lang.current = captured_lc
			_rebuild())
		main_menu.add_child(lb)

	# Étoiles
	var shapes   : Array[String] = ["*", "+", "x", "o", "#"]
	var s_colors : Array[Color]  = [U.C_PINK, U.C_CYAN, U.C_GOLD, U.C_PURPLE]
	for i in range(18):
		var star := Label.new()
		star.text = shapes[i % shapes.size()]
		star.add_theme_font_size_override("font_size", 8 + (i % 5) * 4)
		star.modulate = s_colors[i % s_colors.size()]
		var bx : float = float((i * 57 + 30) % U.WIN_W)
		var by : float = float((i * 83 + 40) % 680)
		star.position = Vector2(bx, by)
		star.set_meta("bx", bx)
		star.set_meta("by", by)
		main_menu.add_child(star)
		_sparkles.append(star)

	var ft : Label = U.lbl(U.lt("footer"), Vector2(0, 698), 10, Color(0.40, 0.30, 0.55))
	ft.size = Vector2(U.WIN_W, 20)
	ft.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_menu.add_child(ft)


func _build_play_screen() -> void:
	_play_screen = U.make_screen(false)
	_parent.add_child(_play_screen)
	U.add_header(_play_screen, "JOUER", U.C_PINK)

	# Bloc AI VS TOI
	var ai_block := Panel.new()
	ai_block.position = Vector2(55, 150)
	ai_block.size     = Vector2(490, 200)
	ai_block.add_theme_stylebox_override("panel", U.flat(Color(0.10,0.03,0.20), U.C_PINK, 2, 12))
	_play_screen.add_child(ai_block)

	var ai_lbl := Label.new()
	ai_lbl.text = "🤖  AI VS TOI"
	ai_lbl.position = Vector2(20, 18)
	ai_lbl.add_theme_font_size_override("font_size", 22)
	ai_lbl.add_theme_color_override("font_color", U.C_PINK)
	ai_block.add_child(ai_lbl)

	var ai_desc := Label.new()
	ai_desc.text = "Affronte une IA · Choisis ton équipe et la difficulté"
	ai_desc.position = Vector2(20, 56)
	ai_desc.size = Vector2(450, 28)
	ai_desc.add_theme_font_size_override("font_size", 13)
	ai_desc.add_theme_color_override("font_color", Color(0.80, 0.60, 0.85))
	ai_block.add_child(ai_desc)

	var ai_btn : Button = U.btn("→  LANCER", Vector2(20, 130), Vector2(450, 52), 17)
	ai_btn.add_theme_stylebox_override("normal", U.flat(Color(0.28,0.05,0.18), U.C_PINK, 2, 8))
	ai_btn.add_theme_stylebox_override("hover",  U.flat(Color(0.42,0.10,0.28), U.C_PINK, 2, 8))
	ai_btn.add_theme_color_override("font_color", U.C_WHITE)
	ai_btn.pressed.connect(func():
		_context = "ai"
		UIUtils.goto(_play_screen, _ai_screen))
	ai_block.add_child(ai_btn)

	# Bloc MULTIJOUEUR
	var mp_block := Panel.new()
	mp_block.position = Vector2(607, 150)
	mp_block.size     = Vector2(490, 200)
	mp_block.add_theme_stylebox_override("panel", U.flat(Color(0.03,0.10,0.20), U.C_CYAN, 2, 12))
	_play_screen.add_child(mp_block)

	var mp_lbl := Label.new()
	mp_lbl.text = "🌐  MULTIJOUEUR"
	mp_lbl.position = Vector2(20, 18)
	mp_lbl.add_theme_font_size_override("font_size", 22)
	mp_lbl.add_theme_color_override("font_color", U.C_CYAN)
	mp_block.add_child(mp_lbl)

	var mp_desc := Label.new()
	mp_desc.text = "Joue en ligne · Crée ou rejoins une mission"
	mp_desc.position = Vector2(20, 56)
	mp_desc.size = Vector2(450, 28)
	mp_desc.add_theme_font_size_override("font_size", 13)
	mp_desc.add_theme_color_override("font_color", Color(0.60, 0.80, 0.90))
	mp_block.add_child(mp_desc)

	var mp_btn : Button = U.btn("→  EN MISSION", Vector2(20, 130), Vector2(450, 52), 17)
	mp_btn.add_theme_stylebox_override("normal", U.flat(Color(0.05,0.18,0.28), U.C_CYAN, 2, 8))
	mp_btn.add_theme_stylebox_override("hover",  U.flat(Color(0.10,0.28,0.42), U.C_CYAN, 2, 8))
	mp_btn.add_theme_color_override("font_color", U.C_WHITE)
	mp_btn.pressed.connect(func():
		_context = "multi"
		UIUtils.goto(_play_screen, _multi_screen))
	mp_block.add_child(mp_btn)

	_play_screen.add_child(U.back_btn(func(): UIUtils.goto(_play_screen, main_menu)))


# =============================================================================
#  ÉCRAN AI VS TOI  — choisir team joueur + difficulté IA
# =============================================================================
func _build_ai_screen() -> void:
	_ai_screen = U.make_screen(false)
	_parent.add_child(_ai_screen)
	U.add_header(_ai_screen, "AI VS TOI", U.C_PINK)

	var teams : Array = _get_teams()

	# Indicateur team sélectionnée
	var sel_label := Label.new()
	sel_label.name = "AISelLabel"
	sel_label.text = "Ton équipe : " + teams[0]["name"]
	sel_label.position = Vector2(55, 124)
	sel_label.size = Vector2(U.WIN_W - 110, 22)
	sel_label.add_theme_font_size_override("font_size", 13)
	sel_label.add_theme_color_override("font_color", U.C_GOLD)
	_ai_screen.add_child(sel_label)

	# Grille des teams (2 rangées × 4)
	_build_team_grid(_ai_screen, teams, Vector2(55, 148), "ai", sel_label)

	# Séparateur
	var div := ColorRect.new()
	div.color    = Color(U.C_CYAN.r, U.C_CYAN.g, U.C_CYAN.b, 0.30)
	div.position = Vector2(55, 346)
	div.size     = Vector2(U.WIN_W - 110, 1)
	_ai_screen.add_child(div)

	# Niveau IA
	_ai_screen.add_child(U.lbl("Niveau de l'IA :", Vector2(55, 358), 13, U.C_CYAN))
	var diff_label := Label.new()
	diff_label.name = "DiffLabel"
	diff_label.text = "Medium"
	diff_label.position = Vector2(280, 358)
	diff_label.add_theme_font_size_override("font_size", 13)
	diff_label.add_theme_color_override("font_color", U.C_GOLD)
	_ai_screen.add_child(diff_label)

	var diff_data : Array = [
		{"t": "Facile",   "col": U.C_GREEN, "k": "easy"},
		{"t": "Medium",   "col": U.C_GOLD,  "k": "medium"},
		{"t": "Difficile","col": U.C_PINK,  "k": "hard"},
	]
	for i in range(3):
		var dd : Dictionary = diff_data[i]
		var db : Button = U.btn(dd["t"], Vector2(55 + i * 136, 382), Vector2(126, 40), 14)
		db.add_theme_stylebox_override("normal",
			U.flat(Color(dd["col"].r*0.18, dd["col"].g*0.18, dd["col"].b*0.18), dd["col"], 2, 6))
		db.add_theme_stylebox_override("hover",
			U.flat(Color(dd["col"].r*0.32, dd["col"].g*0.32, dd["col"].b*0.32), dd["col"], 2, 6))
		db.add_theme_color_override("font_color", U.C_WHITE)
		var dk : String = dd["k"]
		var dt : String = dd["t"]
		db.pressed.connect(func():
			_ai_difficulty = dk
			diff_label.text = dt)
		_ai_screen.add_child(db)

	# Bouton Suivant → map
	var next_btn : Button = U.btn("Suivant  →  Choisir la map",
		Vector2(U.WIN_W - 380, 638), Vector2(320, 50), 16)
	next_btn.add_theme_stylebox_override("normal", U.flat(Color(0.28,0.05,0.18), U.C_PINK, 2, 10))
	next_btn.add_theme_stylebox_override("hover",  U.flat(Color(0.42,0.10,0.28), U.C_PINK, 2, 10))
	next_btn.add_theme_color_override("font_color", U.C_WHITE)
	next_btn.pressed.connect(_on_ai_next)
	_ai_screen.add_child(next_btn)
	_ai_screen.add_child(U.back_btn(func(): UIUtils.goto(_ai_screen, _play_screen)))


func _on_ai_next() -> void:
	var teams : Array = _get_teams()
	var player_name : String = teams[_player_team_idx]["name"]
	# L'IA prend la team suivante (différente du joueur)
	var ai_idx : int = (_player_team_idx + 1) % teams.size()
	var ai_name : String = teams[ai_idx]["name"]
	mode_selected.emit(true, _ai_difficulty)
	squads_selected.emit(player_name, ai_name)
	UIUtils.goto(_ai_screen, map_screen)


# =============================================================================
#  ÉCRAN MULTIJOUEUR — choisir team (nom) → Créer ou Rejoindre
# =============================================================================
func _build_multi_screen() -> void:
	_multi_screen = U.make_screen(false)
	_parent.add_child(_multi_screen)
	U.add_header(_multi_screen, "MISSION EN LIGNE", U.C_CYAN)

	var teams : Array = _get_teams()

	# Indicateur team sélectionnée
	var sel_label := Label.new()
	sel_label.name = "MPSelLabel"
	sel_label.text = "Ton agent : " + teams[0]["name"]
	sel_label.position = Vector2(55, 124)
	sel_label.size = Vector2(U.WIN_W - 110, 22)
	sel_label.add_theme_font_size_override("font_size", 13)
	sel_label.add_theme_color_override("font_color", U.C_GOLD)
	_multi_screen.add_child(sel_label)

	# Grille des teams
	_build_team_grid(_multi_screen, teams, Vector2(55, 148), "multi", sel_label)

	# Séparateur
	var div := ColorRect.new()
	div.color    = Color(U.C_PINK.r, U.C_PINK.g, U.C_PINK.b, 0.30)
	div.position = Vector2(55, 346)
	div.size     = Vector2(U.WIN_W - 110, 1)
	_multi_screen.add_child(div)

	# Statut
	var status_lbl := Label.new()
	status_lbl.name = "MPStatus"
	status_lbl.position = Vector2(55, 610)
	status_lbl.size = Vector2(700, 22)
	status_lbl.add_theme_font_size_override("font_size", 11)
	status_lbl.add_theme_color_override("font_color", U.C_GOLD)
	_multi_screen.add_child(status_lbl)

	# Bouton Créer
	var create_btn : Button = U.btn("✦  CRÉER UNE MISSION",
		Vector2(55, 366), Vector2(490, 60), 18)
	create_btn.add_theme_stylebox_override("normal", U.flat(Color(0.20,0.04,0.12), U.C_PINK, 2, 10))
	create_btn.add_theme_stylebox_override("hover",  U.flat(Color(0.35,0.08,0.20), U.C_PINK, 2, 10))
	create_btn.add_theme_color_override("font_color", U.C_WHITE)
	create_btn.pressed.connect(_on_multi_create)
	_multi_screen.add_child(create_btn)

	var desc_c := Label.new()
	desc_c.text = "Héberge une partie — les autres agents pourront te rejoindre"
	desc_c.position = Vector2(55, 432)
	desc_c.add_theme_font_size_override("font_size", 11)
	desc_c.add_theme_color_override("font_color", Color(0.70, 0.50, 0.75))
	_multi_screen.add_child(desc_c)

	# Bouton Rejoindre
	var join_btn : Button = U.btn("⟳  REJOINDRE UNE MISSION",
		Vector2(55, 458), Vector2(490, 60), 18)
	join_btn.add_theme_stylebox_override("normal", U.flat(Color(0.04,0.12,0.20), U.C_CYAN, 2, 10))
	join_btn.add_theme_stylebox_override("hover",  U.flat(Color(0.08,0.20,0.35), U.C_CYAN, 2, 10))
	join_btn.add_theme_color_override("font_color", U.C_WHITE)
	join_btn.pressed.connect(_on_multi_join)
	_multi_screen.add_child(join_btn)

	var desc_j := Label.new()
	desc_j.text = "Parcours les missions disponibles et rejoins une partie"
	desc_j.position = Vector2(55, 524)
	desc_j.add_theme_font_size_override("font_size", 11)
	desc_j.add_theme_color_override("font_color", Color(0.50, 0.70, 0.80))
	_multi_screen.add_child(desc_j)

	_multi_screen.add_child(U.back_btn(func(): UIUtils.goto(_multi_screen, _play_screen)))


func _on_multi_create() -> void:
	var teams : Array = _get_teams()
	var agent_name : String = teams[_player_team_idx]["name"]
	GameConfig.steam_name = agent_name
	GameConfig.username   = agent_name
	GameConfig.is_host    = true
	GameConfig.mode       = "multi"
	GameConfig.format     = "1v1"
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	NetworkManager.create_server()
	SceneLoader.goto("res://scenes/online/ChoixFormat.tscn")


func _on_multi_join() -> void:
	var teams : Array = _get_teams()
	var agent_name : String = teams[_player_team_idx]["name"]
	GameConfig.steam_name = agent_name
	GameConfig.username   = agent_name
	GameConfig.is_host    = false
	SceneLoader.goto("res://scenes/online/ListeRooms.tscn")


# =============================================================================
#  GRILLE DES TEAMS (partagée AI + Multi)
# =============================================================================
func _build_team_grid(parent: Panel, teams: Array, origin: Vector2,
		ctx: String, sel_label: Label) -> void:
	for i in range(mini(teams.size(), 8)):
		var team : Dictionary = teams[i]
		var raw_col : Color   = team["color"]
		# Évite les couleurs trop sombres (Shadow Squad)
		var col : Color = raw_col
		if raw_col.r < 0.15 and raw_col.g < 0.15 and raw_col.b < 0.20:
			col = Color(0.45, 0.45, 0.70)

		var col_x : int = i % 4
		var col_y : int = i / 4
		var pos : Vector2 = origin + Vector2(col_x * 258, col_y * 50)

		var tb : Button = U.btn(team["name"], pos, Vector2(248, 42), 13)
		tb.add_theme_stylebox_override("normal",
			U.flat(Color(col.r*0.15, col.g*0.15, col.b*0.15), col, 2, 6))
		tb.add_theme_stylebox_override("hover",
			U.flat(Color(col.r*0.30, col.g*0.30, col.b*0.30), col, 2, 6))
		tb.add_theme_color_override("font_color", U.C_WHITE)

		var ti : int    = i
		var tn : String = team["name"]
		tb.pressed.connect(func():
			_player_team_idx = ti
			if ctx == "ai":
				sel_label.text = "Ton équipe : " + tn
			else:
				sel_label.text = "Ton agent : " + tn)
		parent.add_child(tb)


# =============================================================================
#  MAP SCREEN
# =============================================================================
func _build_map_screen() -> void:
	map_screen = U.make_screen(false)
	_parent.add_child(map_screen)
	U.add_header(map_screen, U.lt("map_title"), U.C_GOLD)

	var map_data : Array = [
		{"name": "Beverly Hills  (Clover)", "desc": "Urbain · Rivière · Pont",     "col": U.C_PINK},
		{"name": "Jungle Techno  (Sam)",    "desc": "Forêt dense · Hauts revenus", "col": U.C_GREEN},
		{"name": "Île Tropicale  (Alex)",   "desc": "Île · Océan · Ports",         "col": U.C_CYAN},
	]

	for i in range(map_data.size()):
		var md : Dictionary = map_data[i]
		var card := Panel.new()
		card.position = Vector2(55, 140 + i * 148)
		card.size     = Vector2(U.WIN_W - 110, 130)
		card.add_theme_stylebox_override("panel",
			U.flat(Color(md["col"].r*0.10, md["col"].g*0.10, md["col"].b*0.10), md["col"], 1, 10))
		map_screen.add_child(card)
		card.add_child(U.lbl("0%d" % (i+1), Vector2(18, 28), 32,
			Color(md["col"].r, md["col"].g, md["col"].b, 0.30)))
		card.add_child(U.lbl(md["name"], Vector2(70, 22), 22, U.C_WHITE))
		card.add_child(U.lbl(md["desc"], Vector2(70, 52), 13,
			Color(md["col"].r, md["col"].g, md["col"].b, 0.85)))
		var play : Button = U.btn(U.lt("play_btn"),
			Vector2(card.size.x - 130, 40), Vector2(110, 50), 16)
		play.add_theme_stylebox_override("normal",
			U.flat(Color(md["col"].r*0.22, md["col"].g*0.22, md["col"].b*0.22), md["col"], 2, 8))
		play.add_theme_stylebox_override("hover",
			U.flat(Color(md["col"].r*0.40, md["col"].g*0.40, md["col"].b*0.40), md["col"], 2, 8))
		play.add_theme_color_override("font_color", U.C_WHITE)
		play.pressed.connect(func(idx: int = i):
			map_screen.visible = false
			map_selected.emit(idx))
		card.add_child(play)

	map_screen.add_child(U.back_btn(func(): UIUtils.goto(map_screen, _ai_screen)))


func hide_map_screen() -> void:
	if map_screen: map_screen.visible = false


# =============================================================================
#  OVERLAYS (Classement, Paramètres)
# =============================================================================
func _open_leaderboard() -> void:
	_open_overlay(U.lt("leaderboard"), U.C_PURPLE, func(scr: Panel):
		var headers : Array[String] = ["#", U.lt("player_col"), "ELO", U.lt("wins"), U.lt("losses")]
		var cols_x  : Array[int]    = [55, 110, 380, 550, 680]
		for i in range(headers.size()):
			scr.add_child(U.lbl(headers[i], Vector2(cols_x[i], 148), 13, U.C_PURPLE))
		var div := ColorRect.new()
		div.color    = Color(U.C_PURPLE.r, U.C_PURPLE.g, U.C_PURPLE.b, 0.5)
		div.position = Vector2(55, 168); div.size = Vector2(U.WIN_W - 110, 1)
		scr.add_child(div)
		var rows : Array = [
			["1","Champion","1850","42","8"],
			["2","Stratège","1720","35","12"],
			["3","Conquérant","1680","30","10"],
		]
		for r in range(rows.size()):
			for c in range(rows[r].size()):
				scr.add_child(U.lbl(rows[r][c], Vector2(cols_x[c], 184 + r * 44), 14,
					U.C_GOLD if r == 0 else Color(0.88, 0.85, 0.92))))


func _open_settings() -> void:
	_open_overlay(U.lt("settings"), Color(0.55, 0.50, 0.75), func(scr: Panel):
		scr.add_child(U.lbl(U.lt("lang_title") + " :", Vector2(55, 130), 13, U.C_PINK))
		var lang_codes  : Array[String] = ["fr", "en", "es"]
		var lang_labels : Array[String] = ["Français", "English", "Español"]
		for i in range(3):
			var lc : String = lang_codes[i]
			var lb : Button = U.btn(lang_labels[i], Vector2(55 + i * 148, 154), Vector2(134, 36), 13)
			lb.add_theme_stylebox_override("normal", U.flat(Color(0.12,0.05,0.18), U.C_PINK, 2, 8))
			lb.add_theme_color_override("font_color", U.C_WHITE)
			lb.pressed.connect(func(captured_lc: String = lc):
				var lang : Node = _parent.get_node_or_null("/root/Lang")
				if lang: lang.current = captured_lc
				_rebuild())
			scr.add_child(lb)
		scr.add_child(U.lbl(U.lt("volume") + " :", Vector2(55, 210), 13, U.C_CYAN))
		var sv : HSlider = HSlider.new()
		sv.position = Vector2(55, 232); sv.size = Vector2(350, 22)
		sv.min_value = 0; sv.max_value = 100; sv.value = 80
		sv.value_changed.connect(func(v: float):
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(v / 100.0)))
		scr.add_child(sv))


func _open_overlay(title: String, col: Color, builder: Callable) -> void:
	main_menu.visible = false
	var scr : Panel = U.make_screen(true)
	_parent.add_child(scr)
	U.add_header(scr, title, col)
	builder.call(scr)
	scr.add_child(U.back_btn(func():
		scr.queue_free()
		main_menu.visible = true))


# =============================================================================
#  COMPAT (écrans vides pour les getters de UI.gd)
# =============================================================================
func _build_compat_screens() -> void:
	setup_screen      = U.make_screen(false); _parent.add_child(setup_screen)
	mode_screen       = U.make_screen(false); _parent.add_child(mode_screen)
	difficulty_screen = U.make_screen(false); _parent.add_child(difficulty_screen)
	squad_screen      = U.make_screen(false); _parent.add_child(squad_screen)


# =============================================================================
#  Grille de fond
# =============================================================================
class _GridNode extends Node2D:
	func _draw() -> void:
		var col := Color(1.00, 0.20, 0.58, 0.04)
		var x : int = 0
		while x <= 1152:
			draw_line(Vector2(x, 0), Vector2(x, 720), col, 1.0)
			x += 48
		var y : int = 0
		while y <= 720:
			draw_line(Vector2(0, y), Vector2(1152, y), col, 1.0)
			y += 48
		var dc := Color(0.00, 0.90, 0.88, 0.025)
		var i : int = 0
		while i < 1900:
			draw_line(Vector2(i, 0), Vector2(0, i), dc, 1.0)
			i += 96