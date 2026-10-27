"""B source-only authorized remaining129 continuation; original36-stop FAIL remains separate."""
from pathlib import Path
import argparse,hashlib,json,subprocess,os,time,traceback,sys,math,struct
from warning_policy import classify as classify_stderr
from report_policy import classify as classify_report
q=Path(__file__).resolve().parent
ap=argparse.ArgumentParser();ap.add_argument('--plan-sha256',required=True);approved=ap.parse_args().plan_sha256
plan_path=q/'PLAN.json';out=q/'raw-first'
def h(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def inventory(root):
 result={}
 for p in root.rglob('*'):
  rel=p.relative_to(root)
  if '.godot' in rel.parts:continue
  if p.is_symlink():raise ValueError('unexpected symlink '+str(p))
  if p.is_file():result[str(rel)]=h(p)
 return result
if out.exists():raise SystemExit('REFUSE OVERWRITE')
out.mkdir();plan={};rows=[];exception=None;after_issues=[];before={};after={};started=time.monotonic()
def pin_guard():
 if h(plan_path)!=approved:raise ValueError('PLAN changed')
 for path,sha in plan['pins'].items():
  if h(path)!=sha:raise ValueError('pin changed '+path)
def helper_check(d,schema):
 if not isinstance(d,dict):return False
 n=schema['owners'];games=schema['game_owners'];rate=d.get('mix_rate')
 if type(rate) not in (int,float) or not math.isfinite(rate) or rate<=0:return False
 required=math.ceil(rate*.15);obs=d.get('observations',[])
 if not isinstance(obs,list) or not obs or not all(isinstance(o,dict) for o in obs):return False
 last=obs[-1]
 return (d.get('driver')=='Dummy' and d.get('complete') is True and d.get('capture_removed') is True and d.get('prepare_errors')==[] and d.get('requested_owner_count')==d.get('tracked_owner_count')==n and d.get('game_owner_count')==games and d.get('tracked_stream_count',0)>0 and all(o.get('invalid')==o.get('discarded')==o.get('prepare_errors')==0 and o.get('owner_count')==n and o.get('game_owner_count')==games and o.get('required_frames')==required for o in obs) and last.get('owners_released') is True and last.get('streams_released') is True and last.get('new_pushed',-1)>=required and last.get('silent_frames',-1)>=required and 150000<=last.get('elapsed_us',-1)<=1000000)
def run(route):
 folder=out/route['name'];folder.mkdir();stdout=stderr=b'';native=None;timeout=False;error=None;parse_errors=[];reports=[];helpers=[];t=time.monotonic();command=[];report_file=None;full_report=None;file_report_validation=None
 try:
  command=['/usr/local/bin/godot','--headless','--audio-driver','Dummy','--path',plan['project'],'--script',route['script']]
  args=[]
  if route.get('expected_file'):args.append(route['expected_file'])
  if route.get('write_report'):
   report_file=folder/'report.json';args.append(str(report_file))
  if route.get('mixer_pcm'):
   pcm=folder/'pcm';pcm.mkdir();args.append(str(pcm))
  if args:command+=['--',*args]
  (folder/'COMMAND.json').write_text(json.dumps(command,indent=2)+'\n')
  try:
   completed=subprocess.run(command,env=env,capture_output=True,timeout=180,cwd=folder);stdout,stderr,native=completed.stdout,completed.stderr,completed.returncode
  except subprocess.TimeoutExpired as e:stdout,stderr=e.stdout or b'',e.stderr or b'';timeout=True
  text=stdout.decode('utf-8',errors='strict')
  for line in text.splitlines():
   if line.startswith('TEST_AUDIO_TEARDOWN '):
    try:helpers.append(json.loads(line.split(' ',1)[1]))
    except Exception as e:parse_errors.append('helper JSON '+repr(e))
   elif '{' in line and not line.startswith('Godot Engine'):
    # Every apparent report must parse; malformed marker cannot be ignored in favor of a later good one.
    prefix=line[:line.index('{')]
    try:reports.append((prefix,json.loads(line[line.index('{'):])))
    except Exception as e:parse_errors.append('report JSON '+repr(e))
   elif 'TEST_AUDIO_TEARDOWN' in line:
    parse_errors.append('malformed apparent helper line '+line[:120])
   elif route['marker']['kind']=='json':
    prefix=route['marker']['prefix']
    if (prefix and line.startswith(prefix)) or any(k in line for k in route['marker']['counts']) or line.lstrip().startswith(('\"','[',']','}')):parse_errors.append('malformed apparent report line '+line[:120])
  marker=route['marker'];semantic=False
  if marker['kind']=='json':
   if len(reports)==1:
    prefix,report=reports[0]
    semantic=prefix==marker['prefix'] and isinstance(report,dict) and report.get('failures')==[] and all(type(report.get(k)) is int and report[k]==v for k,v in marker['counts'].items())
    if 'observations' in route:
     observed=report.get('observations')
     semantic=semantic and isinstance(observed,list) and all(isinstance(o,dict) for o in observed) and len(observed)==route['observations']
    if report_file is not None:
     full_report=json.loads(report_file.read_text())
     file_report_validation=classify_report(report,full_report,route['report_policy'])
     semantic=semantic and file_report_validation['accepted']
  else:
   semantic=not reports and text.splitlines().count(marker['text'])==1
  helper_ok=len(helpers)==len(route['helper_schemas']) and all(helper_check(d,s) for d,s in zip(helpers,route['helper_schemas']))
  if route.get('mixer_pcm') and semantic:
   report=full_report;windows=report['windows'];assert len(windows)==51 and report['status']=='PASS'
   for w in windows:assert w['discarded_before']==w['discarded_after']==0 and w['nonfinite']==0 and w['fresh_pushed_frames']>=2048 and w['frames']>=2048 and w['pushed_after']-w['pushed_before']==w['fresh_pushed_frames']
   pcm_files=sorted((folder/'pcm').glob('*.f32le'));assert len(pcm_files)==7
   for f in pcm_files:
    data=f.read_bytes();matching=[w for w in windows if w.get('raw_file')==f.name];assert len(matching)==1
    w=matching[0];assert h(f)==w['pcm_f32le_stereo_sha256'] and len(data)==w['frames']*8
    samples=struct.unpack('<'+'f'*(len(data)//4),data);assert all(math.isfinite(v) for v in samples)
    assert abs(max(abs(v) for v in samples)-w['peak'])<1e-6 and abs(math.sqrt(sum(v*v for v in samples)/len(samples))-w['rms'])<1e-6
 except Exception:error=traceback.format_exc();semantic=False;helper_ok=False
 finally:
  (folder/'stdout.raw').write_bytes(stdout);(folder/'stderr.raw').write_bytes(stderr);(folder/'native.exit').write_text(('TIMEOUT' if timeout else 'NOT_COMPLETED')+'\n' if native is None else str(native)+'\n')
  stderr_policy=classify_stderr(stderr,route.get('stderr_policy'))
  text=(stdout+(b'' if stderr_policy['accepted'] else stderr)).decode(errors='replace');tags=[x for x in ['SCRIPT ERROR','ERROR:','Parse Error','WARNING:','ObjectDB instances leaked','resources still in use'] if x in text]
  record={'name':route['name'],'native_exit':native,'timeout':timeout,'seconds':time.monotonic()-t,'stderr_bytes':len(stderr),'stderr_policy':stderr_policy,'tags':tags,'parse_errors':parse_errors,'semantic':semantic,'file_report_validation':file_report_validation,'helper_ok':helper_ok,'reports':[r[1] for r in reports],'helpers':helpers,'exception':error}
  record['pass']=native==0 and not timeout and stderr_policy['accepted'] and not tags and not parse_errors and semantic and helper_ok and error is None
  (folder/'RESULT.json').write_text(json.dumps(record,indent=2)+'\n');rows.append({k:v for k,v in record.items() if k not in ['reports','helpers']});(out/'STEPS.json').write_text(json.dumps(rows,indent=2)+'\n');print(json.dumps(rows[-1]),flush=True)
 if not record['pass']:raise RuntimeError('first FAIL '+route['name']+'; no further route or retry')
try:
 if h(plan_path)!=approved:raise ValueError('caller PLAN mismatch')
 plan=json.loads(plan_path.read_text());pin_guard()
 for prerequisite in plan['preconditions']:
  receipt=json.loads(Path(prerequisite['path']).read_text());assert receipt.get(prerequisite['pass_key']) is True
 project=Path(plan['project']);before=inventory(project)
 assert before==plan['inputs'];assert len(plan['routes'])==129
 (out/'BEFORE.json').write_text(json.dumps(before,indent=2)+'\n')
 env=dict(os.environ)
 for key,leaf in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_DATA_HOME','data'),('XDG_CACHE_HOME','cache')]:
  p=out/leaf;p.mkdir();env[key]=str(p)
 for route in plan['routes']:run(route)
except Exception:exception=traceback.format_exc()
finally:
 try:
  pin_guard();after=inventory(Path(plan['project']))
  if after!=plan['inputs']:after_issues.append('full authored file set/hash changed')
 except Exception:after_issues.append(traceback.format_exc())
 (out/'AFTER.json').write_text(json.dumps(after,indent=2)+'\n')
 result={'pass':exception is None and not after_issues and len(rows)==129 and all(r['pass'] for r in rows),'scope':'remaining129 source continuation only; combine independently accepted first35 and original435, never claim a new single165 run; excludes cold/PCK/native/ordinary','completed':len(rows),'seconds':time.monotonic()-started,'exception':exception,'after_issues':after_issues,'approved_plan':approved}
 (out/'RESULT.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result),flush=True)
sys.exit(0 if result['pass'] else 1)
