extends SceneTree
## Exact asset-candidate native cards; controlled valid builds, not natural acquisition.
const Rules=preload("res://scripts/rules.gd")
const Teardown=preload("<WORKSPACE>/moss-v39-ui/equipment16-native/support/audio_teardown.gd")
const OLD_WEAPONS=["rivet_gun","scrap_shotgun","rail_lance","orbit_saw"]
const OLD_ITEMS=["power_coil","cooling_fan","iron_plate","moss_patch","running_boots","salvage_magnet","lucky_chip","lens","capacitor","gear","pellet_pouch","recycler"]
const A_WEAPONS=["tether_emitter","seismic_drum"]
const A_ITEMS=["lock_memory","return_collar","recoil_plate"]
var g
var checks:int=0
var failures:Array=[]
var records:Array=[]
var groups:Array=[]
var oracle:Dictionary={}
func ck(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label)
func nodes(node:Node)->Array:
	var out:Array=[node]
	for child in node.get_children():out.append_array(nodes(child))
	return out
func button(text:String)->Button:
	var found:Array=nodes(g.ui).filter(func(n):return n is Button and n.text==text and n.is_visible_in_tree())
	return found[0] if found.size()==1 else null
func pointer(at:Vector2,which:int,pressed:bool)->void:
	var e:=InputEventMouseButton.new();e.position=at;e.global_position=at;e.button_index=which;e.pressed=pressed;root.push_input(e,true)
func click(at:Vector2)->void:pointer(at,MOUSE_BUTTON_LEFT,true);pointer(at,MOUSE_BUTTON_LEFT,false)
func key(code:int,shift:bool=false)->void:
	for pressed in [true,false]:
		var e:=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.shift_pressed=shift;e.pressed=pressed;root.push_input(e,true)
func frames()->void:await process_frame;await process_frame
func scroll_of(node:Node)->ScrollContainer:
	var n:Node=node
	while n!=null:
		if n is ScrollContainer:return n
		n=n.get_parent()
	return null
func fit(card:Control)->bool:
	if card==null:return false
	var scroll:ScrollContainer=scroll_of(card)
	if scroll==null:return false
	for _i in range(24):
		var rect:Rect2=card.get_global_rect();var sr:Rect2=scroll.get_global_rect()
		if sr.encloses(rect):return true
		var which:int=MOUSE_BUTTON_WHEEL_DOWN if rect.end.y>sr.end.y else MOUSE_BUTTON_WHEEL_UP
		pointer(sr.get_center(),which,true);pointer(sr.get_center(),which,false);await frames()
	return scroll.get_global_rect().encloses(card.get_global_rect())
func digest(bytes:PackedByteArray)->String:
	var h:=HashingContext.new();h.start(HashingContext.HASH_SHA256);h.update(bytes);return h.finish().hex_encode()
func identity(tex:Texture2D,id:String)->bool:
	if not tex is AtlasTexture or not oracle.has(id):return false
	var e:Dictionary=oracle[id]
	if tex.atlas.resource_path!=e.atlas or tex.region!=Rect2(e.rect[0],e.rect[1],e.rect[2],e.rect[3]) or not tex.filter_clip:return false
	var im:Image=tex.get_image()
	if im==null:return false
	if im.is_compressed():im.decompress()
	im.clear_mipmaps();im.convert(Image.FORMAT_RGBA8);var bytes:PackedByteArray=im.get_data()
	for i in range(0,bytes.size(),4):
		if bytes[i+3]==0:bytes[i]=0;bytes[i+1]=0;bytes[i+2]=0
	return im.get_size()==Vector2i(e.rect[2],e.rect[3]) and digest(bytes)==str(e.visible_rgba_sha256)
func focus_cycle(reverse:bool)->Dictionary:
	var seen:Array=[];var paths:Array=[];var closed:bool=false;var isolated:bool=true
	for _i in range(64):
		key(KEY_TAB,reverse);await process_frame;var owner:Control=root.gui_get_focus_owner()
		if owner==null:isolated=false;break
		var path:String=str(owner.get_path());paths.append(path)
		if not g.ui.modal.is_ancestor_of(owner):isolated=false;break
		if seen.has(path):closed=path==seen[0];break
		seen.append(path)
	return {"pass":closed and isolated,"closed":closed,"isolated":isolated,"paths":paths}
func open_build()->bool:
	var b:Button=button("BUILD [I]")
	if b==null:return false
	click(b.get_global_rect().get_center());await frames();return g.state=="inventory" and g.ui.modal_visible()
