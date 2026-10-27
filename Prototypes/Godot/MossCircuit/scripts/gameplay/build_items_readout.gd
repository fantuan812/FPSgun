extends RefCounted
## Pure, bounded presentation of the canonical detached B snapshot.
## Never calls runtime housekeeping, RNG, combat, healing or pickup collection.
static func describe(snapshot:Dictionary, now:float, enemies:Array)->Dictionary:
	var out:Dictionary={"rows":[],"pin":{},"fields":[]}
	var owned:Dictionary=snapshot.get("owned_items",{})
	var definitions:Dictionary=snapshot.get("definitions",{})
	if not is_finite(now):return out
	for id in ["crossfire_pin","salvage_capacitor","medic_winch"]:
		if int(owned.get(id,0))<=0:continue
		var profile:Dictionary=definitions.get(id,{})
		if bool(snapshot.get("configuration_open",true)) or profile.is_empty():
			out.rows.append({"id":id,"status":"INACTIVE / configuration unavailable","detail":"No active mechanic is implied."})
			continue
		match id:
			"crossfire_pin":
				var status:String="READY / awaiting first eligible contact"
				var types:Array=snapshot.get("equipped_types",[])
				var mark:Variant=snapshot.get("mark")
				var ready:Variant=snapshot.get("pin_ready_at")
				if types.size()<int(profile.requires_distinct_weapon_types):
					status="INACTIVE / needs %d distinct weapon types" % int(profile.requires_distinct_weapon_types)
				elif mark is Dictionary:
					var target:Dictionary=_live_target(mark.get("target_id"),enemies)
					if float(mark.get("expires",0))<=now or target.is_empty() or not types.has(mark.get("weapon")):
						status="NO VALID MARK / awaiting simulation update"
					else:
						status="MARKED / %.2fs left / hit same target with another type" % (float(mark.expires)-now)
						out.pin={"anchor":mark.position,"target":target.pos}
				elif ready!=null and float(ready)>now:
					status="COOLDOWN / %.2fs" % (float(ready)-now)
				out.rows.append({"id":id,"status":status,"detail":"Pull control only; no added damage. Mark symbol is not a successful pull."})
			"salvage_capacitor":
				for field in snapshot.get("fields",[]):
					if float(field.expires)>now:
						out.fields.append({"pos":field.pos,"radius":float(profile.field_radius)})
				var charges:int=int(snapshot.get("charges",0))
				var status:String="CHARGING" if charges<int(profile.charge_limit) else "READY / next real dash spends charge"
				out.rows.append({"id":id,"status":"%s / %d/%d / fields %d/%d" % [status,charges,int(profile.charge_limit),out.fields.size(),int(profile.field_limit)],"detail":"Normal combat pickups charge it. Field: %.0f%% movement speed, no damage; bosses and charging enemies excluded." % (100.0*float(profile.field_speed_factor))})
			"medic_winch":
				var status:String="PICKUPS %d/%d" % [int(snapshot.get("winch_count",0)),int(profile.pickup_count)]
				if snapshot.get("pending")!=null:status+=" / pull queued for this batch"
				out.rows.append({"id":id,"status":status,"detail":"NEEDS MEDICAL PICKUPS (currently Medic Seed). Normal combat pickups count; at most one pull per collection batch. Moves medicine only: no direct healing, creation or collection; no medicine still spends threshold."})
	return out

static func _live_target(id:Variant,enemies:Array)->Dictionary:
	if not id is int or id<=0:return {}
	var found:Dictionary={}
	var matches:int=0
	for enemy in enemies:
		if not enemy is Dictionary or not enemy.get("id") is int or enemy.id!=id:continue
		matches+=1
		found=enemy
	if matches!=1:return {}
	if not (found.get("hp") is float or found.get("hp") is int):return {}
	if not is_finite(float(found.hp)) or float(found.hp)<=0:return {}
	if not found.get("boss") is bool or bool(found.boss):return {}
	if not found.get("pos") is Vector2 or not found.pos.is_finite():return {}
	return found
