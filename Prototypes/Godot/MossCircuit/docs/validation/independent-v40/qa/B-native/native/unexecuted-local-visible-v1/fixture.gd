extends SceneTree
## Unexecuted controlled B native UI candidate. Not natural acquisition.
const Combat=preload("res://scripts/gameplay/combat_runtime.gd")
const Motor=preload("res://scripts/gameplay/character_motor.gd")
const Layout=preload("res://scripts/gameplay/field_layout.gd")
const Teardown=preload("evidence-workspace/moss-v39-ui/B/native/support/audio_teardown.gd")
const IDS=["crossfire_pin","salvage_capacitor","medic_winch"]
const NAMES=["Crossfire Pin","Salvage Capacitor","Medic Winch"]
var g
var checks:int=0
var failures:Array=[]
var records:Array=[]
var current:Dictionary={}
var mode_id:String=""
var prefix:String=""
var oracle:Dictionary={}
func ck(ok:bool,label:String)->void:
	checks+=1
	current.assertions.append({"label":label,"pass":ok})
	if not ok:failures.append(str(current.id)+" / "+label)
func scene(id:String)->void:
	current={"id":id,"assertions":[],"stages":[]};records.append(current)
func nodes(node:Node)->Array:
	var out:Array=[node]
	for child in node.get_children():out.append_array(nodes(child))
	return out
func button(text:String)->Button:
	var found:Array=nodes(g.ui).filter(func(n):return n is Button and n.text==text and n.is_visible_in_tree())
	return found[0] if found.size()==1 else null
func label_start(text:String)->Label:
	var found:Array=nodes(g.ui).filter(func(n):return n is Label and n.text.begins_with(text) and n.is_visible_in_tree())
	return found[0] if found.size()==1 else null
func scroll_of(node:Node)->ScrollContainer:
	var n:Node=node
	while n!=null:
		if n is ScrollContainer:return n
		n=n.get_parent()
	return null
func pointer(at:Vector2,which:int,pressed:bool)->void:
	var e:=InputEventMouseButton.new();e.position=at;e.global_position=at;e.button_index=which;e.pressed=pressed
	root.push_input(e,true)
func click(at:Vector2)->void:pointer(at,MOUSE_BUTTON_LEFT,true);pointer(at,MOUSE_BUTTON_LEFT,false)
func key(code:int,shift:bool=false)->void:
	for pressed in [true,false]:
		var e:=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.shift_pressed=shift;e.pressed=pressed;root.push_input(e,true)
func frames()->void:
	await process_frame;await process_frame
func refresh()->void:
	g.hero.position=g.player_pos.round();g.camera.position=Layout.camera_position(g.player_pos,g.config.arena)
	for e in g.enemies:
		if is_instance_valid(e.get("sprite")):e.sprite.position=e.pos.round()
	g._update_hud();g._sync_telegraphs();g.queue_redraw()
	await frames()
func small()->Dictionary:return g._build_items_view()
func state()->Dictionary:return g.effect_runtime.build_items.debug_snapshot()
func hash_bytes(value:PackedByteArray)->String:
	var h:=HashingContext.new();h.start(HashingContext.HASH_SHA256);h.update(value);return h.finish().hex_encode()
func stage(name:String)->void:
	await refresh()
	var filename:String=prefix+"_"+str(current.id)+"_"+name+".png"
	var image:Image=root.get_texture().get_image()
	var save_error:int=image.save_png(OS.get_environment("MOSS_B_UI_IMAGES").path_join(filename))
	var owner:Control=root.gui_get_focus_owner()
	current.stages.append({"name":name,"image":filename,"save_error":save_error,"logical":str(root.get_visible_rect()),"os_size":str(DisplayServer.window_get_size()),"os_position":str(DisplayServer.window_get_position()),"content_scale":str(root.content_scale_size),"state":g.state,"elapsed":g.elapsed,"projection":small(),"B_snapshot_sha256":hash_bytes(JSON.stringify(state()).to_utf8_buffer()),"focus_enemy":g.combat.focus_enemy_id,"keyboard_focus":str(owner.get_path()) if owner!=null else "","reduced":g.settings.reduced_flashes})
	print("B_NATIVE_IMAGE "+JSON.stringify(current.stages[-1]))
func start(items:Dictionary={},weapons:Array=["rivet_gun","scrap_shotgun"])->void:
	g._title();g._select_mode(mode_id);g._start_run(39031);g.set_process(false)
	g.build.items=items.duplicate(true);g.build.weapons=weapons.duplicate();g.build.weapon_temper=[]
	for _id in weapons:g.build.weapon_temper.append(0)
	g._recompute();g.player_pos=Vector2(300,300);g.weapon_clocks=[]
	for _id in weapons:g.weapon_clocks.append(999.0)
	g.combat_frame.area=g.config.arena;g.settings.reduced_flashes=false
	await refresh()
