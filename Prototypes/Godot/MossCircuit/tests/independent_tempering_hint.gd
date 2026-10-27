extends SceneTree
## Regression for the R1 ordinary sole-TEMPERED misleading donor hint.
const IDS=["rivet_gun","scrap_shotgun","rail_lance","orbit_saw","return_disc","shock_mortar","cryo_sprayer","bankshot_driver"]
const MAXIMUM="TEMPERED / maximum tier. Cannot be fused again."
const DONOR="Requires another STANDARD copy of this weapon."
var g
var checks:=0
var failures:Array=[]
func ck(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func snapshot()->Dictionary:
 return {"build":g.build.duplicate(true),"stats":g.stats.duplicate(true),"clocks":g.weapon_clocks.duplicate(),"offers":g.shop_offers.duplicate(true),"held":g.reserved_offer.duplicate(true),"generation":g.shop_generation,"message":g.shop_message,"rng":[g.rng.state,g.loot_rng.state,g.shop_rng.state],"effects":[g.effects.epoch,g.effects.last_sequence,g.effect_runtime.sequence,g.effects.echo_hits,g.effects.phase_charge,g.effects.feedback_armed,g.effects.cooldowns.duplicate(true)]}
func setup(mode:String,id:String,count:int)->void:
 g._title();g._select_mode(mode);g._start_run(3307);g.build.weapons=[]
 for i in range(count):g.build.weapons.append(id)
 g._recompute();g.weapon_clocks=[]
 for i in range(count):g.weapon_clocks.append(.23+float(i)*.11)
 g._open_shop()
func nodes(n:Node)->Array:
 var all:Array=[n]
 for child in n.get_children():all.append_array(nodes(child))
 return all
func visible_text()->String:
 var lines:Array=[]
 for n in nodes(g.ui.modal):
  if n is Label or n is Button:lines.append(n.text)
 return "\n".join(lines)
func _initialize()->void:call_deferred("run")
func run()->void:
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 for mode in ["arena","rooms"]:
  for id in IDS:
   setup(mode,id,1);var before:=snapshot();var single:Dictionary=g._weapon_temper_view(0)
   ck(single=={"available":false,"reason":DONOR,"donor_slot":-1},"standard sole copy retains donor hint "+mode+id)
   ck(snapshot()==before,"standard hint read-only")
   g.build.weapon_temper=[0];ck(g._weapon_temper_view(0).reason==DONOR,"explicit zero standard hint")
   setup(mode,id,2);var old_generation:int=g.shop_generation
   ck(g._temper_weapon(0,1,old_generation,id,id),"actual fusion reaches sole tempered copy "+id)
   before=snapshot();single=g._weapon_temper_view(0)
   ck(single=={"available":false,"reason":MAXIMUM,"donor_slot":-1},"sole tempered copy states maximum, never donor hint "+mode+id)
   ck(g._view().weapons[0].tempering.reason==MAXIMUM,"actual detached view has corrected reason")
   g._render_shop();await process_frame;await process_frame
   ck(visible_text().contains(MAXIMUM) and not visible_text().contains(DONOR),"actual rendered sole-copy shop label")
   ck(nodes(g.ui.modal).filter(func(n):return n is Button and n.text.begins_with("TEMPER / CONSUME SLOT ")).is_empty(),"no second fuse action")
   ck(snapshot()==before,"view and render preserve authority")
   ck(not g._temper_weapon(0,1,old_generation,id,id),"old generation rejected")
   ck(not g._temper_weapon(0,0,g.shop_generation,id,id),"current generation same copy rejected")
   ck(snapshot()==before,"rejected actions atomic")
   for bad_slot in [-1,1]:ck(g._weapon_temper_view(bad_slot).reason==DONOR,"invalid slot retains old one-copy rejection reason")
   g.bullets=[{"life":1.0}];ck(g._weapon_temper_view(0).reason.contains("shots are still active"),"flight guard retains priority")
   g.bullets=[];g.pending_blasts=[{"life":1.0}];ck(g._weapon_temper_view(0).reason.contains("shots are still active"),"blast guard retains priority");g.pending_blasts=[]
   g.state="inventory";ck(g._weapon_temper_view(0).reason=="Tempering is only available in the shop.","state guard retains priority");g.state="shop"
   for invalid in [[],[1.0],[true],[2],[-1],[1,0],{},null]:
    g.build.weapon_temper=invalid;before=snapshot();single=g._weapon_temper_view(0)
    ck(not single.available and single.reason.begins_with("Weapon tier data"),"invalid metadata never gets maximum or donor hint")
    ck(snapshot()==before,"invalid hint does not repair state")
 g.queue_free();await process_frame
 var result:Dictionary={"checks":checks,"failures":failures,"scope":"Controlled all-eight/both-mode sole-copy reason, actual fusion/render, prior-guard priority and rejection atomicity; no ordinary acquisition or native pixel claim."}
 var args:=OS.get_cmdline_user_args()
 if not args.is_empty():FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify(result,"  ")+"\n")
 print(JSON.stringify(result));quit(0 if failures.is_empty() else 1)
