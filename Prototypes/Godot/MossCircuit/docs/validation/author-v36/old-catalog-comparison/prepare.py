from pathlib import Path
import json,hashlib,difflib,datetime
r=Path('workspace/shared');d=r/'moss-v36-parity';sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();cat=r/'moss-v35-r4/data/catalog.json';assert sha(cat)=='317a2d343ba1a005cd44cc1c2ee91e894adf059d77e57c24f7a5ee9439ec56a0'
insert='''
 # Exact old catalog in the SAME shared Dictionary, before any tested run/offer.
 var old_catalog:Variant=JSON.parse_string(FileAccess.get_file_as_string("evidence-workspace/moss-v35-r4/data/catalog.json"))
 if not old_catalog is Dictionary or not Rules.validate_catalog(old_catalog).is_empty():
  push_error("Invalid pinned old catalog");quit(1);return
 g.catalog.clear();g.catalog.merge(old_catalog,true);g.effects.configure(g.catalog)
 g.catalog["__parity_identity_probe"]=36036
 if g.weapon_combat.catalog.get("__parity_identity_probe")!=36036 or g.combat_frame.catalog.get("__parity_identity_probe")!=36036:
  failures.append("old catalog is not shared by actual combat authorities")
 g.catalog.erase("__parity_identity_probe")
 if g.catalog!=old_catalog:failures.append("old catalog authority differs")
'''
rows=[]
for label,source,expected in [('transactions',r/'moss-v33-qa/checks/no_temper_transactions.gd',r/'moss-v35-r3-prep/old-transactions.json'),('combat',r/'moss-v33-qa/baseline/no_reorder_trace.gd',r/'moss-v35-r3-prep/old-combat.json')]:
 old=source.read_text();needle=' g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)\n';assert needle in old;new=old.replace(needle,needle+insert,1);needle=' g.queue_free();await process_frame';assert needle in new;new=new.replace(needle,' var audio_teardown=preload("res://tests/support/audio_teardown.gd").new()\n audio_teardown.prepare([g])\n g.queue_free();await process_frame\n await audio_teardown.finish(self)',1)
 p=d/(label+'.gd');assert not p.exists();p.write_text(new);(d/(label+'.patch')).write_text(''.join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile=str(source),tofile=str(p))))
 rows.append({'name':label,'original_source':str(source),'original_sha256':sha(source),'external_fixture':str(p),'external_sha256':sha(p),'historical_trace':str(expected),'historical_trace_sha256':sha(expected)})
plan={'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'status':'FROZEN_EXTERNAL_FIXTURE_NOT_EXECUTED','old_catalog':str(cat),'old_catalog_sha256':sha(cat),'fixtures':rows,'projects':['moss-v35-r4','moss-v36-work'],'candidate_source_map_sha256':sha(r/'moss-v36-prep/POSTIMPORT_INPUTS.json'),'budget_per_case':180,'order':'baseline transactions, baseline combat, candidate transactions, candidate combat','gates':['strict exit/error/resource warning/semantic marker','baseline and candidate output byte equality','both output bytes also equal retained historical outputs','project source maps unchanged'],'scope':'Actual old catalog actual shared combat/transaction authority; not new enlarged-catalog shop offer parity. Only catalog setup and final-owner test cleanup differ from historical oracles.'};(d/'PLAN.json').write_text(json.dumps(plan,indent=2)+'\n');print(json.dumps(plan))
