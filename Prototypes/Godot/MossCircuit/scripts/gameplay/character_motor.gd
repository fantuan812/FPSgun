extends RefCounted
const CombatState=preload("res://scripts/gameplay/combat_state.gd")
## Character movement and damage arithmetic; no input polling, UI, mode, RNG, or animation.
static func step(world:CombatState,area:Dictionary,direction:Vector2,dash_requested:bool,dt:float)->bool:
	world.hurt_clock=maxf(0,world.hurt_clock-dt)
	world.stats.dash_cooldown=maxf(0,world.stats.dash_cooldown-dt)
	world.stats.dash_time=maxf(0,world.stats.dash_time-dt)
	var started:bool=dash_requested and world.stats.dash_cooldown<=0 and direction!=Vector2.ZERO
	if started:
		world.stats.dash_time=.16
		world.stats.dash_cooldown=2.5
	world.player_pos+=direction*world.stats.speed*dt*(3.0 if world.stats.dash_time>0 else 1.0)
	world.player_pos=world.player_pos.clamp(Vector2(24,24),Vector2(area.width-24,area.height-24))
	return started
static func apply_damage(world:CombatState,damage:float)->float:
	var loss:float=minf(world.stats.hp,damage)
	world.stats.hp=maxf(0,world.stats.hp-damage)
	return loss
