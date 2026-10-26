extends RefCounted
## Pure starting-loadout registry. No random draws, transactions or live combat state.
const Rules = preload("res://scripts/rules.gd")
const WeaponReadout = preload("res://scripts/weapon_readout.gd")
const DEFAULT_ID := "rivet"

static func integral(value:Variant, low:float, high:float)->bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value)>=low and float(value)<=high and float(value)==floorf(float(value))

static func validate(data:Variant,catalog:Dictionary)->Array:
	var errors:Array=[]
	if not data is Dictionary:return ["Starting loadouts must be an object"]
	if not integral(data.get("version"),1,1):errors.append("Starting loadout version")
	if not data.get("default_id") is String or data.default_id!=DEFAULT_ID:errors.append("Default starting loadout must be rivet")
	if not data.get("loadouts") is Array:return errors+["Starting loadouts must be an array"]
	if data.loadouts.is_empty() or data.loadouts.size()>8:errors.append("Starting loadout count must be 1..8")
	var known:Dictionary={}
	for entry in catalog.get("weapons",[]):
		if entry is Dictionary and entry.get("id") is String:known[entry.id]=true
	var seen:Dictionary={}
	var default_row:Dictionary={}
	for row in data.loadouts:
		if not row is Dictionary:
			errors.append("Starting loadout row must be an object");continue
		for key in ["id","name","strength","limitation"]:
			if not row.get(key) is String or row[key].strip_edges().is_empty():errors.append("Invalid loadout "+key)
		if row.get("id") is String:
			if seen.has(row.id):errors.append("Duplicate starting loadout ID")
			seen[row.id]=true
			if row.id==DEFAULT_ID:default_row=row
		if not row.get("weapon") is String or not known.has(row.weapon):errors.append("Unknown starting weapon")
		if not integral(row.get("starting_scrap"),0,1000000):errors.append("Starting scrap must be a finite nonnegative integer")
	if default_row.is_empty():errors.append("Missing rivet default")
	else:
		if not default_row.get("weapon") is String or default_row.weapon!="rivet_gun":errors.append("Default weapon must preserve Rivet")
		if not integral(catalog.get("starting_coins"),0,1000000) or not integral(default_row.get("starting_scrap"),0,1000000):errors.append("Invalid default starting scrap")
		elif int(default_row.starting_scrap)!=int(catalog.starting_coins):errors.append("Default scrap must preserve existing factory")
	return errors

static func entry(data:Dictionary,catalog:Dictionary,id:Variant)->Dictionary:
	if not id is String or not validate(data,catalog).is_empty():return {}
	for row in data.loadouts:
		if row.id==id:
			var result:Dictionary=row.duplicate(true)
			result.starting_scrap=int(result.starting_scrap)
			return result
	return {}

static func make_build(data:Dictionary,catalog:Dictionary,id:Variant)->Dictionary:
	var row:=entry(data,catalog,id)
	if row.is_empty():return {}
	var build:=Rules.new_build(catalog)
	if id!=DEFAULT_ID:
		build.weapons=[row.weapon]
		build.coins=row.starting_scrap
	return build

static func previews(data:Dictionary,catalog:Dictionary)->Array:
	if not validate(data,catalog).is_empty():return []
	var result:Array=[]
	for source in data.loadouts:
		var row:=entry(data,catalog,source.id)
		var weapon:=Rules.catalog_entry(catalog,row.weapon)
		row.weapon_name=weapon.name
		row.weapon_readout=WeaponReadout.describe(weapon,{},false)
		result.append(row)
	return result
