from pathlib import Path
import json,hashlib,shutil,difflib
R=Path('workspace/shared');src=R/'moss-v36-final';dst=R/'moss-v36-r2';out=R/'moss-v36-catalog-plan';assert not dst.exists();dst.mkdir();h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();pins=json.loads((R/'moss-v36-final-prep/FINAL_INPUTS.json').read_text())
for n,s in pins.items():
 assert h(src/n)==s;q=dst/n;q.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src/n,q)
# Authored expected declaration, from the approved feature contract and initial content plan.
item={'id':'scavenger_reel','name':'Scavenger Reel','kind':'item','price':28,'max_stack':1,'rarity':'rare','tags':['returning','salvage'],'effects':{},'description':'Return Disc gathers normal/energy pickups on its return leg; medicine excluded.','trigger':'Actual returning path touches a normal/energy pickup','cost':'1 module slot; Return Disc required; finite quota per launched disc','cooldown':0,'stack_rule':'Unique: maximum 1. Per-disc quota never refills.','synergy_targets':['return_disc'],'return_pickup_radius':18.0,'return_pickup_limit':3,'pickup_sources':['normal','energy']}
pair={'id':'scavenger_return','name':'SCAVENGER RETURN','requires':['return_disc','scavenger_reel'],'description':'Return Disc immediately gathers normal/energy pickups on its return leg. Medicine excluded; no reward multiplier.'};link=['return_disc','scavenger_reel']
insertions=[]
for value in [item,pair,link]:
 lines=json.dumps(value,indent=2).splitlines();close='}' if isinstance(value,dict) else ']';insertions.append('    '+close+',\n'+'\n'.join('    '+line for line in lines[:-1])+'\n')
declared={'item':item,'pair':pair,'link':link,'raw_insertions':insertions};f=dst/'tests/fixtures/v36_catalog_additions.json';f.write_text(json.dumps(declared,indent=2)+'\n');declaration_sha=h(f)
raw=(src/'data/catalog.json').read_text();oldraw=raw
for ins in insertions:assert oldraw.count(ins)==1;oldraw=oldraw.replace(ins,'',1)
assert hashlib.sha256(oldraw.encode()).hexdigest()=='317a2d343ba1a005cd44cc1c2ee91e894adf059d77e57c24f7a5ee9439ec56a0'
assert oldraw==(R/'moss-v35-r4/data/catalog.json').read_text()
helper='''extends RefCounted
## Test-only exact additive history projection. No production code references this.
const DECLARATION_SHA="DECL_SHA"
static func project(catalog:Dictionary,raw:String)->Dictionary:
 var errors:Array=[]
 var path:String="res://tests/fixtures/v36_catalog_additions.json"
 if FileAccess.get_sha256(path)!=DECLARATION_SHA:return {"pass":false,"errors":["declaration identity"],"catalog":{},"bytes":""}
 var declaration:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
 for key in ["weapons","items","mechanism_synergies","affinity_links"]:
  if not catalog.get(key) is Array:return {"pass":false,"errors":["array shape "+key],"catalog":{},"bytes":""}
 if catalog.weapons.size()!=8 or catalog.items.size()!=30 or catalog.mechanism_synergies.size()!=12 or catalog.affinity_links.size()!=12:
  return {"pass":false,"errors":["exact expanded sizes"],"catalog":{},"bytes":""}
 if catalog.items[-1]!=declaration.item:errors.append("exact appended item")
 if catalog.mechanism_synergies[-1]!=declaration.pair:errors.append("exact appended mechanism")
 if catalog.affinity_links[-1]!=declaration.link:errors.append("exact appended affinity")
 if catalog.items.filter(func(e):return e is Dictionary and e.get("id")=="scavenger_reel").size()!=1:errors.append("unique new item")
 if catalog.mechanism_synergies.filter(func(e):return e is Dictionary and e.get("id")=="scavenger_return").size()!=1:errors.append("unique new mechanism")
 if catalog.affinity_links.filter(func(e):return e==declaration.link).size()!=1:errors.append("unique new link")
 var historical:Dictionary=catalog.duplicate(true)
 historical.items.pop_back();historical.mechanism_synergies.pop_back();historical.affinity_links.pop_back()
 var historical_bytes:String=raw
 for insertion in declaration.raw_insertions:
  if historical_bytes.count(insertion)!=1:errors.append("exact raw insertion multiplicity")
  else:historical_bytes=historical_bytes.replace(insertion,"")
 if historical_bytes.sha256_text()!="317a2d343ba1a005cd44cc1c2ee91e894adf059d77e57c24f7a5ee9439ec56a0":errors.append("exact original v35/v33 catalog hash")
 var parsed:Variant=JSON.parse_string(historical_bytes)
 if not parsed is Dictionary or parsed!=historical:errors.append("byte and structured historical projections differ")
 return {"pass":errors.is_empty(),"errors":errors,"catalog":historical,"bytes":historical_bytes}
'''.replace('DECL_SHA',declaration_sha)
(dst/'tests/support/v36_catalog_projection.gd').write_text(helper)
changes={}
def edit(n,a,b):
 p=dst/'tests'/n;s=p.read_text();assert a in s,(n,a);p.write_text(s.replace(a,b,1))
