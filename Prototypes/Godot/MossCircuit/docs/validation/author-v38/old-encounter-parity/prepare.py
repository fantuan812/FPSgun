from pathlib import Path
import json,hashlib,difflib
r=Path('workspace/shared');o=r/'moss-v38-parity';h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();base=r/'moss-v37-final'
for n in ['encounters','room_encounters']:(o/(n+'.json')).write_bytes((base/'data'/ (n+'.json')).read_bytes())
block=''' # Exact held v37 encounter/Rooms injection, before any mode construction/run.
 var old_encounters:String=FileAccess.get_file_as_string("evidence-workspace/moss-v38-parity/encounters.json")
 var old_rooms:String=FileAccess.get_file_as_string("evidence-workspace/moss-v38-parity/room_encounters.json")
 if old_encounters.sha256_text()!="853bb3699bb05c2ed1eb7d1c8dc3e51844428c233ffa3127ac035a2762a3f356" or old_rooms.sha256_text()!="4a0067faa08241d91042505d72b3a027956ef27571710d74d8559462ac2c5131":
  failures.append("held encounter bytes changed")
 var current:Dictionary=preload("res://tests/support/v38_encounter_projection.gd").project(FileAccess.get_file_as_string("res://data/encounters.json"),FileAccess.get_file_as_string("res://data/room_encounters.json"))
 if not current.get("pass",false) or current.encounter_bytes!=old_encounters or current.room_bytes!=old_rooms:failures.append("candidate additions not exactly declared")
 var shared_encounters:Dictionary=g.encounters
 var shared_rooms:Dictionary=g.room_profile
 g.encounters.clear();g.encounters.merge(JSON.parse_string(old_encounters),true)
 g.room_profile.clear();g.room_profile.merge(JSON.parse_string(old_rooms),true)
 if shared_encounters!=JSON.parse_string(old_encounters) or shared_rooms!=JSON.parse_string(old_rooms):failures.append("actual shared authority injection failed")
'''
(o/'injection.txt').write_text(block);routes=[]
for name,source,trace,count in [('transactions',r/'moss-v37-parity/current_transactions.gd',r/'moss-v37-parity/results/current-transactions-candidate.json',6),('combat',r/'moss-v36-qa/checks/new_catalog_old_combat.gd',r/'moss-v37-parity/results/current-combat.json',24)]:
 s=source.read_text();needle=' g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)\n';assert s.count(needle)==1;new=s.replace(needle,needle+block,1);f=o/(name+'.gd');f.write_text(new);assert new.replace(block,'',1)==s;(o/(name+'.patch')).write_text(''.join(difflib.unified_diff(s.splitlines(True),new.splitlines(True),fromfile=str(source),tofile=str(f))));routes.append({'name':name,'fixture':str(f),'fixture_sha256':h(f),'original':str(source),'original_sha256':h(source),'retained_trace':str(trace),'retained_sha256':h(trace),'case_count':count})
plan={'status':'STATIC_TWO_ROUTE_PLAN_NOT_EXECUTED','routes':routes,'inputs':{n:h(o/n) for n in ['encounters.json','room_encounters.json','injection.txt']},'source_map':'evidence-workspace/moss-v38-prep/CORRECTED_INPUTS.json','source_map_sha256':h(r/'moss-v38-prep/CORRECTED_INPUTS.json'),'budget_each_seconds':180,'scope':'Only v38 with exact held v37 encounters/Rooms and unchanged current catalog. Original6transaction and24combat assertions/projection/order unchanged; whole output bytes must equal actually executed held v37 traces. Not a baseline rerun or new encounter all-seed parity claim.'};(o/'PLAN.json').write_text(json.dumps(plan,indent=2)+'\n');print(h(o/'PLAN.json'))
