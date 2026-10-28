extends "evidence-workspace/moss-held8-integration-review/pre-capture-r2/actual_fire_r2.gd"
# External native observation; inherited assertion/state utilities, not run_one.
const RETAINED=["tether_emitter","seismic_drum"]
var images:Array=[]
func transforms(p:Dictionary)->Array:
 var sprite:Sprite2D=g.weapon_rig.slots[0].sprite
 var geo:Dictionary=g.weapon_rig.geometry[g.build.weapons[0]]
 var size:=Vector2(geo.region[2],geo.region[3])
 return [sprite.to_global(Vector2(geo.grip[0],geo.grip[1])*size+sprite.offset).distance_to(p.mount)<0.001,sprite.to_global(Vector2(geo.muzzle[0],geo.muzzle[1])*size+sprite.offset).distance_to(p.muzzle)<0.001]
func shot_ok(id:String,p:Dictionary,target:Vector2,enemy:Dictionary)->bool:
 var weapon:Dictionary=Rules.catalog_entry(g.catalog,id)
 var reach:float=Rules.weapon_reach(weapon,g.stats)
 if id=="orbit_saw":return g.bullets.is_empty() and enemy.hp<1000 and not g.flashes.is_empty() and g.flashes[-1].pos==g.player_pos
 if id=="cryo_sprayer":
  var cones:Array=g.combat.effect_visuals.filter(func(x):return x.kind=="cryo_cone")
  return cones.size()==1 and cones[0].pos==g.player_pos and cones[0].radius==reach
 if id=="shock_mortar":return g.pending_blasts.size()==1 and g.pending_blasts[0].visual_origin==p.muzzle and g.pending_blasts[0].pos==target
 if g.bullets.size()!=Rules.weapon_projectiles(weapon,g.stats):return false
 for b in g.bullets:
  if b.pos!=p.muzzle:return false
 return true
func photo(name:String)->void:
 var authority:PackedByteArray=pre_capture_authority()
 g.queue_redraw()
 await process_frame
 await RenderingServer.frame_post_draw
 var im:=root.get_texture().get_image()
 var error:=im.save_png(OS.get_environment("MOSS_HELD_IMAGES").path_join(name+".png"))
 var row:Dictionary={"name":name+".png","width":im.get_width(),"height":im.get_height(),"save_error":error,"logical":str(root.get_visible_rect()),"window":str(root.size),"os_window":str(DisplayServer.window_get_size()),"crop_rect":[400,250,160,140],"authority_before":byte_hash(authority),"authority_after":byte_hash(pre_capture_authority()),"owner_live_disabled":is_instance_valid(g) and not g.is_queued_for_deletion() and not g.is_processing()}
 images.append(row)
 print("HELD_NATIVE_IMAGE "+JSON.stringify(row))
 ck(error==OK and im.get_width()==960 and im.get_height()==540 and row.authority_before==row.authority_after and row.owner_live_disabled,"actual viewport saved "+name)
func run()->void:
 if DisplayServer.get_name()=="headless":quit(2);return
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 await process_frame
 for id in IDS+RETAINED:
  for left in [false,true]:
   g._title();g._select_mode("arena");g._start_run(83017);g.set_process(false)
   g.build.weapons=[id];g.build.weapon_temper=[0];g.build.items={};g._recompute();g.spawn_clock=999;g.weapon_clocks=[999.0]
   g.hero.flip_h=left
   var weapon:Dictionary=Rules.catalog_entry(g.catalog,id)
   var target:Vector2=g.player_pos+Vector2(-1 if left else 1,0.12).normalized()*minf(Rules.weapon_reach(weapon,g.stats)*0.45,120)
   var enemy:Dictionary=g._spawn_kind("crawler",target);enemy.hp=1000;enemy.max_hp=1000;enemy.speed=0
   g._sync_weapon_rig()
   var label:String=id+("_left" if left else "_right")
   var sprite:Sprite2D=g.weapon_rig.slots[0].sprite
   var pose:Dictionary=g.weapon_rig.slots[0].pose
   var t:Array=transforms(pose)
   ck(g.weapon_rig.slots[0].id==id,"actual slot "+label)
   ck(sprite.texture is AtlasTexture and sprite.texture.atlas.resource_path==g.weapon_rig.geometry[id].path,"actual texture binding "+label)
   ck(t[0],"actual grip "+label);ck(t[1],"actual tip "+label)
   ck(sprite.visible,"held visible "+label)
   ck(sprite.scale==pose.scale,"actual calibrated scale "+label)
   await photo(label+"_held")
   var row:Dictionary={"id":id,"left_requested":left,"held_pose":var_to_str(pose),"retained_only":id in RETAINED}
   if id in IDS:
    var before:Array=states()
    g._fire_weapon(id,0)
    var shot:Dictionary=g.weapon_rig.last_shot
    ck(not shot.is_empty() and shot.id==id,"actual fire "+label)
    var p:Dictionary=shot.pose
    ck(shot_ok(id,p,target,enemy),"classification origin "+label)
    var x:Array=transforms(p)
    ck(x[0] and x[1],"fire real grip/tip "+label)
    g._sync_weapon_rig()
    var state_ok:bool=true
    if id=="return_disc":state_ok=g.weapon_rig.slots[0].hidden and g.weapon_rig.disc_sprites.size()==1 and g.weapon_rig.disc_sprites[0].position==g.bullets[0].pos
    elif id not in ["orbit_saw","cryo_sprayer"]:
     var flashes:Array=g.vfx.active.filter(func(v):return v.id=="muzzle_flash")
     state_ok=flashes.size()==1 and flashes[0].pos==p.muzzle.round()
    ck(state_ok,"actual flight/flash state "+label)
    ck(states()==before,"fire gameplay RNG unchanged "+label)
    row.fire_pose=var_to_str(p);row.bullets=g.bullets.size();row.player_centered=id in ["orbit_saw","cryo_sprayer"]
    await photo(label+"_fire")
   records.append(row)
 ck(records.size()==20,"20 finite held scenes")
 ck(images.size()==36,"36 original viewport images")
 var before_drain:PackedByteArray=pre_capture_authority()
 await process_frame
 ck(before_drain==pre_capture_authority() and is_instance_valid(g) and not g.is_queued_for_deletion() and not g.is_processing(),"pre-capture live authority unchanged")
 var teardown=Teardown.new();teardown.prepare([g]);g.queue_free();await process_frame
 var audio:Dictionary=await teardown.finish(self)
 print(JSON.stringify({"checks":checks,"failures":failures,"records":records,"images":images,"scope":"20 native held scenes;16 real old-weapon fire;A2 held preservation only;human original screenshot review required"}))
 quit(0 if failures.is_empty() and audio.complete else 1)
