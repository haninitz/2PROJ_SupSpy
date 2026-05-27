extends PanelContainer
class_name Leaderboard

@onready var rows_container : VBoxContainer = $VBoxContainer

func _ready() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.camp_captured.connect(func(_c, _o, _n): refresh())
		gm.income_distributed.connect(func(_p, _a): refresh())
		gm.player_defeated.connect(func(_p): refresh())

func refresh() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if not gm:
		return

	for child in rows_container.get_children():
		child.queue_free()

	var sorted : Array = gm.players.duplicate()
	sorted.sort_custom(func(a, b): return a.get_camp_count() > b.get_camp_count())

	for player in sorted:
		var row         := HBoxContainer.new()
		var dot         := ColorRect.new()
		dot.color        = player.color
		dot.custom_minimum_size = Vector2(10, 10)

		var lbl         := Label.new()
		lbl.text         = "%s  %d  +%dG" % [
			player.player_name.split(" ")[0],
			player.get_camp_count(),
			player.get_income()
		]
		lbl.add_theme_color_override("font_color", player.color)

		row.add_child(dot)
		row.add_child(lbl)
		rows_container.add_child(row)