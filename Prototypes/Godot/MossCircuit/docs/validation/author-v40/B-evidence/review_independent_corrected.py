from pathlib import Path
import json,hashlib,math
q=Path('evidence-workspace/moss-v39-B-qa/integration/corrected');raw=q/'raw-first';plan=json.loads((q/'PLAN.json').read_text());h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();expected=json.loads(Path(plan['input_map']).read_text())['inputs'];checks=[];receipts=[]
def ck(ok,label):
 checks.append({'check':label,'pass':bool(ok)})
for route in plan['routes']:
 d=raw/route['name'];a=(d/'stdout.raw').read_bytes();b=(d/'stderr.raw').read_bytes();ck((d/'native.exit').read_text().strip()=='0',route['name']+' native0');ck(not b,route['name']+' stderr empty');ck(not any(t in a+b for t in [b'SCRIPT ERROR',b'ERROR:',b'WARNING:',b'Parse Error',b'instances leaked',b'resources still in use']),route['name']+' strict raw')
 reports=[];helpers=[]
 for line in a.decode().splitlines():
  if line.startswith('TEST_AUDIO_TEARDOWN '):helpers.append(json.loads(line.split(' ',1)[1]))
  elif line.lstrip().startswith('{'):reports.append(json.loads(line))
 ck(len(reports)==1 and reports[0].get(route['marker'])==route['checks'] and reports[0].get('failures')==[],route['name']+' exact report');ck(len(reports[0]['observations'])==route['observations'],route['name']+' observations');ck(len(helpers)==1,route['name']+' helper1')
 x=helpers[0];obs=x['observations'];last=obs[-1]
 ck(x['complete'] is True and x['capture_removed'] is True and x['prepare_errors']==[] and x['requested_owner_count']==x['tracked_owner_count']==x['game_owner_count']==1 and x['tracked_stream_count']>0 and x['driver']=='Dummy',route['name']+' helper ownership')
 ck(all(v['invalid']==v['discarded']==v['prepare_errors']==0 for v in obs),route['name']+' all observations clean')
 ck(last['owner_count']==last['game_owner_count']==1 and last['owners_released'] is True and last['streams_released'] is True and last['required_frames']==math.ceil(x['mix_rate']*.15) and last['new_pushed']>=last['required_frames']>0 and last['silent_frames']>=last['required_frames'] and 150000<=last['elapsed_us']<=1000000,route['name']+' fresh silence final release')
 receipts.append({'name':route['name'],'stdout_sha256':h(d/'stdout.raw'),'stderr_sha256':h(d/'stderr.raw'),'count':route['checks'],'observations':route['observations']})
for name,path in [('author',Path(plan['source'])),('copy',Path('evidence-workspace/moss-v39-B-qa/integration/first/project'))]:
 actual={str(p.relative_to(path)):h(p) for p in path.rglob('*') if p.is_file() and '.godot' not in p.relative_to(path).parts};ck(actual==expected,name+' full live894')
for name in ['BEFORE.json','AUTHOR_AFTER.json','COPY_AFTER.json']:ck(json.loads((raw/name).read_text())==expected,name+' expected894')
ck(all(h(Path(k))==v for k,v in plan['pins'].items()),'all execution pins still match')
result={'review_pass':all(x['pass'] for x in checks),'checks':checks,'routes':receipts,'scope':'Independent corrected126/62 controlled real hooks raw readback; not full/native/ordinary or visual acceptance; original failures retained'}
p=Path('evidence-workspace/moss-v39-items/B-evidence/INDEPENDENT_CORRECTED_188_RAW_REVIEW.json');p.write_text(json.dumps(result,indent=2)+'\n');print(json.dumps({'pass':result['review_pass'],'checks':len(checks),'sha256':h(p),'failed':[x for x in checks if not x['pass']]}))
