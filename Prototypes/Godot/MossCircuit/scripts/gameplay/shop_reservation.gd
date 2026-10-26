extends RefCounted
## Pure stock policy. A held offer is never equipment or a transaction price override.
const Rules=preload("res://scripts/rules.gd")
const OFFER_COUNT := 4

static func _integer(value:Variant,minimum:int)->bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value)>=minimum and floorf(float(value))==float(value)

static func eligibility_error(build:Dictionary,catalog:Dictionary,offer:Dictionary)->String:
	if not offer.get("id") is String or not offer.get("sold") is bool or offer.sold: return "Offer is not available."
	var entry:=Rules.catalog_entry(catalog,offer.id)
	if entry.is_empty(): return "Unknown offer."
	if not _integer(entry.get("price"),0) or not _integer(entry.get("max_stack"),1): return "Invalid catalog identity."
	var owned:int=build.weapons.count(entry.id) if entry.kind=="weapon" else int(build.items.get(entry.id,0))
	if owned>=int(entry.max_stack): return "Owned maximum reached."
	return ""

static func create(build:Dictionary,catalog:Dictionary,offer:Dictionary,slot:int,token:int)->Dictionary:
	if slot<0 or slot>=OFFER_COUNT or token<=0 or not eligibility_error(build,catalog,offer).is_empty(): return {}
	var entry:=Rules.catalog_entry(catalog,offer.id)
	return {"id":offer.id,"price":int(entry.price),"slot":slot,"token":token,"offer":offer.duplicate(true)}

static func invalid_reason(build:Dictionary,catalog:Dictionary,held:Dictionary)->String:
	if held.is_empty(): return ""
	if not held.get("id") is String or not held.get("offer") is Dictionary: return "invalid reservation identity"
	if not held.get("slot") is int or held.slot<0 or held.slot>=OFFER_COUNT or not held.get("token") is int or held.token<=0: return "invalid reservation token/slot"
	if not held.get("price") is int or held.price<0 or not held.offer.get("id") is String or held.offer.id!=held.id: return "invalid reservation identity"
	var entry:=Rules.catalog_entry(catalog,held.id)
	if entry.is_empty(): return "unknown offer"
	if not _integer(entry.get("price"),0) or int(entry.price)!=held.price: return "catalog price changed"
	var error:=eligibility_error(build,catalog,held.offer)
	return error.trim_suffix(".").to_lower() if not error.is_empty() else ""

static func draw(build:Dictionary,catalog:Dictionary,rng:RandomNumberGenerator,held:Dictionary)->Dictionary:
	if held.is_empty(): return {"offers":Rules.draw_shop(build,catalog,rng,OFFER_COUNT),"clear":false,"notice":""}
	var reason:=invalid_reason(build,catalog,held)
	if not reason.is_empty(): return {"offers":Rules.draw_shop(build,catalog,rng,OFFER_COUNT),"clear":true,"notice":"Reservation released: "+reason+". Four fresh slots."}
	var offers:=Rules.draw_shop(build,catalog,rng,OFFER_COUNT-1,[held.id])
	offers.insert(mini(held.slot,offers.size()),held.offer.duplicate(true))
	return {"offers":offers,"clear":false,"notice":""}

static func describe(build:Dictionary,catalog:Dictionary,held:Dictionary)->Dictionary:
	if held.is_empty(): return {}
	var id:String=held.get("id","") if held.get("id") is String else ""
	var entry:=Rules.catalog_entry(catalog,id)
	var reason:=invalid_reason(build,catalog,held)
	return {"id":id,"name":entry.get("name",id if not id.is_empty() else "Unknown"),"price":held.price if held.get("price") is int else 0,"slot":held.slot if held.get("slot") is int else -1,"token":held.token if held.get("token") is int else -1,"valid":reason.is_empty(),"invalid_reason":reason}

static func matches(held:Dictionary,id:String)->bool:
	# Associate a malformed record with its original visible card too, so it cannot
	# bypass the identity guard or hide the explicit release action.
	if held.get("id") is String and held.id==id: return true
	var original:Variant=held.get("offer")
	return original is Dictionary and original.get("id") is String and original.id==id
