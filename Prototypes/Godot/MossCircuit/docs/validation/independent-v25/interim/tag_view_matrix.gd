extends SceneTree
const Rules=preload("res://scripts/rules.gd")
const IDS=["arc_grid","saw_rig","scatter_rig"]
const NAMES=["ARC GRID","SAW RIG","SCATTER RIG"]
const TAGS=["electric","melee","spread"]
const WEAPONS=["rail_lance","orbit_saw","scrap_shotgun"]
const MODULES=["capacitor","gear","pellet_pouch"]
var checks:=0
var failures:Array=[]
var g
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func nodes(n:Node)->Array:
 var out:Array=[n]
 for c in n.get_children():out.append_array(nodes(c))
 return out
func snapshot()->String:return JSON.stringify([g.build,g.stats,g.rng.state,g.shop_rng.state,g.loot_rng.state,g.weapon_clocks,g.effects.cooldowns,g.shop_offers,g.catalog])
func _initialize()->void:call_deferred("run")
func run()->void:
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 var cases:Array=[[["rivet_gun"],{}],[["rail_lance","rail_lance"],{}],[["rail_lance","rail_lance","rail_lance","rail_lance"],{}],[["rivet_gun"],{"capacitor":3,"gear":3}],[["rail_lance","orbit_saw","scrap_shotgun"],{"capacitor":2,"gear":2,"pellet_pouch":2}],[["rail_lance"],{"capacitor":1}],[["orbit_saw"],{"gear":1}],[["scrap_shotgun"],{"pellet_pouch":1}]]
 for mode in ["arena","rooms"]:
  g._title();g._select_mode(mode);g._start_run(25025)
  for size in [Vector2i(960,540),Vector2i(1280,720)]:
   root.size=size
   for c in cases:
    g.build.weapons=c[0].duplicate();g.build.items=c[1].duplicate();g.build.coins=1000;g._recompute()
    var before:String=snapshot();var view:Dictionary=g._view();var rows:Array=view.tag_synergy_status
    check(rows.size()==3,"exact three rows "+str(c))
    for i in 3:
     var expected_count:int=int(c[1].get(MODULES[i],0));var matching:Array=[]
     for id in c[0]:
      if id==WEAPONS[i]:expected_count+=1;matching.append(Rules.catalog_entry(g.catalog,id).name)
     var r:Dictionary=rows[i]
     check(r.id==IDS[i] and r.name==NAMES[i] and r.tag==TAGS[i] and r.threshold==3,"fixed identity/order")
     check(r.count==expected_count and r.active==(expected_count>=3),"independent copy/stack count")
     check(r.matching_weapons==matching,"exact repeated matching slot names")
     check(r.description==g.catalog.synergies[i].description,"unchanged catalog wording")
     check(r.qualifier.contains("Applies once") and (r.qualifier.contains("Additive matching-weapon") and r.qualifier.contains("Fixed module damage is not scaled") if i<2 else r.qualifier.contains("spread attacks only") and r.qualifier.contains("Pellet Pouch")),"scope qualifier")
    g.ui.show_inventory(view);await process_frame;await process_frame
    var labels:Array=[]
    for node in nodes(g.ui.modal):
     if node is Label:labels.append(node.text)
    check(labels.count("TAG SYNERGY PROGRESS")==1 and not "ACTIVE TAG SYNERGIES" in labels,"one current section")
    check(labels.count("MECHANISM PAIRS")==1,"mechanism pairs remain distinct")
    for r in rows:
     var header:String="%s / %s / %d / 3 %s" % [r.name,"ACTIVE" if r.active else "INACTIVE",r.count,r.tag]
     check(header in labels and r.description in labels and r.qualifier in labels,"actual Label full content")
     var note:String="Active, but no equipped %s weapon currently benefits." % r.tag
     check((note in labels)==(r.active and r.matching_weapons.is_empty()),"no false activation prerequisite")
    var pair_before:Array=view.synergy_status.duplicate(true)
    rows[0].count=999;rows[0].matching_weapons.append("not owned");rows[0].description="tampered"
    var fresh:Dictionary=g._view();check(fresh.tag_synergy_status[0].count!=999 and fresh.synergy_status==pair_before,"returned row detached; pairs unchanged")
    check(snapshot()==before,"view/actual inventory no authority/RNG mutation")
   # Offer-only tag must not alter current ownership, first action must stay visible.
   for full in [false,true]:
    g.build.weapons=["rail_lance","rail_lance","rivet_gun","rivet_gun"] if full else ["rail_lance","rail_lance"]
    g.build.items={};g._recompute();g._open_shop();g.shop_offers=[{"id":"rail_lance","sold":false}];g._render_shop();await process_frame;await process_frame
    check(g._view().tag_synergy_status[0].count==2 and not g._view().tag_synergy_status[0].active,"offer not ownership")
    var found:=false
    for n in nodes(g.ui.modal):
     if n is Button and n.text.begins_with("REPLACE" if full else "BUY"):
      var p:Node=n.get_parent()
      while p!=null and not p is ScrollContainer:p=p.get_parent()
      if p is ScrollContainer:found=p.get_global_rect().encloses(n.get_global_rect()) and not n.disabled
    check(found,"first purchase/replace fully visible at "+str(size))
 g.queue_free();await process_frame
 print(JSON.stringify({"tag_view_checks":checks,"failures":failures}))
 var args:=OS.get_cmdline_user_args()
 if not args.is_empty():FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"  ")+"\n")
 quit(0 if failures.is_empty() else 1)
