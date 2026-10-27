from pathlib import Path
import json,hashlib,subprocess,os,time
q=Path(__file__).parent;p=q/'PLAN.json';h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();ph=h(p);plan=json.loads(p.read_text());root=Path(plan['source']);old=Path(plan['r3_source']);expected=json.loads(Path(plan['input_map']).read_text());oldmap=json.loads(Path(plan['r3_map']).read_text())
def snap(r):return {str(f.relative_to(r)):h(f) for f in sorted(r.rglob('*')) if f.is_file() and '.godot' not in f.relative_to(r).parts}
def pins():return h(p)==ph and all(Path(f).is_file() and h(Path(f))==v for f,v in plan['pins'].items())
assert snap(root)==expected and snap(old)==oldmap and pins();out=q/'raw-first';assert not out.exists();out.mkdir();env=dict(os.environ)
for k,n in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_DATA_HOME','data'),('XDG_CACHE_HOME','cache')]:
 (out/n).mkdir();env[k]=str(out/n)
rows=[]
for name in ['move','temper']:
 t=time.monotonic();a=b=b'';rc=125;timed=False;errors=[]
 try:
  z=subprocess.run(['godot','--headless','--audio-driver','Dummy','--path',str(root),'--script',str(q/(name+'.gd'))],env=env,capture_output=True,timeout=180);a,b,rc=z.stdout,z.stderr,z.returncode
 except subprocess.TimeoutExpired as e:a,b,rc=e.stdout or b'',e.stderr or b'',124;timed=True
 except Exception as e:errors.append(repr(e))
 (out/(name+'.stdout')).write_bytes(a);(out/(name+'.stderr')).write_bytes(b);(out/(name+'.exit')).write_text(str(rc)+'\n');reports=[];helpers=[]
 for line in a.decode(errors='replace').splitlines():
  try:
   if line.startswith('AUTHORITY_DELTA '):reports.append(json.loads(line.split(' ',1)[1]))
   elif line.startswith('TEST_AUDIO_TEARDOWN '):helpers.append(json.loads(line.split(' ',1)[1]))
  except ValueError as e:errors.append(repr(e))
 helper_ok=len(helpers)==1
 for x in helpers:
  try:
   z=x['observations'][-1];helper_ok=helper_ok and x['complete'] and x['capture_removed'] and x['prepare_errors']==[] and x['requested_owner_count']==x['tracked_owner_count']==x['game_owner_count']==1 and x['tracked_stream_count']>0 and z['owners_released'] and z['streams_released'] and 150000<=z['elapsed_us']<=1000000 and z['new_pushed']>=z['required_frames']>0 and z['silent_frames']>=z['required_frames'] and all(v['invalid']==v['discarded']==v['prepare_errors']==0 for v in x['observations'])
  except (KeyError,TypeError,IndexError):helper_ok=False
 observation_ok=len(reports)==1 and isinstance(reports[0],dict) and isinstance(reports[0].get('observations'),list) and len(reports[0]['observations'])==2 and all(isinstance(x,dict) for x in reports[0]['observations']) and [x.get('mode') for x in reports[0]['observations']]==['arena','rooms'] and all(x.get('action')==name and x.get('accepted') is True for x in reports[0]['observations'])
 clean=not any(s in (a+b).decode(errors='replace') for s in ['SCRIPT ERROR','Parse Error','ERROR:','instances leaked','resources still in use'])
 row={'route':name,'exit':rc,'seconds':time.monotonic()-t,'timeout':timed,'parse_errors':errors,'observations_ok':observation_ok,'helpers':helpers,'reports':reports,'clean':clean,'helper_ok':helper_ok};row['diagnostic_completed']=rc==0 and not timed and not errors and clean and helper_ok and observation_ok;rows.append(row);(out/'STEPS.json').write_text(json.dumps(rows,indent=2)+'\n')
 if not row['diagnostic_completed']:break
post=snap(root);(out/'POST_INPUTS.json').write_text(json.dumps(post,indent=2,sort_keys=True)+'\n');result={'diagnostic_completed':len(rows)==2 and all(x['diagnostic_completed'] for x in rows) and post==expected and snap(old)==oldmap and pins(),'source_unchanged':post==expected,'r3_unchanged':snap(old)==oldmap,'pins_unchanged':pins(),'scope':'Diagnostic completion only, not prior failing assertions passing or fixture/prod attribution; 4 controlled representative deltas.'};(out/'RESULT.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result),flush=True);raise SystemExit(0 if result['diagnostic_completed'] else 1)