func owned3()->Dictionary:return {"crossfire_pin":1,"salvage_capacitor":1,"medic_winch":1}
func begin()->void:g.combat.combat_tick_serial+=1;g.effect_runtime.begin_build_items_step(g.config.arena)
func enemy(pos:Vector2)->Dictionary:
	var e:Dictionary=g._spawn_kind("crawler",pos);e.hp=1000.0;e.max_hp=1000.0;e.anim_hp=1000.0;e.speed=0.0;e.damage=0.0;return e
func hit(e:Dictionary,weapon:String)->void:g._effect_event("hit",{"target":e.id,"pos":e.pos,"weapon":weapon,"source":"primary","depth":0,"damage":0.0})
func normal_pickups(count:int)->void:
	for _i in range(count):g.pickups.append({"pos":g.player_pos,"xp":0,"coins":1})
	Combat.step(g.combat_frame,0.0)
func dash()->bool:
	var origin:Vector2=g.player_pos;g.stats.dash_cooldown=0.0
	var started:bool=Motor.step(g.combat,g.config.arena,Vector2.RIGHT,true,.01)
	if started:g._effect_event("dash",{"pos":origin,"angle":0.0})
	return started
func open_build()->bool:
	await refresh();var b:Button=button("BUILD [I]")
	if b==null:return false
	click(b.get_global_rect().get_center());await frames();return g.state=="inventory" and g.ui.modal.visible
func escape()->void:key(KEY_ESCAPE);await frames()
func fit_rect(scroll:ScrollContainer,rect:Rect2)->bool:return scroll.get_global_rect().encloses(rect)
func scroll_group(first:Control,last:Control)->bool:
	if first==null or last==null:return false
	var scroll:ScrollContainer=scroll_of(first)
	if scroll==null:return false
	for _step in range(24):
		var rect:Rect2=first.get_global_rect().merge(last.get_global_rect())
		if fit_rect(scroll,rect):return true
		var which:int=MOUSE_BUTTON_WHEEL_DOWN if rect.end.y>scroll.get_global_rect().end.y else MOUSE_BUTTON_WHEEL_UP
		pointer(scroll.get_global_rect().get_center(),which,true);pointer(scroll.get_global_rect().get_center(),which,false);await frames()
	return fit_rect(scroll,first.get_global_rect().merge(last.get_global_rect()))
func focus_cycle(reverse:bool)->bool:
	var seen:Array=[];var paths:Array=[];var closed:bool=false;var isolated:bool=true
	for _i in range(64):
		key(KEY_TAB,reverse);await process_frame;var owner:Control=root.gui_get_focus_owner()
		if owner==null:isolated=false;break
		var path:String=str(owner.get_path());paths.append(path)
		if not g.ui.modal.is_ancestor_of(owner):isolated=false;break
		if seen.has(path):closed=path==seen[0];break
		seen.append(path)
	current["reverse_cycle" if reverse else "forward_cycle"]={"paths":paths,"closed":closed,"isolated":isolated}
	return closed and isolated
func ui_rows()->Array:return small().rows
func rendered_row(index:int,row:Dictionary)->bool:
	var label:Label=label_start(NAMES[index]+":")
	if label==null:return false
	var detail:Node=label.get_parent().get_child(label.get_index()+1)
	return label.text==NAMES[index]+": "+str(row.status) and detail is Label and detail.text==str(row.detail)
func hud_focus()->Array:
	var out:Array=[]
	for text in ["BUILD [I]","PAUSE [ESC]"]:
		var b:Button=button(text);out.append(b.focus_mode if b!=null else -1)
	return out
func icon_identity(tex:Texture2D,id:String)->bool:
	if not tex is AtlasTexture or not oracle.has(id):return false
	var e:Dictionary=oracle[id]
	if tex.atlas.resource_path!=str(e.atlas) or tex.region!=Rect2(e.rect[0],e.rect[1],e.rect[2],e.rect[3]):return false
	var im:Image=tex.get_image()
	if im==null:return false
	if im.is_compressed():im.decompress()
	im.clear_mipmaps();im.convert(Image.FORMAT_RGBA8);var bytes:PackedByteArray=im.get_data()
	for i in range(0,bytes.size(),4):
		if bytes[i+3]==0:bytes[i]=0;bytes[i+1]=0;bytes[i+2]=0
	return hash_bytes(bytes)==str(e.visible_rgba_sha256)
