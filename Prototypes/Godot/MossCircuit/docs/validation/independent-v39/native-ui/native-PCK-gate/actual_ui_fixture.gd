extends SceneTree
## Author candidate: real A catalog/UI/controller, controlled viewport input.
## Not ordinary gameplay, real shop acquisition, or hardware mouse verification.
var g
var checks:=0
var failures:Array=[]
const STARTERS=[["tether","TETHER STARTER","tether_emitter",10.0,1.2,280.0,"per pulse"],["seismic","SEISMIC STARTER","seismic_drum",22.0,1.4,180.0,"per target / outward leg"]]
const MODULES=["lock_memory","return_collar","recoil_plate"]
func ck(value:bool,label:String)->void:
	checks+=1
	if not value:failures.append(label)
func nodes(node:Node)->Array:
	var result:Array=[node]
	for child in node.get_children():result.append_array(nodes(child))
	return result
func button(text:String)->Button:
	for node in nodes(g.ui.modal):
		if node is Button and node.text==text:return node
	return null
func scroll_of(node:Node)->ScrollContainer:
	var parent:Node=node.get_parent()
	while parent!=null and not parent is ScrollContainer:parent=parent.get_parent()
	return parent as ScrollContainer
func pointer(at:Vector2,index:int,pressed:bool)->void:
	var e:=InputEventMouseButton.new();e.position=at;e.global_position=at;e.button_index=index;e.pressed=pressed
	root.push_input(e,true)
func click(at:Vector2)->void:
	pointer(at,MOUSE_BUTTON_LEFT,true);pointer(at,MOUSE_BUTTON_LEFT,false)
func authority()->Dictionary:
	return {"build":g.build.duplicate(true),"stats":g.stats.duplicate(true),"rng":[g.rng.state,g.loot_rng.state,g.shop_rng.state],"clocks":g.weapon_clocks.duplicate(),"state":g.state,"new_beams":g.combat.pulse_beams.duplicate(true),"new_waves":g.combat.seismic_waves.duplicate(true)}
func screenshot(name:String)->void:
	var dir:String=OS.get_environment("MOSS_A_UI_IMAGES")
	if not dir.is_empty():root.get_texture().get_image().save_png(dir.path_join(name+".png"))
func _initialize()->void:call_deferred("run")
func run()->void:
	if DisplayServer.get_name()=="headless":
		print("ACTUAL_UI_NATIVE_GATE_FAIL");quit(2);return
	g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
	await process_frame;await process_frame
	var catalog_before:String=JSON.stringify(g.catalog)
	var entries:Array=g.catalog.weapons+g.catalog.items
	ck(entries.size()==43,"actual A catalog exactly10weapons+33modules")
	var seen:Dictionary={}
	for entry in entries:
		ck(not seen.has(entry.id),"distinct catalog id "+entry.id);seen[entry.id]=true
		var tex:Texture2D=g.ui.icon(entry.id)
		ck(tex!=null and tex.get_width()>0 and tex.get_height()>0,"actual icon exists "+entry.id)
	for viewport in [Vector2i(960,540),Vector2i(1280,720)]:
		root.size=viewport
		for mode in ["arena","rooms"]:
			for row in STARTERS:
				g._title();g._select_mode(mode)
				await process_frame;await process_frame
				var label:String=mode+"/"+str(viewport)+"/"+str(row[0])
				var choice:Button=button("CHOOSE "+row[1])
				ck(choice!=null,"actual new choice exists "+label)
				if choice==null:continue
				var card:Control=choice.get_parent().get_parent()
				var scroll:ScrollContainer=scroll_of(choice)
				ck(scroll!=null,"choice belongs to scrolling body "+label)
				if scroll==null:continue
				for _step in range(24):
					if scroll.get_global_rect().encloses(card.get_global_rect()):break
					var at:Vector2=scroll.get_global_rect().get_center()
					pointer(at,MOUSE_BUTTON_WHEEL_DOWN,true);pointer(at,MOUSE_BUTTON_WHEEL_DOWN,false)
					await process_frame;await process_frame
				var visible_choice:bool=scroll.get_global_rect().encloses(card.get_global_rect())
				ck(visible_choice,"wheel brings whole new card into viewport "+label)
				if not visible_choice:continue
				screenshot("choice_"+mode+"_"+str(viewport.x)+"_"+row[0])
				click(choice.get_global_rect().get_center());await process_frame;await process_frame
				ck(g.selected_loadout_id==row[0],"pointer select changes actual selected id "+label)
				var start:Button=button("START "+row[1]+" / 21 SCRAP")
				ck(start!=null and not start.disabled,"actual selected START summary "+label)
				if start==null:continue
				ck(scroll_of(start)==null and g.ui.body.get_global_rect().encloses(start.get_global_rect()),"START fixed visible "+label)
				click(start.get_global_rect().get_center());await process_frame;await process_frame
				ck(g.state=="playing" and g.build.weapons==[row[2]] and g.build.coins==21 and g.build.items.is_empty(),"actual START creates exact free loadout "+label)
				var before:Dictionary=authority();var view:Dictionary=g._view()
				var readout:Dictionary=view.weapons[0].weapon_readout
				ck(is_equal_approx(readout.damage,row[3]) and is_equal_approx(readout.interval,row[4]) and is_equal_approx(readout.reach,row[5]) and readout.damage_unit==row[6],"actual controller readout independent base values "+label)
				ck(authority()==before,"view leaves authority unchanged "+label)
				g.ui.update_hud(view);await process_frame;await process_frame
				ck(g.ui.hud.get_global_rect().encloses(g.ui.hud_action.get_global_rect()) and g.ui.hp.size.x>=130 and g.ui.xp.size.x>=130,"new HUD action fits without crushing bars "+label)
				screenshot("started_"+mode+"_"+str(viewport.x)+"_"+row[0])
	# Controlled stock validates actual view/card text, not natural shop acquisition.
	g._open_shop();g.shop_offers=[]
	for id in MODULES:g.shop_offers.append({"id":id,"sold":false})
	var before:Dictionary=authority();var view:Dictionary=g._view();g.ui.show_shop(view)
	await process_frame;await process_frame
	var all_text:String=""
	for node in nodes(g.ui.modal):
		if node is Label:all_text+=node.text+"\n"
	for id in MODULES:
		var entry:Dictionary={}
		for candidate in g.catalog.items:
			if candidate.id==id:entry=candidate
		ck(not entry.is_empty(),"module actual definition "+id)
		if entry.is_empty():continue
		ck(all_text.contains(entry.description) and all_text.contains(entry.trigger) and all_text.contains(entry.cost) and all_text.contains(entry.stack_rule),"actual module description/trigger/tradeoff/stack text "+id)
		ck(entry.max_stack==1 and entry.effects.is_empty(),"unique mechanism is not hidden stat multiplier "+id)
	ck(authority()==before,"module presentation leaves authority unchanged")
	ck(JSON.stringify(g.catalog)==catalog_before,"entire actual catalog unchanged")
	var teardown=preload("<WORKSPACE>/moss-v39-ui/pck-ui-buttons/support/audio_teardown.gd").new();teardown.prepare([g]);g.queue_free();await process_frame;await teardown.finish(self)
	print(JSON.stringify({"checks":checks,"failures":failures,"scope":"author controlled actual A catalog + viewport wheel/click; not ordinary gameplay or hardware input"}))
	quit(0 if failures.is_empty() else 1)
