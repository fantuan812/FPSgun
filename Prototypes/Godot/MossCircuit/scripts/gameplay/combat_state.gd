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
