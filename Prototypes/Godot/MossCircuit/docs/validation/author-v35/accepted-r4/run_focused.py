from pathlib import Path
import json,hashlib,subprocess,os,time,re
r=Path('workspace/shared');src=r/'moss-v35-r4';out=r/'moss-v35-r4-prep';plan=json.load(open(r/'moss-v35-teardown-plan/FOCUSED_PLAN.json'));h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();env=os.environ.copy()
for k,v in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_DATA_HOME','data'),('XDG_CACHE_HOME','cache')]:env[k]=str(out/v)
rows=[]
def call(name,args,marker=True):
 t=time.monotonic();p=subprocess.run(['godot','--headless','--audio-driver','Dummy','--path',str(src),*args],env=env,capture_output=True,text=True,timeout=180);log=p.stdout+p.stderr;(out/(name+'.log')).write_text(log)
 success=bool(re.search(r'"failures"\s*:\s*\[\s*\]|failures=\[\]|\b0 failed\b|\b0 failures\b|^PASS:|UI_STRUCTURE_AND_INTENTS_PASS',log,re.M)) if marker else True
 teardown=[]
 for line in log.splitlines():
  if line.startswith('TEST_AUDIO_TEARDOWN '):teardown.append(json.loads(line[len('TEST_AUDIO_TEARDOWN '):]))
 row={'case':name,'exit':p.returncode,'seconds':time.monotonic()-t,'error':'ERROR:' in log,'resource_warning':'instances leaked' in log or 'resources still in use' in log,'semantic_marker':success,'teardown_observations':len(teardown)};row['pass']=p.returncode==0 and not row['error'] and not row['resource_warning'] and success and all(d['complete'] and d['capture_removed'] and d['tracked_owner_count']>0 for d in teardown);rows.append(row);(out/'FOCUSED_STEPS.json').write_text(json.dumps(rows,indent=2)+'\n');print(row,flush=True);assert row['pass'],name+' rejected, no retry'
assert not (src/'.godot').exists(),'cold import must start without cache';call('cold-import',['--editor','--import','--quit'],False)
manifest={str(p.relative_to(src)):h(p) for p in sorted(src.rglob('*')) if p.is_file() and '.godot' not in p.parts and '__pycache__' not in p.parts and p.name!='MANIFEST.json'};(src/'MANIFEST.json').write_text(json.dumps(manifest,indent=2,sort_keys=True)+'\n');inputs=dict(manifest);inputs['MANIFEST.json']=h(src/'MANIFEST.json');(out/'R4_INPUTS.json').write_text(json.dumps(inputs,indent=2,sort_keys=True)+'\n')
prod=json.load(open(r/'moss-v35-final-prep/PRODUCTION_FINAL.json'));assert all(h(src/k)==v for k,v in prod.items());(out/'R4_FREEZE.json').write_text(json.dumps({'inputs':len(inputs),'production128_exact':True,'manifest_sha256':h(src/'MANIFEST.json'),'inputs_sha256':h(out/'R4_INPUTS.json'),'status':'FROZEN_FOCUSED_PENDING'},indent=2)+'\n')
for name in plan['cases']:
 args=['--script','res://tests/'+name]
 if name.startswith('independent_feedback') or name=='independent_settlement_types.gd':args+=['--',str(out/(name+'.json'))]
 call(name,args)
changed=[k for k,v in inputs.items() if h(src/k)!=v];report={'all_pass':not changed,'steps':rows,'inputs':len(inputs),'changed':changed,'original119aggregate':'retainedFAIL116/119','scope':'Focused revised test-onlyfinal disposal; not finalaggregate/pack/physicalaudio'};(out/'R4_FOCUSED_GATE.json').write_text(json.dumps(report,indent=2)+'\n');assert not changed
