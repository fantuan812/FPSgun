extends SceneTree
# Independent legacy-status reference frozen from v36, before v37 target execution.
const Forecast=preload("res://scripts/gameplay/build_forecast.gd")
const Rules=preload("res://scripts/rules.gd")
const Reel=preload("res://scripts/gameplay/scavenger_reel.gd")
var checks:int=0
var failures:Array=[]
func ck(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label)
func b(ids:Array,items:Dictionary)->Dictionary:return {"coins":500,"weapons":ids.duplicate(true),"items":items.duplicate(true),"levels":{},"revision":0}
func old_status(build:Dictionary,catalog:Dictionary)->Array:
	var rows:Array=[]
	var owned:Array=build.weapons.duplicate()
	owned.append_array(build.items.keys())
	for pair in catalog.get("mechanism_synergies",[]):
		var required:Array=[];var missing:Array=[]
		for id in pair.requires:
			var name:String=Rules.catalog_entry(catalog,id).name
			required.append(name)
			if not owned.has(id):missing.append(name)
		var other:String=str(pair.get("requires_other_weapon_than",""))
		if other!="":
			var requirement:String="a weapon type other than "+Rules.catalog_entry(catalog,other).name
			required.append(requirement)
			var found:bool=false
			for id in build.weapons:
				if id!=other:found=true
			if not found:missing.append(requirement)
		rows.append({"name":pair.name,"active":missing.is_empty(),"requires":required,"missing":missing,"description":Reel.describe(Rules.catalog_entry(catalog,"scavenger_reel")) if pair.get("id","")=="scavenger_return" else str(pair.description)})
	return rows
func run()->void:
	var c:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/catalog.json"))
	var base:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/balance.json")).player
	for legacy in [false,true]:
		var cat:Dictionary=c.duplicate(true)
		if legacy:
			for pair in cat.mechanism_synergies:pair.erase("id");pair.name="same display name"
		for index in range(cat.mechanism_synergies.size()):
			var pair:Dictionary=cat.mechanism_synergies[index]
			for mask in range(4):
				var ids:Array=[];var items:Dictionary={}
				for j in range(pair.requires.size()):
					if mask & (1<<j):
						var id:String=pair.requires[j]
						if Rules.catalog_entry(cat,id).kind=="weapon":ids.append(id)
						else:items[id]=1
				if ids.is_empty():ids=["rivet_gun"]
				for extra in [false,true]:
					var weapons:Array=ids.duplicate()
					if extra and not weapons.has("rivet_gun"):weapons.append("rivet_gun")
					var build:Dictionary=b(weapons,items)
					var expected:Array=old_status(build,cat)
					ck(Forecast.mechanism_status(build,cat)==expected,"legacy exact all row values/order "+str([legacy,index,mask,extra]))
					for offered in pair.requires:
						var next:Dictionary=build.duplicate(true)
						var reason:String=Rules.transaction(next,cat,offered)
						var report:Dictionary=Forecast.project(base,build,cat,offered)
						if reason!="":
							ck(report=={"available":false,"reason":reason},"legacy unavailable exact");continue
						var after:Array=old_status(next,cat);var transitions:Array=[]
						for k in range(expected.size()):
							var change:String=""
							if expected[k].active!=after[k].active:change="enables" if after[k].active else "disables"
							elif not after[k].active and offered in cat.mechanism_synergies[k].requires:change="needs"
							if change!="":transitions.append({"index":k,"before":expected[k],"after":after[k],"change":change})
						ck(report.mechanisms==transitions,"index identity not display name; only relevant transitions")
						var before_tags:Array=Rules.tag_synergy_status(build,cat);var after_tags:Array=Rules.tag_synergy_status(next,cat);var tags:Array=[]
						for k in range(before_tags.size()):
							if before_tags[k].count!=after_tags[k].count or before_tags[k].active!=after_tags[k].active or before_tags[k].matching_weapons!=after_tags[k].matching_weapons:tags.append({"index":k,"before":before_tags[k],"after":after_tags[k]})
						ck(report.tags==tags,"shared legacy tag records exact; transition filter independent")
	print(JSON.stringify({"checks":checks,"failures":failures,"scope":"finite legacy status matrix: 2 catalogs x12pairs x4ownership masks x2otherweapon states; old authority reference, not numeric golden generator"}))
	quit(0 if failures.is_empty() else 1)
func _initialize()->void:call_deferred("run")
