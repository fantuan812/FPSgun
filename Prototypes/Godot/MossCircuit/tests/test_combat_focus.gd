extends SceneTree
const Focus=preload("res://scripts/gameplay/combat_focus.gd")
const Runtime=preload("res://scripts/gameplay/combat_runtime.gd")
const Rules=preload("res://scripts/rules.gd")
var g
var passed:=0
var failures:Array=[]
func ck(ok:bool,label:String)->void:
	if ok:passed+=1
	else:failures.append(label)
func _initialize()->void:call_deferred("run")
func fake(id:int,pos:Vector2,scale:float=1.0)->Dictionary:return {"id":id,"pos":pos,"scale":scale,"hp":100.0}
func setup(mode:String,ids:Array=["rivet_gun","cryo_sprayer","orbit_saw"])->void:
	g._title();g._select_mode(mode);g._start_run(3401);g.set_process(false)
	g.build.weapons=ids.duplicate();g.build.items={"echo_chamber":1,"mirror_shell":1,"phase_capacitor":1};g._recompute()
	g.weapon_clocks=[.3,.5,.7].slice(0,ids.size());g.stats.hp=57.5;g.stats.dash_cooldown=1.2
	g.effects.echo_hits=3;g.effects.phase_charge=2;g.effects.cooldowns={"fixture":3.25}
	g._update_hud()
func enemy(offset:Vector2,kind:String="crawler")->Dictionary:
	var e:Dictionary=g._spawn_kind(kind,g.player_pos+offset);e.hp=1000.0;e.max_hp=1000.0;e.anim_hp=1000.0;e.speed=0;e.cooldown_left=999
	return e
func vp(point:Vector2)->Vector2:return g.get_global_transform_with_canvas()*point
func snap()->Dictionary:
	var rig:Array=[]
	for s in g.weapon_rig.slots:rig.append({"id":s.id,"age":s.age,"pose":s.pose.duplicate(true),"aim":s.aim,"sprite":s.sprite.get_instance_id()})
	return {"build":g.build.duplicate(true),"stats":g.stats.duplicate(true),"clocks":g.weapon_clocks.duplicate(),"rng":[g.rng.state,g.shop_rng.state,g.loot_rng.state],"generations":[g.shop_generation,g.choice_generation],"offers":g.shop_offers.duplicate(true),"held":g.reserved_offer.duplicate(true),"enemies":g.enemies.duplicate(true),"bullets":g.bullets.duplicate(true),"blasts":g.pending_blasts.duplicate(true),"hazards":g.hazards.duplicate(true),"visuals":g.effect_visuals.duplicate(true),"effects":[g.effects.epoch,g.effects.last_sequence,g.effect_runtime.sequence,g.effects.echo_hits,g.effects.phase_charge,g.effects.cooldowns.duplicate(true),g.effects.shield],"rig":rig,"rig_time":[g.weapon_rig.visible_clock,g.weapon_rig.generation,g.weapon_rig.last_shot.duplicate(true)]}
