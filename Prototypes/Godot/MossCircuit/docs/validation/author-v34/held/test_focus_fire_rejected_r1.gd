extends SceneTree
const Focus=preload("res://scripts/gameplay/combat_focus.gd")
const Rules=preload("res://scripts/rules.gd")
const Runtime=preload("res://scripts/gameplay/combat_runtime.gd")
var g
var passed:=0
var failures:Array=[]
const IDS=["rivet_gun","scrap_shotgun","rail_lance","orbit_saw","return_disc","shock_mortar","cryo_sprayer","bankshot_driver"]
func ck(ok:bool,label:String)->void:
	if ok:passed+=1
	else:failures.append(label)
func _initialize()->void:call_deferred("run")
func setup(mode:String,id:String,tempered:bool=false)->void:
	g._title();g._select_mode(mode);g._start_run(3402);g.set_process(false);g.build.weapons=[id]
	if tempered:g.build.weapon_temper=[1]
	g._recompute();g.weapon_clocks=[.37];g.combat_frame.area=g.config.arena
func enemy(offset:Vector2,kind:String="crawler")->Dictionary:
	var e:Dictionary=g._spawn_kind(kind,g.player_pos+offset);e.hp=1000.0;e.max_hp=1000.0;e.anim_hp=1000.0;e.speed=0.0;e.cooldown_left=999.0
	return e
func settle(id:String)->void:
	match id:
		"shock_mortar":g.effect_runtime.advance_mortars(.6)
		"bankshot_driver":
			for b in g.bullets:g.weapon_combat.advance_bankshot(b,.3)
		"return_disc":
			for b in g.bullets:g.weapon_combat.advance_disc(b,.3)
		"cryo_sprayer","orbit_saw":pass
		_:
			for b in g.bullets:g.weapon_combat.advance_bullet(b,.3)
func aims_at(point:Vector2)->bool:
	if g.weapon_rig.last_shot.is_empty():return false
	var pose:Dictionary=g.weapon_rig.last_shot.pose
	return Geometry2D.get_closest_point_to_segment(point,pose.muzzle,pose.muzzle+pose.direction*2000).distance_to(point)<.01
