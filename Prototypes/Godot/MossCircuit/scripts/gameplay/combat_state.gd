extends RefCounted
## Sole state owner; no scene, UI, mode implementation, or rendering dependencies.
var stats: Dictionary
var player_pos := Vector2.ZERO
var enemies: Array = []
var bullets: Array = []
var enemy_bullets: Array = []
var pickups: Array = []
var flashes: Array = []
var weapon_clocks: Array = []
var hurt_clock := 0.0
var pending_blasts: Array = []
var hazards: Array = []
var effect_visuals: Array = []
var next_enemy_id := 0
var focus_enemy_id := 0 # Transient current ID only; 0 preserves automatic nearest acquisition.

# New A attacks are bounded and owned only within this epoch; old arrays remain unchanged.
var pulse_beams:Array=[]
var seismic_waves:Array=[]
var new_weapon_epoch:int=0
var new_wave_sequence:int=0
var combat_tick_serial:int=0
var new_weapon_last_tick:int=-1
var new_weapon_motion:Dictionary={}
func clear_new_attacks()->void:
	pulse_beams.clear();seismic_waves.clear();new_weapon_motion.clear()
	new_weapon_epoch+=1
