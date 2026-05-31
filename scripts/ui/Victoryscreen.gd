class_name VictoryScreen
extends Node

var U : Node
signal turn_confirmed

# ── Écran victoire ────────────────────────────────────────────────────────────
var victory_screen   : Panel
var victory_title    : Label
var victory_winner   : Label
var victory_sparkles : Array = []
var _confetti_pieces : Array = []
var _end_layer: CanvasLayer = null

# ── Écran défaite ─────────────────────────────────────────────────────────────
var defeat_screen      : Panel
var _defeat_title_lbl  : Label
var _defeat_badge_lbl  : Label
var _defeat_sub_lbl    : Label
var _defeat_try_btn    : Button
var _defeat_quit_btn   : Button
# ── Écran victoire (labels dynamiques) ───────────────────────────────────────
var _victory_badge_lbl : Label
var _victory_sub_lbl   : Label
var _victory_play_btn  : Button
var _victory_quit_btn  : Button

# ── Interne ───────────────────────────────────────────────────────────────────
var _parent : Node


func initialize(parent: Node, u: Node) -> void:
	U       = u
	_parent = parent
	_build_victory_screen()
	_build_defeat_screen()


# ─────────────────────────────────────────────────────────────────────────────
#  ANIMATION
# ─────────────────────────────────────────────────────────────────────────────

func animate(t: float) -> void:
	if victory_screen and victory_screen.visible:
		_animate_victory(t)


func _animate_victory(t: float) -> void:
	if victory_title:
		var p : float = 1.0 + sin(t * 2.5) * 0.045
		victory_title.scale = Vector2(p, p)

	for i in range(victory_sparkles.size()):
		var star : Label = victory_sparkles[i]
		if not is_instance_valid(star):
			continue
		var angle : float = t * 1.1 + float(i) * TAU / float(victory_sparkles.size())
		star.position = Vector2(
			U.WIN_W / 2.0 + cos(angle) * 320.0 - 14,
			310.0 + sin(angle) * 160.0 - 14)
		star.modulate.a = (sin(t * 3.5 + float(i)) + 1.0) * 0.55

	for c in _confetti_pieces:
		var lbl : Label = c["label"]
		if not is_instance_valid(lbl):
			continue
		var yf : float = fmod(t * c["speed"] * 0.018 + c["phase"], 1.15)
		lbl.position.x = c["xb"] + sin(t * c["drift"] * 0.5 + c["xb"] * 0.008) * 30.0
		lbl.position.y = yf * 780.0 - 30.0
		lbl.rotation   = t * 0.8 + c["phase"]
		lbl.modulate.a = clamp(0.85 - max(0.0, lbl.position.y - 680.0) / 80.0, 0.0, 1.0)


# ─────────────────────────────────────────────────────────────────────────────
#  API PUBLIQUE
# ─────────────────────────────────────────────────────────────────────────────

func show_victory(winner_name: String, stats: Dictionary = {}) -> void:
	# Vérifie si c'est le joueur LOCAL qui gagne
	# On cherche local_player_id dans Main pour trouver le bon joueur
	var gm   = _parent.get_node_or_null("/root/GameManager")
	var main = _parent.get_tree().get_first_node_in_group("main_node")
	var local_player_id : int = 1
	if main and "local_player_id" in main:
		local_player_id = main.local_player_id

	var local_name : String = ""
	if gm and gm.has_method("find_player_by_id"):
		var lp = gm.find_player_by_id(local_player_id)
		if lp:
			local_name = lp.player_name

	if local_name != "" and local_name != winner_name:
		show_defeat(winner_name, stats)
		return

	victory_winner.text     = winner_name
	victory_winner.modulate = U.C_PINK
	# Mise à jour texte selon langue courante
	if victory_title:
		victory_title.text = U.lt("victory_scr_title")
	if _victory_sub_lbl:
		_victory_sub_lbl.text = U.lt("agent_secured")
	if _victory_play_btn:
		_victory_play_btn.text = U.lt("play_again")
	if _victory_quit_btn:
		_victory_quit_btn.text = U.lt("quit_btn")

	_fill_stats_panel(victory_screen, winner_name, stats, true)

	_parent.move_child(victory_screen, _parent.get_child_count() - 1)
	victory_screen.visible = true
	Sound.play("victory")