func case01()->void:
	scene("01_old_build");await start();var focus:int=g.combat.focus_enemy_id;var hud:Array=[g.ui.hud_action.text,g.ui.hud_detail.text]
	ck(small()=={"rows":[],"pin":{},"fields":[]},"no owned B empty projection");await stage("before")
	var opened:bool=await open_build();ck(opened and label_start("CONTROL MODULES / LIVE SNAPSHOT")==null,"actual BUILD no B section");await stage("build")
	await escape();ck(g.state=="playing" and not g.ui.modal.visible,"Escape closes");await stage("closed")
	ck(g.combat.focus_enemy_id==focus and [g.ui.hud_action.text,g.ui.hud_detail.text]==hud,"old HUD and focus unchanged")
func case02()->void:
	scene("02_three_cards");await start(owned3());await open_build()
	ck(state().owned_items==owned3(),"exact B ownership")
	for i in range(3):
		var title:Label=label_start(NAMES[i]+"  x")
		var card:Control=title.get_parent().get_parent().get_parent() if title!=null else null
		var fitted:bool=await scroll_group(card,card)
		ck(fitted,"whole card "+IDS[i])
		var tex:Texture2D=null
		if card!=null:
			var textures:Array=nodes(card).filter(func(n):return n is TextureRect)
			if textures.size()==1:tex=textures[0].texture
		ck(icon_identity(tex,IDS[i]),"actual card icon identity "+IDS[i]);await stage(IDS[i])
func case03()->void:
	scene("03_summaries");await start(owned3(),["rivet_gun","rivet_gun"]);await open_build()
	var fixed_ok:bool=true;var horizontal_ok:bool=true
	for i in range(3):
		var first:Label=label_start(NAMES[i]+":")
		var last:Control=null
		if first!=null:last=first.get_parent().get_child(first.get_index()+1)
		var fitted:bool=await scroll_group(first,last);ck(fitted,"whole summary "+IDS[i])
		if first!=null and last!=null:
			var rect:Rect2=first.get_global_rect().merge(last.get_global_rect());var sr:Rect2=scroll_of(first).get_global_rect()
			horizontal_ok=horizontal_ok and rect.position.x>=sr.position.x and rect.end.x<=sr.end.x
		else:horizontal_ok=false
		var back:Button=button("BACK");fixed_ok=fixed_ok and back!=null and root.get_visible_rect().encloses(back.get_global_rect())
		await stage(["pin_row","salvage_row","winch_row"][i])
	var rows:Array=ui_rows()
	ck(rows[0].status=="INACTIVE / needs 2 distinct weapon types" and rendered_row(0,rows[0]),"exact prerequisite")
	ck(rows[1].status=="CHARGING / 0/3 / fields 0/2" and rendered_row(1,rows[1]),"exact charge")
	ck(rows[2].status=="PICKUPS 0/5" and "NEEDS MEDICAL PICKUPS" in rows[2].detail and "no direct healing" in rows[2].detail and "one pull per collection batch" in rows[2].detail and rendered_row(2,rows[2]),"Winch limitations")
	ck(fixed_ok,"fixed BACK remains inside viewport");ck(horizontal_ok,"no summary horizontal overflow")
	var forward:bool=await focus_cycle(false);ck(forward,"Tab closes inside modal")
	var reverse:bool=await focus_cycle(true);ck(reverse,"ShiftTab closes inside modal")
func case04()->void:
	scene("04_pin_readiness");await start({"crossfire_pin":1},["rivet_gun","rivet_gun"])
	ck(ui_rows()[0].status.begins_with("INACTIVE"),"duplicate type inactive");await open_build();await stage("prerequisite");await escape()
	g.build.weapons=["rivet_gun","scrap_shotgun"];g._recompute();ck(ui_rows()[0].status.begins_with("READY"),"distinct ready")
	begin();var e:Dictionary=enemy(Vector2(400,300));hit(e,"rivet_gun");ck(state().mark!=null,"actual first mark")
	e.pos=Vector2(500,300);hit(e,"scrap_shotgun");ck(state().mark==null and state().pin_ready_at==1.0,"actual consume CD")
	await open_build();ck(ui_rows()[0].status=="COOLDOWN / 1.00s","BUILD cooldown")
	var frozen:Dictionary=state();var time:float=g.elapsed;await stage("cooldown");await frames();ck(state()==frozen and g.elapsed==time,"pause render frozen")
