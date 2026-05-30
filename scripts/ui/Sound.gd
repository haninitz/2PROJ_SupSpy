extends Node

# Sons générés procéduralement — aucun fichier audio requis
# Utilise AudioStreamWAV avec données PCM 16-bit générées en GDScript

const RATE = 22050

var _players: Dictionary = {}
var _music_player : AudioStreamPlayer = null

func _ready() -> void:
	_add("select",       _snd_select(),       -10.0)
	_add("move",         _snd_move(),         -10.0)
	_add("attack",       _snd_attack(),        -6.0)
	_add("recruit",      _snd_recruit(),       -8.0)
	_add("end_turn",     _snd_end_turn(),      -8.0)
	_add("victory",      _snd_victory(),       -4.0)
	_add("income_chime", _snd_income_chime(),  -8.0)
	_add("capture",      _snd_capture(),       -6.0)
	_add("defeat",       _snd_defeat(),        -5.0)
	_add("ui_click",     _snd_ui_click(),     -12.0)
	_start_music()
	start_music()

func play(name: String) -> void:
	if _players.has(name):
		(_players[name] as AudioStreamPlayer).play()

# #  Utilitaires internes
func _add(name: String, stream: AudioStreamWAV, vol_db: float) -> void:
	var p = AudioStreamPlayer.new()
	p.stream    = stream
	p.volume_db = vol_db
	add_child(p)
	_players[name] = p

func _env(i: int, n: int, atk: float, rel: float) -> float:
	var a = int(n * atk)
	var r = int(n * rel)
	if i < a:          return float(i) / max(a, 1)
	if i > n - r:      return float(n - i) / max(r, 1)
	return 1.0

func _pcm(buf: PackedFloat32Array) -> AudioStreamWAV:
	var data = PackedByteArray()
	data.resize(buf.size() * 2)
	for i in range(buf.size()):
		var v = int(clamp(buf[i], -1.0, 1.0) * 32767)
		data[i * 2]     = v & 0xFF
		data[i * 2 + 1] = (v >> 8) & 0xFF
	var s = AudioStreamWAV.new()
	s.data      = data
	s.format    = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate  = RATE
	s.stereo    = false
	return s

# #  Sélection d'un camp — bip montant court
func _snd_select() -> AudioStreamWAV:
	var n   = int(RATE * 0.12)
	var buf = PackedFloat32Array()
	buf.resize(n)
	for i in range(n):
		var t    = float(i) / RATE
		var freq = 220.0 + 220.0 * float(i) / n   # 220 → 440 Hz
		buf[i]   = sin(TAU * freq * t) * _env(i, n, 0.02, 0.45) * 0.6
	return _pcm(buf)

# #  Déplacement — ton descendant doux
func _snd_move() -> AudioStreamWAV:
	var n   = int(RATE * 0.22)
	var buf = PackedFloat32Array()
	buf.resize(n)
	for i in range(n):
		var t    = float(i) / RATE
		var freq = 440.0 - 200.0 * float(i) / n   # 440 → 240 Hz
		buf[i]   = sin(TAU * freq * t) * _env(i, n, 0.02, 0.55) * 0.55
	return _pcm(buf)

# #  Attaque — bruit blanc + basse
func _snd_attack() -> AudioStreamWAV:
	var n   = int(RATE * 0.28)
	var buf = PackedFloat32Array()
	buf.resize(n)
	var rng = RandomNumberGenerator.new()
	rng.seed = 42
	for i in range(n):
		var t     = float(i) / RATE
		var env   = _env(i, n, 0.005, 0.50)
		var noise = rng.randf_range(-1.0, 1.0)
		var bass  = sin(TAU * 90.0 * t)
		var mid   = sin(TAU * 180.0 * t)
		buf[i]    = (noise * 0.45 + bass * 0.35 + mid * 0.20) * env * 0.75
	return _pcm(buf)

# #  Recrutement — clochette douce
func _snd_recruit() -> AudioStreamWAV:
	var n   = int(RATE * 0.38)
	var buf = PackedFloat32Array()
	buf.resize(n)
	for i in range(n):
		var t   = float(i) / RATE
		var env = _env(i, n, 0.01, 0.65)
		var s   = sin(TAU * 880.0  * t) * 0.60
		s      += sin(TAU * 1760.0 * t) * 0.25
		s      += sin(TAU * 2640.0 * t) * 0.10
		buf[i]  = s * env * 0.65
	return _pcm(buf)

# #  Fin de tour — deux notes (Do puis Sol)
func _snd_end_turn() -> AudioStreamWAV:
	var n    = int(RATE * 0.55)
	var half = n / 2
	var buf  = PackedFloat32Array()
	buf.resize(n)
	for i in range(n):
		var seg_i  = i if i < half else i - half
		var freq   = 523.25 if i < half else 392.00   # C5 puis G4
		var t      = float(seg_i) / RATE
		var env    = _env(seg_i, half, 0.02, 0.45)
		buf[i]     = sin(TAU * freq * t) * env * 0.60
	return _pcm(buf)

# #  Chime d'or (income) — arpège scintillant C5-E5-G5
func _snd_income_chime() -> AudioStreamWAV:
	var notes : Array = [523.25, 659.25, 783.99]   # C5 E5 G5
	var n    = int(RATE * 0.55)
	var seg  = n / notes.size()
	var buf  = PackedFloat32Array()
	buf.resize(n)
	for i in range(n):
		var ni   = mini(i / seg, notes.size() - 1)
		var si   = i - ni * seg
		var t    = float(si) / RATE
		var env  = _env(si, seg, 0.01, 0.50)
		var freq = notes[ni]
		var s    = sin(TAU * freq * t) * 0.62
		s       += sin(TAU * freq * 2.0 * t) * 0.22
		s       += sin(TAU * freq * 3.0 * t) * 0.10
		buf[i]   = s * env * 0.60
	return _pcm(buf)

