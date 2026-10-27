extends SceneTree
const Rules=preload("res://scripts/rules.gd")
const Temper=preload("res://scripts/gameplay/weapon_tempering.gd")
const Status=preload("res://scripts/gameplay/target_status.gd")
const Runtime=preload("res://scripts/gameplay/combat_runtime.gd")
var game
var passed:=0
var failures:Array=[]
var hit_events:Array=[]
func _initialize()->void:call_deferred("run")
func check(value:bool,label:String)->void:
	if value:passed+=1
	else:failures.append(label)
func capture(kind:String,data:Dictionary)->void:
	if kind=="hit":hit_events.append(data.duplicate(true))
	game._effect_event(kind,data)
func setup(mode:String,id:String,tempered:bool=true,copies:int=2)->void:
	game._title();game._select_mode(mode);game._start_run(3302);game.set_process(false)
	game.build.weapons=[]
	for _copy in range(copies):game.build.weapons.append(id)
	game._recompute();game.state="shop"
	if tempered:check(game._temper_weapon(0,1,game.shop_generation,id,id),"actual fusion setup "+id)
	game.state="playing";game.combat_frame.area=game.config.arena;hit_events.clear()
func target(guarded:bool=false,offset:Vector2=Vector2(90,0))->Dictionary:
	var enemy:Dictionary=game._spawn_kind("charger" if guarded else "crawler",game.player_pos+offset)
	enemy.hp=1000.0;enemy.max_hp=1000.0;enemy.anim_hp=1000.0;enemy.speed=0.0;enemy.cooldown_left=999.0
	if guarded:enemy.ai_state="warning";enemy.attack="charge";enemy.aim=Vector2.LEFT
	return enemy
func resolve_one(id:String,enemy:Dictionary,offcenter_mortar:bool=false)->void:
	var weapon:Dictionary=Rules.catalog_entry(game.catalog,id)
	match str(weapon.behavior):
		"single","spread","pierce","return":
			# One real contact using a launched shot; spread checks one authored pellet.
			var shot:Dictionary=game.bullets[0]
			game.weapon_combat.hit_segment(shot,enemy.pos-Vector2(30,0),enemy.pos+Vector2(30,0))
		"field_bankshot":game.weapon_combat.advance_bankshot(game.bullets[0],.3)
		"mortar":
			if offcenter_mortar:game.pending_blasts[0].pos=enemy.pos-Vector2(40,0)
			game.effect_runtime.advance_mortars(.6)
func run()->void:
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.set_process(false)
	game.weapon_combat.effect_event=capture
	var expected:Dictionary={"rivet_gun":24.0,"scrap_shotgun":14.4,"rail_lance":48.0,"orbit_saw":32.0,"return_disc":28.8,"shock_mortar":57.6,"cryo_sprayer":14.4,"bankshot_driver":28.8}
	for mode in ["arena","rooms"]:
		for id in expected:
			var weapon:Dictionary=Rules.catalog_entry(game.catalog,id)
			for guarded in [false,true]:
				setup(mode,id);var enemy:Dictionary=target(guarded)
				game._fire_weapon(id,0)
				check(is_equal_approx(game._view().weapons[0].weapon_readout.damage,expected[id]),"current copy readout "+id+mode)
				for shot in game.bullets:check(is_equal_approx(shot.damage,expected[id]),"launch snapshot "+id+mode)
				for blast in game.pending_blasts:check(is_equal_approx(blast.damage,expected[id]),"mortar snapshot "+mode)
				resolve_one(id,enemy,guarded)
				var resolved:float=expected[id]*(.5 if guarded else 1.0)
				check(is_equal_approx(1000.0-enemy.hp,resolved),"actual primary then brace "+str([mode,id,guarded]))
				if id=="shock_mortar":check(hit_events.is_empty() and game.effect_runtime.sequence==2,"one primary plus existing mortar event committed through effect runtime "+str(guarded))
				else:check(hit_events.size()==1 and is_equal_approx(hit_events[0].damage,resolved),"one resolved nominal event "+id+str(guarded))
				if id=="cryo_sprayer":check(Status.chilled(enemy,game.elapsed),"tempered Cryo retains surviving mark")
				await process_frame
			# One fused copy and one independently acquired standard copy of the same ID.
			setup(mode,id,true,3);target();game._fire_weapon(id,1)
			check(game.build.weapon_temper==[1,0],"mixed same ID tiers "+id)
			check(is_equal_approx(game._view().weapons[1].weapon_readout.damage,weapon.damage),"mixed standard readout "+id)
			for shot in game.bullets:check(is_equal_approx(shot.damage,weapon.damage),"mixed standard launch "+id)
			for blast in game.pending_blasts:check(is_equal_approx(blast.damage,weapon.damage),"mixed standard blast "+id)
			await process_frame
		# Existing contact/late-hit code reads only stored nominal damage, not mutable tiers.
		for id in ["rivet_gun","scrap_shotgun","rail_lance","return_disc","shock_mortar","bankshot_driver"]:
			setup(mode,id);var enemy:Dictionary=target();game._fire_weapon(id,0)
			game.build.weapon_temper[0]=0
			resolve_one(id,enemy)
			check(is_equal_approx(1000.0-enemy.hp,expected[id]),"late hit keeps launched tier damage "+id)
			await process_frame
		for slot in [0,7,-1]:
			setup(mode,"rivet_gun");target();game._fire_weapon("rail_lance",slot)
			check(game.bullets.size()==1 and game.bullets[0].damage==30.0,"legacy mismatched direct fire standard "+str(slot))
		# Fixed + derived proc boundary, after the real brace-resolved primary event.
		setup(mode,"rivet_gun");game.build.items={"arc_relay":1,"fracture_coil":1,"echo_chamber":1};game._recompute()
		var first:Dictionary=target(true);var second:Dictionary=target(false,Vector2(90,100))
		Status.apply_chill(first,game.elapsed,Rules.catalog_entry(game.catalog,"cryo_sprayer"));game.effects.echo_hits=4
		game._fire_weapon("rivet_gun",0);resolve_one("rivet_gun",first)
		check(is_equal_approx(first.hp,960.0),"brace12 plus fixed Fracture16 Echo12 "+mode)
		check(is_equal_approx(second.hp,995.2),"Arc 40pct of resolved12 not tier twice "+mode)
		check(hit_events.size()==1 and hit_events[0].damage==12.0 and not Status.chilled(first,game.elapsed),"single primary proc event and consume "+mode)
		check(first.last_source=="echo" and second.last_source=="chain","actual secondary attribution retained "+mode)
		# Actual shared equal-target one-cycle comparison: 2x15 versus one24, not DPS proof.
		var pair_damage:float=0.0
		for fused in [false,true]:
			setup(mode,"rivet_gun",fused);var enemy:Dictionary=target();game.weapon_clocks=[]
			for _id in game.build.weapons:game.weapon_clocks.append(0.0)
			Runtime.step(game.combat_frame,.3)
			if not fused:pair_damage=1000.0-enemy.hp
			else:check(is_equal_approx(pair_damage,30.0) and is_equal_approx(1000.0-enemy.hp,24.0),"one cycle sacrifices independent timer "+mode)
	game.queue_free();await process_frame
	print(JSON.stringify({"passed":passed,"failed":failures.size(),"failures":failures}))
	quit(0 if failures.is_empty() else 1)