func card(id:String)->void:
	var entry:Dictionary=Rules.catalog_entry(g.catalog,id)
	var prefix:String=str(entry.name)+("  [SLOT " if entry.kind=="weapon" else "  x")
	var labels:Array=nodes(g.ui).filter(func(n):return n is Label and n.text.begins_with(prefix) and n.is_visible_in_tree())
	ck(labels.size()==1,"unique actual card "+id)
	if labels.size()!=1:return
	var panel:Control=labels[0].get_parent().get_parent().get_parent()
	var fitted:bool=await fit(panel);ck(fitted,"whole card GUI wheel "+id)
	var textures:Array=nodes(panel).filter(func(n):return n is TextureRect)
	ck(textures.size()==1 and textures[0].is_visible_in_tree(),"actual TextureRect "+id)
	if textures.size()!=1:return
	var image:TextureRect=textures[0]
	ck(identity(image.texture,id),"loaded atlas crop visible RGBA "+id)
	ck(root.get_visible_rect().encloses(image.get_global_rect()) and panel.get_global_rect().encloses(image.get_global_rect()) and image.size.x>=48 and image.size.y>=48,"icon visual rect within card "+id)
	var back:Button=button("BACK");ck(back!=null and root.get_visible_rect().encloses(back.get_global_rect()),"fixed BACK visible "+id)
	await frames();var name:String="card_"+id+".png";var save_error:int=root.get_texture().get_image().save_png(OS.get_environment("MOSS_E16_IMAGES").path_join(name))
	records.append({"id":id,"image":name,"save_error":save_error,"card_rect":str(panel.get_global_rect()),"icon_rect":str(image.get_global_rect()),"scroll_rect":str(scroll_of(panel).get_global_rect()),"back_rect":str(back.get_global_rect()) if back!=null else "","atlas":image.texture.atlas.resource_path if image.texture is AtlasTexture else "","region":str(image.texture.region) if image.texture is AtlasTexture else "","logical":str(root.get_visible_rect()),"os_size":str(DisplayServer.window_get_size()),"content_scale":str(root.content_scale_size),"modal_layer":g.ui.layer,"scope":"controlled real inventory card, not offer or natural acquisition"})
	print("E16_NATIVE_IMAGE "+JSON.stringify(records[-1]))
func group(name:String,weapons:Array,items:Array,targets:Array)->void:
	g._title();g._select_mode("arena");g._start_run(39031);g.set_process(false)
	g.build.weapons=weapons.duplicate();g.build.weapon_temper=[];g.weapon_clocks=[]
	for _id in weapons:g.build.weapon_temper.append(0);g.weapon_clocks.append(999.0)
	g.build.items={}
	for id in items:g.build.items[id]=1
	g._recompute();g._update_hud();g.queue_redraw();await frames()
	var selected:int=g.combat.focus_enemy_id
	ck(g.build.weapons.size()<=4 and g.build.items.size()<=8,"legal slot counts "+name)
	var opened:bool=await open_build();ck(opened,"actual BUILD click "+name)
	if not opened:return
	for id in targets:
		await card(id)
		if not failures.is_empty():return
	var forward:Dictionary=await focus_cycle(false);ck(forward["pass"],"Tab isolation "+name)
	var reverse:Dictionary=await focus_cycle(true);ck(reverse["pass"],"ShiftTab isolation "+name)
	var back:Button=button("BACK")
	if back!=null:click(back.get_global_rect().get_center());await frames()
	var closed_record:Dictionary={"state":g.state,"modal_visible":g.ui.modal_visible(),"local_panel_visible":g.ui.modal.visible,"focus_enemy":g.combat.focus_enemy_id,"expected_focus_enemy":selected}
	ck(g.state=="playing" and not g.ui.modal_visible() and g.combat.focus_enemy_id==selected,"actual BACK closes no world activation "+name)
	var reopened:bool=await open_build()
	var reopen_record:Dictionary={"state":g.state,"modal_visible":g.ui.modal_visible(),"focus_enemy":g.combat.focus_enemy_id,"open_result":reopened}
	key(KEY_ESCAPE);await frames()
	var escaped_record:Dictionary={"state":g.state,"modal_visible":g.ui.modal_visible(),"local_panel_visible":g.ui.modal.visible,"focus_enemy":g.combat.focus_enemy_id,"expected_focus_enemy":selected}
	ck(reopened and g.state=="playing" and not g.ui.modal_visible() and g.combat.focus_enemy_id==selected,"reopen Escape closes "+name)
	groups.append({"name":name,"forward":forward,"reverse":reverse,"selected_before_after":selected,"after_back":closed_record,"after_reopen":reopen_record,"after_escape":escaped_record})
func _initialize()->void:call_deferred("run")
func run()->void:
	var args:PackedStringArray=OS.get_cmdline_user_args()
	if DisplayServer.get_name()=="headless" or args.size()!=1:print("E16_NATIVE_PREFLIGHT_REJECT");quit(2);return
	var parsed:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(args[0]));oracle=parsed.icons
	if oracle.size()!=21:print("E16_NATIVE_ORACLE_REJECT");quit(2);return
	g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false);await frames()
	DisplayServer.window_set_size(Vector2i(960,540));await frames()
	ck(g.ui.manifest.icons.size()==43,"actual merged43 unchanged")
	await group("legacy_first",OLD_WEAPONS,OLD_ITEMS.slice(0,8),OLD_WEAPONS+OLD_ITEMS.slice(0,8))
	if failures.is_empty():await group("legacy_rest",OLD_WEAPONS,OLD_ITEMS.slice(8,12),OLD_ITEMS.slice(8,12))
	if failures.is_empty():await group("expansion_A",A_WEAPONS,A_ITEMS,A_WEAPONS+A_ITEMS)
	var teardown=Teardown.new();teardown.prepare([g]);g.queue_free();await process_frame;await teardown.finish(self)
	print(JSON.stringify({"checks":checks,"failures":failures,"records":records,"groups":groups,"scope":"equipment16 plus A5 actual native inventory display/identity/input; controlled builds, not natural acquisition"}))
	quit(0 if failures.is_empty() else 1)
