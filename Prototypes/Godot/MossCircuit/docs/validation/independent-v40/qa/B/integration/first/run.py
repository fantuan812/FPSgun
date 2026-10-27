from pathlib import Path
import argparse,hashlib,json,subprocess,os,time,traceback,shutil,math
q=Path(__file__).resolve().parent;pp=q/'PLAN.json';out=q/'raw-first';project=q/'project'
a=argparse.ArgumentParser();a.add_argument('--plan-sha256',required=True);approved=a.parse_args().plan_sha256
h=lambda f:hashlib.sha256(Path(f).read_bytes()).hexdigest()
def inventory(root):
 result={}
 for f in root.rglob('*'):
  rel=f.relative_to(root)
  if '.godot' in rel.parts:continue
  if f.is_symlink():raise ValueError('symlink '+str(f))
  if f.is_file():result[str(rel)]=h(f)
 return result
if out.exists() or project.exists():raise SystemExit('REFUSE OVERWRITE')
out.mkdir();plan={};rows=[];issues=[];error=None;source={};author=None

def guard(copy_required=True):
 assert h(pp)==approved,'plan changed'
 for name,sha in plan['pins'].items():assert h(name)==sha,'pin '+name
 assert inventory(author)==source,'author exact894 changed'
 if copy_required:assert inventory(project)==source,'copy exact894 changed'

def cleanup(x):
 try:
  obs=x['observations'];last=obs[-1];rate=x['mix_rate']
  if type(rate) not in (int,float) or not math.isfinite(rate) or rate<=0:return False
  return x['driver']=='Dummy' and x['complete'] is True and x['capture_removed'] is True and x['prepare_errors']==[] and x['requested_owner_count']==x['tracked_owner_count']==x['game_owner_count']==1 and x['tracked_stream_count']>0 and last['owner_count']==last['game_owner_count']==1 and last['owners_released'] is True and last['streams_released'] is True and last['required_frames']==math.ceil(rate*.15) and last['new_pushed']>=last['required_frames']>0 and last['silent_frames']>=last['required_frames'] and 150000<=last['elapsed_us']<=1000000 and all(v['discarded']==v['invalid']==v['prepare_errors']==0 for v in obs)
 except (KeyError,TypeError,IndexError):return False
try:
 assert h(pp)==approved,'caller plan mismatch'
 plan=json.loads(pp.read_text());source=json.loads(Path(plan['input_map']).read_text())['inputs'];author=Path(plan['source']);assert len(source)==894
 guard(False);project.mkdir()
 for n in source:
  t=project/n;t.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(author/n,t)
 guard();(out/'BEFORE.json').write_text(json.dumps(source,indent=2)+'\n')
 env=dict(os.environ)
 for k,n in [('HOME','home'),('XDG_DATA_HOME','data'),('XDG_CONFIG_HOME','config'),('XDG_CACHE_HOME','cache')]:
  p=out/n;p.mkdir();env[k]=str(p)
 for route in plan['routes']:
  folder=out/route['name'];folder.mkdir();stdout=stderr=b'';rc=None;timed=False;exception=None;reports=[];helpers=[];parse_errors=[];start=time.monotonic()
  try:
   guard();args=['--editor','--import'] if route['name']=='cold' else ['--script',route['script']]
   try:
    z=subprocess.run(['/usr/local/bin/godot','--headless','--audio-driver','Dummy','--path',str(project),*args],capture_output=True,env=env,timeout=180);stdout,stderr,rc=z.stdout,z.stderr,z.returncode
   except subprocess.TimeoutExpired as e:stdout,stderr=e.stdout or b'',e.stderr or b'';timed=True;rc=124
   for line in stdout.decode(errors='strict').splitlines():
    if line.startswith('TEST_AUDIO_TEARDOWN '):
     try:helpers.append(json.loads(line.split(' ',1)[1]))
     except Exception:parse_errors.append(traceback.format_exc())
    elif line.lstrip().startswith('{') or 'TEST_AUDIO_TEARDOWN' in line or (route.get('marker') is not None and route['marker'] in line):
     try:reports.append(json.loads(line))
     except Exception:parse_errors.append(traceback.format_exc())
   guard()
  except Exception:exception=traceback.format_exc()
  for name,data in [('stdout.raw',stdout),('stderr.raw',stderr)]: (folder/name).write_bytes(data)
  (folder/'native.exit').write_text(str(rc)+'\n' if rc is not None else 'NO_NATIVE_EXIT\n')
  tags=[x for x in [b'ERROR:',b'SCRIPT ERROR',b'WARNING:',b'Parse Error',b'ObjectDB instances leaked',b'resources still in use'] if x in stdout+stderr]
  semantic=reports==[] if route['name']=='cold' else len(reports)==1 and isinstance(reports[0],dict) and type(reports[0].get(route['marker'])) is int and reports[0][route['marker']]==route['checks'] and reports[0].get('failures')==[] and isinstance(reports[0].get('observations'),list) and len(reports[0]['observations'])==route['observations'] and all(isinstance(v,dict) for v in reports[0]['observations'])
  helper_ok=len(helpers)==route['helpers'] and all(cleanup(x) for x in helpers)
  good=rc==0 and not timed and exception is None and stderr==b'' and not tags and not parse_errors and semantic and helper_ok
  row={'name':route['name'],'pass':good,'native_exit':rc,'timeout':timed,'seconds':time.monotonic()-start,'stderr_bytes':len(stderr),'tags':[x.decode() for x in tags],'exception':exception,'parse_errors':parse_errors,'semantic':semantic,'helper_ok':helper_ok,'reports':reports,'helpers':helpers};rows.append(row);(folder/'RESULT.json').write_text(json.dumps(row,indent=2)+'\n');print(json.dumps({k:v for k,v in row.items() if k not in ['reports','helpers']}),flush=True)
  if not good:break
except Exception:error=traceback.format_exc()
finally:
 try:guard()
 except Exception:issues.append(traceback.format_exc())
 try:
  (out/'COPY_AFTER.json').write_text(json.dumps(inventory(project),indent=2)+'\n');(out/'AUTHOR_AFTER.json').write_text(json.dumps(inventory(author),indent=2)+'\n')
 except Exception:issues.append(traceback.format_exc())
 result={'pass':error is None and not issues and len(rows)==3 and all(v['pass'] for v in rows),'completed':len(rows),'exception':error,'after_issues':issues,'rows':rows,'approved_plan':approved,'scope':'Independent exactcopy cold and two controlled real-hook routes; no full/native/ordinary claim'};(out/'RESULT.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps({k:v for k,v in result.items() if k!='rows'}),flush=True)
raise SystemExit(0 if result['pass'] else 1)