func run()->void:
	var one:=fake(7,Vector2.ZERO)
	for x in range(-28,29,4):
		for y in range(-28,29,4):ck(Focus.pick([one],Vector2(x,y))==(7 if x*x+y*y<=576 else 0),"closed pick disk "+str([x,y]))
	ck(Focus.pick([one],Vector2(24.0001,0))==0,"pick just outside")
	ck(Focus.pick([fake(9,Vector2(-8,0)),fake(2,Vector2(8,0))],Vector2.ZERO)==2,"overlap tie ID")
	ck(Focus.pick([fake(2,Vector2(8,0)),fake(9,Vector2(-8,0))],Vector2.ZERO)==2,"reversed tie same")
	ck(Focus.pick([fake(2,Vector2(8,0)),fake(9,Vector2(-7,0))],Vector2.ZERO)==9,"distance before ID")
	for bad in [null,{},[],0,true,"point",Vector2(NAN,0),Vector2(INF,0)]:ck(Focus.pick([one],bad)==-1,"invalid point sentinel")
	for patch in [{"id":true},{"id":1.0},{"id":0},{"hp":0},{"hp":INF},{"pos":Vector2(NAN,0)},{"pos":Vector2(1e30,0)},{"scale":true},{"scale":0},{"scale":INF},{"scale":1e200}]:
		var bad:Dictionary=one.duplicate(true);bad.merge(patch,true);ck(Focus.pick([bad],Vector2.ZERO)==0,"invalid actor/intermediate "+str(patch))
	g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
	for mode in ["arena","rooms"]:
		setup(mode);await process_frame;await process_frame
		var near:Dictionary=enemy(Vector2(0,70));var far:Dictionary=enemy(Vector2(300,0))
		var before:Dictionary=snap();ck(g._focus_click(vp(far.pos)),"actual viewport controller selects "+mode)
		ck(g.combat.focus_enemy_id==far.id and snap()==before,"selection only changes focus "+mode)
		ck(not g._focus_click(vp(far.pos)) and snap()==before,"same target true no-op "+mode)
		var focus_view:Dictionary=g._focus_view();ck(focus_view.active and focus_view.eligible==1 and focus_view.directional==2,"per-copy range count excludes Orbit")
		ck(g._view().focus==focus_view and snap()==before,"view pure")
		var times:Array=[g.weapon_rig.visible_clock,g.weapon_rig.generation,g.weapon_rig.slots.map(func(s):return s.age),g.weapon_rig.last_shot.duplicate(true)]
		g._sync_weapon_rig()
		ck(g.weapon_rig.slots[0].pose.direction.x>.9,"long-range idle prefers mark")
		ck(g.weapon_rig.slots[1].pose.direction.y>.9,"short-range idle retains old nearest")
		ck(g.weapon_rig.slots[2].pose.direction.y>.9,"Orbit idle retains old nearest")
		ck(times==[g.weapon_rig.visible_clock,g.weapon_rig.generation,g.weapon_rig.slots.map(func(s):return s.age),g.weapon_rig.last_shot.duplicate(true)],"idle focus does not reset rig time/history")
		g.stats.range_bonus=2.0;ck(g._focus_view().eligible==2,"range modifiers reflected")
		g.stats.range_bonus=0.0
		for point in [Vector2(-1,250),Vector2(960,250),Vector2(250,-1),Vector2(250,540),Vector2(NAN,0),"point"]:
			ck(not g._focus_click(point) and g.combat.focus_enemy_id==far.id,"invalid viewport never clears")
		g._update_hud();await process_frame
		var blocked:Array=[g.ui.hud.get_global_rect().get_center(),g.mode_status.objective.get_global_rect().get_center()]
		if mode=="rooms":blocked.append(g.mode_status.badge.position+Vector2(20,20))
		for point in blocked:ck(not g._focus_click(point) and g.combat.focus_enemy_id==far.id,"visible HUD/mode rectangles never clear")
		var boss:Dictionary=enemy(Vector2(-100,0),"boss_warden");g._update_hud();await process_frame
		ck(not g._focus_click(g.ui.boss_panel.get_global_rect().get_center()) and g.combat.focus_enemy_id==far.id,"boss bar excludes picking")
		for state in ["paused","inventory","settings","codex","upgrade","shop","room_clear","title","dead","won"]:
			g.state=state;ck(not g._focus_click(vp(near.pos)) and g.combat.focus_enemy_id==far.id,"nonplaying input ignored "+state)
		g.state="playing"
		var release:=InputEventMouseButton.new();release.button_index=MOUSE_BUTTON_LEFT;release.position=vp(near.pos);release.pressed=false;g._unhandled_input(release)
		ck(g.combat.focus_enemy_id==far.id,"release ignored")
		release.pressed=true;release.button_index=MOUSE_BUTTON_RIGHT;g._unhandled_input(release);ck(g.combat.focus_enemy_id==far.id,"right click ignored")
		var motion:=InputEventMouseMotion.new();motion.position=vp(near.pos);motion.button_mask=MOUSE_BUTTON_MASK_LEFT;g._unhandled_input(motion);ck(g.combat.focus_enemy_id==far.id,"held drag ignored")
		g._on_intent("pause",{});ck(g.combat.focus_enemy_id==far.id,"pause retains")
		g._on_intent("settings",{});ck(g.combat.focus_enemy_id==far.id,"settings retains")
		g._on_intent("close_settings",{});g._on_intent("resume",{})
		g._on_intent("inventory",{});ck(g.combat.focus_enemy_id==far.id,"inventory retains")
		g._on_intent("close_inventory",{});g._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
		ck(g.state=="paused" and g.combat.focus_enemy_id==far.id,"focus loss pauses and retains")
		g._on_intent("resume",{});g.upgrade_pending=1;g._show_upgrades();ck(g.combat.focus_enemy_id==far.id,"upgrade retains")
		g._take_upgrade(0,g.choice_generation);ck(g.combat.focus_enemy_id==far.id,"upgrade resolution retains")
		g._hide_modal();g.state="playing";g._update_hud();await process_frame
		ck(g._focus_click(vp(g.player_pos+Vector2(-150,100))) and g.combat.focus_enemy_id==0,"empty valid ground AUTO")
		g.combat.focus_enemy_id=far.id;far.hp=0;before=snap()
		ck(not g._focus_view().active and g.combat.focus_enemy_id==far.id and snap()==before,"dead view AUTO without authority write")
		Runtime._prune_focus(g.combat);ck(g.combat.focus_enemy_id==0,"shared boundary prunes death")
		g.combat.focus_enemy_id=999;Runtime._prune_focus(g.combat);ck(g.combat.focus_enemy_id==0,"removed ID prunes")
		g.combat.focus_enemy_id=near.id;g._begin_room_clear();ck(g.combat.focus_enemy_id==0,"room clear clears")
		for terminal in [false,true]:
			setup(mode);near=enemy(Vector2(100,0));g.combat.focus_enemy_id=near.id;g._finish(terminal);ck(g.combat.focus_enemy_id==0,"terminal clears "+str(terminal))
		setup(mode);near=enemy(Vector2(100,0));g.combat.focus_enemy_id=near.id;g._title();ck(g.combat.focus_enemy_id==0,"title clears")
		g._start_run(3401);ck(g.combat.focus_enemy_id==0,"new run no reused ID focus")
		setup(mode);near=enemy(Vector2(100,0));g.combat.focus_enemy_id=near.id;g.wave_time=30
		if mode=="arena":g._complete_wave();ck(g.combat.focus_enemy_id==0,"actual arena settlement clears")
	var audio_teardown = preload("res://tests/support/audio_teardown.gd").new()
	audio_teardown.prepare([g])
	g.queue_free();await process_frame
	await audio_teardown.finish(self)
	print(JSON.stringify({"passed":passed,"failures":failures,"scope":"Controlled geometry, input gate, purity, range-aware idle presentation and lifecycle; actual GUI dispatch/native input independently required."}));quit(0 if failures.is_empty() else 1)
