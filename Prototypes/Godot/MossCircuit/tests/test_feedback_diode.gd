extends SceneTree
const Rules = preload("res://scripts/rules.gd")
const Motor = preload("res://scripts/gameplay/character_motor.gd")
const Runtime = preload("res://scripts/gameplay/combat_runtime.gd")
const EffectEngine = preload("res://scripts/effects.gd")
var game
var checks := 0
var failures: Array = []
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func _initialize() -> void: call_deferred("run")
func fresh(mode: String, items: Dictionary = {"feedback_diode":1}) -> void:
	game._title(); game._select_mode(mode); game._start_run(26026)
	game.build.items = items.duplicate(true); game._recompute()
	game.player_pos = Vector2(400,300); game.elapsed = 10.0
	game.stats.hp = 100; game.stats.max_hp = 100; game.hurt_clock = 0
	game.combat_frame.area = game.config.arena
	for i in range(game.weapon_clocks.size()): game.weapon_clocks[i] = 999.0
func owner(offset: Vector2 = Vector2(150,0), hp: float = 100) -> Dictionary:
	var enemy: Dictionary = game._spawn_kind("spitter",game.player_pos+offset)
	enemy.hp=hp; enemy.max_hp=hp; enemy.anim_hp=hp; enemy.speed=0; enemy.cooldown_left=999
	return enemy
func dash() -> void:
	game.stats.dash_cooldown=0
	var started: bool = Motor.step(game.combat,game.config.arena,Vector2.RIGHT,true,0.0)
	check(started,"actual motor dash starts")
	if started: game._effect_event("dash",{"pos":game.player_pos,"angle":0.0})
func shot(id: int, y: float = 0, life: float = 1.0) -> void:
	game.enemy_bullets.append({"owner":id,"pos":game.player_pos+Vector2(-6,y),"velocity":Vector2(600,0),"life":life,"damage":20.0})
