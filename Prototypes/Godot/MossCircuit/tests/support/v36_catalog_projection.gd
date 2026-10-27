extends RefCounted
## Test-only exact additive history projection. No production code references this.
const DECLARATION_SHA="b26ca154835eecd3ad85f7f1925aaa9f3089aac3f18d36d66b2425be99852622"
static func project(catalog:Dictionary,raw:String)->Dictionary:
 if catalog.get("weapons") is Array and catalog.weapons.size()==10:
  var a:Dictionary=preload("res://tests/support/v39_B_then_A_catalog_projection.gd").project(catalog,raw)
  if not a.pass:return a
  catalog=a.catalog;raw=a.bytes
 var errors:Array=[]
 var path:String="res://tests/fixtures/v36_catalog_additions.json"
 if FileAccess.get_sha256(path)!=DECLARATION_SHA:return {"pass":false,"errors":["declaration identity"],"catalog":{},"bytes":""}
 var declaration:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
 for key in ["weapons","items","mechanism_synergies","affinity_links"]:
  if not catalog.get(key) is Array:return {"pass":false,"errors":["array shape "+key],"catalog":{},"bytes":""}
 if catalog.weapons.size()!=8 or catalog.items.size()!=30 or catalog.mechanism_synergies.size()!=12 or catalog.affinity_links.size()!=12:
  return {"pass":false,"errors":["exact expanded sizes"],"catalog":{},"bytes":""}
 if catalog.items[-1]!=declaration.item:errors.append("exact appended item")
 if catalog.mechanism_synergies[-1]!=declaration.pair:errors.append("exact appended mechanism")
 if catalog.affinity_links[-1]!=declaration.link:errors.append("exact appended affinity")
 if catalog.items.filter(func(e):return e is Dictionary and e.get("id")=="scavenger_reel").size()!=1:errors.append("unique new item")
 if catalog.mechanism_synergies.filter(func(e):return e is Dictionary and e.get("id")=="scavenger_return").size()!=1:errors.append("unique new mechanism")
 if catalog.affinity_links.filter(func(e):return e==declaration.link).size()!=1:errors.append("unique new link")
 var historical:Dictionary=catalog.duplicate(true)
 historical.items.pop_back();historical.mechanism_synergies.pop_back();historical.affinity_links.pop_back()
 var historical_bytes:String=raw
 for insertion in declaration.raw_insertions:
  if historical_bytes.count(insertion)!=1:errors.append("exact raw insertion multiplicity")
  else:historical_bytes=historical_bytes.replace(insertion,"")
 if historical_bytes.sha256_text()!="317a2d343ba1a005cd44cc1c2ee91e894adf059d77e57c24f7a5ee9439ec56a0":errors.append("exact original v35/v33 catalog hash")
 var parsed:Variant=JSON.parse_string(historical_bytes)
 if not parsed is Dictionary or parsed!=historical:errors.append("byte and structured historical projections differ")
 return {"pass":errors.is_empty(),"errors":errors,"catalog":historical,"bytes":historical_bytes}
