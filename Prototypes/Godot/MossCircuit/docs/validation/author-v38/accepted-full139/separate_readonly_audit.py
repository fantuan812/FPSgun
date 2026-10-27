from pathlib import Path
import json, hashlib,re,datetime
R=Path('workspace/shared'); S=R/'moss-v38-final-r2'; P=R/'moss-v38-final-r2-prep'; F=P/'full-regression'; O=R/'moss-v38-final-prep'; OLD=R/'moss-v38-final'
h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
j=lambda p:json.loads(p.read_text())
checks=[]
def ck(v,label):
 checks.append({'check':label,'pass':bool(v)})
 if not v: print('FAIL',label)
pins=j(P/'FINAL_INPUTS.json'); prod=j(P/'PRODUCTION_FINAL.json')
ck(len(pins)==772 and all(h(S/k)==v for k,v in pins.items()),'772 frozen file bytes match')
ck(len(prod)==139 and all(h(S/k)==v for k,v in prod.items()),'139 production hashes match')
ck(all(h(R/'moss-v38-r2'/k)==v for k,v in prod.items()),'139 production bytes identical to repaired R2')
ck(h(P/'FINAL_INPUTS.json')=='bcf2b8555bd6acd17ca4ce62a209fe1701ec886937ec991223a59f560a6784cc','pinned map identity')
ck(h(S/'MANIFEST.json')==j(P/'FINAL_FREEZE.json')['manifest_sha256'],'source manifest identity')
plan=j(P/'REVISION_PLAN.json')
ck(all(h(S/k)==v['after'] and h(OLD/k)==v['before'] for k,v in plan['changed'].items()),'declared revision changed hashes')
ck(all(h(S/k)==v for k,v in plan['added'].items()),'declared revision added hashes')
historical=(S/'tests/support/historical_feedback_authority_v35.gd').read_text()
ck(h(S/'tests/support/historical_feedback_authority_v35.gd')==h(OLD/'tests/independent_feedback_authority.gd'),'historical773 exact old source')
a=(S/'tests/independent_feedback_authority.gd').read_text();b=(S/'tests/independent_feedback_authority_rooms.gd').read_text()
ck(a.replace('for mode in ["arena"]:', 'for mode in ["arena","rooms"]:')==historical,'Arena partition only loop edit')
initial=' var initial=make_game("arena");resource_checks(initial);initial.queue_free();await process_frame\n'
ck(b.replace('for mode in ["rooms"]:', 'for mode in ["arena","rooms"]:').replace('func run()->void:\n','func run()->void:\n'+initial)==historical,'Rooms partition only loop edit and resource97 removal')
runner=(S/'tests/run_regression.py').read_text(); oldrunner=(OLD/'tests/run_regression.py').read_text()
newblock=runner[runner.index('        # Preserve partial timeout streams;'):runner.index('    (output / (label + ".log"))')]
restored=runner.replace(newblock,'        log, code = str(error), 124\n').replace('"independent_feedback_authority_rooms.gd", ','')
ck(restored==oldrunner,'runner only partial-timeout preservation and Rooms dispatch')
ck(h(S/'tests/run_regression.py')==j(P/'FULL_PLAN.json')['runner_sha256'],'actual plan runner identity')
discovered=sorted((S/'tests').glob('*.gd'))+[S/'ui/test_ui.gd']+sorted((S/'docs/art').glob('check*.gd'))
discovered=[x for x in discovered if x.read_text().lstrip().startswith('extends SceneTree')]
summary=j(F/'summary.json'); expected=['import']+[x.name for x in discovered]
ck(len(discovered)==138 and [x['test'] for x in summary]==expected,'exact139 discovery and recorded execution order')
ck(len(list(F.glob('*.log')))==139,'exact139 original logs')
ck(all(x['exit']==0 and x['pass'] and not x['error'] and x['seconds']<180 for x in summary),'all139 native0 within original per-command180')
ck((P/'full-native-exit.txt').read_text().strip()=='0' and (P/'full-exit.txt').read_text().strip()=='0','native and wrapper original terminal0')
rawhash={}; warnings=[]; tears=[]; semantic={}; json_count=0
marker=re.compile(r'"failures"\s*:\s*\[\s*\]|failures=\[\]|\b0 failed\b|\b0 failures\b|^PASS:|UI_STRUCTURE_AND_INTENTS_PASS',re.M)
for rec in summary:
 f=F/(rec['test']+'.log');t=f.read_text();rawhash[f.name]=h(f)
 ck('ERROR:' not in t and not re.search(r'(?:SCRIPT ERROR|Parse Error|leaked|still in use)',t,re.I),'clean error/resource scan '+rec['test'])
 if rec['test']!='import':ck(bool(marker.search(t)) and rec['success_marker'],'raw success marker '+rec['test'])
 for line in t.splitlines():
  if 'WARNING:' in line:warnings.append({'test':rec['test'],'line':line})
  if line.startswith('TEST_AUDIO_TEARDOWN '):
   d=json.loads(line.split(' ',1)[1]);q=d['observations'][-1]
   good=d['complete'] and d['capture_removed'] and not d['prepare_errors'] and q['owner_count']>0 and q['game_owner_count']>0 and q['prepare_errors']==0 and q['owners_released'] and q['streams_released'] and q['invalid']==q['discarded']==0 and q['new_pushed']>=q['required_frames']>0 and q['silent_frames']>=q['required_frames'] and 150000<=q['elapsed_us']<=1000000
   ck(good,'bounded teardown '+rec['test']);tears.append({'test':rec['test'],'final':q,'observations':len(d['observations'])});continue
  start=line.find('{')
  if start<0:continue
  try:d=json.loads(line[start:])
  except ValueError:continue
  if not isinstance(d,dict):continue
  json_count+=1
  if 'failures' in d:ck(d['failures']==[],'semantic failures empty '+rec['test'])
  if 'failed' in d:ck(d['failed']==0,'semantic failed zero '+rec['test'])
  if 'pass' in d:ck(d['pass'] is True,'semantic pass '+rec['test'])
  semantic.setdefault(rec['test'],[]).append(d)
