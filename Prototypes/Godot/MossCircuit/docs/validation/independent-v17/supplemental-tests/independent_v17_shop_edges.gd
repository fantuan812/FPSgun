extends SceneTree
var passed:=0
var failures:Array=[]
func check(ok:bool,label:String)->void:
	if ok:passed+=1
	else:failures.append(label)
func _initialize()->void:call_deferred("run")
func controls(n:Node)->Array:
	var out:Array=[n]
	for child in n.get_children():out.append_array(controls(child))
	return out
func run()->void:
	root.size=Vector2i(960,540)
	var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false);g._start_run(1717)
	g.build.coins=1000;g._open_shop()
	for full in [false,true]:
		for status in ["affordable","unaffordable","sold"]:
			var v:Dictionary=g._view()
			if full:
				v.weapons=[]
				for i in range(4):
					var w:Dictionary=g.catalog.weapons[i].duplicate(true);w.slot=i;v.weapons.append(w)
			var offer:Dictionary=g.catalog.weapons[0].duplicate(true)
			offer.merge({"index":0,"sold":status=="sold","can_buy":status=="affordable","weight_multiplier":1.5,"bias_reasons":["Test fixture"]})
			v.offers=[offer];g.ui.show_shop(v)
			await process_frame;await process_frame
			var label:="full=%s status=%s"%[full,status]
			var action:Button
			for n in controls(g.ui.modal):
				if n is Button and (n.text.begins_with("BUY") or n.text.begins_with("REPLACE") or n.text=="SOLD"):action=n;break
			check(action!=null,"offer action present "+label)
			if action==null:continue
			var scroll:Node=action.get_parent()
			while scroll!=null and not scroll is ScrollContainer:scroll=scroll.get_parent()
			scroll.scroll_vertical=0;await process_frame
			var a:Rect2=action.get_global_rect();var s:Rect2=scroll.get_global_rect()
			check(a.position.y>=s.position.y and a.end.y<=s.end.y,"action visible at zero scroll "+label)
			check(action.disabled==(status!="affordable"),"transaction availability preserved "+label)
			var before:Dictionary={"coins":g.build.coins,"generation":g.shop_generation,"offers":g.shop_offers.duplicate(true)}
			for n in controls(g.ui.modal):
				if n is Button and n.toggle_mode:
					n.button_pressed=true;await process_frame
					n.button_pressed=false;await process_frame
			check(g.build.coins==before.coins and g.shop_generation==before.generation and g.shop_offers==before.offers,"all disclosures read-only "+label)
	# Opening and dismissing inventory must not change transaction generation/offers.
	g._render_shop();var generation:int=g.shop_generation;var stock:Array=g.shop_offers.duplicate(true)
	g._on_intent("inventory",{});g._on_intent("close_inventory",{})
	check(g.state=="shop" and g.shop_generation==generation and g.shop_offers==stock,"inventory return preserves existing stock")
	g.queue_free();await process_frame
	print(JSON.stringify({"independent_v17_shop_edges_passed":passed,"failures":failures,"scope":"headless layout/transaction edges; actual keyboard/GUI separate"}))
	quit(0 if failures.is_empty() else 1)