func run()->void:
	g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
	for mode in ["arena","rooms"]:
		for id in IDS:
			for tempered in [false,true]:
				setup(mode,id,tempered);var near:Dictionary=enemy(Vector2(0,50));var marked:Dictionary=enemy(Vector2(110,0));g.combat.focus_enemy_id=marked.id
				var rngs:Array=[g.rng.state,g.loot_rng.state,g.shop_rng.state];var clocks:Array=g.weapon_clocks.duplicate();g._fire_weapon(id,0)
				if id!="orbit_saw":ck(aims_at(marked.pos),"actual launch pose prefers farther mark "+mode+id+str(tempered))
				if id=="shock_mortar":ck(g.pending_blasts[0].pos==marked.pos,"Mortar snapshots chosen position")
				if id=="cryo_sprayer":ck(g.effect_visuals.filter(func(v):return v.kind=="cryo_cone")[0].direction==Vector2.RIGHT,"Cryo orientation preference")
				settle(id)
				ck(marked.hp<1000,"actual marked primary hit "+mode+id+str(tempered))
				ck(near.hp<1000 if id=="orbit_saw" else near.hp==1000,"Orbit radial / other paths do not prefer distractor "+id)
				ck(rngs==[g.rng.state,g.loot_rng.state,g.shop_rng.state] and clocks==g.weapon_clocks,"focus fire no RNG or direct-call clock rewrite "+id)
				await process_frame
			# Outside THIS copy's reach falls back, retaining the living mark.
			setup(mode,id);var near:Dictionary=enemy(Vector2(0,50));var weapon:Dictionary=Rules.catalog_entry(g.catalog,id)
			var reach:float=Rules.weapon_reach(weapon,g.stats);var distant:Dictionary=enemy(Vector2(reach+10,0));g.combat.focus_enemy_id=distant.id
			g._fire_weapon(id,0);settle(id)
			ck(near.hp<1000 and distant.hp==1000,"out-of-range fallback actual hit "+id)
			ck(g.combat.focus_enemy_id==distant.id,"out of range does not clear "+id)
			await process_frame
		# Distinct legacy tie policies remain, even when array IDs are reversed.
		for id in ["rivet_gun","shock_mortar","cryo_sprayer","bankshot_driver"]:
			setup(mode,id);var low:Dictionary=enemy(Vector2(100,0));var high:Dictionary=enemy(Vector2(0,100));g.enemies=[high,low]
			g._fire_weapon(id,0)
			ck(aims_at(low.pos if id in ["cryo_sprayer","bankshot_driver"] else high.pos),"AUTO original tie semantics "+id)
			await process_frame
		# Reach tolerance belongs only to the existing ordered paths.
		for id in IDS:
			setup(mode,id);var w:Dictionary=Rules.catalog_entry(g.catalog,id);var r:float=Rules.weapon_reach(w,g.stats)
			var e:Dictionary=enemy(Vector2(r,0));g.combat.focus_enemy_id=e.id
			ck(not Focus.eligible(g.enemies,e.id,g.player_pos,w,g.stats).is_empty() if id!="orbit_saw" else Focus.eligible(g.enemies,e.id,g.player_pos,w,g.stats).is_empty(),"exact reach / Orbit exclusion "+id)
			e.pos=g.player_pos+Vector2(r+.01,0);ck(Focus.eligible(g.enemies,e.id,g.player_pos,w,g.stats).is_empty(),"beyond reach "+id)
			await process_frame
		# Existing flights do not read the changing preference.
		for id in ["rivet_gun","return_disc","shock_mortar","bankshot_driver"]:
			setup(mode,id);var near:Dictionary=enemy(Vector2(0,50));var marked:Dictionary=enemy(Vector2(110,0));g.combat.focus_enemy_id=marked.id;g._fire_weapon(id,0)
			var shots:Array=g.bullets.duplicate(true);var blasts:Array=g.pending_blasts.duplicate(true);g.combat.focus_enemy_id=near.id
			ck(g.bullets==shots and g.pending_blasts==blasts,"change mark never mutates flight "+id)
			settle(id);ck(marked.hp<1000 and near.hp==1000,"previous flight still hits original lane "+id)
			await process_frame
		# A primary can still be intercepted before reaching the preferred enemy.
		setup(mode,"rivet_gun");var blocker:Dictionary=enemy(Vector2(65,0));var target:Dictionary=enemy(Vector2(140,0));g.combat.focus_enemy_id=target.id;g._fire_weapon("rivet_gun",0)
		g.weapon_combat.advance_bullet(g.bullets[0],.35);ck(blocker.hp<1000 and target.hp==1000,"priority is not guaranteed hit/piercing")
		await process_frame
		# Immediate first slot kills the priority; the later slot falls back before removal.
		setup(mode,"cryo_sprayer");g.build.weapons=["cryo_sprayer","rivet_gun"];g._recompute();g.weapon_clocks=[0.0,0.0]
		var marked:Dictionary=enemy(Vector2(100,0));marked.hp=1;var distractor:Dictionary=enemy(Vector2(0,60));g.combat.focus_enemy_id=marked.id
		Runtime.step(g.combat_frame,0.0)
		ck(g.bullets.size()==1 and aims_at(distractor.pos),"later slot rejects killed focus before removal")
		ck(g.combat.focus_enemy_id==0 and not g.enemies.has(marked),"death pass clears without reassignment")
		await process_frame
		# Focus never bypasses Amber Ram brace; primary event still originates at player/flight.
		setup(mode,"cryo_sprayer",true);var ram:Dictionary=enemy(Vector2(100,0),"charger");ram.ai_state="warning";ram.attack="charge";ram.aim=Vector2.LEFT;g.combat.focus_enemy_id=ram.id;g._fire_weapon("cryo_sprayer",0)
		ck(is_equal_approx(ram.hp,992.8),"tempered focus primary still halves at brace")
		await process_frame
	g.queue_free();await process_frame
	print(JSON.stringify({"passed":passed,"failures":failures,"scope":"Controlled actual8-path primary/pose, mixed tier, fallback, interception, snapshot and same-step-death checks; not ordinary damage/balance proof."}));quit(0 if failures.is_empty() else 1)