for f in F.glob('*.json'):
 rawhash[f.name]=h(f); d=j(f)
 if isinstance(d,dict) and 'failures' in d:ck(d['failures']==[],'sidecar empty failures '+f.name)
ih=j(F/'input-hashes.json');ck(ih['before']==ih['after'] and not ih['changed'] and all(h(S/k)==v for k,v in ih['before'].items()),'runner before/after map current bytes all equal')
result=j(F/'result.json'); ck(result=={'entries':138,'passed':139,'import_included_in_passed':True,'input_changes':[],'all_pass':True},'aggregate original result consistency')
for n,c in [('independent_feedback_authority',435),('independent_feedback_authority_rooms',338),('independent_settlement_types',1164),('independent_feedback_views',168),('independent_feedback_mixer',236)]:ck(j(F/(n+'.json'))['checks']==c,'exact sidecar checks '+n)
settle=j(F/'independent_settlement_types.json');rows=settle['audio_observations']
ck(len(rows)==204 and {(r['mode'],r['index']) for r in rows}=={(m,i) for m in ['arena','rooms'] for i in range(102)},'all204 invalid controller boundaries')
ck(all(r['explicit_stop_all_calls_during_controller']==r['stop_calls_through_snapshot']==0 and r['positive_control_requested']==[True,True] and r['positive_control_stop_delta']==1 and r['positive_control_players_stopped'] for r in rows),'all204 zero explicit stop and true positive controls')
for mode,name in [('arena','independent_feedback_authority'),('rooms','independent_feedback_authority_rooms')]:
 obs=j(F/(name+'.json'))['observations'];ck(len(obs)==36 and all(x['mode']==mode for x in obs) and {x['audio'] for x in obs}=={'enabled','muted','missing'},'authority observations '+mode)
for name,count in [('authority',126),('runtime',104),('encounters',369),('projectiles',38),('death_disposal',8),('assets',120)]:
 d=semantic['independent_support_'+name+'.gd'][-1];ck(d['checks']==count,'support exact count '+name)
ck(semantic['test_actor_actions.gd'][-1]['passed']==418,'actor exact418')
d=semantic['independent_support_death_disposal.gd'][-1]
ck(all(x['source_removed'] and not x['token_present'] and not x['due'] and x['pending']=={} and x['target_id']==-1 and x['witness']==0 and x['target_hp']==50 for x in d['observations']),'both retained dead dictionaries fully disposed no recipient heal')
oldreject=j(O/'COORDINATED_FULL_REJECTED.json')
ck(h(O/'COORDINATED_FULL_REJECTED.json')==plan['old_full_rejected_sha256'],'old rejected report pinned identity')
ck(all(h(O/k)==v for k,v in oldreject['artifact_sha256'].items()),'all original rejected evidence bytes retained')
ck(oldreject['passed']==135 and oldreject['commands']==138 and oldreject['native_exit']==1,'old135/138 remains rejected')
for n in ['independent_settlement_types.gd','test_actor_actions.gd']:
 t=(O/'full-regression'/(n+'.log')).read_text(); ds=[json.loads(l) for l in t.splitlines() if l.startswith('{')];ck(bool(ds[-1]['failures']),'retained original semantic failures '+n)
