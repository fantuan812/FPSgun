extends RefCounted
## Sole state owner; no scene, UI, mode implementation, or rendering dependencies.
var build: Dictionary
var wave := 1
var wave_time := 0.0
var elapsed := 0.0
var level := 1
var xp := 0
var kills := 0
var state := "title"
var resume_state := "playing"
var upgrade_pending := 0
var choice_generation := 0
var shop_generation := 0
var shop_pending := false
var boss_spawned := false
var boss_defeated := false
var boss_rewards: Dictionary = {}
var rewards: Array = []
var choices: Array = []
var shop_offers: Array = []
var shop_message := ""
var run_seed := 240102
