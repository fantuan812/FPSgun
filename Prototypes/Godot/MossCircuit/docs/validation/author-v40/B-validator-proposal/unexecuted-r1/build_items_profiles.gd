extends RefCounted
## Detached data-only projection. No live helper configure/sync or gameplay side effects.
const Runtime=preload("res://scripts/gameplay/build_items_runtime.gd")
static func definition(entry:Variant)->Dictionary:
	if not entry is Dictionary or not entry.get("id") is String:return {}
	if not str(entry.id) in Runtime.B_IDS:return {}
	return Runtime._definition(entry).duplicate(true)
static func weapon_types(weapons:Variant,catalog:Variant)->Dictionary:
	var invalid:Dictionary={"valid":false,"ids":[]}
	if not catalog is Dictionary or not catalog.get("weapons") is Array:return invalid
	var known:Dictionary={}
	for row in catalog.weapons:
		if not row is Dictionary or not row.get("id") is String:return invalid
		if str(row.id).is_empty() or known.has(row.id):return invalid
		if not row.get("kind") is String or str(row.kind)!="weapon":return invalid
		if not Runtime._whole(row.get("max_stack"),1):return invalid
		known[row.id]={"kind":"weapon","max_stack":int(row.max_stack)}
	return Runtime.distinct_weapon_types(weapons,known).duplicate(true)

## Exact configuration admission domain of frozen Runtime, without any instance/state.
static func configuration(catalog:Variant)->Dictionary:
	var errors:Array=[]
	if not catalog is Dictionary:return {"ok":false,"errors":["catalog must be dictionary"]}
	if not catalog.get("weapons") is Array or not catalog.get("items") is Array:return {"ok":false,"errors":["catalog lists required"]}
	if not Runtime._whole(catalog.get("weapon_slots"),1) or not Runtime._whole(catalog.get("item_slots"),1):return {"ok":false,"errors":["invalid slot counts"]}
	if int(catalog.weapon_slots)!=4 or int(catalog.item_slots)!=8:return {"ok":false,"errors":["B preserves four weapon/eight item slots"]}
	var next_registry:Dictionary={}
	var next_definitions:Dictionary={"crossfire_pin":{},"salvage_capacitor":{},"medic_winch":{}}
	var seen:Dictionary={}
	for list_key in ["weapons","items"]:
		var expected_kind:String="weapon" if list_key=="weapons" else "item"
		for value in catalog[list_key]:
			if not value is Dictionary:errors.append("entry must be dictionary");continue
			var entry:Dictionary=value
			if not entry.get("id") is String or str(entry.id).is_empty():errors.append("invalid ID");continue
			var id:String=entry.id
			if seen.has(id):errors.append("duplicate ID "+id);continue
			seen[id]=true
			if not entry.get("kind") is String or str(entry.kind)!=expected_kind:errors.append("wrong registry kind "+id);continue
			if not Runtime._whole(entry.get("max_stack"),1):errors.append("invalid max stack "+id);continue
			next_registry[id]={"kind":expected_kind,"max_stack":int(entry.max_stack)}
			if id in Runtime.B_IDS:
				var definition:Dictionary=definition(entry)
				if definition.is_empty():errors.append("invalid B definition "+id)
				else:next_definitions[id]=definition
	if not errors.is_empty():return {"ok":false,"errors":errors}
	return {"ok":true,"errors":[],"registry":next_registry,"definitions":next_definitions,"slot_caps":{"weapons":4,"items":8}}

