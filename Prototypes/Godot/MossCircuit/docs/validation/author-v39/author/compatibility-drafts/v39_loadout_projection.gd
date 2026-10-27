extends RefCounted
## Test-only exact inverse; never loaded by production. Draft not yet executed.
const DECLARATION_SHA="201fdfa7de14d2fadd94af590dc2e2eb6c35798d3b30e2145bf50fa97b5c7bfa"
static func project(data:Dictionary,raw:String)->Dictionary:
 var errors:Array=[]
 var path:String="res://tests/fixtures/v39_loadout_additions.json"
 if FileAccess.get_sha256(path)!=DECLARATION_SHA:return {"pass":false,"errors":["A starter declaration identity"],"data":{},"bytes":""}
 var declaration:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
 if not data.get("loadouts") is Array or data.loadouts.size()!=5:return {"pass":false,"errors":["A starter exact five rows"],"data":{},"bytes":""}
 if data.loadouts.slice(3)!=declaration.rows:errors.append("A exact two appended starters")
 var historical:Dictionary=data.duplicate(true)
 historical.loadouts=data.loadouts.slice(0,3)
 var bytes:String=raw
 for insertion in declaration.raw_insertions:
  if bytes.count(insertion)!=1:errors.append("A starter raw insertion multiplicity")
  else:bytes=bytes.replace(insertion,"")
 if bytes.sha256_text()!=declaration.baseline_sha256:errors.append("accepted v38 starter raw identity")
 var parsed:Variant=JSON.parse_string(bytes)
 if not parsed is Dictionary or parsed!=historical:errors.append("A starter raw/structured inverse disagreement")
 return {"pass":errors.is_empty(),"errors":errors,"data":historical,"bytes":bytes}
