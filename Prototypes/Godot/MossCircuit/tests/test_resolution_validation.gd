extends SceneTree
const Flow=preload("res://scripts/gameplay/run_flow.gd")
class Policy:
	extends RefCounted
	var decision:Variant
	func can_end(_session,_world,_encounters)->bool:return true
	func resolution(_session,_world,_config)->Variant:return decision
var g
var checks:=0
var failures:Array=[]
func ck(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label)
func _initialize()->void:call_deferred("run")
func valid()->Dictionary:return {"terminal":false,"shop":false,"next_stage":2,"upgrades":0,"coins":7,"heal":10.0}
func fields(value:RefCounted)->Dictionary:
	var result:Dictionary={}
	for prop in value.get_property_list():
		if int(prop.usage)&PROPERTY_USAGE_SCRIPT_VARIABLE:result[str(prop.name)]=value.get(prop.name)
	return result
func snapshot()->PackedByteArray:
	return var_to_bytes({"world":fields(g.combat),"session":fields(g.run),"effects":fields(g.effects),"sequence":g.effect_sequence,"rng":[g.rng.state,g.shop_rng.state,g.loot_rng.state]})
func setup(mode_id:String)->void:
	g._title();g._select_mode(mode_id);g._start_run(3511);g.set_process(false)
	g.build.items={"mirror_shell":1,"echo_chamber":1,"medic_seed":1};g._recompute();g.effects.reset(g.build.items)
	g.build.coins=43;g.stats.hp=57;g.effects.echo_hits=2;g.effects.medic_damage=11;g.effects.cooldowns={"fixture":9.0}
	g.xp=3;g.elapsed=2.75;g.wave_time=5;g.hurt_clock=.3;g.weapon_clocks=[.37];g.combat.focus_enemy_id=77
	g.pickups=[{"pos":g.player_pos+Vector2(9,0),"xp":4,"coins":5,"heal":2}]
	g.bullets=[{"life":2.0,"id":61}];g.enemy_bullets=[{"life":3.0,"id":62}]
	g.pending_blasts=[{"id":63}];g.hazards=[{"id":64}];g.effect_visuals=[{"id":65}];g.flashes=[{"id":66}]
	g.shop_offers=[{"id":"rivet_gun","price":24}];g.reserved_offer={"id":"rail_lance","price":42};g.rewards=["fixture reward"]
func run()->void:
	for terminal in [false,true]:
		for shop in [false,true]:
			for upgrades in [0,1]:
				var data:=valid();data.terminal=terminal;data.shop=shop;data.upgrades=upgrades
				var expected:Array=["terminal cannot open shop or upgrade"] if terminal and (shop or upgrades>0) else []
				ck(Flow.validate_resolution(data)==expected,"valid boolean cross-field rule "+str([terminal,shop,upgrades]))
	var invalids:Array=[]
	for field in ["terminal","shop"]:
		for value in [null,"true","",0,1,0.0,1.0,INF,NAN,[],{}]:
			var data:=valid();data.terminal=true;data[field]=value
			var before:=var_to_bytes(data);var errors:Array=Flow.validate_resolution(data)
			ck(errors.has(field),"malformed boolean field rejected "+field+" "+str(value))
			ck(var_to_bytes(data)==before,"validation never normalizes input")
			invalids.append(data)
		var missing:=valid();missing.terminal=true;missing.erase(field)
		ck(Flow.validate_resolution(missing).has(field),"missing boolean rejected "+field);invalids.append(missing)
	for patch in [{"coins":-1},{"heal":INF},{"upgrades":-1},{"upgrades":1.0},{"next_stage":0},{"next_stage":null}]:
		var data:=valid();data.merge(patch,true);ck(not Flow.validate_resolution(data).is_empty(),"existing numeric guard unchanged "+str(patch));invalids.append(data)
	g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
	setup("arena")
	ck(fields(g.combat).size()>=10 and fields(g.run).size()>=15 and fields(g.effects).size()>=8,"snapshot includes full nonempty authority owners")
	for mode_id in ["arena","rooms"]:
		for decision in invalids:
			setup(mode_id)
			var policy:=Policy.new();policy.decision=decision
			var before:=snapshot()
			ck(Flow.settle(g.combat,g.run,policy,g.config,g.effects,g.encounters)=="invalid","real settle returns invalid "+mode_id)
			ck(snapshot()==before,"invalid settle preserves nonempty world/session/effects/RNG "+mode_id)
			var saved_mode=g.mode;g.mode=policy
			g.feedback_audio.request("player_damage")
			ck(g.feedback_audio.players.player_damage.playing,"audio active before invalid settlement")
			g._complete_wave()
			ck(snapshot()==before and g.feedback_audio.players.player_damage.playing,"controller invalid no stop/no mutation "+mode_id)
			g.mode=saved_mode;g.feedback_audio.stop_all()
		# Actual accepted settlement retains the original authoritative outcome.
		setup(mode_id);g.bullets.clear();g.enemy_bullets.clear();g.pending_blasts.clear();g.hazards.clear();g.effect_visuals.clear();g.flashes.clear()
		var policy:=Policy.new();policy.decision=valid()
		var coins_before:float=g.build.coins
		ck(Flow.settle(g.combat,g.run,policy,g.config,g.effects,g.encounters)=="next","valid policy still advances")
		ck(g.wave==2 and g.build.coins==coins_before+12 and g.stats.hp==69 and g.pickups.is_empty(),"valid pickup/heal/economy unchanged")
	var audio_teardown = preload("res://tests/support/audio_teardown.gd").new()
	audio_teardown.prepare([g])
	g.queue_free();await process_frame
	await audio_teardown.finish(self)
	var report:Dictionary={"checks":checks,"failures":failures,"scope":"Separate pre-existing malformed-boolean validator correction; valid policy and non-vacuous invalid-settle/controller preservation, not new audio behavior."}
	var args:=OS.get_cmdline_user_args()
	if not args.is_empty():FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print(JSON.stringify(report));quit(0 if failures.is_empty() else 1)
