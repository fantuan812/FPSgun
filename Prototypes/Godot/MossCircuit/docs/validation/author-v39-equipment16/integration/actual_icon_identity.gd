extends SceneTree
# External gate, never shipped in runtime. Uses actual MossUI ready/merge/icon method.
var checks := 0
var failures: Array = []
var observations: Array = []
func ck(ok: bool, label: String) -> void:
 checks += 1
 if not ok: failures.append(label)
func digest(bytes: PackedByteArray) -> String:
 var h := HashingContext.new(); h.start(HashingContext.HASH_SHA256); h.update(bytes); return h.finish().hex_encode()
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var args := OS.get_cmdline_user_args()
 if args.size()!=2: quit(2); return
 var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
 var ui = load("res://ui/moss_ui.gd").new()
 root.add_child(ui)
 await process_frame
 ck(ui.manifest.icons.size()==43,"actual merged43icons")
 ck(ui.manifest.atlas=="res://assets/items/equipment_atlas_editable.png","actual primary new atlas")
 for id in expected.icons:
  var e: Dictionary = expected.icons[id]
  ck(ui.manifest.icons.has(id),"actual merged id "+id)
  if not ui.manifest.icons.has(id): continue
  var entry: Dictionary = ui.manifest.icons[id]
  ck(entry.get("atlas",ui.manifest.atlas)==e.atlas,"actual binding "+id)
  ck(entry.rect==e.rect,"actual rect "+id)
  ck(entry.name==e.name and entry.category==e.category,"actual metadata "+id)
  var tex = ui.icon(id)
  ck(tex is AtlasTexture,"actual icon AtlasTexture "+id)
  if not tex is AtlasTexture: continue
  ck(tex.atlas.resource_path==e.atlas,"actual loaded atlas "+id)
  ck(tex.filter_clip,"actual cell clip "+id)
  ck(tex.region==Rect2(e.rect[0],e.rect[1],e.rect[2],e.rect[3]),"actual texture region "+id)
  var im: Image = tex.get_image()
  ck(im!=null and not im.is_empty(),"actual image readable "+id)
  if im==null or im.is_empty(): continue
  if im.is_compressed(): im.decompress()
  im.clear_mipmaps(); im.convert(Image.FORMAT_RGBA8)
  ck(im.get_size()==Vector2i(e.rect[2],e.rect[3]),"actual cropped size "+id)
  var raw := im.get_data(); var visible := raw.duplicate()
  for k in range(0,visible.size(),4):
   if visible[k+3]==0: visible[k]=0; visible[k+1]=0; visible[k+2]=0
  ck(digest(visible)==e.visible_rgba_sha256,"actual visible RGBA exact "+id)
  observations.append({"id":id,"raw_rgba_sha256":digest(raw),"source_raw_rgba_sha256":e.rgba_sha256,"visible_rgba_sha256":digest(visible),"atlas":tex.atlas.resource_path})
 for alias in {"damage":"power_coil","speed":"running_boots","haste":"cooling_fan","health":"iron_plate","magnet":"salvage_magnet","pierce":"capacitor"}:
  ck(ui.icon(alias)!=null,"upgrade alias load "+alias)
 ck(not ResourceLoader.exists("res://assets/items/equipment_atlas_v2.png"),"oldatlas not loadable")
 var report := {"checks":checks,"failures":failures,"observations":observations,"scope":"actual UI21 texture identities (equipment16+A5); no native appearance or actual PCK listing proof"}
 var file := FileAccess.open(args[1],FileAccess.WRITE); file.store_string(JSON.stringify(report,"  ")+"\n");file.close()
 ui.queue_free();await process_frame
 print(JSON.stringify(report))
 quit(0 if failures.is_empty() else 1)
