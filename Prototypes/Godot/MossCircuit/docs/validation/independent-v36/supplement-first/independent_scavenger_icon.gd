extends SceneTree
## Dedicated SVG imported-texture source/PCK identity, separate from PNG-only generic fingerprint.
func _initialize()->void:call_deferred("run")
func run()->void:
 var failures:Array=[]
 var texture=load("res://assets/items/scavenger_reel.svg")
 if not texture is Texture2D:failures.append("SVG actual Texture2D load")
 var result:Dictionary={}
 if texture is Texture2D:
  var pixels:Image=texture.get_image()
  if pixels==null:failures.append("texture Image unavailable")
  else:
   if pixels.is_compressed():pixels.decompress()
   result={"width":pixels.get_width(),"height":pixels.get_height(),"format":pixels.get_format(),"pixel_bytes":pixels.get_data().size(),"pixel_sha256":pixels.get_data().hex_encode().sha256_text()}
   # Hash convention above is explicitly hexadecimal image bytes followed by SHA256, not PNG encoding.
   if result.width!=64 or result.height!=64 or result.pixel_bytes<=0:failures.append("exact64 nonempty texture")
 var manifest:PackedByteArray=FileAccess.get_file_as_bytes("res://assets/items/scavenger_icon_manifest.json")
 result.manifest_sha256=manifest.hex_encode().sha256_text()
 var parsed=JSON.parse_string(manifest.get_string_from_utf8())
 if not parsed is Dictionary or not parsed.has("icons") or not parsed.icons.has("scavenger_reel"):failures.append("manifest mapping")
 else:
  var icon:Dictionary=parsed.icons.scavenger_reel
  if icon.atlas!="res://assets/items/scavenger_reel.svg" or icon.rect!=[0,0,64,64]:failures.append("exact mapped texture rectangle")
  result.original_svg_source_sha256=icon.get("source_sha256","")
 var args:=OS.get_cmdline_user_args()
 if args.size()<2:failures.append("need write-oracle or verify and JSON path")
 elif args[0]=="write-oracle":
  if FileAccess.file_exists(args[1]):failures.append("refuse overwrite source oracle")
  elif failures.is_empty():FileAccess.open(args[1],FileAccess.WRITE).store_string(JSON.stringify(result,"  ")+"\n")
 elif args[0]=="verify":
  var expected=JSON.parse_string(FileAccess.get_file_as_string(args[1]))
  if expected!=result:failures.append("packed imported pixels/metadata differ from frozen source oracle")
 else:failures.append("unknown operation")
 print(JSON.stringify({"status":"PASS" if failures.is_empty() else "FAIL","failures":failures,"identity":result,"scope":"Actual loaded SVG texture pixels/format and manifest identity; not generic PNG coverage or visual aesthetic certification; no source SVG byte-presence claim in PCK."}))
 quit(0 if failures.is_empty() else 1)
