# ─────────────────────────────────────────────────────────────────────────────
#  UI.gd — SupKonQuest · Totally Spies Edition
#  Version fusionnée : compatible avec Main.gd du projet principal
# ─────────────────────────────────────────────────────────────────────────────
extends CanvasLayer

# ── Signaux ───────────────────────────────────────────────────────────────────
signal recruit_pressed(unit_type: String)
signal map_selected(map_index: int)
signal mode_selected(is_ai: bool, difficulty: String)
signal squads_selected(squad1: String, squad2: String)
signal turn_confirmed
signal end_turn_pressed   # ← requis par Main.gd du projet principal

# ── Modules ───────────────────────────────────────────────────────────────────
var _menu    : MainMenu
var _splash  : Node
var _hud     : HUD
var _victory : VictoryScreen
var _pause   : Node
var _u       : Node
var _game_started : bool = false
var hud : CanvasLayer : get = _get_hud  # accès public pour Main.gd

# ── Compat getters pour Main.gd ───────────────────────────────────────────────
var main_menu         : Panel : get = _get_main_menu
var setup_screen      : Panel : get = _get_setup_screen
var map_screen        : Panel : get = _get_map_screen
var mode_screen       : Panel : get = _get_mode_screen
var difficulty_screen : Panel : get = _get_difficulty_screen
var squad_screen      : Panel : get = _get_squad_screen
var victory_screen    : Panel : get = _get_victory_screen
var turn_screen       : Panel : get = _get_turn_screen


func _ready() -> void:
	_u = get_node_or_null("/root/UIutils")
	if _u == null:
		_u = load("res://scripts/ui/UIutils.gd").new()
		add_child(_u)

	_menu    = load("res://scripts/ui/Mainmenu.gd").new()
	_hud     = load("res://scripts/ui/Hud.gd").new()
	_victory = load("res://scripts/ui/Victoryscreen.gd").new()
	_pause   = load("res://scripts/ui/Pausemenu.gd").new()

	add_child(_menu)
	add_child(_hud)
	add_child(_victory)
	add_child(_pause)

	# Initialise le menu d'abord
	_menu.initialize(self, _u)

	# Lance le splash screen par-dessus
	_splash = load("res://scripts/ui/SplashScreen.gd").new()
	add_child(_splash)
	_splash.splash_finished.connect(_on_splash_finished)
	# Cache le menu pendant le splash
	_menu.main_menu.visible = false
	_hud.setup(_u)
	_victory.initialize(self, _u)
	_pause.setup(_u)

	# Signaux vers Main.gd
	_menu.map_selected.connect(func(i : int):
		_game_started = true
		_hud.show_hud()
		_show_map(i)
		map_selected.emit(i))
	_menu.mode_selected.connect(func(a : bool, d : String): mode_selected.emit(a, d))
	_menu.squads_selected.connect(func(a : String, b : String): squads_selected.emit(a, b))
	_hud.recruit_pressed.connect(func(t : String): recruit_pressed.emit(t))
	_victory.turn_confirmed.connect(func(): turn_confirmed.emit())

	var gm : Node = get_node_or_null("/root/GameManager")
	if gm and gm.has_signal("game_over"):
		gm.game_over.connect(func(winner): show_victory(winner.player_name, 0, {}))


func _process(_delta: float) -> void:
	var t : float = Time.get_ticks_msec() / 1000.0
	_menu.animate(t)
	_victory.animate(t)


func _input(event: InputEvent) -> void:
	_victory.handle_input(event)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE and _game_started:
			if _victory.victory_screen and _victory.victory_screen.visible:
				return
			_pause.toggle()
			get_viewport().set_input_as_handled()


# ─────────────────────────────────────────────────────────────────────────────
#  API publique — appelée par Main.gd
# ─────────────────────────────────────────────────────────────────────────────

func show_victory(winner_name: String, turns: int, stats: Dictionary = {}) -> void:
	_victory.show_victory(winner_name, turns, stats)

func show_turn_screen(squad_name: String, turn_number: int) -> void:
	_victory.show_turn_screen(squad_name, turn_number)

func show_recruit(camp) -> void:
	_hud.show_recruit(camp)

func hide_recruit() -> void:
	_hud.hide_recruit()

func hide_map_screen() -> void:
	_menu.hide_map_screen()

func update_selection_panel(selected_units: Array) -> void:
	_hud.update_selection_panel(selected_units)

func refresh_leaderboard() -> void:
	_hud.refresh_leaderboard()

func add_log(message: String) -> void:
	_hud.add_log(message)

# ── Méthodes compat Main.gd projet principal ──────────────────────────────────

func update_hud(player_name: String, turn: int, gold: int, income: int,
		camps_owned: int, selected_unit: String, msg: String, p_index: int) -> void:
	# Délègue au HUD module
	if not _hud:
		return
	if _hud.info_label:
		_hud.info_label.text    = "%s — Tour %d" % [player_name, turn]
		_hud.info_label.modulate = Color(0.22, 0.45, 0.90) if p_index == 0 else Color(0.88, 0.22, 0.22)
	if _hud.gold_label:
		_hud.gold_label.text    = "%d G" % gold
	if _hud.income_label:
		_hud.income_label.text  = "+%d G/tick" % income
	if _hud.camps_label:
		_hud.camps_label.text   = "%d camps" % camps_owned
	if _hud.msg_label:
		_hud.msg_label.text     = msg
	if _hud.unit_label:
		_hud.unit_label.text    = "Unité : %s" % selected_unit if selected_unit != "" else ""
		_hud.unit_label.visible = selected_unit != ""


func disable_end_btn() -> void:
	# Cherche le bouton "Fin de tour" dans le HUD
	var btn : Node = _hud.get_node_or_null("EndTurnBtn")
	if btn and btn is Button:
		btn.disabled = true


# ── Getters compat ────────────────────────────────────────────────────────────

func _get_main_menu()         -> Panel: return _menu.main_menu         if _menu else null
func _get_setup_screen()      -> Panel: return _menu.setup_screen      if _menu else null
func _get_map_screen()        -> Panel: return _menu.map_screen        if _menu else null
func _get_mode_screen()       -> Panel: return _menu.mode_screen       if _menu else null
func _get_difficulty_screen() -> Panel: return _menu.difficulty_screen if _menu else null
func _get_squad_screen()      -> Panel: return _menu.squad_screen      if _menu else null
func _get_victory_screen()    -> Panel: return _victory.victory_screen if _victory else null
func _get_turn_screen()       -> Panel: return _victory.turn_screen    if _victory else null


func _get_hud() -> CanvasLayer: return _hud

func _on_splash_finished() -> void:
	if _menu and _menu.main_menu:
		_menu.main_menu.visible = true


# Appelé depuis recap_ia.gd pour démarrer directement sans passer par le menu
func start_from_online(map_idx: int) -> void:
	_game_started = true
	_hud.show_hud()
	_show_map(map_idx)
	map_selected.emit(map_idx)


func _show_map(index: int) -> void:
	var map_names := ["MapBeverly", "MapJungle", "MapTropical"]
	var parent := get_parent()
	for map_name in map_names:
		var node := parent.get_node_or_null(map_name)
		if node:
			node.visible = false
	if index >= 0 and index < map_names.size():
		var target := parent.get_node_or_null(map_names[index])
		if target:
			target.visible = true