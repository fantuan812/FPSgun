extends SceneTree
const Combat=preload("res://scripts/gameplay/combat_runtime.gd")
const RunFlow=preload("res://scripts/gameplay/run_flow.gd")
class InvalidMode extends RefCounted:
	func can_end(_session:RefCounted,_world:RefCounted,_encounters:Dictionary)->bool:return true
	func resolution(_session:RefCounted,_world:RefCounted,_config:Dictionary)->Dictionary:return {"terminal":"invalid"}
const Motor=preload("res://scripts/gameplay/character_motor.gd")
const Rules=preload("res://scripts/rules.gd")
const Forecast=preload("res://scripts/gameplay/build_forecast.gd")
var g
var checks:=0
var failures:Array=[]
func ck(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label)
func _initialize()->void:call_deferred("run")
func start(items:Dictionary)->void:
	g._start_run(39031);g.set_process(false)
	g.build.items=items.duplicate(true);g.build.weapons=["rivet_gun","scatter_rig"];g._recompute()
	g.player_pos=Vector2(300,300);g.weapon_clocks=[999.0,999.0];g.combat_frame.area=g.config.arena
func begin()->void:
	g.combat.combat_tick_serial+=1;g.effect_runtime.begin_build_items_step(g.config.arena)
func hit(e:Dictionary,weapon:String,source:String="primary")->void:
	g._effect_event("hit",{"target":e.id,"pos":e.pos,"weapon":weapon,"source":source,"depth":0,"damage":0.0})
func enemy(pos:Vector2,hp:float=1000.0)->Dictionary:
	var e:Dictionary=g._spawn_kind("crawler",pos);e.hp=hp;e.max_hp=hp;e.anim_hp=hp;e.speed=0.0;e.damage=0.0
	return e