func show_defeat(winner_name: String, stats: Dictionary = {}) -> void:
	# Mise à jour texte selon langue courante
	if _defeat_title_lbl:
		_defeat_title_lbl.text = U.lt("defeat_scr_title")
	if _defeat_sub_lbl:
		_defeat_sub_lbl.text = U.lt("territory_lost")
	if _defeat_try_btn:
		_defeat_try_btn.text = U.lt("try_again")
	if _defeat_quit_btn:
		_defeat_quit_btn.text = U.lt("quit_btn")

	_parent.move_child(defeat_screen, _parent.get_child_count() - 1)
	defeat_screen.visible = true

	var sub : Label = defeat_screen.get_node_or_null("WinnerLabel")
	if sub:
		sub.text = U.lt("won_victory") % winner_name

	_fill_stats_panel(defeat_screen, winner_name, stats, false)

	Sound.play("defeat")


# ─────────────────────────────────────────────────────────────────────────────
#  STATS PANEL  (commun victoire + défaite)
# ─────────────────────────────────────────────────────────────────────────────

func _fill_stats_panel(screen: Panel, winner_name: String,
		stats: Dictionary, is_victory: bool) -> void:

	var container : Node = screen.get_node_or_null("StatsContainer")
	if container == null:
		return  # pas encore construit (ne devrait pas arriver)

	# Vide les anciens enfants
	for c in container.get_children():
		container.remove_child(c)
		c.free()

	var accent : Color = U.C_PINK if is_victory else Color(0.85, 0.25, 0.25)

	# ── Ligne durée ───────────────────────────────────────────────────────────
	var dur_sec : float = stats.get("duration_sec", 0.0)
	var dur_str : String
	if dur_sec >= 60.0:
		dur_str = "%dm %02ds" % [int(dur_sec) / 60, int(dur_sec) % 60]
	else:
		dur_str = "%.0f s" % dur_sec
	_add_stat_row(container, U.lt("stat_duration"), dur_str, accent)

	var peak : int = stats.get("camps_peak", 0)
	if peak > 0:
		_add_stat_row(container, U.lt("stat_camps_peak"), str(peak), accent)

	var final_camps : int = stats.get("camps_final", 0)
	if final_camps > 0:
		_add_stat_row(container, U.lt("stat_camps_final"), str(final_camps), accent)

	var inc_peak : int = stats.get("income_peak", 0)
	if inc_peak > 0:
		_add_stat_row(container, U.lt("stat_income_peak"), "+%d G/tick" % inc_peak, accent)

	var lost : int = stats.get("units_lost", 0)
	if lost > 0:
		_add_stat_row(container, U.lt("stat_units_lost"), str(lost), accent)

	_add_stat_row(container, U.lt("stat_winner"), winner_name,
		U.C_GOLD if is_victory else Color(0.80, 0.50, 0.50))


func _add_stat_row(parent: Node, key: String, value: String, accent: Color) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(560, 28)
	parent.add_child(row)

	var key_lbl := Label.new()
	key_lbl.text = key
	key_lbl.custom_minimum_size = Vector2(240, 28)
	key_lbl.add_theme_font_size_override("font_size", 13)
	key_lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.85))
	row.add_child(key_lbl)

	# Séparateur pointillé
	var dots := Label.new()
	dots.text = "· · · · · · · · · ·"
	dots.custom_minimum_size = Vector2(140, 28)
	dots.add_theme_font_size_override("font_size", 10)
	dots.add_theme_color_override("font_color", Color(0.35, 0.30, 0.45))
	dots.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(dots)

	var val_lbl := Label.new()
	val_lbl.text = value
	val_lbl.custom_minimum_size = Vector2(180, 28)
	val_lbl.add_theme_font_size_override("font_size", 14)
	val_lbl.add_theme_color_override("font_color", accent)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(val_lbl)


# ─────────────────────────────────────────────────────────────────────────────
#  CONSTRUCTION
# ─────────────────────────────────────────────────────────────────────────────

