from pathlib import Path
import json,hashlib,subprocess,os,signal,time,math,traceback,argparse,sys
Q=Path(__file__).resolve().parent;ap=argparse.ArgumentParser();ap.add_argument('--plan-sha256',required=True);approved=ap.parse_args().plan_sha256;H=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest();pp=Q/'PLAN.json';out=Q/'raw-first';assert not out.exists();out.mkdir();plan={};errors=[];points=[];helpers=[];reports=[];stdout=stderr=b'';rc=None;timeout=False;after=False;t=time.monotonic();diagnostic=False;target=False

def snap(root):
 root=Path(root);return {str(p.relative_to(root)):H(p) for p in root.rglob('*') if p.is_file() and '.godot' not in p.relative_to(root).parts}
def guard():
 assert H(pp)==approved
 for p,h in plan['pins'].items():assert H(p)==h,p
 for root,mp in plan['source_maps'].items():assert snap(root)==json.loads(Path(mp).read_text()),root
try:
 assert H(pp)==approved;plan=json.loads(pp.read_text());guard()
 for key in ['source','base']:(out/(key.upper()+'_BEFORE.json')).write_text(json.dumps(snap(plan[key]),indent=2)+'\n')
 env=dict(os.environ)
 for k,leaf in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_DATA_HOME','data'),('XDG_CACHE_HOME','cache')]:
  p=out/leaf;p.mkdir();env[k]=str(p)
 reader=out/'empty-runtime';reader.mkdir();(out/'COMMAND.json').write_text(json.dumps(plan['command'],indent=2)+'\n')
 proc=subprocess.Popen(plan['command'],cwd=reader,env=env,stdout=subprocess.PIPE,stderr=subprocess.PIPE,start_new_session=True)
 try:stdout,stderr=proc.communicate(timeout=180)
 except subprocess.TimeoutExpired:
  timeout=True
  try:os.killpg(proc.pid,signal.SIGKILL)
  except ProcessLookupError:pass
  stdout,stderr=proc.communicate()
 rc=proc.returncode
 for line in stdout.decode('utf-8',errors='strict').splitlines():
  if line.startswith('HELD_TEARDOWN_POINT '):points.append(json.loads(line.split(' ',1)[1]))
  elif line.startswith('TEST_AUDIO_TEARDOWN '):helpers.append(json.loads(line.split(' ',1)[1]))
  elif line.startswith('{'):reports.append(json.loads(line))
  elif any(x in line for x in ['HELD_TEARDOWN_POINT','TEST_AUDIO_TEARDOWN','checks','failures','{']):raise ValueError('malformed report marker')
 assert len(reports)==1 and isinstance(reports[0],dict) and type(reports[0].get('checks')) is int and reports[0]['checks']==1089 and reports[0]['failures']==[]
 source=json.loads(Path(plan['source_fire_report']).read_text());assert reports[0]['records']==source['records'] and len(reports[0]['records'])==136
 assert len(points)==7 and [x['point'] for x in points]==plan['point_names']
 prev=-1
 for i,x in enumerate(points):
  assert type(x['ticks_usec']) is int and x['ticks_usec']>=prev;prev=x['ticks_usec'];assert type(x['capture_exists']) is bool
  assert set(x)==({'point','ticks_usec','capture_exists','available','pushed','discarded'}|({'complete','pre_window_drained'} if i==6 else set()))
  assert all(type(x[k]) is int for k in ['available','pushed','discarded'])
  assert x['capture_exists']==(0<i<6)
  assert all(x[k]>=0 for k in ['available','pushed','discarded']) if x['capture_exists'] else all(x[k]==-1 for k in ['available','pushed','discarded'])
 assert len(helpers)==1 and isinstance(helpers[0],dict);h=helpers[0];rate=h['mix_rate'];assert type(rate) in (int,float) and math.isfinite(rate) and rate>0;req=math.ceil(rate*.15)
 assert h['driver']=='Dummy' and type(h['complete']) is bool and h['capture_removed'] is True and h['prepare_errors']==[] and h['requested_owner_count']==h['tracked_owner_count']==h['game_owner_count']==1 and type(h['tracked_stream_count']) is int and h['tracked_stream_count']>0
 assert isinstance(h['observations'],list) and h['observations'] and all(isinstance(x,dict) for x in h['observations'])
 for x in h['observations']:
  assert x['required_frames']==req and x['owner_count']==x['game_owner_count']==1
  assert all(type(x[k]) is int and x[k]>=0 for k in ['discarded','invalid','prepare_errors','elapsed_us','new_pushed','silent_frames'])
 assert points[-1]['complete']==h['complete'] and points[-1]['pre_window_drained']==h['pre_window_drained']
 text=(stdout+stderr).decode('utf-8',errors='strict');allowed='ERROR: Test final-owner audio teardown did not complete within its bounded contract'
 assert not any(x in text for x in ['SCRIPT ERROR','Parse Error','WARNING:','ObjectDB instances leaked','resources still in use'])
 errorlines=[line for line in text.splitlines() if 'ERROR:' in line];assert errorlines==([] if h['complete'] else [allowed])
 # Any unrelated stderr text is rejected; only the exact expected helper push_error stack is admitted diagnostically.
 if h['complete']:assert not stderr
 else:
  sl=stderr.decode().splitlines();assert sl and sl[0]==allowed
  assert all(not x.strip() or x==allowed or x.lstrip().startswith(('at: push_error (core/variant/variant_utility.cpp:','GDScript backtrace (most recent call first):','[0] finish (','[1] run (')) for x in sl)
 diagnostic=rc==0 and not timeout
 z=h['observations'][-1];target=diagnostic and h['complete'] and all(x['discarded']==x['invalid']==x['prepare_errors']==0 for x in h['observations']) and z['owners_released'] and z['streams_released'] and z['new_pushed']>=req and z['silent_frames']>=req and 150000<=z['elapsed_us']<=1000000
except Exception:errors.append(traceback.format_exc())
finally:
 (out/'stdout.raw').write_bytes(stdout);(out/'stderr.raw').write_bytes(stderr);(out/'native.exit').write_text(str(rc)+'\n' if rc is not None else 'NOT_COMPLETED\n')
 try:
  guard();after=True
  for key in ['source','base']:(out/(key.upper()+'_AFTER.json')).write_text(json.dumps(snap(plan[key]),indent=2)+'\n')
 except Exception:errors.append('AFTERGUARD '+traceback.format_exc())
 result={'diagnostic_completed':diagnostic and not errors and after,'target_pass':target and not errors and after,'native_exit':rc,'timeout':timeout,'seconds':time.monotonic()-t,'errors':errors,'pins_and_sources_unchanged':after,'points':points,'helper':helpers[0] if len(helpers)==1 else helpers,'report':reports[0] if len(reports)==1 else reports,'scope':'One original136case diagnostic, only getter/ticks telemetry around unchanged prepare/queue_free/original frame await/finish. No extraawait/drain/helperchange. Diagnostic completion does not establish targetPASS or cause; original failure retained.'};(out/'RESULT.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps({k:v for k,v in result.items() if k not in ['points','helper','report']}),flush=True)
sys.exit(0 if result['diagnostic_completed'] else 1)
