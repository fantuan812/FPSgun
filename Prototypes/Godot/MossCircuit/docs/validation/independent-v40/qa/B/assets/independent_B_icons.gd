extends SceneTree
# External independent resource probe: old A43 bindings, actual46 loading, B3 Pillow identities.
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
 var ui = load("res://ui/moss_ui.gd").new(); root.add_child(ui)
 await process_frame
 var ids: Array = ui.manifest.icons.keys(); ids.sort()
 var wanted: Array = expected.icons.keys(); wanted.sort()
 ck(ids==wanted and ids.size()==46,"exact actual46 IDs including preserved A43")
 ck(ui.manifest.atlas=="res://assets/items/equipment_atlas_v2.png","B does not silently integrate equipment16 candidate")
 for id in wanted:
  var e: Dictionary = expected.icons[id]
  ck(ui.manifest.icons.has(id),"actual id "+id)
  if not ui.manifest.icons.has(id): continue
  var entry: Dictionary = ui.manifest.icons[id]
  ck(entry.get("atlas",ui.manifest.atlas)==e.atlas and entry.rect==e.rect and entry.name==e.name and entry.category==e.category,"exact accepted binding metadata "+id)
  var tex = ui.icon(id)
  ck(tex is AtlasTexture,"actual AtlasTexture "+id)
  if not tex is AtlasTexture: continue
  ck(tex.atlas.resource_path==e.atlas and tex.filter_clip and tex.region==Rect2(e.rect[0],e.rect[1],e.rect[2],e.rect[3]),"actual loaded path region clipping "+id)
  if not expected.new.has(id): continue
  var im: Image = tex.get_image()
  ck(im!=null and not im.is_empty(),"readable B3 image "+id)
  if im==null or im.is_empty(): continue
  if im.is_compressed(): im.decompress()
  im.clear_mipmaps(); im.convert(Image.FORMAT_RGBA8)
  ck(im.get_size()==Vector2i(64,64),"B3 exact64 "+id)
  var raw := im.get_data(); var visible := raw.duplicate(); var alpha := PackedByteArray(); var binary := true
  for k in range(0,raw.size(),4):
   alpha.append(raw[k+3]); binary = binary and raw[k+3] in [0,255]
   if raw[k+3]==0: visible[k]=0;visible[k+1]=0;visible[k+2]=0
  var v: Dictionary = expected.new[id]
  ck(binary and digest(alpha)==v.alpha_sha256,"B3 binary alpha exact "+id)
  ck(digest(visible)==v.visible_rgba_sha256,"B3 nonzero-alpha RGB exact; alpha0 RGB normalized only "+id)
  ck(im.get_used_rect()==Rect2i(v.bbox[0],v.bbox[1],v.bbox[2],v.bbox[3]),"B3 alpha bounds exact "+id)
  observations.append({"id":id,"raw_rgba_sha256":digest(raw),"source_png_rgba_sha256":v.rgba_sha256,"visible_rgba_sha256":digest(visible),"alpha_sha256":digest(alpha),"atlas":tex.atlas.resource_path})
 var report := {"checks":checks,"failures":failures,"observations":observations,"scope":"actual46 UI resource binding/loading plus B3 independent visible RGBA; no native layer/ordinary claim"}
 var file := FileAccess.open(args[1],FileAccess.WRITE);file.store_string(JSON.stringify(report,"  ")+"\n");file.close()
 ui.queue_free();await process_frame
 print(JSON.stringify(report));quit(0 if failures.is_empty() else 1)