func _build_victory_screen() -> void:
	victory_screen = U.make_screen(false)
	var ov := StyleBoxFlat.new()
	ov.bg_color = Color(0, 0, 0, 0.80)
	victory_screen.add_theme_stylebox_override("panel", ov)
	_parent.add_child(victory_screen)
	victory_screen.z_index = 10000
	victory_screen.mouse_filter = Control.MOUSE_FILTER_STOP

	# Panneau central
	var panel := Panel.new()
	panel.position = Vector2(U.WIN_W / 2 - 360, 80)
	panel.size     = Vector2(720, 530)
	panel.add_theme_stylebox_override("panel",
		U.flat(Color(0.08, 0.04, 0.18), U.C_PINK, 3, 16))
	victory_screen.add_child(panel)

	U.add_badge(victory_screen, U.lt("mission_complete"),
		Vector2(U.WIN_W / 2 - 100, 88), Vector2(200, 26), U.C_PINK)

	# Titre animé
	victory_title          = Label.new()
	victory_title.text     = U.lt("victory_scr_title")
	victory_title.position = Vector2(U.WIN_W / 2 - 360, 122)
	victory_title.size     = Vector2(720, 80)
	victory_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	victory_title.add_theme_font_size_override("font_size", 56)
	victory_title.modulate = U.C_PINK
	victory_screen.add_child(victory_title)

	# Nom du gagnant
	victory_winner          = Label.new()
	victory_winner.position = Vector2(U.WIN_W / 2 - 360, 210)
	victory_winner.size     = Vector2(720, 46)
	victory_winner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	victory_winner.add_theme_font_size_override("font_size", 30)
	victory_screen.add_child(victory_winner)

	_victory_sub_lbl = U.lbl(U.lt("agent_secured"),
		Vector2(U.WIN_W / 2 - 360, 258), 13, Color(0.70, 0.55, 0.85))
	victory_screen.add_child(_victory_sub_lbl)

	# Séparateur stats
	var div := ColorRect.new()
	div.position = Vector2(U.WIN_W / 2 - 300, 285)
	div.size     = Vector2(600, 1)
	div.color    = Color(U.C_PINK.r, U.C_PINK.g, U.C_PINK.b, 0.30)
	victory_screen.add_child(div)

	# Conteneur stats (rempli par _fill_stats_panel)
	var stats_container := VBoxContainer.new()
	stats_container.name     = "StatsContainer"
	stats_container.position = Vector2(U.WIN_W / 2 - 295, 295)
	stats_container.size     = Vector2(590, 210)
	stats_container.add_theme_constant_override("separation", 4)
	victory_screen.add_child(stats_container)

	# Boutons
	_victory_play_btn = U.btn(U.lt("play_again"),
		Vector2(U.WIN_W / 2 - 240, 620), Vector2(200, 50), 18)
	_victory_play_btn.add_theme_stylebox_override("normal",
		U.flat(Color(0.28, 0.05, 0.18), U.C_PINK, 2, 10))
	_victory_play_btn.add_theme_color_override("font_color", U.C_WHITE)
	_victory_play_btn.pressed.connect(func(): _parent.get_tree().reload_current_scene())
	victory_screen.add_child(_victory_play_btn)

	_victory_quit_btn = U.btn(U.lt("quit_btn"),
		Vector2(U.WIN_W / 2 + 40, 620), Vector2(200, 50), 18)
	_victory_quit_btn.add_theme_stylebox_override("normal",
		U.flat(Color(0.18, 0.05, 0.05), Color(0.70, 0.20, 0.20), 2, 10))
	_victory_quit_btn.add_theme_color_override("font_color", U.C_WHITE)
	_victory_quit_btn.pressed.connect(func(): _parent.get_tree().quit())
	victory_screen.add_child(_victory_quit_btn)

	# Étoiles orbitales
	var shapes : Array[String] = ["✦","✧","◆","✶","⋆"]
	var colors : Array[Color]  = [U.C_PINK, U.C_CYAN, U.C_GOLD, U.C_PURPLE]
	for i in range(12):
		var s := Label.new()
		s.text = shapes[i % shapes.size()]
		s.add_theme_font_size_override("font_size", 18 + (i % 4) * 6)
		s.modulate   = colors[i % colors.size()]
		s.modulate.a = 0.0
		victory_screen.add_child(s)
		victory_sparkles.append(s)

	# Confettis
	var c_shapes : Array[String] = ["✦","○","+","×","◆"]
	var c_colors : Array[Color]  = [U.C_PINK, U.C_CYAN, U.C_GOLD, U.C_PURPLE, U.C_WHITE]
	for i in range(40):
		var p := Label.new()
		p.text = c_shapes[i % c_shapes.size()]
		p.add_theme_font_size_override("font_size", 8 + (i % 4) * 3)
		p.modulate  = c_colors[i % c_colors.size()]
		p.position  = Vector2(float((i * 30 + 10) % U.WIN_W), -30.0)
		victory_screen.add_child(p)
		_confetti_pieces.append({
			"label": p,
			"xb":    float((i * 30 + 10) % U.WIN_W),
			"speed": 50.0 + float(i % 7) * 22.0,
			"drift": sin(float(i) * 1.7) * 0.8,
			"phase": float(i) * 0.44
		})


