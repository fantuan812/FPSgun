from pathlib import Path
import json,hashlib
q=Path('<WORKSPACE>/moss-v39-prep/final-r2');o=q/'raw-first';h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();plan=json.loads((q/'PLAN.json').read_text());rows=json.loads((o/'STEPS.json').read_text());checks=[]
def ck(x,s):
 assert x,s
 checks.append(s)
ck(h(q/'PLAN.json')=='48ee4a823e0f6b58c870314039b80825c7be971eb91405d878331cbd8525011f','approved plan');ck((q/'wrapper.exit').read_text().strip()=='0','actual wrapper exit');ck(len(rows)==4,'four routes')
for route,row in zip(plan['routes'],rows):
 n=route['name'];a=(o/(n+'.stdout')).read_text();b=(o/(n+'.stderr')).read_text();reports=[json.loads(l) for l in a.splitlines() if l.startswith('{')];hs=[json.loads(l.split(' ',1)[1]) for l in a.splitlines() if l.startswith('TEST_AUDIO_TEARDOWN ')]
 ck(row['route']==n and row['pass'] and row['native_exit']==0 and (o/(n+'.exit')).read_text().strip()=='0' and not row['timeout'] and row['seconds']<=180,'native raw '+n)
 ck(not b and not any(t in a for t in ['SCRIPT ERROR','ERROR:','Parse Error','instances leaked','resources still in use']),'strict logs '+n)
 ck(reports==row['reports'] and hs==row['helpers'],'raw JSON exact '+n)
 ck(len(reports)==(0 if n=='cold' else 1),'report count '+n)
 if n!='cold':ck(reports[0]['checks']==route['checks'] and reports[0]['failures']==[],'exact checks '+n)
 if 'observations' in route:ck(len(reports[0]['observations'])==26,'lifecycle26')
 ck(len(hs)==route['helpers'],'helper count '+n)
 for x in hs:
  z=x['observations'][-1];ck(x['complete'] and x['capture_removed'] and x['prepare_errors']==[] and x['requested_owner_count']==x['tracked_owner_count']==x['game_owner_count']==1 and x['tracked_stream_count']>0,'helper preparation '+n)
  ck(z['owners_released'] and z['streams_released'] and 150000<=z['elapsed_us']<=1000000 and z['new_pushed']>=z['required_frames']>0 and z['silent_frames']>=z['required_frames'] and all(v['invalid']==v['discarded']==v['prepare_errors']==0 and v['owner_count']==v['game_owner_count']==1 for v in x['observations']),'fresh bounded silence '+n)
for p,v in plan['pins'].items():ck(h(Path(p))==v,'pin '+p)
for r,m in [(plan['source'],plan['input_map']),*plan['original_maps'].items()]:
 root=Path(r);actual={str(f.relative_to(root)):h(f) for f in root.rglob('*') if f.is_file() and '.godot' not in f.relative_to(root).parts};ck(actual==json.loads(Path(m).read_text()),'source exact '+r)
result=json.loads((o/'RESULT.json').read_text());ck(result['pass_gate'] and result['source_unchanged'] and result['originals_unchanged'] and result['pins_unchanged'],'final guards');ck(json.loads((o/'POST_INPUTS.json').read_text())==json.loads(Path(plan['input_map']).read_text()),'no cold additions')
r={'pass':True,'separate_reviewer':True,'checks':len(checks),'routes':['cold','temper903','move837','lifecycle124'],'plan_sha256':h(q/'PLAN.json'),'source_map_sha256':h(Path(plan['input_map'])),'original_full_result':'149/151 FAIL retained, not rerun or relabeled','combined_evidence':'Original full149 passing routes with byte-identical production and unrelated tests, plus exact two-test/MANIFEST revision and this complete corrected903/837 + unchanged124 + cold pass. No new151/151 process exists.','helper_records':3,'source_files':869}
out=Path('<WORKSPACE>/moss-v39-qa/FINAL_R2_RAW_REVIEW.json');out.write_text(json.dumps(r,indent=2)+'\n');print(h(out),r)
