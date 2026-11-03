extends RefCounted
## Proposed test-only strict B inverse. Not installed into a candidate, never production.
const DECLARATION_SHA="5ab1bb1f93b8b58706c6782d5729e104d8320d5a7668518cd48a8ee38dcbb65d"
static func project(catalog:Dictionary,raw:String)->Dictionary:
	var failure:Dictionary={"pass":false,"errors":[],"catalog":{},"bytes":""}
	# V58 adds one acquisition link, not a B combat or economy definition.
	# Only strip that exact addition; the original accepted B bytes remain the oracle.
	if catalog.get("affinity_links") is Array and catalog.affinity_links.size()==15:
		var insertion:String=",\n    [\n      \"medic_winch\",\n      \"medic_seed\"\n    ]"
		if catalog.affinity_links[-1]!=["medic_winch","medic_seed"] or raw.count(insertion)!=1:
			failure.errors.append("V58 exact medical affinity addition");return failure
		catalog=catalog.duplicate(true);catalog.affinity_links.pop_back()
		raw=raw.replace(insertion,"")
		if raw.sha256_text()!="12070828394102ea257f7e234690b1f51fe377b0640f72a89e121fe961c281ee" or JSON.parse_string(raw)!=catalog:
			failure.errors.append("V58 inverse accepted B identity");return failure
	var path:String="res://tests/fixtures/v39_B_catalog_additions.json"
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
