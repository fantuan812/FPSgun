extends RefCounted
## Proposed test-only strict B inverse. Not installed into a candidate, never production.
const DECLARATION_SHA="5ab1bb1f93b8b58706c6782d5729e104d8320d5a7668518cd48a8ee38dcbb65d"
static func project(catalog:Dictionary,raw:String)->Dictionary:
	var failure:Dictionary={"pass":false,"errors":[],"catalog":{},"bytes":""}
	var path:String="evidence-workspace/moss-v39-B-qa/packed-harness/v39_B_catalog_additions.json"
	if FileAccess.get_sha256(path)!=DECLARATION_SHA:
		failure.errors.append("B declaration identity");return failure
	var declaration:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
	var lengths:Dictionary={"weapons":10,"items":36,"mechanism_synergies":17,"affinity_links":14}
	var historical:Dictionary=catalog.duplicate(true)
	for key in lengths:
		if not catalog.get(key) is Array or catalog[key].size()!=lengths[key]:
			failure.errors.append("B exact size "+key);return failure
		var addition:Array=declaration[key]
		if not addition.is_empty() and catalog[key].slice(lengths[key]-addition.size())!=addition:failure.errors.append("B exact tail "+key)
		historical[key]=catalog[key].slice(0,lengths[key]-addition.size()).duplicate(true)
	var bytes:String=raw
	for insertion in declaration.raw_insertions:
		if bytes.count(insertion)!=1:failure.errors.append("B exact raw insertion multiplicity")
		else:bytes=bytes.replace(insertion,"")
	if bytes.sha256_text()!=declaration.baseline_sha256:failure.errors.append("accepted A catalog raw identity")
	var parsed:Variant=JSON.parse_string(bytes)
	if not parsed is Dictionary or parsed!=historical:failure.errors.append("B raw/structured inverse disagreement")
	if not failure.errors.is_empty():return failure
	return {"pass":true,"errors":[],"catalog":historical,"bytes":bytes,"scope":"exact B3 items/B3 mechanism rows removed to accepted A raw; not B catalog acceptance"}