func case05()->void:
	scene("05_pin_vs_focus");await start({"crossfire_pin":1});begin();var a:Dictionary=enemy(Vector2(400,300));hit(a,"rivet_gun");a.pos=Vector2(500,300)
	var b:Dictionary=enemy(Vector2(600,350));await refresh();click(g.get_global_transform_with_canvas()*b.pos);await frames()
	ck(small().pin.anchor==Vector2(400,300),"stored anchor");ck(small().pin.target==Vector2(500,300),"live target");ck(g.combat.focus_enemy_id==b.id,"actual click distinct priority")
	var projection:Dictionary=small();var before:Dictionary=state();await stage("normal");g.settings.reduced_flashes=true;await stage("reduced")
	ck(small()==projection,"reduced projection same");ck(state()==before,"render no mutation")
	hit(a,"scrap_shotgun");ck(a.pos==Vector2(455,300),"actual pull45");ck(a.hp==1000.0,"Pin no damage")
	ck(small().pin.is_empty() and g.combat.focus_enemy_id==b.id,"consumed no priority replacement");await stage("consumed")
func case06()->void:
	scene("06_invalid_mark");await start({"crossfire_pin":1});begin();var e:Dictionary=enemy(Vector2(400,300));hit(e,"rivet_gun");ck(state().mark!=null,"real mark")
	g.enemies.erase(e)
	if is_instance_valid(e.get("sprite")):e.sprite.queue_free()
	var stale:Dictionary=state();ck(small().pin.is_empty(),"missing target hides marker");ck(ui_rows()[0].status=="NO VALID MARK / awaiting simulation update","honest stale status");await stage("invalid")
	ck(state()==stale,"projection cannot prune")
	begin();ck(state().mark==null and state().pin_ready_at==1.0,"actual step prunes CD");await stage("pruned")
func case07()->void:
	scene("07_salvage_fields");await start({"salvage_capacitor":1});var old:Array=g.hazards.duplicate(true)
	normal_pickups(3);ck(state().charges==3,"actual pickups charge3")
	var origin:Vector2=g.player_pos;var started:bool=dash();ck(started and state().charges==0 and state().fields.size()==1 and state().fields[0].pos==origin and g.player_pos!=origin,"real dash saved origin")
	g.elapsed=.2;g.player_pos=Vector2(420,320);normal_pickups(3);dash();ck(state().fields.size()==2,"two fields")
	ck(small().fields.size()==2 and small().fields.all(func(f):return f.radius==80.0),"canonical radius80")
	var before:Dictionary=state();var projection:Dictionary=small();await stage("normal");g.settings.reduced_flashes=true;await stage("reduced")
	ck(state()==before and small()==projection,"reduced no authority changes");ck(g.hazards==old,"not old damaging hazards")
	var later:Vector2=state().fields[1].pos;g.elapsed=1.8;begin();ck(small().fields.size()==1 and small().fields[0].pos==later,"first expiry equality");await stage("expired")
	g.elapsed=2.0;begin();ck(small().fields.is_empty(),"second expiry equality")
func case08()->void:
	scene("08_winch_pipeline");await start({"salvage_capacitor":1,"medic_winch":1});g.stats.hp=50.0
	g.pickups=[{"pos":Vector2(380,300),"xp":0,"coins":0,"heal":8.0,"source":"medical"}]
	var coins:float=g.build.coins;normal_pickups(5)
	ck(g.build.coins==coins+5,"normal rewards once");ck(state().winch_count==0,"threshold spent")
	ck(g.pickups.size()==1 and g.pickups[0].pos==g.player_pos,"move medicine no collect");ck(g.stats.hp==50,"no direct healing")
	var before:Dictionary=state();var pickups:Array=g.pickups.duplicate(true);await stage("normal");g.settings.reduced_flashes=true;await stage("reduced")
	ck(state()==before and g.pickups==pickups and g.stats.hp==50,"reduced rendering no collection")
	Combat.step(g.combat_frame,0.0);ck(g.pickups.is_empty() and g.stats.hp==58,"next actual collection heals");ck(state().charges==3 and state().winch_count==0,"medical excluded");await stage("collected")
	normal_pickups(5);ck(state().winch_count==0 and g.stats.hp==58 and g.pickups.is_empty(),"absent medicine still spends")
	await open_build();var rows:Array=ui_rows();var label:Label=label_start("Medic Winch:")
	var detail:Control=label.get_parent().get_child(label.get_index()+1) if label!=null else null
	var fitted:bool=await scroll_group(label,detail)
	ck(fitted and rendered_row(2,rows[1]) and rows[1].status=="PICKUPS 0/5" and "NEEDS MEDICAL PICKUPS" in rows[1].detail and "no direct healing" in rows[1].detail,"BUILD medical limitation");await stage("no_medicine")
