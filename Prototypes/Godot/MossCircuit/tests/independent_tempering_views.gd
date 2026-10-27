extends SceneTree
## Controlled actual ownership and UI callbacks. No actual controller/hardware claim.
const Rules=preload("res://scripts/rules.gd")
const IDS=["rivet_gun","scrap_shotgun","rail_lance","orbit_saw","return_disc","shock_mortar","cryo_sprayer","bankshot_driver"]
const AMOUNTS=[24.0,14.4,48.0,32.0,28.8,57.6,14.4,28.8]
var g
var checks:=0
var failures:Array=[]
func ck(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func eq(a:float,b:float,label:String)->void:ck(absf(a-b)<.0001,label+" got="+str(a)+" expected="+str(b))
func authority()->Dictionary:
 return {"build":g.build.duplicate(true),"stats":g.stats.duplicate(true),"clocks":g.weapon_clocks.duplicate(),"offers":g.shop_offers.duplicate(true),"held":g.reserved_offer.duplicate(true),"generation":g.shop_generation,"message":g.shop_message,"rng":[g.rng.state,g.loot_rng.state,g.shop_rng.state],"effects":[g.effects.epoch,g.effects.last_sequence,g.effect_runtime.sequence,g.effects.echo_hits,g.effects.phase_charge,g.effects.feedback_armed,g.effects.cooldowns.duplicate(true)]}
func setup(mode:String,ids:Array,tiers:Variant=null)->void:
 g._title();g._select_mode(mode);g._start_run(3303);g.build.weapons=ids.duplicate()
 if tiers!=null:g.build.weapon_temper=tiers.duplicate(true) if tiers is Array or tiers is Dictionary else tiers
 g._recompute();g.build.coins=999;g.build.coin_fraction=.3;g.weapon_clocks=[]
 for i in range(ids.size()):g.weapon_clocks.append(.13+float(i)*.17)
 g._open_shop();g._sync_weapon_rig()
func offer(id:String)->void:
 var e:Dictionary=Rules.catalog_entry(g.catalog,id).duplicate(true);e.sold=false;g.shop_offers=[e]
func nodes(n:Node)->Array:
 var a:Array=[n]
 for child in n.get_children():a.append_array(nodes(child))
 return a
func buttons(prefix:String)->Array:return nodes(g.ui.modal).filter(func(n):return n is Button and n.text.begins_with(prefix))
func text()->String:
 var a:Array=[]
 for n in nodes(g.ui.modal):
  if n is Label or n is Button:a.append(n.text)
 return "\n".join(a)
func scroll_of(n:Node)->ScrollContainer:
 var p:Node=n.get_parent()
 while p!=null and not p is ScrollContainer:p=p.get_parent()
 return p as ScrollContainer
func accept(pressed:bool)->void:
 var e:=InputEventAction.new();e.action="ui_accept";e.pressed=pressed;root.push_input(e)
func _initialize()->void:call_deferred("run")
func run()->void:
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 for mode in ["arena","rooms"]:
  # All mutation seams preserve copy-tier alignment, and only fresh purchases reset it.
  for id in IDS:
   setup(mode,[id,id],[1,0]);offer(id);ck(g._buy(0,g.shop_generation),"append standard "+id);ck(g.build.weapon_temper==[1,0,0],"append does not inherit tier")
   offer("rivet_gun");ck(g._buy(0,g.shop_generation),"fill fourth slot");offer(id)
   ck(g._buy(0,g.shop_generation,0),"same-ID replacement succeeds");ck(g.build.weapon_temper==[0,0,0,0],"same-ID replacement resets tier")
   g.build.weapon_temper=[1,0,1,0];g._recompute();var clocks:Array=g.weapon_clocks.duplicate()
   ck(g._move_weapon(0,1,g.shop_generation,id),"move mixed tiers");ck(g.build.weapon_temper==[0,1,1,0] and g.weapon_clocks[1]==clocks[0],"tier and exact clock follow copy")
   var coins:int=g.build.coins;var price:int=int(Rules.catalog_entry(g.catalog,id).price)
   ck(g._sell_weapon(1,g.shop_generation),"sell tempered copy");ck(g.build.weapon_temper==[0,1,0],"sell removes same tier index");ck(g.build.coins==coins+floori(price*.5),"ordinary resale no tier premium")
   g.build.items={"recycler":2};g._recompute();coins=g.build.coins
   ck(g._sell_weapon(1,g.shop_generation),"sell recycler tempered copy");ck(g.build.coins==coins+floori(price*.8),"old capped resale80 percent only")
  # Metadata validation fails closed for weapon mutations, not unrelated income or stock policy.
  for bad in [[1.0,0],[true,0],[1],[2,0],{},null]:
   setup(mode,["rivet_gun","rivet_gun"]);g.build.weapon_temper=bad;offer("rail_lance");var before:=authority()
   ck(not g._buy(0,g.shop_generation),"bad tiers reject weapon buy");ck(authority()==before,"rejected weapon buy atomic")
   ck(not g._move_weapon(0,1,g.shop_generation,"rivet_gun"),"bad tiers reject order");ck(authority()==before,"rejected move atomic")
   ck(not g._sell_weapon(0,g.shop_generation),"bad tiers reject weapon sale");ck(authority()==before,"rejected sale atomic")
   var v:Dictionary=g._view();ck(v.weapons[0].temper_label=="INVALID TIER DATA / NO BOOST" and v.weapons[0].weapon_readout.damage==15,"invalid metadata visible no boost");ck(not v.offers[0].can_buy,"invalid weapon buy disabled")
   offer("power_coil");ck(g._buy(0,g.shop_generation),"unrelated module buy remains available");ck(g.build.weapon_temper==bad,"unrelated buy never repairs tiers")
  # A retained Bankshot uses its snapshotted damage through old replacement preservation.
  setup(mode,["bankshot_driver","rivet_gun","rail_lance","orbit_saw"],[1,0,0,0]);var enemy:Dictionary=g._spawn_kind("crawler",g.player_pos+Vector2(80,0));enemy.hp=1000
  g._fire_weapon("bankshot_driver",0);ck(g.bullets.size()==1,"one real Bankshot before replacement")
  var bank:Dictionary=g.bullets[0];eq(bank.damage,28.8,"tempered Bankshot snapshot before replacement");offer("cryo_sprayer");ck(g._buy(0,g.shop_generation,0),"replace bankshot slot");ck(g.bullets.size()==1 and g.bullets[0]==bank,"old special Bankshot survives replacement");eq(g.bullets[0].damage,28.8,"surviving shot not retiered");ck(g.build.weapon_temper[0]==0,"new Cryo standard")
  setup(mode,["rivet_gun","rivet_gun"]);ck(g._temper_weapon(0,1,g.shop_generation,"rivet_gun","rivet_gun"),"lifecycle actual temper")
  g._leave_shop(g.shop_generation);ck(g.build.weapon_temper==[1] and g.state=="playing","deploy retains tier")
  for action in ["pause","inventory","close_inventory","settings","close_settings","resume"]:
   var preserved:Dictionary=g.build.duplicate(true);g._on_intent(action,{});ck(g.build==preserved,"menu preserves copy tier "+action)
  if mode=="rooms":g.mode.planned_index=g.mode.planned_count;g.mode.clear_elapsed=g.mode.profile.clear_delay
  g._complete_wave();ck(g.wave==2 and g.build.weapon_temper==[1],"actual controlled settlement retains tier")
  for kit in ["rivet","scatter","rail"]:
   g._start_run(3303,kit);ck(not g.build.has("weapon_temper"),"fresh starter metadata absent "+kit)
   g.build.weapon_temper=[1];g._finish(true);g._on_intent("retry",{});ck(not g.build.has("weapon_temper") and g.run.starting_loadout_id==kit,"actual result retry resets tiers "+kit)
   g.build.weapon_temper=[1];g._finish(false);g._on_intent("new_seed",{});ck(not g.build.has("weapon_temper") and g.run_seed==3304 and g.run.starting_loadout_id==kit,"actual loss new seed resets tiers "+kit)
  for size in [Vector2i(960,540),Vector2i(1280,720)]:
   root.size=size
   for i in range(IDS.size()):
    var id:String=IDS[i];setup(mode,[id,id]);var before:=authority();var v:Dictionary=g._view()
    ck(v.weapons.size()==2 and v.weapons[0].temper_label=="STANDARD","two owned standard labels")
    eq(v.weapons[0].tempering.preview.damage,AMOUNTS[i],"literal projected damage "+id)
    ck(v.weapons[0].tempering.donor_slot==1 and v.weapons[1].tempering.donor_slot==0,"deterministic donor identity")
    v.weapons[0].tempering.preview.damage=-999;v.weapon_tempering.primary_damage_multiplier=99
    ck(authority()==before and g.catalog.weapon_tempering.primary_damage_multiplier==1.6,"detached projection no mutation")
    g._render_shop();await process_frame;await process_frame
    var fuse:Array=buttons("TEMPER / CONSUME SLOT ");ck(fuse.size()==2,"one explicit action per eligible retained copy "+id)
    ck(not root.gui_get_focus_owner() in fuse,"destructive action never initial focus")
    ck(text().contains("Irreversible / no refund") and text().contains("removes one timer and tag copy") and text().contains("Preview includes lost tag bonuses"),"complete loss/tradeoff copy")
    for action in fuse:
     var bag:ScrollContainer=scroll_of(action);ck(bag!=null,"owned action scroll parent")
     if bag!=null:
      bag.ensure_control_visible(action);await process_frame;await process_frame
      ck(bag.get_global_rect().encloses(action.get_global_rect()),"full destructive button reachable "+str(size))
      ck(action.size.y>=32 and action.size.x>=100 and action.focus_mode==Control.FOCUS_ALL,"existing keyboard reachable usable action")
    ck(authority()==before,"render scroll geometry read-only")
   # Threshold-aware preview uses unmodified config base, not current derived damage.
   for id in ["rail_lance","orbit_saw","scrap_shotgun"]:
    setup(mode,[id,id,id]);var before:=authority();var v:Dictionary=g._view()
    eq(v.weapons[0].tempering.preview.damage,{"rail_lance":48.0,"orbit_saw":32.0,"scrap_shotgun":14.4}[id],"preview subtracts old tag bonus "+id)
    if id=="scrap_shotgun":ck(v.weapons[0].weapon_readout.pellets==6 and v.weapons[0].tempering.preview.pellets==5,"preview actual lost pellet")
    ck(authority()==before,"threshold projection read-only")
   setup(mode,["rivet_gun","rivet_gun"]);await process_frame;await process_frame
   var fuse:Button=buttons("TEMPER / CONSUME SLOT ")[0];var old_call:Callable=fuse.get_signal_connection_list("pressed")[0].callable;var before:=authority()
   fuse.grab_focus();accept(true);await process_frame;accept(false);await process_frame;await process_frame
   ck(g.build.weapons==["rivet_gun"] and g.build.weapon_temper==[1] and g.weapon_clocks==[before.clocks[0]],"synthetic ui_accept invokes exact survivor transaction")
   ck(g.build.coins==before.build.coins and g.shop_generation==before.generation+1,"UI transaction no fee once")
   var stable:=authority();old_call.call();ck(authority()==stable,"freed old callback cannot fuse again");ck(buttons("TEMPER / CONSUME SLOT ").is_empty(),"no action without standard pair")
   g.state="inventory";g.ui.show_inventory(g._view());await process_frame;await process_frame
   ck(text().contains("TEMPERED") and text().contains("24.00") and buttons("TEMPER / CONSUME SLOT ").is_empty(),"inventory tier/current damage no action")
   setup(mode,["rail_lance","rivet_gun","rivet_gun","rail_lance"],[1,0,1,0]);offer("cryo_sprayer");g._render_shop();await process_frame;await process_frame
   var replacement:Array=nodes(g.ui.modal).filter(func(n):return n is OptionButton)
   ck(not replacement.is_empty(),"full loadout replacement choices exist")
   if not replacement.is_empty():
    var selector:OptionButton=replacement[0];ck(selector.item_count==4,"four replacement identities")
    ck(selector.get_item_text(0).contains("SLOT 1") and selector.get_item_text(0).contains("TEMPERED") and selector.get_item_text(1).contains("STANDARD"),"replacement labels preserve slot/tier")
   setup(mode,["rivet_gun","rivet_gun"]);g.bullets=[{"life":1.0}];g._render_shop();await process_frame;await process_frame
   ck(buttons("TEMPER / CONSUME SLOT ").is_empty() and text().contains("shots are still active"),"outstanding-flight UI unavailable")
 g.queue_free();await process_frame
 var result:Dictionary={"checks":checks,"failures":failures,"scope":"Controlled all-eight ownership lifecycle, malformed-state fail-safe, snapshot seam, detached actual view arithmetic and UI hierarchy/rectangles/action dispatch at both modes/sizes. Synthetic ui_accept, no physical-controller/native pixel/ordinary claim."}
 var args:=OS.get_cmdline_user_args()
 if not args.is_empty():FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify(result,"  ")+"\n")
 print(JSON.stringify(result));quit(0 if failures.is_empty() else 1)