func tick(dt: float) -> void:
	Motor.step(game.combat,game.config.arena,Vector2.ZERO,false,dt)
	game.elapsed += dt
	Runtime.step(game.combat_frame,dt)
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate(); root.add_child(game); game.set_process(false)
	check(Rules.validate_catalog(game.catalog).is_empty(),"new catalog validates")
	var entry: Dictionary = Rules.catalog_entry(game.catalog,"feedback_diode")
	check(entry.price==28 and entry.feedback_damage==24 and entry.max_stack==1,"exact module definition")
	for invalid in [null,0,-1,INF,NAN,"24",1001]:
		var catalog: Dictionary = game.catalog.duplicate(true)
		Rules.catalog_entry(catalog,"feedback_diode").feedback_damage=invalid
		check(not Rules.validate_catalog(catalog).is_empty(),"reject malformed damage "+str(invalid))
	for invalid in [null,0,-1,2,INF,NAN,"bad",true,{},[]]:
		var catalog: Dictionary = game.catalog.duplicate(true)
		Rules.catalog_entry(catalog,"feedback_diode").max_stack=invalid
		check(not Rules.validate_catalog(catalog).is_empty(),"reject malformed uniqueness "+str(invalid))
	for mode in ["arena","rooms"]:
		fresh(mode,{"feedback_diode":1,"mirror_shell":1}); var enemy: Dictionary = owner(); dash()
		var shield: int=game.effects.shield; var clock: float=game.hurt_clock
		shot(enemy.id); tick(.05)
		check(enemy.hp==76 and enemy.last_source=="feedback",mode+" real swept contact fixed secondary")
		check(game.stats.hp==100 and game.hurt_clock==clock and game.effects.shield==shield,mode+" no new immunity side effects / shield consumption")
		check(not game.effects.feedback_armed and game.enemy_bullets.is_empty(),mode+" one allowance and old shot removal")
		check(game.effect_visuals.any(func(v):return v.kind=="feedback"),mode+" return cue emitted")
		shot(enemy.id); tick(.01); check(enemy.hp==76,mode+" second shot in same dash cannot counter")
		dash(); shot(enemy.id); tick(.05); check(enemy.hp==52,mode+" next real dash rearms")
		fresh(mode); enemy=owner(); var other: Dictionary=owner(Vector2(-150,0)); dash()
		shot(enemy.id); shot(other.id); tick(.05)
		check(enemy.hp==100 and other.hp==76,mode+" existing reverse-array winner")
		fresh(mode); enemy=owner(); dash(); shot(enemy.id,12.0); tick(.05)
		check(enemy.hp==100 and game.effects.feedback_armed,mode+" exact 12 edge is not contact")
		shot(enemy.id,11.99); tick(.01); check(enemy.hp==76,mode+" strict interior hits")
		fresh(mode); enemy=owner(); dash(); shot(enemy.id,0,0); tick(0)
		check(enemy.hp==100 and game.effects.feedback_armed,mode+" initially expired shot excluded")
		shot(enemy.id,0,.05); tick(.05); check(enemy.hp==76,mode+" lifetime endpoint uses existing contact")
		fresh(mode); enemy=owner(); dash()
		game.enemy_bullets.append({"owner":enemy.id,"pos":game.player_pos,"velocity":Vector2.ZERO,"life":1.0,"damage":20.0})
		tick(0); check(enemy.hp==76,mode+" zero-delta overlap is existing contact")
		fresh(mode); enemy=owner(); dash(); shot(-999); tick(.05)
		check(enemy.hp==100 and game.effects.feedback_armed,mode+" invalid owner removed without spending")
		shot(enemy.id); tick(.01); check(enemy.hp==76,mode+" later valid owner can consume")
		fresh(mode); enemy=owner(); dash(); tick(.16)
		check(not game.effects.feedback_armed,mode+" expiry clears allowance")
		shot(enemy.id); tick(.05); check(enemy.hp==100 and game.stats.hp==80,mode+" expired dash retains ordinary damage")
		fresh(mode); enemy=owner(); game.hurt_clock=.5; shot(enemy.id); tick(.05)
		check(enemy.hp==100 and game.stats.hp==100,mode+" ordinary hurt invulnerability is not a dash counter")
		fresh(mode); enemy=owner(); dash(); game._hurt(50)
		check(enemy.hp==100 and game.effects.feedback_armed,mode+" contact/blast-style hurt cannot counter")
		fresh(mode,{}); enemy=owner(); dash(); var seq: int=game.effect_runtime.sequence; shot(enemy.id); tick(.05)
		check(enemy.hp==100 and game.effect_runtime.sequence==seq,mode+" unequipped collision emits no new event")
		fresh(mode); enemy=owner(); dash(); game._on_intent("pause",{}); var remaining: float=game.stats.dash_time
		game._process(.5); check(game.effects.feedback_armed and game.stats.dash_time==remaining,mode+" pause freezes allowance/window")
		game._on_intent("resume",{}); shot(enemy.id); tick(.05); check(enemy.hp==76,mode+" resume preserves allowance without rearm")
		game.build.items={};game._recompute();game.build.items={"feedback_diode":1};game._recompute()
		check(not game.effects.feedback_armed,mode+" sale/rebuy never rearms current dash")
		fresh(mode,{"feedback_diode":1,"power_coil":5,"capacitor":4,"gear":4,"lens":3}); enemy=owner(); dash(); shot(enemy.id); tick(.05)
		check(enemy.hp==76,mode+" damage and range modifiers do not scale fixed feedback")
		fresh(mode,{"feedback_diode":1,"echo_chamber":1,"arc_relay":1,"blood_valve":1,"phase_capacitor":1,"fracture_coil":1,"kill_cell":1}); enemy=owner(); other=owner(Vector2(180,20)); game.stats.hp=20; dash();game.effects.echo_hits=4;enemy.chill_until=20.0
		shot(enemy.id);tick(.05)
		check(enemy.hp==76 and other.hp==100,mode+" no chain/echo/splash secondary recursion")
		check(game.stats.hp==20 and game.effects.phase_charge==1 and game.effects.echo_hits==4 and enemy.chill_until==20,mode+" no lifesteal/phase/echo/chill consumption")
		fresh(mode,{"feedback_diode":1,"kill_cell":1});enemy=owner(Vector2(150,0),24);dash();shot(enemy.id);tick(.05)
		check(game.kills==1 and not game.enemies.has(enemy),mode+" feedback kill enters deferred death once")
		check(game.pickups.size()==1 and not game.pickups.any(func(p):return p.get("source","")=="energy"),mode+" normal drop, no Kill Cell orb")
		tick(0);check(game.kills==1,mode+" no repeated kill reward")
		fresh(mode);dash();game._finish(false);check(not game.effects.feedback_armed,mode+" result reset")
		fresh(mode);dash();game._title();check(not game.effects.feedback_armed,mode+" title reset")
		fresh(mode);dash();game.effects.reset(game.build.items);check(not game.effects.feedback_armed,mode+" stage reset")
		await process_frame
	game.queue_free(); await process_frame
	print(JSON.stringify({"checks":checks,"failures":failures,"scope":"controlled motor/shared-runtime contact and lifecycle checks; not native gameplay"}))
	quit(0 if failures.is_empty() else 1)
