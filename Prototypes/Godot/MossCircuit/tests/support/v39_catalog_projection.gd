extends RefCounted
## Strict test-only inverse of exactly the declared A additions. Never loaded by production.
const DECLARATION_SHA="d065fb56f5fa678e60a1d8ebdc7decdcbc580eb7f50ee8594c4a5227126af736"
static func project(catalog:Dictionary,raw:String)->Dictionary:
 var errors:Array=[]
 var path:String="res://tests/fixtures/v39_catalog_additions.json"
 if FileAccess.get_sha256(path)!=DECLARATION_SHA:return {"pass":false,"errors":["A declaration identity"],"catalog":{},"bytes":""}
 var declaration:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
 var lengths:Dictionary={"weapons":10,"items":33,"mechanism_synergies":14,"affinity_links":14}
 var historical:Dictionary=catalog.duplicate(true)
 for key in lengths:
  if not catalog.get(key) is Array or catalog[key].size()!=lengths[key]:return {"pass":false,"errors":["A exact size "+key],"catalog":{},"bytes":""}
  var addition:Array=declaration[key]
  if catalog[key].slice(lengths[key]-addition.size())!=addition:errors.append("A exact tail "+key)
  historical[key]=catalog[key].slice(0,lengths[key]-addition.size())
 var bytes:String=raw
 for insertion in declaration.raw_insertions:
  if bytes.count(insertion)!=1:errors.append("A exact raw insertion multiplicity")
  else:bytes=bytes.replace(insertion,"")
 if bytes.sha256_text()!=declaration.baseline_sha256:errors.append("accepted v38 catalog raw identity")
 var parsed:Variant=JSON.parse_string(bytes)
 if not parsed is Dictionary or parsed!=historical:errors.append("A raw/structured inverse disagreement")
 return {"pass":errors.is_empty(),"errors":errors,"catalog":historical,"bytes":bytes}
