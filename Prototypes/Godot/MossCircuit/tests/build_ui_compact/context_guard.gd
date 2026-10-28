extends SceneTree
# Controlled controller transitions plus synthetic actual viewport-local GUI inputs.
# No native-pixel, natural-room-clear, all-build-state or physical-controller claim.
const Teardown=preload("res://tests/support/audio_teardown.gd")
var g
var checks:=0
var failures:Array=[]
var records:Array=[]
var current:=""
func ck(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(current+" / "+label)
func nodes(n:Node)->Array:
 var out:Array=[n]
 for c in n.get_children():out.append_array(nodes(c))
 return out
func frames()->void:await process_frame;await process_frame
func key(code:int,shift:=false)->void:
 for pressed in [true,false]:
  var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=pressed;event.shift_pressed=shift;root.push_input(event,true)
func button(text:String)->Button:
 var found:Array=nodes(g.ui.modal).filter(func(n):return n is Button and n.text==text and n.is_visible_in_tree())
 return found[0] if found.size()==1 else null
func top_groups()->Array:
 return nodes(g.ui.modal).filter(func(n):return n is Button and n.toggle_mode and (n.text.ends_with("MODULE STATUS DETAILS") or n.text.ends_with("SYNERGIES / COOLDOWNS / STATS") or n.text.contains("WEAPON CARDS /") or n.text.contains("MODULE CARDS /")))
func details(toggle:Button)->Control:return toggle.get_parent().get_child(toggle.get_index()+1)
func authority()->PackedByteArray:
 return var_to_bytes([g.build,g.stats,g.elapsed,g.state,g.weapon_clocks,g.player_pos,g.combat.focus_enemy_id,g.effect_runtime.build_items.debug_snapshot(),g.rng.state,g.loot_rng.state,g.shop_rng.state,g.shop_generation,g.shop_offers])
func cycle(reverse:bool,groups:Array)->bool:
 var seen:Array=[];var required:Array=groups.duplicate();required.append(button("BACK"));var closed:=false
 for _i in range(64):
  key(KEY_TAB,reverse);await frames();var owner:Control=root.gui_get_focus_owner()
  if owner==null or not owner.is_visible_in_tree() or not g.ui.modal.is_ancestor_of(owner):return false
  if seen.has(owner):closed=owner==seen[0];break
  seen.append(owner)
 return closed and required.all(func(n):return seen.has(n))
func run_case(mode:String,context:String)->void:
 current=mode+"/"+context
 g._title();g._select_mode(mode);g._start_run(41002);g.set_process(false)
 g.build.weapons=["rivet_gun","scrap_shotgun"];g.build.weapon_temper=[0,0];g.weapon_clocks=[9.0,11.0]
 g.build.items={"crossfire_pin":1,"salvage_capacitor":1,"medic_winch":1};g._recompute();g._sync_weapon_rig()
 if context=="paused":key(KEY_ESCAPE)
 elif context=="shop":g._open_shop()
 elif context=="room_clear":g.enemies.clear();g._begin_room_clear()
 await frames();ck(g.state==context,"actual controller establishes entry context")
 key(KEY_I);await frames()
 ck(g.state=="inventory" and g.inventory_return==context,"I enters BUILD and records return context")
 var back:Button=button("BACK");var groups:Array=top_groups()
 ck(back!=null and root.gui_get_focus_owner()==back,"BACK default focus")
 ck(groups.size()==4 and groups.all(func(t):return not t.button_pressed and not details(t).visible),"all4 initially collapsed")
 if back==null or groups.size()!=4:return
 var before:PackedByteArray=authority()
 for t in groups:t.button_pressed=true
 await frames();ck(groups.all(func(t):return t.button_pressed and details(t).is_visible_in_tree()),"actual toggled handlers open all groups")
 ck(await cycle(false,groups),"expanded Tab isolated and includes4toggles+BACK")
 ck(await cycle(true,groups),"expanded ShiftTab isolated and includes4toggles+BACK")
 ck(authority()==before,"expanded traversal leaves selected post-entry authority unchanged")
 var p:Vector2=back.get_global_rect().get_center()
 for pressed in [true,false]:
  var event:=InputEventMouseButton.new();event.position=p;event.global_position=p;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed;root.push_input(event,true)
 await frames();ck(g.state==context and (g.ui.modal_visible()==(context in ["paused","shop"])),"actual BACK restores correct context/modal")
 key(KEY_I);await frames();groups=top_groups()
 ck(g.state=="inventory" and groups.size()==4 and groups.all(func(t):return not t.button_pressed and not details(t).visible),"reopen all4 collapsed")
 key(KEY_ESCAPE);await frames();ck(g.state==context and (g.ui.modal_visible()==(context in ["paused","shop"])),"Escape restores correct context/modal")
 key(KEY_I);await frames();key(KEY_I);await frames();ck(g.state==context,"I toggles back to correct context")
 records.append({"mode":mode,"context":context,"final_state":g.state,"scope":"controlled actual controller context, synthetic viewport input"})
func _initialize()->void:call_deferred("run")
func run()->void:
 root.size=Vector2i(960,540)
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false);await frames()
 for mode in ["arena","rooms"]:
  for context in (["playing","paused","shop"] if mode=="arena" else ["playing","paused","shop","room_clear"]):
   await run_case(mode,context)
   if not failures.is_empty():break
  if not failures.is_empty():break
 var teardown=Teardown.new();teardown.prepare([g]);g.queue_free();await process_frame;await teardown.finish(self)
 print(JSON.stringify({"checks":checks,"failures":failures,"records":records,"scope":"7controlled mode/context return paths, expanded focus/reopen; not native or natural acquisition"}))
 quit(0 if failures.is_empty() else 1)