# #  Capture de camp — fanfare courte G4-C5-E5-G5
func _snd_capture() -> AudioStreamWAV:
	var notes : Array = [392.00, 523.25, 659.25, 783.99]
	var n    = int(RATE * 0.60)
	var seg  = n / notes.size()
	var buf  = PackedFloat32Array()
	buf.resize(n)
	for i in range(n):
		var ni   = mini(i / seg, notes.size() - 1)
		var si   = i - ni * seg
		var t    = float(si) / RATE
		var env  = _env(si, seg, 0.01, 0.35)
		var s    = sin(TAU * notes[ni] * t) * 0.60
		s       += sin(TAU * notes[ni] * 1.5 * t) * 0.18
		buf[i]   = s * env * 0.65
	return _pcm(buf)

# #  Défaite — accord descendant triste G4→D4
func _snd_defeat() -> AudioStreamWAV:
	var n    = int(RATE * 1.20)
	var half = n / 2
	var buf  = PackedFloat32Array()
	buf.resize(n)
	for i in range(n):
		var seg_i = i if i < half else i - half
		var freq  = 392.00 if i < half else 293.66   # G4 puis D4
		var t     = float(seg_i) / RATE
		var env   = _env(seg_i, half, 0.02, 0.60)
		var s     = sin(TAU * freq * t) * 0.55
		s        += sin(TAU * freq * 0.75 * t) * 0.25
		buf[i]    = s * env * 0.55
	return _pcm(buf)

# #  Clic UI — pop court et vif
func _snd_ui_click() -> AudioStreamWAV:
	var n   = int(RATE * 0.08)
	var buf = PackedFloat32Array()
	buf.resize(n)
	for i in range(n):
		var t    = float(i) / RATE
		var freq = 660.0 - 600.0 * float(i) / float(n)
		buf[i]   = sin(TAU * freq * t) * _env(i, n, 0.01, 0.60) * 0.70
	return _pcm(buf)

# #  Victoire — arpège ascendant Do-Mi-Sol-Do
func _snd_victory() -> AudioStreamWAV:
	var notes: Array = [261.63, 329.63, 392.00, 523.25]   # C4 E4 G4 C5
	var n    = int(RATE * 1.50)
	var seg  = n / notes.size()
	var buf  = PackedFloat32Array()
	buf.resize(n)
	for i in range(n):
		var ni    = mini(i / seg, notes.size() - 1)
		var si    = i - ni * seg
		var t     = float(si) / RATE
		var env   = _env(si, seg, 0.02, 0.30)
		var freq  = notes[ni]
		var s     = sin(TAU * freq * t) * 0.65
		s        += sin(TAU * freq * 2.0 * t) * 0.20
		buf[i]    = s * env * 0.70
	return _pcm(buf)


# =============================================================================
#  MUSIQUE DE FOND — boucle générée procéduralement
# =============================================================================

func _start_music() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.stream    = _snd_music()
	_music_player.volume_db = -14.0
	_music_player.autoplay  = false  # on lance manuellement après setup

	# Connecte au bus Music si disponible
	var bus_idx : int = AudioServer.get_bus_index("Music")
	if bus_idx >= 0:
		_music_player.bus = "Music"

	add_child(_music_player)

	# Boucle infinie
	_music_player.finished.connect(func(): _music_player.play())

func start_music() -> void:
	if _music_player and not _music_player.playing:
		_music_player.play()


func stop_music() -> void:
	if _music_player and _music_player.playing:
		_music_player.stop()


func _snd_music() -> AudioStreamWAV:
	# Boucle ambient de 8 secondes
	# Arpège pentatonique lent : C4 E4 G4 A4 C5
	var notes : Array = [261.63, 329.63, 392.00, 440.00, 523.25]
	var bpm    : float = 72.0
	var beat   : float = 60.0 / bpm
	var n_beats : int  = 16
	var total  : int   = int(RATE * beat * n_beats)
	var buf    := PackedFloat32Array()
	buf.resize(total)

	# Pattern : [note_idx, beat_offset, duration_beats]
	var pattern : Array = [
		[0, 0,  2], [2, 2,  2], [1, 4,  2], [3, 6,  2],
		[4, 8,  2], [2, 10, 2], [0, 12, 2], [1, 14, 2],
	]

	for p in pattern:
		var freq     : float = notes[p[0]]
		var start    : int   = int(p[1] * beat * RATE)
		var duration : int   = int(p[2] * beat * RATE * 0.85)
		for i in range(duration):
			if start + i >= total:
				break
			var t   : float = float(i) / RATE
			var env : float = _env(i, duration, 0.05, 0.40)
			# Son de type piano simple (fondamentale + harmoniques)
			var s : float = sin(TAU * freq * t)       * 0.55
			s            += sin(TAU * freq * 2.0 * t) * 0.20
			s            += sin(TAU * freq * 3.0 * t) * 0.08
			buf[start + i] += s * env * 0.35

	# Basse lente (C3 toutes les 4 mesures)
	var bass_freq : float = 130.81
	for beat_i in [0, 4, 8, 12]:
		var start : int   = int(beat_i * beat * RATE)
		var dur   : int   = int(beat * RATE * 1.8)
		for i in range(dur):
			if start + i >= total:
				break
			var t   : float = float(i) / RATE
			var env : float = _env(i, dur, 0.02, 0.55)
			buf[start + i] += sin(TAU * bass_freq * t) * env * 0.25

	return _pcm(buf)