def support(n):edit(n,'extends SceneTree','extends SceneTree\nconst CatalogHistory=preload("res://tests/support/v36_catalog_projection.gd")')
edit('independent_cryo_shop.gd','c.items.size()==29 and','c.items.size()==30 and c.items[-1].id=="scavenger_reel" and');edit('independent_cryo_shop.gd','explicit v26 8+29 including reviewed additions','explicit v36 8+30 including the unique appended Scavenger Reel')
edit('independent_feedback_shop.gd','g.catalog.items.map(func(e):return e.id)==ITEMS,"exact 29 module IDs and order"','g.catalog.items.map(func(e):return e.id)==ITEMS+["scavenger_reel"],"exact 30 module IDs: old order plus Scavenger Reel"')
edit('independent_reservation_views.gd','g.catalog.items.size()==29,"exact 29-module catalog count"','g.catalog.items.size()==30 and g.catalog.items[-1].id=="scavenger_reel","exact 30-module catalog with appended Scavenger Reel"')
edit('test_upgrade_salvage.gd','game.catalog.weapons.size() + game.catalog.items.size() == 37, "still 37 catalog entries"','game.catalog.weapons.size() + game.catalog.items.size() == 38 and game.catalog.items[-1].id=="scavenger_reel", "exact 38 entries including appended Scavenger Reel"')
edit('test_weapon_order.gd','game.catalog.items.size()==29,"catalog count unchanged"','game.catalog.items.size()==30 and game.catalog.items[-1].id=="scavenger_reel","exact expanded catalog count/last module"')
support('test_bankshot_build.gd');edit('test_bankshot_build.gd','g.catalog.items.size()==29 and','g.catalog.items.size()==30 and g.catalog.items[-1].id=="scavenger_reel" and');edit('test_bankshot_build.gd',' check(g.catalog.mechanism_synergies[-2]==expected.pair and g.catalog.affinity_links[-2]==expected.link,"exact additive pair/link")',' var history:Dictionary=CatalogHistory.project(g.catalog,FileAccess.get_file_as_string("res://data/catalog.json"))\n check(history.pass,"exact v36 append-only declaration and original v35 byte identity")\n check(history.catalog.mechanism_synergies[-2]==expected.pair and history.catalog.affinity_links[-2]==expected.link,"exact additive pair/link")')
support('test_modifier_copy.gd');edit('test_modifier_copy.gd',' var masked_catalog:Dictionary=catalog.duplicate(true)',' var history:Dictionary=CatalogHistory.project(catalog,FileAccess.get_file_as_string("res://data/catalog.json"))\n check(history.pass,"exact v36 append-only declaration and original v35 byte identity")\n var masked_catalog:Dictionary=history.catalog.duplicate(true)')
support('independent_reservation_records.gd');edit('independent_reservation_records.gd',' var catalog_bytes:String=FileAccess.get_file_as_string("res://data/catalog.json")',' var expanded_bytes:String=FileAccess.get_file_as_string("res://data/catalog.json")\n var history:Dictionary=CatalogHistory.project(c,expanded_bytes)\n ck(history.pass,"exact v36 append-only declaration and original v35 byte identity")\n var catalog_bytes:String=history.bytes\n projection_negatives(c,expanded_bytes)');edit('independent_reservation_records.gd','c.items.map(func(e):return e.id)==ITEM_IDS,"exact ordered 29 module IDs"','c.items.map(func(e):return e.id)==ITEM_IDS+["scavenger_reel"],"exact ordered 30 module IDs with old order preserved"')
negative='''func projection_negatives(c:Dictionary,raw:String)->void:
 var original:Dictionary=c.duplicate(true)
 for which in range(9):
  var bad:Dictionary=c.duplicate(true)
  match which:
   0:bad.items[-1].price=29
   1:bad.items[0].price+=1
   2:bad.items[-1].return_pickup_limit=4
   3:bad.items.append(bad.items[-1].duplicate(true))
   4:bad.mechanism_synergies[-1].description="unreviewed extra reward"
   5:bad.affinity_links[-1]=["rail_lance","scavenger_reel"]
   6:bad.items.reverse()
   7:bad.mechanism_synergies.append(bad.mechanism_synergies[-1].duplicate(true))
   8:bad.affinity_links.append(bad.affinity_links[-1].duplicate())
  ck(not CatalogHistory.project(bad,raw).pass,"history projector rejects unrelated/undeclared mutation "+str(which))
 ck(not CatalogHistory.project(c,raw+" ").pass,"history projector rejects altered original raw bytes")
 ck(not CatalogHistory.project(c,raw.replace('"return_pickup_limit": 3','"return_pickup_limit": 4')).pass,"history projector rejects nonmatching new raw insertion")
 ck(c==original,"history projection is input read-only")
'''
edit('independent_reservation_records.gd','func _initialize()->void:call_deferred("run")',negative+'func _initialize()->void:call_deferred("run")')
files=['independent_cryo_shop.gd','independent_feedback_shop.gd','independent_reservation_records.gd','independent_reservation_views.gd','test_bankshot_build.gd','test_modifier_copy.gd','test_upgrade_salvage.gd','test_weapon_order.gd'];(out/'diffs').mkdir()
for n in files:
 a=(src/'tests'/n).read_text();b=(dst/'tests'/n).read_text();(out/'diffs'/(n+'.patch')).write_text(''.join(difflib.unified_diff(a.splitlines(True),b.splitlines(True),fromfile='rejected714/tests/'+n,tofile='r2/tests/'+n)));changes['tests/'+n]={'before':h(src/'tests'/n),'after':h(dst/'tests'/n)}
