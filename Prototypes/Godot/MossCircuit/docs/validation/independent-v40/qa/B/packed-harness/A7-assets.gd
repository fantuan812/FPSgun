extends SceneTree
var checks:=0
var failures:Array=[]
func ck(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func image_of(t:Texture2D)->Image:
 var im=t.get_image()
 if im.is_compressed():im.decompress()
 im.clear_mipmaps();im.convert(Image.FORMAT_RGBA8)
 return im
func sha(im:Image)->String:
 var h=HashingContext.new();h.start(HashingContext.HASH_SHA256);h.update(im.get_data());return h.finish().hex_encode()
func _initialize()->void:call_deferred("run")
func run()->void:
 var args=OS.get_cmdline_user_args()
 if args.size()!=3:push_error("Expected raw source oracle, actual source imported fingerprint, output report");quit(2);return
 var expected=JSON.parse_string(FileAccess.get_file_as_string(args[0]))
 var imported=JSON.parse_string(FileAccess.get_file_as_string(args[1]))
 ck(expected.rows.size()==7,"exact accepted seven source assets")
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 var historical_A=load("evidence-workspace/moss-v39-B-qa/packed-harness/v39_B_catalog_projection.gd").project(g.catalog,FileAccess.get_file_as_string("res://data/catalog.json"))
 var A_catalog:Dictionary=historical_A.get("catalog",{})
 ck(historical_A.get("pass",false) and A_catalog.get("weapons",[]).size()==10 and A_catalog.get("items",[]).size()==33,"strict B-only inverse A catalog identity counts; actual rig/UI remain current B")
 var world=JSON.parse_string(FileAccess.get_file_as_string("res://assets/weapon_mounts/world_weapon_manifest.json"))
 var icons=JSON.parse_string(FileAccess.get_file_as_string("res://assets/items/expansion_A_icon_manifest.json"))
 for row in expected.rows:
  var texture=load(row.path)
  ck(texture is Texture2D,"texture resolves "+row.id)
  if not texture is Texture2D:continue
  var im=image_of(texture)
  ck(im.get_width()==int(row.width) and im.get_height()==int(row.height),"source dimensions "+row.id)
  ck(sha(im)==imported.images[row.path.trim_prefix("res://")].imported_rgba_sha256,"actual source-imported RGBA equality "+row.id)
  var box=im.get_used_rect();ck(box==Rect2i(int(row.alpha_bbox[0]),int(row.alpha_bbox[1]),int(row.alpha_bbox[2]),int(row.alpha_bbox[3])),"independent raw alpha bbox "+row.id)
  var binary=true;var data=im.get_data()
  for i in range(3,data.size(),4):
   if data[i]!=0 and data[i]!=255:binary=false
  ck(binary,"binary alpha preserved "+row.id)
  if row.id.ends_with("_held"):
   var id=row.id.trim_suffix("_held");var actual=world.weapons[id];var geometry={}
   for k in row.geometry:geometry[k]=actual[k]
   ck(geometry==row.geometry and actual.path==row.path and actual.sha256==row.png_sha256 and actual.editable_source==row.editable_source and actual.editable_sha256==row.svg_sha256,"accepted world geometry and source identity "+id)
   ck(g.weapon_rig.assets.has(id) and sha(image_of(g.weapon_rig.assets[id]))==sha(im),"actual rig loads held sprite not inventory "+id)
   ck(im.get_pixel(int(row.grip_px[0]),int(row.grip_px[1])).a==1.0,"opaque physical grip "+id)
  else:
   var id=row.id.trim_suffix("_icon");var actual=icons.icons[id]
   ck(actual.atlas==row.path and actual.source_sha256==row.png_sha256 and actual.editable_source==row.editable_source and actual.editable_sha256==row.svg_sha256,"accepted icon source identity "+id)
   var icon=g.ui.icon(id)
   ck(icon is AtlasTexture and icon.filter_clip,"actual UI clipped icon "+id)
   ck(icon is AtlasTexture and icon.region==Rect2(row.icon_rect[0],row.icon_rect[1],row.icon_rect[2],row.icon_rect[3]),"actual UI exact crop "+id)
   ck(icon is AtlasTexture and sha(image_of(icon.atlas))==sha(im),"actual UI source atlas identity "+id)
 var helper=load("evidence-workspace/moss-v39-B-qa/packed-harness/audio_teardown.gd").new();helper.prepare([g]);g.queue_free();await process_frame;await helper.finish(self)
 var report={"checks":checks,"failures":failures,"scope":"Seven SVG-derived formal source identities, current actual rig/UI bindings, imported source vs PCK pixel equality; raw transparent RGB not assumed identical to imported"}
 FileAccess.open(args[2],FileAccess.WRITE).store_string(JSON.stringify(report));print(JSON.stringify(report));quit(0 if failures.is_empty() else 1)
