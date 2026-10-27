extends RefCounted
## Detached equipped-build projection only. Never a live transaction or combat forecast.
const BuildItemsProfiles=preload("res://scripts/gameplay/build_items_profiles.gd")
const Rules=preload("res://scripts/rules.gd")
const WeaponTempering=preload("res://scripts/gameplay/weapon_tempering.gd")
const WeaponReadout=preload("res://scripts/weapon_readout.gd")
const ScavengerReel=preload("res://scripts/gameplay/scavenger_reel.gd")

static func mechanism_status(build:Dictionary,catalog:Dictionary)->Array:
	var result:Array=[]
	for pair_data in catalog.get("mechanism_synergies",[]):
		var required:Array=[]
		var missing:Array=[]
		for id in pair_data.requires:
			var label:String=Rules.catalog_entry(catalog,id).name
			required.append(label)
			if not Rules.owned_ids(build).has(id):missing.append(label)
		var excluded_weapon:String=str(pair_data.get("requires_other_weapon_than",""))
		if not excluded_weapon.is_empty():
			var requirement:String="a weapon type other than "+Rules.catalog_entry(catalog,excluded_weapon).name
			required.append(requirement)
			if not build.weapons.any(func(id):return id!=excluded_weapon):missing.append(requirement)
		if pair_data.has("requires_distinct_weapon_types"):
			var requirement:String="two different currently equipped weapon types"
			required.append(requirement)
			var types:Dictionary=BuildItemsProfiles.weapon_types(build.weapons,catalog)
			var requirement_value:Variant=pair_data.requires_distinct_weapon_types
			var valid_requirement:bool=(requirement_value is int or requirement_value is float) and is_finite(float(requirement_value)) and float(requirement_value)==2.0
			if not valid_requirement or not types.valid or types.ids.size()<2:missing.append(requirement)
		var description:String=ScavengerReel.describe(Rules.catalog_entry(catalog,"scavenger_reel")) if pair_data.get("id","")=="scavenger_return" else str(pair_data.description)
		result.append({"name":pair_data.name,"active":missing.is_empty(),"requires":required,"missing":missing,"description":description})
	return result.duplicate(true)

static func _unavailable(reason:String)->Dictionary:
	return {"available":false,"reason":reason}

static func project(base:Dictionary,build:Dictionary,catalog:Dictionary,id:String,replace_slot:Variant=-1)->Dictionary:
	var entry:Dictionary=Rules.catalog_entry(catalog,id)
	if entry.is_empty():return _unavailable("Unknown item")
	if not replace_slot is int or replace_slot < -1:return _unavailable("Invalid replacement slot")
	if entry.kind=="item" and replace_slot!=-1:return _unavailable("Item purchases do not replace weapons")
	if entry.kind=="weapon" and replace_slot>=build.weapons.size():return _unavailable("Invalid replacement slot")
	var projected:Dictionary=build.duplicate(true)
	var error:String=Rules.transaction(projected,catalog,id,replace_slot)
	if not error.is_empty():return _unavailable(error)
	var removed:Dictionary={}
	var added:Dictionary={"kind":entry.kind,"id":id,"name":entry.name,"slot":-1,"tier":0}
	if entry.kind=="weapon":
		added.slot=replace_slot if replace_slot>=0 else projected.weapons.size()-1
		if replace_slot>=0:
			var old_id:String=build.weapons[replace_slot]
			removed={"slot":replace_slot,"id":old_id,"name":Rules.catalog_entry(catalog,old_id).name,"tier":WeaponTempering.tier_at(build,replace_slot,old_id)}
	var mechanisms:Array=[]
	var before_status:Array=mechanism_status(build,catalog)
	var after_status:Array=mechanism_status(projected,catalog)
	for i in range(before_status.size()):
		var before:Dictionary=before_status[i]
		var after:Dictionary=after_status[i]
		var change:String=""
		if before.active!=after.active:change="enables" if after.active else "disables"
		elif not after.active and id in catalog.mechanism_synergies[i].requires:change="needs"
		if not change.is_empty():mechanisms.append({"index":i,"before":before,"after":after,"change":change})
	var tags:Array=[]
	var before_tags:Array=Rules.tag_synergy_status(build,catalog)
	var after_tags:Array=Rules.tag_synergy_status(projected,catalog)
	for i in range(before_tags.size()):
		var before:Dictionary=before_tags[i]
		var after:Dictionary=after_tags[i]
		if before.count!=after.count or before.active!=after.active or before.matching_weapons!=after.matching_weapons:
			tags.append({"index":i,"before":before,"after":after})
	var weapons:Array=[]
	var warning:String=WeaponTempering.metadata_error(build)
	if warning.is_empty():
		var before_stats:Dictionary=Rules.derive(base,build,catalog)
		var after_stats:Dictionary=Rules.derive(base,projected,catalog)
		for i in range(projected.weapons.size()):
			var weapon_id:String=projected.weapons[i]
			var weapon:Dictionary=Rules.catalog_entry(catalog,weapon_id)
			var before:Dictionary={}
			if i<build.weapons.size():
				var old_id:String=build.weapons[i]
				before=WeaponReadout.describe(Rules.catalog_entry(catalog,old_id),before_stats,true,WeaponTempering.multiplier(build,catalog,i,old_id))
			var after:Dictionary=WeaponReadout.describe(weapon,after_stats,true,WeaponTempering.multiplier(projected,catalog,i,weapon_id))
			weapons.append({"slot":i,"id":weapon_id,"name":weapon.name,"tier":WeaponTempering.tier_at(projected,i,weapon_id),"before":before,"after":after})
	return {"available":true,"reason":"","id":id,"replace_slot":replace_slot,"coins_before":int(build.coins),"coins_after":int(projected.coins),"weapon_count_before":build.weapons.size(),"weapon_count_after":projected.weapons.size(),"item_count_before":build.items.size(),"item_count_after":projected.items.size(),"removed":removed,"added":added,"mechanisms":mechanisms,"tags":tags,"weapons":weapons,"weapon_readouts_available":warning.is_empty(),"weapon_readout_warning":warning}.duplicate(true)
