from pathlib import Path
import json,hashlib,subprocess,os,time
q=Path(__file__).parent;p=q/'PLAN.json';h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();ph=h(p);plan=json.loads(p.read_text());root=Path(plan['source']);expected=json.loads(Path(plan['input_map']).read_text())
def snap(r):return {str(f.relative_to(r)):h(f) for f in sorted(r.rglob('*')) if f.is_file() and '.godot' not in f.relative_to(r).parts}
def pins():return h(p)==ph and all(Path(f).is_file() and h(Path(f))==v for f,v in plan['pins'].items())
def originals():return all(snap(Path(r))==json.loads(Path(m).read_text()) for r,m in plan['original_maps'].items())
assert snap(root)==expected and originals() and pins() and not(root/'.godot').exists();out=q/'raw-first';assert not out.exists();out.mkdir();env=dict(os.environ)
for k,n in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_DATA_HOME','data'),('XDG_CACHE_HOME','cache')]:
 (out/n).mkdir();env[k]=str(out/n)
rows=[];unexpected=[]
try:
 for route in plan['routes']:
  name=route['name'];args=['--editor','--import'] if name=='cold' else ['--script','res://'+route['script']];t=time.monotonic();a=b=b'';rc=125;timed=False;errors=[]
  try:
   z=subprocess.run(['godot','--headless','--audio-driver','Dummy','--path',str(root),*args],env=env,capture_output=True,timeout=180);a,b,rc=z.stdout,z.stderr,z.returncode
  except subprocess.TimeoutExpired as e:a,b,rc=e.stdout or b'',e.stderr or b'',124;timed=True
  except Exception as e:errors.append(repr(e))
  (out/(name+'.stdout')).write_bytes(a);(out/(name+'.stderr')).write_bytes(b);(out/(name+'.exit')).write_text(str(rc)+'\n');reports=[];helpers=[]
  for line in a.decode(errors='replace').splitlines():
   try:
    if line.startswith('{'):reports.append(json.loads(line))
    elif line.startswith('TEST_AUDIO_TEARDOWN '):helpers.append(json.loads(line.split(' ',1)[1]))
   except ValueError as e:errors.append(repr(e))
  helper_ok=len(helpers)==route['helpers']
  for x in helpers:
   try:
    z=x['observations'][-1];helper_ok=helper_ok and x['complete'] is True and x['capture_removed'] is True and x['prepare_errors']==[] and x['requested_owner_count']==x['tracked_owner_count']==x['game_owner_count']==1 and x['tracked_stream_count']>0 and z['owners_released'] is True and z['streams_released'] is True and 150000<=z['elapsed_us']<=1000000 and z['new_pushed']>=z['required_frames']>0 and z['silent_frames']>=z['required_frames'] and all(v['invalid']==v['discarded']==v['prepare_errors']==0 and v['owner_count']==v['game_owner_count']==1 for v in x['observations'])
   except (KeyError,TypeError,IndexError):helper_ok=False
  semantic=len(reports)==0 if name=='cold' else len(reports)==1 and isinstance(reports[0],dict) and reports[0].get('checks')==route['checks'] and reports[0].get('failures')==[] and ('observations' not in route or len(reports[0].get('observations',[]))==route['observations'])
  clean=not any(s in (a+b).decode(errors='replace') for s in ['SCRIPT ERROR','Parse Error','ERROR:','instances leaked','resources still in use'])
  row={'route':name,'native_exit':rc,'seconds':time.monotonic()-t,'timeout':timed,'parse_errors':errors,'semantic':semantic,'helpers':helpers,'reports':reports,'clean':clean,'helper_ok':helper_ok};row['pass']=rc==0 and not timed and not errors and clean and helper_ok and semantic;rows.append(row);(out/'STEPS.json').write_text(json.dumps(rows,indent=2)+'\n');print(json.dumps({k:v for k,v in row.items() if k not in ['helpers','reports']}),flush=True)
  if not row['pass']:break
except Exception as e:unexpected.append(repr(e))
finally:
 post=snap(root);(out/'POST_INPUTS.json').write_text(json.dumps(post,indent=2,sort_keys=True)+'\n');result={'pass_gate':len(rows)==4 and all(x['pass'] for x in rows) and not unexpected and post==expected and originals() and pins(),'unexpected':unexpected,'source_unchanged':post==expected,'originals_unchanged':originals(),'pins_unchanged':pins(),'input_count':len(post),'scope':'Test-only exact epoch contract extension. Cold plus complete903/837 and unchanged124; combined evidence, NOT a new151/151 full run.'};(out/'RESULT.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result),flush=True)
raise SystemExit(0 if result['pass_gate'] else 1)
