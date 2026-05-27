class_name DamageNumber
extends Node2D

# ─────────────────────────────────────────────────────────────────────────────
#  DamageNumber.gd — SupKonQuest
#
#  Label flottant affiché lors d'un dégât sur une unité.
#  Créé dynamiquement depuis Unit.gd via le signal unit_damaged.
#
#  Comportement :
#    - Monte de FLOAT_DIST pixels en DURATION secondes
#    - Fondu en sortie sur la dernière moitié de la durée
#    - Se détruit automatiquement
#
#  Couleurs :
#    - Blanc      : dégâts normaux
#    - Orange-rouge: dégâts avec multiplicateur (>1.0)
#    - Vert clair : soins (amount négatif)
# ─────────────────────────────────────────────────────────────────────────────

const DURATION    : float = 1.1   # secondes d'existence
const FLOAT_DIST  : float = 40.0  # pixels parcourus vers le haut
const FONT_SIZE   : int   = 14

# Couleurs selon contexte
const COLOR_NORMAL   := Color(1.00, 1.00, 1.00, 1.0)   # blanc
const COLOR_CRITICAL := Color(1.00, 0.35, 0.10, 1.0)   # rouge-orange
const COLOR_HEAL     := Color(0.25, 1.00, 0.40, 1.0)   # vert

var _label    : Label  = null
var _elapsed  : float  = 0.0
var _start_y  : float  = 0.0


# ─────────────────────────────────────────────────────────────────────────────
# INITIALISATION
# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_start_y = position.y
	z_index  = 10   # au-dessus des unités et de la barre de vie


func setup(amount: float, is_critical: bool = false) -> void:
	_label = Label.new()

	# Texte
	var display := int(abs(amount))
	_label.text = ("+" if amount < 0.0 else "-") + str(display)

	# Style
	_label.add_theme_font_size_override("font_size", FONT_SIZE)
	if amount < 0.0:
		_label.add_theme_color_override("font_color", COLOR_HEAL)
	elif is_critical:
		_label.add_theme_color_override("font_color", COLOR_CRITICAL)
	else:
		_label.add_theme_color_override("font_color", COLOR_NORMAL)

	# Ombre portée légère pour lisibilité sur n'importe quel fond
	_label.add_theme_constant_override("shadow_offset_x", 1)
	_label.add_theme_constant_override("shadow_offset_y", 1)
	_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))

	# Centrage horizontal
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.custom_minimum_size  = Vector2(60, 20)
	_label.position             = Vector2(-30, -20)  # centré au-dessus de l'unité

	add_child(_label)


# ─────────────────────────────────────────────────────────────────────────────
# ANIMATION — monte + fondu, puis suppression
# ─────────────────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	_elapsed += delta

	# Mouvement vertical
	var t : float = _elapsed / DURATION                         # 0 → 1
	position.y = _start_y - FLOAT_DIST * t

	# Fondu : opaque pendant la 1ère moitié, puis disparaît
	var fade_start : float = DURATION * 0.5
	if _elapsed > fade_start:
		var fade_t : float = (_elapsed - fade_start) / (DURATION - fade_start)
		modulate.a = clamp(1.0 - fade_t, 0.0, 1.0)

	if _elapsed >= DURATION:
		queue_free()