func run()->void:
	g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
	ck(Rules.validate_catalog(g.catalog).is_empty(),"real B catalog valid")
	start({"crossfire_pin":1});begin();var e:=enemy(Vector2(400,300));hit(e,"rivet_gun")
	ck(g.effect_runtime.build_items.mark.position==Vector2(400,300),"real event mark current position")
	e.pos=Vector2(500,300);hit(e,"scatter_rig")
	ck(e.pos==Vector2(455,300),"real event B control moves exactly45")
	ck(e.hp==1000,"Pin no damage")
	ck(g.effect_runtime.build_items.pin_ready_at==1.0,"actual run clock cooldown")
	var snap:Dictionary=g.effect_runtime.build_items.debug_snapshot();g.state="shop";g._buy(0,-1)
	ck(g.effect_runtime.build_items.debug_snapshot()==snap,"rejected real transaction preserves B")
	start({"crossfire_pin":1,"echo_chamber":1});begin();e=enemy(Vector2(400,300),1);g.effects.echo_hits=4;hit(e,"rivet_gun")
	ck(e.hp<=0 and g.effect_runtime.build_items.mark==null,"old Echo kills before B live target resolution")
	start({"crossfire_pin":1});begin();e=enemy(Vector2(400,300));hit(e,"rivet_gun","chain")
	ck(g.effect_runtime.build_items.mark==null,"secondary does not become primary")
	g._effect_event("hit",{"target":e.id,"pos":e.pos,"weapon":"rivet_gun","damage":0.0})
	ck(g.effect_runtime.build_items.mark!=null,"trusted absent source/depth defaults only")
	g.build.weapons=["scatter_rig","return_disc"];g._recompute()
	ck(g.effect_runtime.build_items.mark==null and g.effect_runtime.build_items.pin_ready_at==1.0,"actual recompute removes origin even two other types")
	start({"salvage_capacitor":1,"medic_winch":1})
	g.pickups=[{"pos":Vector2(380,300),"xp":0,"coins":0,"heal":8.0,"source":"medical"}]
	for i in range(5):g.pickups.append({"pos":g.player_pos,"xp":1,"coins":1})
	g.stats.hp=50;var before_coins:float=g.build.coins;Combat.step(g.combat_frame,0.0)
	ck(g.effect_runtime.build_items.charges==3,"real normal pickup events charge3")
	ck(g.effect_runtime.build_items.winch_count==0,"real five threshold consumed")
	ck(g.pickups.size()==1 and g.pickups[0].pos==Vector2(300,300),"deferred flush moves medicine after entire loop")
	ck(g.stats.hp==50,"no same-pass autocollect or direct healing")
	ck(g.build.coins==before_coins+5,"normal rewards exactly once")
	Combat.step(g.combat_frame,0.0)
	ck(g.pickups.is_empty() and g.stats.hp==58,"next actual collection pass heals medicine normally")
	ck(g.effect_runtime.build_items.charges==3 and g.effect_runtime.build_items.winch_count==0,"medical pickup excluded")
	var origin:Vector2=g.player_pos;g.elapsed=.1
	ck(Motor.step(g.combat,g.config.arena,Vector2.RIGHT,true,.01),"actual Motor starts dash")
	g._effect_event("dash",{"pos":origin,"angle":0.0})
	ck(g.player_pos!=origin and g.effect_runtime.build_items.fields[0].pos==origin,"saved pre-Motor origin differs from player")
	Combat.step(g.combat_frame,0.0)
	ck(g.effect_runtime.build_items.fields.size()==1 and g.effect_runtime.build_items.charges==0,"prebegin dash field survives combat begin")
	e=enemy(Vector2(360,300));e.speed=100.0;g.elapsed=.2;Combat.step(g.combat_frame,.1)
	ck(e.pos.distance_to(Vector2(353,300))<.0001 and e.speed==100.0,"actual AI field70percent and speed restored")
	e.slow_until=1.0;g.elapsed=.3;Combat.step(g.combat_frame,.1)
	ck(e.pos.distance_to(Vector2(347.5,300))<.0001,"old stronger55percent wins instead of multiplying")
	start({"medic_winch":1});begin()
	for i in range(5):g._effect_event("pickup",{"source":"normal","pos":g.player_pos})
	ck(g.effect_runtime.build_items.pending!=null,"real ingress pending until flush")
	g.state="paused";g._present_pause()
	ck(g.effect_runtime.build_items.pending==null,"pause entry cancels pending")
	var paused:Dictionary=g.effect_runtime.build_items.debug_snapshot();g._simulate(.5)
	ck(g.effect_runtime.build_items.debug_snapshot()==paused,"paused simulation freezes B clock/state")
	start({"crossfire_pin":1,"salvage_capacitor":1,"medic_winch":1});begin()
	var before:Dictionary=g.effect_runtime.build_items.debug_snapshot();var b:Dictionary=g.build.duplicate(true)
	Forecast.project(g.config.player,g.build,g.catalog,"medic_seed")
	ck(g.effect_runtime.build_items.debug_snapshot()==before and g.build==b,"actual forecast detached from live helper/build")
	g.build.weapons=["rivet_gun","rivet_gun"];g._recompute()
	var statuses:Array=Forecast.mechanism_status(g.build,g.catalog)
	ck(not statuses.filter(func(row):return row.name=="Crossfire Control")[0].active,"forecast duplicate types not active")
	g.build.weapons=["rivet_gun","scatter_rig"];g._recompute();statuses=Forecast.mechanism_status(g.build,g.catalog)
	ck(statuses.filter(func(row):return row.name=="Crossfire Control")[0].active,"forecast distinct equipped types active")
	for id in ["crossfire_pin","salvage_capacitor","medic_winch"]:
		start({});g.build.coins=100;g.state="shop";g.shop_offers=[{"id":id,"sold":false}]
		var price:int=24 if id=="medic_winch" else 28
		var refund:int=12 if id=="medic_winch" else 14
		ck(g._buy(0,g.shop_generation) and g.build.coins==100-price,"real B buy "+id)
		ck(g.effect_runtime.build_items.owned_items.get(id,0)==1,"accepted buy synced "+id)
		g.shop_offers=[{"id":id,"sold":false}];var owned_before:Dictionary=g.effect_runtime.build_items.debug_snapshot()
		ck(not g._buy(0,g.shop_generation) and g.effect_runtime.build_items.debug_snapshot()==owned_before,"unique rejected buy atomic B "+id)
		ck(g._sell_item(id,g.shop_generation) and g.build.coins==100-price+refund,"real B sell refund "+id)
		ck(not g.effect_runtime.build_items.owned_items.has(id),"accepted sale synced "+id)
		g.shop_offers=[{"id":id,"sold":false}]
		ck(g._buy(0,g.shop_generation) and g.build.coins==100-price-price+refund,"real B rebuy "+id)
	# Standalone Flow has no B reference; controller bridge is a separate authority.
	start({"salvage_capacitor":1,"medic_winch":1});begin();g._effect_event("pickup",{"source":"normal","pos":g.player_pos})
	g.pickups=[{"pos":Vector2(700,300),"xp":1,"coins":2}];g.boss_defeated=true
	var direct_before:Dictionary=g.effect_runtime.build_items.debug_snapshot();var direct_coins:float=g.build.coins;var direct_sequence:int=g.effect_sequence
	ck(RunFlow.settle(g.combat,g.run,g.mode,g.config,g.effects,g.encounters)=="next","direct Flow accepted once")
	ck(g.build.coins==direct_coins+23 and g.effect_sequence==direct_sequence and g.effect_runtime.build_items.debug_snapshot()==direct_before,"direct Flow rewards no events and does not secretly clear B")
	ck(RunFlow.settle(g.combat,g.run,g.mode,g.config,g.effects,g.encounters)=="ignored" and g.build.coins==direct_coins+23 and g.effect_runtime.build_items.debug_snapshot()==direct_before,"direct repeated Flow ignored rewards once B unchanged")
	start({"salvage_capacitor":1});begin();g._effect_event("pickup",{"source":"normal","pos":g.player_pos})
	direct_before=g.effect_runtime.build_items.debug_snapshot();direct_coins=g.build.coins
	ck(RunFlow.settle(g.combat,g.run,InvalidMode.new(),g.config,g.effects,g.encounters)=="invalid" and g.build.coins==direct_coins and g.effect_runtime.build_items.debug_snapshot()==direct_before,"invalid direct resolution leaves B and rewards unchanged")
	g.state="shop";g._complete_wave()
	ck(g.effect_runtime.build_items.debug_snapshot()==direct_before,"ignored controller leaves B unchanged")
	# Actual main settlement keeps rewards but cannot manufacture pickup proc events.
	start({"crossfire_pin":1,"salvage_capacitor":1,"medic_winch":1});begin();e=enemy(Vector2(400,300));hit(e,"rivet_gun");e.pos=Vector2(500,300);hit(e,"scatter_rig")
	g._effect_event("pickup",{"source":"normal","pos":g.player_pos})
	g.pickups=[{"pos":Vector2(700,300),"xp":1,"coins":2}];g.boss_defeated=true
	var sequence_before:int=g.effect_sequence;var coins_before:float=g.build.coins;g._complete_wave()
	ck(g.effect_sequence==sequence_before,"settlement sweep emits no event")
	ck(g.build.coins==coins_before+23 and g.pickups.is_empty(),"real floor2 plus nextwave21 reward retained")
	ck(g.effect_runtime.build_items.charges==0 and g.effect_runtime.build_items.winch_count==0 and g.effect_runtime.build_items.fields.is_empty(),"accepted room clears B inventory")
	ck(g.effect_runtime.build_items.pin_ready_at==1.0,"room preserves existing run cooldown")
	g._start_run(39032)
	ck(g.effect_runtime.build_items.pin_ready_at==null and g.effect_runtime.build_items.last_sequence==0 and g.effect_runtime.build_items.charges==0,"actual newrun clears guards and stocks")
	g._title()
	var teardown=load("res://tests/support/audio_teardown.gd").new();teardown.prepare([g]);g.queue_free();await process_frame;await teardown.finish(self)
	print(JSON.stringify({"B_real_hook_checks":checks,"failures":failures,"scope":"Controlled actual main/EffectRuntime/CombatRuntime/Motor and preview; not natural-play/settlement/native/full gate"}))
	quit(0 if failures.is_empty() else 1)
