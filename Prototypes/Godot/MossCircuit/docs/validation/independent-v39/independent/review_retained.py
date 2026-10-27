from pathlib import Path
import json,hashlib
p=Path('<WORKSPACE>/moss-v39-prep/retained-parity'); o=p/'raw-first'; h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest(); plan=json.loads((p/'PLAN.json').read_text()); steps=json.loads((o/'STEPS.json').read_text()); checks=[]
def ck(v,s):
 assert v,s
 checks.append(s)
ck(h(p/'PLAN.json')=='8baa2e40ad07bf584ed5868672c3235bbe8153646b9b72f9023e08103f73aa8a','frozen plan')
for f,v in plan['pins'].items():ck(h(Path(f))==v,'pin '+f)
for route,row in zip(plan['routes'],steps):
 n=route['name'];a=(o/(n+'.stdout')).read_bytes(); b=(o/(n+'.stderr')).read_bytes();ck((o/(n+'.exit')).read_text().strip()=='0','native '+n);ck(not b,'stderr '+n);ck(not any(x in a+b for x in [b'SCRIPT ERROR',b'ERROR:',b'instances leaked',b'resources still in use']), 'strict '+n)
 reports=[json.loads(x) for x in a.decode().splitlines() if x.startswith('{')]; hs=[json.loads(x.split(' ',1)[1]) for x in a.decode().splitlines() if x.startswith('TEST_AUDIO_TEARDOWN ')]
 ck(reports==row['reports'] and len(reports)==1 and reports[0]['cases']==route['case_count'] and reports[0]['failures']==[], 'raw semantic '+n)
 ck(hs==row['helpers'] and len(hs)==1,'raw helper '+n); x=hs[0]; z=x['observations'][-1]
 ck(x['complete'] is True and x['capture_removed'] is True and x['prepare_errors']==[] and x['requested_owner_count']==x['tracked_owner_count']==x['game_owner_count']==1 and x['tracked_stream_count']==2,'owner resources '+n)
 ck(z['owners_released'] and z['streams_released'] and z['new_pushed']>=z['required_frames']>0 and z['silent_frames']>=z['required_frames'] and 150000<=z['elapsed_us']<=1000000 and all(v['invalid']==v['discarded']==v['prepare_errors']==0 for v in x['observations']),'fresh bounded cleanup '+n)
 ck((o/(n+'.json')).read_bytes()==Path(route['retained_trace']).read_bytes() and h(o/(n+'.json'))==route['retained_sha256'],'whole held trace '+n)
 ck(row['native_exit']==0 and row['timeout'] is False and row['seconds']<=180,'recorded duration '+n)
src=json.loads(Path(plan['input_map']).read_text()); r=Path('<WORKSPACE>/moss-v39-r2'); actual={str(f.relative_to(r)):h(f) for f in r.rglob('*') if f.is_file() and '.godot' not in f.relative_to(r).parts};ck(len(src)==853 and actual==src==json.loads((o/'POST_INPUTS.json').read_text()),'actual853 full-set source')
receipt={'pass':True,'reviewer':'independent QA','checks':len(checks),'scope':plan['scope'],'method':'Original raw and full trace byte readback, no engine rerun; bounded Dummy silence is not physical listening.','results':[{k:x[k] for k in ['name','seconds','trace_sha256']} for x in steps],'evidence':{str(f):h(f) for f in o.iterdir() if f.is_file()},'checks_detail':checks}
out=Path('<WORKSPACE>/moss-v39-qa/RETAINED_PARITY_RAW_REVIEW.json');out.write_text(json.dumps(receipt,indent=2)+'\n');print(len(checks),h(out))
