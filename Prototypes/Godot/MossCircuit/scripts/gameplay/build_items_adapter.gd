extends RefCounted
## Pure value projection for the trusted internal EffectRuntime boundary only.
## Does not touch the old event, defaults, command order or enemy dictionaries.
static func _simple(value:Variant)->bool:
	return value==null or value is int or value is float or value is bool or value is String or value is Vector2
static func canonical_event(kind:String,data:Dictionary,epoch:int,sequence:int)->Dictionary:
	var projected:Dictionary={"kind":kind,"epoch":epoch,"sequence":sequence}
	for key in ["source","depth"]:
		var value:Variant=data[key] if data.has(key) else (("normal" if kind=="pickup" else "primary") if key=="source" else 0)
		if not _simple(value):return {}
		projected[key]=value
	var required:Array=["weapon","target"] if kind=="hit" else (["pos"] if kind=="dash" else [])
	for key in required:
		if not data.has(key):continue # Missing payload stays missing; helper PRE rejects.
		var value:Variant=data[key]
		if not _simple(value):return {}
		projected[key]=value
	return projected