new={str(p.relative_to(dst)):h(p) for p in sorted(dst.rglob('*')) if p.is_file()};actual=[n for n in pins if pins[n]!=new[n]];assert set(actual)==set(changes);prod=json.loads((R/'moss-v36-final-prep/PRODUCTION_FINAL.json').read_text());assert all(h(dst/n)==s for n,s in prod.items());assert h(dst/'tests/run_regression.py')==h(src/'tests/run_regression.py')
plan={'source':'moss-v36-r2','preimport_inputs':len(new),'base714_unchanged_except_eight_fixtures':True,'production131_exact':True,'runner_exact':True,'changes':changes,'new_files':{n:s for n,s in new.items() if n not in pins},'historical_byte_identity':'317a2d343ba1a005cd44cc1c2ee91e894adf059d77e57c24f7a5ee9439ec56a0','raw_reconstruction_equals_held_v35':True,'new_declaration_sha256':declaration_sha,'standalone_discovery_unchanged':125,'status':'PREEXECUTION_TEST_ONLY_CANDIDATE_STATIC_REVIEW_PENDING','focused_cases':files+['test_scavenger_reel.gd','independent_scavenger_authority.gd','independent_scavenger_events.gd','independent_scavenger_views.gd','independent_scavenger_settlement.gd']};(out/'PLAN.json').write_text(json.dumps(plan,indent=2)+'\n');(out/'PREIMPORT_INPUTS.json').write_text(json.dumps(new,indent=2,sort_keys=True)+'\n');print(json.dumps(plan))