ck('NOT_CAPTURED' in oldreject['timeout_partial_streams'],'old partial timeout unknown retained')
synthetic=R/'moss-v38-source-partition-plan/synthetic-timeout-results/RESULT.json';ck(h(synthetic)==plan['synthetic_logging_pass_sha256'],'synthetic logger receipt pinned identity')
manifest=j(S/'MANIFEST.json');ck(all(h(S/k)==v for k,v in manifest.items()),'all manifest entries match current source')
oldpins=j(O/'FINAL_INPUTS.json')
actual_changed={k for k in oldpins if pins.get(k)!=oldpins[k]}
# MANIFEST is deliberately regenerated; import adds two UID files.
ck(actual_changed==set(plan['changed'])|{'MANIFEST.json'},'no undeclared source changes beyond regenerated manifest')
ck(set(pins)-set(oldpins)==set(plan['added'])|{'tests/independent_feedback_authority_rooms.gd.uid','tests/support/historical_feedback_authority_v35.gd.uid'},'only two declared files and two imported UIDs added')
oldwarning=(O/'full-regression/independent_scavenger_views.gd.log').read_text().count('WARNING: The draw_rect()')
ck(oldwarning==len(warnings)==48 and all(x['test']=='independent_scavenger_views.gd' for x in warnings),'48 draw_rect warnings exactly same source/count as rejected old aggregate')
ck(h(S/'tests/independent_scavenger_views.gd')==h(OLD/'tests/independent_scavenger_views.gd'),'warning-producing fixture unchanged')
diag=j(R/'moss-v38-settlement-diagnostic/results/RESULT.json')
ck(diag['native_exit']==0 and diag['reports'][0]['checks']==960 and diag['reports'][0]['failures']==[],'retained diagnostic960 does not reproduce old failures')
ck(j(P/'COLD_IMPORT.json')['pass'] and j(P/'focused/RESULT.json')['pass'] and j(P/'focused/RESULT.json')['cases']==6,'separate original cold/focused receipts successful')
report={'pass':all(x['pass'] for x in checks),'separate_reviewer':True,'reviewer':'review-role/audit_v38_full_regression','review_type':'Independent read-only audit of original coordinated QA execution, NOT rerun','source_map_sha256':h(P/'FINAL_INPUTS.json'),'input_map_sha256':h(P/'FINAL_INPUTS.json'),'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'source':str(S),'raw':str(F),'counts':{'frozen_inputs':772,'production':139,'commands':139,'raw_logs':len(rawhash)-len(list(F.glob('*.json'))),'json_sidecars':len(list(F.glob('*.json'))),'semantic_json_records':json_count,'bounded_teardown_reports':len(tears),'audit_checks':len(checks),'warning_lines':len(warnings)},'original_full_seconds':j(P/'COORDINATED_FULL_GATE.json')['seconds'],'max_case_seconds':max(x['seconds'] for x in summary),'warnings':warnings,'checks':checks,'raw_sha256':rawhash,'teardown':tears,'limits':['No Godot/game/test rerun performed by separate reviewer.','New audio435/338 each180,total360 differs from original single180; original135/138 rejection retained.','Original timeout partial streams NOT_CAPTURED; no claim of clean earlier output.','Original settlement two failures not reproduced; cause unresolved.204 playing gates replaced with explicitstop contract and204 true-stop positivecontrols; playing is telemetry.','Teardown proves bounded recorded Dummy internal silence/resource release only, not physical output or universal timing guarantee.','Export/PCK/native/ordinary/Windows/physical listening/campaign/CI/GitHub v38 publication not accepted by this source audit.'],'blockers':[]}
(P/'AGGREGATE_SEPARATE_REVIEW.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({k:report[k] for k in ['pass','counts','max_case_seconds']}));print('receipt sha',h(P/'AGGREGATE_SEPARATE_REVIEW.json'))