func case09()->void:
	scene("09_sale_room");await start(owned3());g.state="shop";var sold:bool=g._sell_item("crossfire_pin",g.shop_generation)
	ck(sold and not state().owned_items.has("crossfire_pin"),"accepted sale removes ownership")
	ck(small().pin.is_empty() and small().rows.all(func(r):return r.id!="crossfire_pin"),"sale removes row and marker")
	g._sell_item("salvage_capacitor",g.shop_generation);g._sell_item("medic_winch",g.shop_generation)
	ck(small()=={"rows":[],"pin":{},"fields":[]},"last sale fastpath");await stage("sold")
	await start(owned3());begin();var e:Dictionary=enemy(Vector2(400,300));hit(e,"rivet_gun");e.pos=Vector2(500,300);hit(e,"scrap_shotgun");normal_pickups(1)
	# Controlled eligibility, then actual main settlement bridge (not direct RunFlow).
	for value in g.enemies:
		if is_instance_valid(value.get("sprite")):value.sprite.queue_free()
	g.enemies.clear();g.boss_defeated=true
	if mode_id=="rooms":g.mode.planned_index=g.mode.planned_count;g.mode.clear_elapsed=float(g.mode.profile.clear_delay)
	g._complete_wave();var after:Dictionary=state()
	ck(after.mark==null and after.fields.is_empty() and after.charges==0 and after.winch_count==0,"main room cleanup")
	ck(after.pin_ready_at==1.0,"room prior CD preserved")
	ck(small().rows.size()==3 and small().pin.is_empty() and small().fields.is_empty() and g.wave==2,"new room projection no cached markers");await stage("room")
func case10()->void:
	scene("10_modal_layer");await start(owned3());normal_pickups(3);dash();g.elapsed=.2;g.player_pos=Vector2(420,320);normal_pickups(3);dash();begin()
	var a:Dictionary=enemy(Vector2(500,300));hit(a,"rivet_gun");var priority:Dictionary=enemy(Vector2(600,350));g.combat.focus_enemy_id=priority.id
	ck(not small().pin.is_empty() and small().fields.size()==2,"valid mark and two fields");await stage("world")
	var before:Dictionary=state();var expected:Dictionary=before.duplicate(true);expected.batch_open=false;expected.pending=null;expected.winch_requested_this_batch=false
	var focus_modes:Array=hud_focus();var b:Button=button("BUILD [I]");enemy(g.make_canvas_position_local(b.get_global_rect().get_center()))
	var opened:bool=await open_build();ck(opened,"actual BUILD opens");ck(hud_focus()==[0,0],"modal HUD no focus");ck(g.combat.focus_enemy_id==priority.id,"BUILD no behind selection");await stage("build")
	await escape();ck(g.state=="playing" and hud_focus()==focus_modes,"BUILD Escape restore")
	b=button("PAUSE [ESC]");enemy(g.make_canvas_position_local(b.get_global_rect().get_center()));click(b.get_global_rect().get_center());await frames()
	ck(g.state=="paused" and g.ui.modal.visible,"actual PAUSE opens");ck(g.combat.focus_enemy_id==priority.id,"PAUSE no behind selection");await stage("pause")
	await escape();ck(g.state=="playing" and hud_focus()==focus_modes and state()==expected,"Escape restore and exact authorized cancel only")
func _initialize()->void:call_deferred("run")
func run()->void:
	var args:PackedStringArray=OS.get_cmdline_user_args()
	if DisplayServer.get_name()=="headless" or args.size()!=2 or not args[0] in ["arena","rooms"]:print("B_NATIVE_PREFLIGHT_REJECT");quit(2);return
	mode_id=args[0];prefix=mode_id+("_960" if mode_id=="arena" else "_1280")
	oracle=JSON.parse_string(FileAccess.get_file_as_string(args[1]))
	if oracle.size()!=3 or not IDS.all(func(id):return oracle.has(id)):print("B_NATIVE_ORACLE_REJECT");quit(2);return
	g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false);await frames()
	DisplayServer.window_set_size(Vector2i(960,540) if mode_id=="arena" else Vector2i(1280,720));await frames()
	for method in ["case01","case02","case03","case04","case05","case06","case07","case08","case09","case10"]:
		await call(method)
		if not failures.is_empty():break
	var teardown=Teardown.new();teardown.prepare([g]);g.queue_free();await process_frame;await teardown.finish(self)
	print(JSON.stringify({"B_native_ui_checks":checks,"failures":failures,"records":records,"scope":"controlled actual B UI/pipeline; not ordinary acquisition, hardware input, or full B acceptance"}))
	quit(0 if failures.is_empty() else 1)
