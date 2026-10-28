#!/usr/bin/env python3
"""Portable finite BUILD-UI14 entry. Run from the Godot project root; not a full165 suite."""
from pathlib import Path
import argparse,hashlib,json,subprocess,os,time,traceback,sys,math,struct,tempfile,shutil
sys.dont_write_bytecode=True
from build_ui_warning_policy import classify as classify_stderr
package=Path(__file__).resolve().parents[1]
ap=argparse.ArgumentParser(description=__doc__)
ap.add_argument('--project',default='.',help='Godot source directory (default: current directory)')
ap.add_argument('--output',help='New evidence directory outside source; default: a fresh system-temp directory')
ap.add_argument('--godot',default=os.environ.get('GODOT','godot'),help='Godot executable, default GODOT or PATH godot')
ap.add_argument('--manifest-sha256',help='Optional exact manifest identity for a frozen validation run')
a=ap.parse_args();project=Path(a.project).resolve();plan_path=package/'tests/build_ui_compact/manifest.json'
def h(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def inventory(root):
 result={}
 for p in root.rglob('*'):
  rel=p.relative_to(root)
  if '.godot' in rel.parts or '.git' in rel.parts:continue
  if p.is_symlink():raise ValueError('unexpected source symlink '+str(p))
  if p.is_file():result[str(rel)]=h(p)
 return result
approved=h(plan_path)
if a.manifest_sha256 and approved!=a.manifest_sha256:raise SystemExit('Manifest identity mismatch')
plan=json.loads(plan_path.read_text());assert plan['schema_version']==1 and plan['exact_routes']==14
assert (project/'project.godot').is_file(),'Run from the project root, or pass --project'
godot_bin=shutil.which(a.godot)
if godot_bin is None:raise SystemExit('Godot not found; install Godot 4.6.3 or set GODOT')
if a.output:
 out=Path(a.output).resolve()
 if out.exists():raise SystemExit('REFUSE OVERWRITE: choose a new evidence directory')
else:out=Path(tempfile.mkdtemp(prefix='moss-build-ui-'))
if out==project or project in out.parents or out==package or package in out.parents:raise SystemExit('Evidence output must be outside the source/package')
if a.output:out.mkdir(parents=True)
rows=[];exception=None;after_issues=[];before={};after={};started=time.monotonic()
def pin_guard():
 if h(plan_path)!=approved:raise ValueError('manifest changed')
 for rel,sha in plan['fixture_pins'].items():
  if h(package/rel)!=sha:raise ValueError('portable fixture/tool changed '+rel)
 for rel,sha in plan['runtime_dependency_pins'].items():
  if h(project/rel)!=sha:raise ValueError('frozen runtime/helper dependency changed '+rel)
for route in plan['routes']:
 rel=Path(route['script']);assert not rel.is_absolute() and '..' not in rel.parts
 route['script']=str(package/rel)
plan['project']=str(project)
def helper_check(d,schema):
 if not isinstance(d,dict):return False
 n=schema['owners'];games=schema['game_owners'];rate=d.get('mix_rate')
 if type(rate) not in (int,float) or not math.isfinite(rate) or rate<=0:return False
 required=math.ceil(rate*.15);obs=d.get('observations',[])
 if not isinstance(obs,list) or not obs or not all(isinstance(o,dict) for o in obs):return False
 last=obs[-1]
 return (d.get('driver')=='Dummy' and d.get('complete') is True and d.get('capture_removed') is True and d.get('prepare_errors')==[] and d.get('requested_owner_count')==d.get('tracked_owner_count')==n and d.get('game_owner_count')==games and d.get('tracked_stream_count',0)>0 and all(o.get('invalid')==o.get('discarded')==o.get('prepare_errors')==0 and o.get('owner_count')==n and o.get('game_owner_count')==games and o.get('required_frames')==required for o in obs) and last.get('owners_released') is True and last.get('streams_released') is True and last.get('new_pushed',-1)>=required and last.get('silent_frames',-1)>=required and 150000<=last.get('elapsed_us',-1)<=1000000)
def run(route):
 folder=out/route['name'];folder.mkdir();stdout=stderr=b'';native=None;timeout=False;error=None;parse_errors=[];reports=[];helpers=[];t=time.monotonic();command=[];report_file=None
 try:
  command=[godot_bin,'--headless','--audio-driver','Dummy','--path',plan['project'],'--script',route['script']]
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
    if report_file is not None:semantic=semantic and json.loads(report_file.read_text())==report
  else:
   semantic=not reports and text.splitlines().count(marker['text'])==1
  if route.get('records_count') is not None:
   semantic=semantic and len(reports)==1 and isinstance(reports[0][1].get('records'),list) and len(reports[0][1]['records'])==route['records_count']
  if route.get('context_cases') is not None:
   semantic=semantic and [[r.get('mode'),r.get('context'),r.get('final_state')] for r in reports[0][1].get('records',[]) if isinstance(r,dict)]==route['context_cases']
  if route.get('disclosure_adapter'):
   adapter_lines=[line for line in text.splitlines() if 'DISCLOSURE_ADAPTER_OPEN' in line]
   semantic=semantic and bool(adapter_lines) and all(line in ['DISCLOSURE_ADAPTER_OPEN 3','DISCLOSURE_ADAPTER_OPEN 4'] for line in adapter_lines)
  helper_ok=len(helpers)==len(route['helper_schemas']) and all(helper_check(d,s) for d,s in zip(helpers,route['helper_schemas']))
  if route.get('mixer_pcm') and semantic:
   report=reports[0][1];windows=report['windows'];assert len(windows)==51 and report['status']=='PASS'
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
  record={'name':route['name'],'native_exit':native,'timeout':timeout,'seconds':time.monotonic()-t,'stderr_bytes':len(stderr),'stderr_policy':stderr_policy,'tags':tags,'parse_errors':parse_errors,'semantic':semantic,'helper_ok':helper_ok,'reports':[r[1] for r in reports],'helpers':helpers,'exception':error}
  record['pass']=native==0 and not timeout and stderr_policy['accepted'] and not tags and not parse_errors and semantic and helper_ok and error is None
  (folder/'RESULT.json').write_text(json.dumps(record,indent=2)+'\n');rows.append({k:v for k,v in record.items() if k not in ['reports','helpers']});(out/'STEPS.json').write_text(json.dumps(rows,indent=2)+'\n');print(json.dumps(rows[-1]),flush=True)
 if not record['pass']:raise RuntimeError('first FAIL '+route['name']+'; no further route or retry')
try:
 pin_guard();before=inventory(project);assert len(plan['routes'])==14
 (out/'BEFORE.json').write_text(json.dumps(before,indent=2)+'\n')
 (out/'EXECUTION.json').write_text(json.dumps({'project':str(project),'package':str(package),'manifest_sha256':approved,'default_project_used':a.project=='.','command':'python3 tools/run_build_ui_checks.py' if a.project=='.' else 'explicit --project','runtime_dependency_pins':len(plan['runtime_dependency_pins']),'fixture_pins':len(plan['fixture_pins']),'scope':plan['scope']},indent=2)+'\n')
 env=dict(os.environ)
 for key,leaf in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_DATA_HOME','data'),('XDG_CACHE_HOME','cache')]:
  p=out/leaf;p.mkdir();env[key]=str(p)
 for route in plan['routes']:run(route)
except Exception:exception=traceback.format_exc()
finally:
 try:
  pin_guard();after=inventory(project)
  if after!=before:after_issues.append('authored source/fixture file set or bytes changed during run')
 except Exception:after_issues.append(traceback.format_exc())
 (out/'AFTER.json').write_text(json.dumps(after,indent=2)+'\n')
 result={'pass':exception is None and not after_issues and len(rows)==14 and all(r['pass'] for r in rows),'scope':plan['scope'],'completed':len(rows),'seconds':time.monotonic()-started,'exception':exception,'after_issues':after_issues,'manifest_sha256':approved,'runtime_dependency_pin_count':len(plan['runtime_dependency_pins']),'whole_authored_source_unchanged':before==after,'source_count':len(before),'default_project_used':a.project=='.','output':str(out)}
 (out/'RESULT.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result),flush=True)
sys.exit(0 if result['pass'] else 1)
