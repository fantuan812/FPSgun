extends Node
## Presentation only. No gameplay references, timing callbacks, RNG or queue.
signal cue_requested(cue: String, accepted: bool)

const GAIN_LINEAR := 0.5
const CUES := {
	"player_damage": {"path":"res://assets/audio/player_damage.wav", "samples":7056},
	"shield_block": {"path":"res://assets/audio/shield_block.wav", "samples":5292},
}
var players: Dictionary = {}
var muted := false

func _ready() -> void:
	for cue in CUES:
		var player := AudioStreamPlayer.new()
		player.name = cue
		player.autoplay = false
		player.max_polyphony = 1
		player.pitch_scale = 1.0
		player.volume_linear = GAIN_LINEAR
		player.bus = &"Master"
		add_child(player)
		players[cue] = player
		var path: String = CUES[cue].path
		if ResourceLoader.exists(path):
			install_stream(cue, load(path))

static func stream_error(cue: String, stream: Resource) -> String:
	if not CUES.has(cue): return "unknown cue"
	if stream == null: return "missing resource"
	if not stream is AudioStreamWAV: return "not PCM WAV"
	if stream.format != AudioStreamWAV.FORMAT_16_BITS: return "not 16-bit PCM"
	if stream.mix_rate != 44100 or stream.stereo: return "not mono 44100 Hz"
	if stream.loop_mode != AudioStreamWAV.LOOP_DISABLED: return "loop must be disabled"
	if stream.data.size() != int(CUES[cue].samples) * 2: return "wrong sample count"
	return ""

func install_stream(cue: String, stream: Resource) -> bool:
	# Setup/fault isolation only. Identity hashes are checked in acceptance, not play.
	if not players.has(cue): return false
	var player: AudioStreamPlayer = players[cue]
	player.stop()
	player.stream = stream if stream_error(cue, stream).is_empty() else null
	return player.stream != null

func request(cue: String) -> bool:
	if not players.has(cue): return false
	var player: AudioStreamPlayer = players[cue]
	var accepted := not muted and stream_error(cue, player.stream).is_empty()
	cue_requested.emit(cue, accepted)
	if not accepted: return false
	# max_polyphony=1 makes the newest same-cue request replace the old voice.
	player.play()
	return true

func stop_all() -> void:
	for player in players.values():
		if is_instance_valid(player): player.stop()

func set_muted(value: bool) -> void:
	muted = value
	if muted: stop_all()

func status() -> Dictionary:
	var unavailable: Array[String] = []
	for cue in CUES:
		if not players.has(cue) or not stream_error(cue, players[cue].stream).is_empty():
			unavailable.append(cue)
	var driver := AudioServer.get_driver_name()
	return {"driver":driver, "dummy":driver == "Dummy", "muted":muted, "unavailable":unavailable}

func _exit_tree() -> void:
	stop_all()
