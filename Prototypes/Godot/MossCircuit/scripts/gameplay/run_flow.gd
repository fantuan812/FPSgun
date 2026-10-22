extends RefCounted
const Rules=preload("res://scripts/rules.gd")
const CombatState=preload("res://scripts/gameplay/combat_state.gd")
const RunSession=preload("res://scripts/gameplay/run_session.gd")
## The single encounter settlement path. Modes choose policy, not a duplicate inventory/economy.
static func settle(world:CombatState,session:RunSession,mode:RefCounted,config:Dictionary,effects:RefCounted,encounters:Dictionary)->String:
	if session.state not in ["playing","room_clear"] or not mode.can_end(session,world,encounters):return "ignored"
	var decision=mode.resolution(session,world,config)
	if not decision is Dictionary or not validate_resolution(decision).is_empty():return "invalid"
	session.state="transition" # Reentrant/repeated requests cannot credit twice.
	for pickup in world.pickups:
		collect_pickup(world,session,pickup)
	world.pickups.clear()
	world.enemies.clear();world.bullets.clear();world.enemy_bullets.clear()
	world.hazards.clear();world.pending_blasts.clear();world.effect_visuals.clear();world.flashes.clear()
	effects.reset(session.build.items)
	world.stats.hp=minf(world.stats.max_hp,world.stats.hp+float(decision.heal))
	Rules.credit(session.build,decision.coins)
	session.shop_pending=decision.shop
	session.upgrade_pending+=int(decision.upgrades)
	if decision.terminal:return "won"
	session.wave=int(decision.next_stage)
	session.wave_time=0
	session.boss_spawned=false;session.boss_defeated=false
	return "next"
static func validate_resolution(data:Dictionary)->Array:
	var errors:Array=[]
	for key in ["terminal","shop"]:
		if not data.get(key) is bool:errors.append(key)
	for key in ["next_stage","upgrades"]:
		if not data.get(key) is int:errors.append(key+" must be integer")
		elif int(data[key])<(1 if key=="next_stage" else 0):errors.append(key+" bounds")
	for key in ["coins","heal"]:
		if not (data.get(key) is int or data.get(key) is float):errors.append(key+" must be numeric")
		elif not is_finite(float(data[key])) or float(data[key])<0 or float(data[key])>1000000:errors.append(key+" bounds")
	if data.get("terminal")==true and (data.get("shop")==true or (data.get("upgrades") is int and data.upgrades>0)):errors.append("terminal cannot open shop or upgrade")
	return errors

static func accrue_levels(session:RunSession)->void:
	while session.xp>=Rules.xp_threshold(session.level):
		session.xp-=Rules.xp_threshold(session.level)
		session.level+=1
		session.upgrade_pending+=1

static func collect_pickup(world:CombatState,session:RunSession,pickup:Dictionary)->void:
	world.stats.hp=minf(world.stats.max_hp,world.stats.hp+pickup.get("heal",0.0))
	session.xp+=int(pickup.xp)
	Rules.credit(session.build,pickup.get("coins",1)*(1.0+world.stats.coin_bonus))
static func award_boss(_world:CombatState,session:RunSession,enemy:Dictionary)->bool:
	if not enemy.get("boss",false) or enemy.hp>0 or session.boss_rewards.has(enemy.kind) or session.state!="playing":return false
	session.boss_rewards[enemy.kind]=true
	session.boss_defeated=true
	if enemy.kind=="boss_warden":
		session.build.boss_protocol=true
		session.rewards.append("WARDEN PROTOCOL: +25 max HP, +10% damage")
		Rules.credit(session.build,50)
		return true # Caller re-derives build before applying the granted 25 HP repair.
	session.rewards.append("REACTOR CROWN: final trophy")
	Rules.credit(session.build,100)
	return false
