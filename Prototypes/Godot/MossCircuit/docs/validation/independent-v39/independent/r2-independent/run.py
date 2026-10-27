from pathlib import Path
import json,hashlib,subprocess,os,time,shutil
p=Path(__file__).parent;pp=p/'PLAN.json';h=lambda f:hashlib.sha256(f.read_bytes()).hexdigest();plan=json.loads(pp.read_text());ph=h(pp);source=json.loads(Path(plan['input_map']).read_text());author=Path(plan['source']);project=p/'project';out=p/'raw-first'
def actual(root):return {str(f.relative_to(root)):h(f) for f in root.rglob('*') if f.is_file() and '.godot' not in f.relative_to(root).parts}
def pins():return h(pp)==ph and all(Path(n).is_file() and h(Path(n))==v for n,v in plan['pins'].items())
assert len(source)==853 and actual(author)==source and pins();assert not project.exists() and not out.exists();project.mkdir();out.mkdir()
for n in source:
 t=project/n;t.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(author/n,t)
assert actual(project)==source;env=dict(os.environ)
for k,n in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_DATA_HOME','data'),('XDG_CACHE_HOME','cache')]:
 (out/n).mkdir();env[k]=str(out/n)
rows=[]
for route in plan['routes']:
 name=route['name'];args=['--editor','--import'] if name=='cold' else ['--script',route['script']];start=time.monotonic();timed=False
 try:z=subprocess.run(['godot','--headless','--audio-driver','Dummy','--path',str(project),*args],env=env,capture_output=True,timeout=180);a,b,rc=z.stdout,z.stderr,z.returncode
 except subprocess.TimeoutExpired as e:a,b,rc=e.stdout or b'',e.stderr or b'',124;timed=True
 (out/(name+'.stdout')).write_bytes(a);(out/(name+'.stderr')).write_bytes(b);(out/(name+'.exit')).write_text(str(rc)+'\n');reports=[];helpers=[];errors=[]
 for line in a.decode(errors='replace').splitlines():
  try:
   if line.startswith('{'):reports.append(json.loads(line))
   elif line.startswith('TEST_AUDIO_TEARDOWN '):helpers.append(json.loads(line.split(' ',1)[1]))
  except ValueError as e:errors.append(str(e))
 clean=not errors and not any(x in a+b for x in [b'ERROR:',b'SCRIPT ERROR',b'instances leaked',b'resources still in use'])
 semantic=len(reports)==0 if name=='cold' else len(reports)==1 and reports[0].get('pass') is True and reports[0].get('checks')==route['checks'] and reports[0].get('failures')==[] and len(reports[0].get('observations',[]))==route['observations']
 cleanup=len(helpers)==route['helpers']
 for x in helpers:
  try:
   obs=x['observations'];last=obs[-1];cleanup=cleanup and x['complete'] is True and x['capture_removed'] is True and x['prepare_errors']==[] and x['requested_owner_count']==x['tracked_owner_count']==x['game_owner_count']==1 and x['tracked_stream_count']>0 and last['owner_count']==last['game_owner_count']==1 and last['owners_released'] is True and last['streams_released'] is True and last['new_pushed']>=last['required_frames']>0 and last['silent_frames']>=last['required_frames'] and 150000<=last['elapsed_us']<=1000000 and all(v['discarded']==v['invalid']==v['prepare_errors']==0 for v in obs)
  except(KeyError,TypeError,IndexError):cleanup=False
 row={'name':name,'native_exit':rc,'seconds':time.monotonic()-start,'timeout':timed,'clean':clean,'semantic':semantic,'helper_ok':cleanup,'reports':reports,'helpers':helpers,'parse_errors':errors};row['pass']=rc==0 and not timed and clean and semantic and cleanup;rows.append(row);(out/'STEPS.json').write_text(json.dumps(rows,indent=2)+'\n');print(json.dumps({k:v for k,v in row.items() if k not in ['reports','helpers']}),flush=True)
 if not row['pass']:break
post=actual(project);author_post=actual(author);unchanged=post==source and author_post==source and pins();result={'pass':len(rows)==5 and all(x['pass'] for x in rows) and unchanged,'completed':len(rows),'double853_and_pins_unchanged':unchanged,'scope':plan['scope']};(out/'POST_INPUTS.json').write_text(json.dumps(post,indent=2)+'\n');(out/'RESULT.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result),flush=True);raise SystemExit(0 if result['pass'] else 1)
