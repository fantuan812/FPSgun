extends SceneTree
# Contract-level UI behavior. Controlled headless layout; native screenshots separate.
const Rules=preload("res://scripts/rules.gd")
var g
var checks:int=0
var failures:Array=[]
var intents:Array=[]
func ck(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label)
func nodes(n:Node)->Array:
	var result:Array=[n]
	for child in n.get_children():result.append_array(nodes(child))
	return result
func labels(n:Node)->String:
	var result:Array=[]
	for x in nodes(n):
		if (x is Label or x is Button) and x.is_visible_in_tree():result.append(x.text)
	return "\n".join(result)
func snap()->Dictionary:
	return {"build":g.build.duplicate(true),"stats":g.stats.duplicate(true),"generation":g.shop_generation,"offers":g.shop_offers.duplicate(true),"held":g.reserved_offer.duplicate(true),"rng":[g.rng.state,g.loot_rng.state,g.shop_rng.state],"projectiles":g.bullets.duplicate(true),"pickups":g.pickups.duplicate(true),"sequence":g.effect_sequence}
func entry(id:String)->Dictionary:
	var e:Dictionary=Rules.catalog_entry(g.catalog,id).duplicate(true);e.sold=false;return e
func record(action:String,payload:Dictionary)->void:intents.append([action,payload.duplicate(true)])
func run()->void:
	g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
	g.ui.intent.connect(record)
	for size in [Vector2i(960,540),Vector2i(1280,720)]:
		root.size=size;g._title();g._start_run(3702)
		g.build.weapons=["return_disc","rivet_gun","rail_lance","orbit_saw"];g.build.weapon_temper=[1,1,0,1];g.build.items={"scavenger_reel":1};g.build.coins=200;g._recompute();g._open_shop();g.reserved_offer={}
		g.shop_offers=[entry("cryo_sprayer"),entry("bankshot_driver")];g._render_shop();await process_frame;await process_frame
		var selectors:Array=[];var scrolls:Array=[]
		for n in nodes(g.ui.modal):
			if n is OptionButton:selectors.append(n)
			if n is ScrollContainer:scrolls.append(n)
		ck(selectors.size()==2,"one replacement selector per unsold full-bag weapon "+str(size))
		if selectors.size()!=2:continue
		var select:OptionButton=selectors[0];var other:OptionButton=selectors[1]
		var card:Node=select.get_parent();var other_card:Node=other.get_parent()
		ck(select.get_selected_id()==0,"default actual slot0")
		ck("CURRENTLY SELECTED SLOT 1" in labels(card),"default slot explicitly communicated")
		ck("DISABLES" in labels(card) and "SCAVENGER RETURN" in labels(card),"last Return loss visible collapsed")
		ck("PROJECTED EQUIPPED STATS" not in labels(card),"full stats initially collapsed")
		ck("no refund" in labels(card).to_lower() or "irreversible" in labels(card).to_lower(),"destructive warning visible")
		var before:Dictionary=snap();var other_text:String=labels(other_card)
		var modal_id:int=g.ui.modal.get_instance_id();var other_id:int=other.get_instance_id()
		other.grab_focus()
		var old_focus:Control=root.gui_get_focus_owner()
		var scroll_positions:Array=[]
		for sc in scrolls:scroll_positions.append([sc.scroll_horizontal,sc.scroll_vertical])
		select.select(1);select.item_selected.emit(1);await process_frame
		ck(g.ui.modal.get_instance_id()==modal_id and is_instance_valid(other) and other.get_instance_id()==other_id,"selector changes no full rebuild")
		ck(labels(other_card)==other_text and other.get_selected_id()==0,"other card unchanged")
		ck(root.gui_get_focus_owner()==old_focus,"other focus not reset by local projection")
		for i in range(scrolls.size()):ck([scrolls[i].scroll_horizontal,scrolls[i].scroll_vertical]==scroll_positions[i],"scroll position preserved")
		ck("CURRENTLY SELECTED SLOT 2" in labels(card),"new selected actual slot explicit")
		ck(var_to_bytes(before)==var_to_bytes(snap()) and intents.is_empty(),"selection no intent/world/RNG mutation")
		var details:Button=null
		for n in nodes(card):
			if n is Button and "BUILD DETAILS" in n.text:details=n;break
		ck(details!=null,"accessible build details button")
		if details!=null:
			details.pressed.emit();await process_frame
			ck("PROJECTED EQUIPPED STATS" in labels(card),"expanded stats heading honest")
			ck("not guaranteed DPS" in labels(card),"existing numeric limits preserved")
		ck(var_to_bytes(before)==var_to_bytes(snap()) and intents.is_empty(),"disclosure no gameplay mutation")
		var buy:Button=null
		for n in nodes(card):
			if n is Button and n.text.begins_with("REPLACE"):buy=n;break
		ck(buy!=null and not buy.disabled,"existing actual replacement button remains enabled")
		if buy!=null:
			buy.pressed.emit();await process_frame
			ck(g.build.weapons==["return_disc","cryo_sprayer","rail_lance","orbit_saw"] and g.build.weapon_temper==[1,0,0,1],"actual click buys selected slot2 only")
			ck(g.build.coins==156 and g.shop_offers[0].sold,"actual click pays real price once")
			ck(intents.size()==1 and intents[0][0]=="buy" and intents[0][1].replace_slot==1,"unchanged single real buy payload")
		intents.clear()
	var teardown=preload("res://tests/support/audio_teardown.gd").new();teardown.prepare([g]);g.queue_free();await process_frame;await teardown.finish(self)
	print(JSON.stringify({"checks":checks,"failures":failures,"scope":"controlled 960/1280 UI local selector/focus/scroll/intent and real click; native aesthetic/clipping separately reviewed"}))
	quit(0 if failures.is_empty() else 1)
func _initialize()->void:call_deferred("run")
