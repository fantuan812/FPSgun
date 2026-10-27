extends SceneTree
## Native author HUD stress probe. Controlled legitimate slot/cap snapshots,
## not a claim that these simultaneous attacks were naturally acquired/launched.
var g
var checks:=0
var failures:Array=[]
var records:Array=[]
const CASES=[
	{"name":"two_lock_six_out","t":2,"d":2,"inside":0,"expected":"LOCK 3/4x2 · RING ↑6 ↓0"},
	{"name":"two_lock_mixed","t":2,"d":2,"inside":3,"expected":"LOCK 3/4x2 · RING ↑3 ↓3"},
	{"name":"three_lock_three_in","t":3,"d":1,"inside":3,"expected":"LOCK 3/4x3 · RING ↑0 ↓3"},
	{"name":"one_lock_nine_out","t":1,"d":3,"inside":0,"expected":"LOCK 3/4 · RING ↑9 ↓0"},
	{"name":"twelve_out","t":0,"d":4,"inside":0,"expected":"RING ↑12 ↓0"},
	{"name":"twelve_in","t":0,"d":4,"inside":12,"expected":"RING ↑0 ↓12"},
	{"name":"old_four_control","t":0,"d":0,"inside":0,"expected":""}
]
func ck(value:bool,label:String)->void:
	checks+=1
	if not value:failures.append(label)
func snapshot()->Dictionary:
	return {"build":g.build.duplicate(true),"stats":g.stats.duplicate(true),"rng":[g.rng.state,g.loot_rng.state,g.shop_rng.state],"clocks":g.weapon_clocks.duplicate(),"beams":g.combat.pulse_beams.duplicate(true),"waves":g.combat.seismic_waves.duplicate(true),"state":g.state}
func configure(row:Dictionary)->void:
	g.build.weapons=[]
	for _i in range(row.t):g.build.weapons.append("tether_emitter")
	for _i in range(row.d):g.build.weapons.append("seismic_drum")
	if g.build.weapons.is_empty():g.build.weapons=["rivet_gun","scrap_shotgun","rail_lance","orbit_saw"]
	g.build.weapon_temper=[0,0,0,0]
	g.build.items={"mirror_shell":1,"arc_relay":1,"feedback_diode":1,"return_collar":1}
	g.build.revision+=1;g._recompute()
	var enemy:Dictionary=g._spawn_kind("crawler",g.player_pos+Vector2(100,0))
	for slot in range(row.t):
		g.combat.pulse_beams.append({"epoch":g.combat.new_weapon_epoch,"slot_id":slot,"weapon_id":"tether_emitter","target_id":enemy.id,"damage":10.0,"range":280.0,"interval":1.2,"tier":0,"pulse_count":4,"pulse_index":3,"active_age":0.9,"wall_age":0.9,"memory_grace":0.0,"grace_left":0.0,"grace_spent":false,"was_outside":false})
	for index in range(row.d*3):
		var inward:bool=index<int(row.inside)
		g.combat.seismic_waves.append({"epoch":g.combat.new_weapon_epoch,"slot_id":int(row.t)+floori(float(index)/3.0),"weapon_id":"seismic_drum","sequence":index+1,"center":g.player_pos,"damage":22.0,"range":180.0,"initial_radius":24.0,"half_width":12.0,"outward_seconds":0.6,"return_enabled":true,"inward_seconds":0.45,"inward_damage_scale":0.5,"age":0.75 if inward else 0.3,"hit_out":{},"hit_in":{},"outward_done":inward})
	g.stats.dash_cooldown=0.0
	g.actor_anim.trigger(0,"attack",2.0)
func _initialize()->void:call_deferred("run")
func run()->void:
	if DisplayServer.get_name()=="headless":print("HUD_WIDTH_NATIVE_GATE_FAIL");quit(2);return
	g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
	await process_frame;await process_frame
	for size in [Vector2i(960,540),Vector2i(1280,720)]:
		root.size=size
		for mode in ["arena","rooms"]:
			for row in CASES:
				g._title();g._select_mode(mode);g._start_run(240102)
				configure(row)
				var before:Dictionary=snapshot();var view:Dictionary=g._view()
				g.ui.update_hud(view);g.queue_redraw();await process_frame;await process_frame
				var label:String=mode+"/"+str(size)+"/"+row.name
				ck(view.new_weapon_status==row.expected,"exact status from actual bounded arrays "+label)
				var expected:String="ATTACK  /  DASH READY"+(" / "+row.expected if not row.expected.is_empty() else "")
				ck(g.ui.hud_action.text==expected,"old action preserved with conditional suffix "+label)
				ck(root.get_visible_rect().encloses(g.ui.hud.get_global_rect()) and g.ui.hud.get_global_rect().encloses(g.ui.hud_action.get_global_rect()) and g.ui.hud_action.size.x>=g.ui.hud_action.get_minimum_size().x,"whole action text fits native HUD "+label)
				ck(g.ui.hp.size.x>=130 and g.ui.xp.size.x>=130 and not g.ui.hp.get_global_rect().intersects(g.ui.hud_action.get_global_rect()) and not g.ui.xp.get_global_rect().intersects(g.ui.hud_action.get_global_rect()),"bars retain minimum width and no overlap "+label)
				ck(snapshot()==before,"HUD/view no authority mutation "+label)
				records.append({"case":label,"status":view.new_weapon_status,"action":g.ui.hud_action.text,"action_rect":str(g.ui.hud_action.get_global_rect()),"hp_width":g.ui.hp.size.x,"xp_width":g.ui.xp.size.x,"module_status":view.mechanics.get("feedback_status","")})
				var dir:String=OS.get_environment("MOSS_A_HUD_IMAGES")
				if not dir.is_empty():root.get_texture().get_image().save_png(dir.path_join(mode+"_"+str(size.x)+"_"+row.name+".png"))
	var teardown=preload("<WORKSPACE>/moss-v39-ui/pck-ui-buttons/support/audio_teardown.gd").new();teardown.prepare([g]);g.queue_free();await process_frame;await teardown.finish(self)
	print(JSON.stringify({"checks":checks,"failures":failures,"records":records,"scope":"controlled native actual view/arrays HUD width, not natural launch or acquisition"}))
	quit(0 if failures.is_empty() else 1)