func _build_defeat_screen() -> void:
	defeat_screen = U.make_screen(false)
	var ov := StyleBoxFlat.new()
	ov.bg_color = Color(0.0, 0.0, 0.0, 0.90)
	defeat_screen.add_theme_stylebox_override("panel", ov)
	_parent.add_child(defeat_screen)
	defeat_screen.z_index = 10000
	defeat_screen.mouse_filter = Control.MOUSE_FILTER_STOP

	# Panneau central
	var panel := Panel.new()
	panel.position = Vector2(U.WIN_W / 2 - 360, 80)
	panel.size     = Vector2(720, 530)
	panel.add_theme_stylebox_override("panel",
		U.flat(Color(0.10, 0.02, 0.02), Color(0.60, 0.10, 0.10), 3, 16))
	defeat_screen.add_child(panel)

	U.add_badge(defeat_screen, U.lt("mission_failed"),
		Vector2(U.WIN_W / 2 - 100, 88), Vector2(200, 26), Color(0.65, 0.12, 0.12))

	# Titre
	_defeat_title_lbl = Label.new()
	var title := _defeat_title_lbl
	title.text     = U.lt("defeat_scr_title")
	title.position = Vector2(U.WIN_W / 2 - 360, 122)
	title.size     = Vector2(720, 80)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	title.modulate = Color(0.85, 0.20, 0.20)
	defeat_screen.add_child(title)

	# Sous-titre (nom du gagnant — rempli dans show_defeat)
	var sub := Label.new()
	sub.name     = "WinnerLabel"
	sub.text     = ""
	sub.position = Vector2(U.WIN_W / 2 - 360, 210)
	sub.size     = Vector2(720, 46)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 24)
	sub.modulate = Color(0.75, 0.45, 0.45)
	defeat_screen.add_child(sub)

	_defeat_sub_lbl = U.lbl(U.lt("territory_lost"),
		Vector2(U.WIN_W / 2 - 360, 258), 13, Color(0.50, 0.30, 0.30))
	defeat_screen.add_child(_defeat_sub_lbl)

	# Séparateur
	var div := ColorRect.new()
	div.position = Vector2(U.WIN_W / 2 - 300, 285)
	div.size     = Vector2(600, 1)
	div.color    = Color(0.60, 0.15, 0.15, 0.40)
	defeat_screen.add_child(div)

	# Conteneur stats
	var stats_container := VBoxContainer.new()
	stats_container.name     = "StatsContainer"
	stats_container.position = Vector2(U.WIN_W / 2 - 295, 295)
	stats_container.size     = Vector2(590, 210)
	stats_container.add_theme_constant_override("separation", 4)
	defeat_screen.add_child(stats_container)

	# Boutons
	_defeat_try_btn = U.btn(U.lt("try_again"),
		Vector2(U.WIN_W / 2 - 240, 620), Vector2(200, 50), 18)
	_defeat_try_btn.add_theme_stylebox_override("normal",
		U.flat(Color(0.18, 0.05, 0.05), Color(0.60, 0.15, 0.15), 2, 10))
	_defeat_try_btn.add_theme_color_override("font_color", U.C_WHITE)
	_defeat_try_btn.pressed.connect(func(): _parent.get_tree().reload_current_scene())
	defeat_screen.add_child(_defeat_try_btn)

	_defeat_quit_btn = U.btn(U.lt("quit_btn"),
		Vector2(U.WIN_W / 2 + 40, 620), Vector2(200, 50), 18)
	_defeat_quit_btn.add_theme_stylebox_override("normal",
		U.flat(Color(0.12, 0.04, 0.04), Color(0.45, 0.10, 0.10), 2, 10))
	_defeat_quit_btn.add_theme_color_override("font_color", U.C_WHITE)
	_defeat_quit_btn.pressed.connect(func(): _parent.get_tree().quit())
	defeat_screen.add_child(_defeat_quit_btn)

	defeat_screen.visible = false