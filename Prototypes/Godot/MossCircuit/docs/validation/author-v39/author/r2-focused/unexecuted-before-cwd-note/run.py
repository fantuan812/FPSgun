from pathlib import Path
import json,hashlib,subprocess,os,time
p=Path(__file__).parent;r=Path('evidence-workspace/moss-v39-r2');h=lambda f:hashlib.sha256(f.read_bytes()).hexdigest();planpath=p/'PLAN.json';planhash=h(planpath);plan=json.loads(planpath.read_text());source=json.loads(Path(plan['input_map']).read_text());pins=plan['pins']
def actual():return {str(f.relative_to(r)):h(f) for f in sorted(r.rglob('*')) if f.is_file() and '.godot' not in f.relative_to(r).parts}
assert len(source)==845 and actual()==source and not(r/'.godot').exists();assert all(h(Path(n))==v for n,v in pins.items())
out=p/'raw-first';assert not out.exists();out.mkdir();env=dict(os.environ)
for k,n in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_DATA_HOME','data'),('XDG_CACHE_HOME','cache')]:
 (out/n).mkdir();env[k]=str(out/n)
rows=[]
for route in plan['routes']:
 name=route['name'];args=['--editor','--import'] if name=='cold' else ['--script',route['script']];t=time.monotonic();timed=False
 try:z=subprocess.run(['godot','--headless','--audio-driver','Dummy','--path',str(r),*args],capture_output=True,env=env,timeout=180);a,b,rc=z.stdout,z.stderr,z.returncode
 except subprocess.TimeoutExpired as e:a,b,rc=e.stdout or b'',e.stderr or b'',124;timed=True
 (out/(name+'.stdout')).write_bytes(a);(out/(name+'.stderr')).write_bytes(b);(out/(name+'.exit')).write_text(str(rc)+'\n');reports=[];helpers=[];errors=[]
 for line in a.decode(errors='replace').splitlines():
  try:
   if line.startswith('{'):reports.append(json.loads(line))
   elif line.startswith('TEST_AUDIO_TEARDOWN '):helpers.append(json.loads(line.split(' ',1)[1]))
  except ValueError as e:errors.append(str(e))
 clean=not errors and not any(v in (a+b).decode(errors='replace') for v in ['SCRIPT ERROR','ERROR:','instances leaked','resources still in use'])
 semantic=len(reports)==0 if name=='cold' else len(reports)==1 and reports[0].get(route['key'])==route['checks'] and reports[0].get('failures')==[] and (name!='negatives' or reports[0].get('pass') is True)
 cleanup=len(helpers)==route['helpers']
 for x in helpers:
  try:
   obs=x['observations'];last=obs[-1];owners=route['owners']
   cleanup=cleanup and x['complete'] is True and x['capture_removed'] is True and x['prepare_errors']==[] and x['requested_owner_count']==x['tracked_owner_count']==x['game_owner_count']==owners and x['tracked_stream_count']>0 and last['owner_count']==last['game_owner_count']==owners and last['prepare_errors']==0 and last['owners_released'] is True and last['streams_released'] is True and last['new_pushed']>=last['required_frames']>0 and last['silent_frames']>=last['required_frames'] and 150000<=last['elapsed_us']<=1000000 and all(v['invalid']==v['discarded']==0 for v in obs)
  except(KeyError,TypeError,IndexError):cleanup=False
 row=dict(case=name,native_exit=rc,timeout=timed,seconds=time.monotonic()-t,clean=clean,semantic=semantic,helper_ok=cleanup,reports=reports,helpers=helpers,parse_errors=errors);row['pass']=rc==0 and not timed and clean and semantic and cleanup;rows.append(row);(out/'STEPS.json').write_text(json.dumps(rows,indent=2)+'\n');print(json.dumps({k:v for k,v in row.items() if k not in ['reports','helpers']}),flush=True)
 if not row['pass']:break
post=actual();changed=[n for n,v in source.items() if post.get(n)!=v];added=sorted(set(post)-set(source));pinchanged=[n for n,v in pins.items() if not Path(n).exists() or h(Path(n))!=v];oldroot=Path('evidence-workspace/moss-v39-work');oldmap=json.loads(Path(plan['original_836_map']).read_text());oldactual={str(f.relative_to(oldroot)):h(f) for f in oldroot.rglob('*') if f.is_file() and '.godot' not in f.relative_to(oldroot).parts}
result=dict(pass_gate=len(rows)==len(plan['routes']) and all(x['pass'] for x in rows) and not changed and added==plan['exact_import_additions'] and not pinchanged and h(planpath)==planhash and oldactual==oldmap,changed=changed,added=added,pinchanged=pinchanged,plan_unchanged=h(planpath)==planhash,original836_unchanged=oldactual==oldmap,input_count=len(source),scope=plan['scope'])
(out/'POST_INPUTS.json').write_text(json.dumps(post,indent=2)+'\n');(out/'RESULT.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result),flush=True);raise SystemExit(0 if result['pass_gate'] else 1)
