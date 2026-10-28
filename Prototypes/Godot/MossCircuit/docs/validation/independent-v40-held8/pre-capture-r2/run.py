from pathlib import Path
import json,hashlib,subprocess,os,signal,time,math,traceback,argparse,sys
Q=Path(__file__).resolve().parent
ap=argparse.ArgumentParser();ap.add_argument('--plan-sha256',required=True);approved=ap.parse_args().plan_sha256
H=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
pp=Q/'PLAN.json';out=Q/'raw-first';assert not out.exists();out.mkdir();plan={};errors=[];steps=[];after=False

def snap(root):
 root=Path(root);return {str(p.relative_to(root)):H(p) for p in root.rglob('*') if p.is_file() and '.godot' not in p.relative_to(root).parts}
def guard():
 assert H(pp)==approved
 for p,h in plan['pins'].items():assert H(p)==h,p
 for root,mp in plan['source_maps'].items():assert snap(root)==json.loads(Path(mp).read_text()),root

def validate(stdout,stderr):
 assert not stderr,'nonempty stderr'
 text=stdout.decode('utf-8',errors='strict')
 assert not any(x in text for x in ['ERROR','WARNING:','ObjectDB instances leaked','resources still in use'])
 gs=[];hs=[];rs=[]
 for line in text.splitlines():
  if line.startswith('HELD_PRE_CAPTURE_GUARD '):gs.append(json.loads(line.split(' ',1)[1]))
  elif line.startswith('TEST_AUDIO_TEARDOWN '):hs.append(json.loads(line.split(' ',1)[1]))
  elif line.startswith('{'):rs.append(json.loads(line))
  elif any(x in line for x in ['HELD_PRE_CAPTURE_GUARD','TEST_AUDIO_TEARDOWN','checks','failures','{']):raise ValueError('malformed marker')
 assert len(gs)==len(hs)==len(rs)==1 and all(isinstance(x,dict) for x in [gs[0],hs[0],rs[0]])
 g,h,r=gs[0],hs[0],rs[0]
 assert set(g)==set(plan['guard_keys'])
 assert all(g[k] is True for k in ['pass','before_current_owner_live_main_disabled','after_current_owner_live_main_disabled','capture_not_constructed_yet'])
 assert type(g['records_count']) is int and g['records_count']==136 and type(g['elapsed_us']) is int and g['elapsed_us']>=0
 for k in ['authority_before','authority_after','records_before','records_after']:assert isinstance(g[k],str) and len(g[k])==64 and all(c in '0123456789abcdef' for c in g[k])
 assert g['authority_before']==g['authority_after'] and g['records_before']==g['records_after']
 source=json.loads(Path(plan['source_fire_report']).read_text())
 assert type(r.get('checks')) is int and r['checks']==1089 and r['failures']==[] and r['records']==source['records'] and len(r['records'])==136
 rate=h['mix_rate'];assert type(rate) in (int,float) and math.isfinite(rate) and rate>0;req=math.ceil(rate*.15)
 assert h['driver']=='Dummy' and h['complete'] is True and h['capture_removed'] is True and h['prepare_errors']==[]
 assert h['requested_owner_count']==h['tracked_owner_count']==h['game_owner_count']==1 and type(h['tracked_stream_count']) is int and h['tracked_stream_count']>0
 obs=h['observations'];assert isinstance(obs,list) and obs and all(isinstance(x,dict) for x in obs)
 for x in obs:
  assert x['required_frames']==req and x['owner_count']==x['game_owner_count']==1
  assert all(type(x[k]) is int and x[k]>=0 for k in ['discarded','invalid','prepare_errors','elapsed_us','new_pushed','silent_frames'])
  assert x['discarded']==x['invalid']==x['prepare_errors']==0
 z=obs[-1];assert z['owners_released'] is True and z['streams_released'] is True and z['new_pushed']>=req and z['silent_frames']>=req and 150000<=z['elapsed_us']<=1000000
 return {'checks':1089,'records':136,'guard':g,'helper':h}
try:
 assert H(pp)==approved;plan=json.loads(pp.read_text());guard()
 for route in plan['routes']:
  d=out/route['name'];d.mkdir();env=dict(os.environ)
  for k,leaf in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_DATA_HOME','data'),('XDG_CACHE_HOME','cache')]:
   p=d/leaf;p.mkdir();env[k]=str(p)
  cwd=d/'empty-runtime';cwd.mkdir();(d/'COMMAND.json').write_text(json.dumps(route['command'],indent=2)+'\n')
  t=time.monotonic();rc=None;timeout=False;stdout=stderr=b'';detail={};err=[]
  try:
   proc=subprocess.Popen(route['command'],cwd=cwd,env=env,stdout=subprocess.PIPE,stderr=subprocess.PIPE,start_new_session=True)
   try:stdout,stderr=proc.communicate(timeout=180)
   except subprocess.TimeoutExpired:
    timeout=True
    try:os.killpg(proc.pid,signal.SIGKILL)
    except ProcessLookupError:pass
    stdout,stderr=proc.communicate()
   rc=proc.returncode;assert rc==0 and not timeout
   detail=validate(stdout,stderr)
  except Exception:err.append(traceback.format_exc())
  finally:
   (d/'stdout.raw').write_bytes(stdout);(d/'stderr.raw').write_bytes(stderr);(d/'native.exit').write_text(str(rc)+'\n')
   row={'name':route['name'],'native_exit':rc,'timeout':timeout,'seconds':time.monotonic()-t,'pass':not err,'errors':err,'detail':detail};steps.append(row);(d/'RESULT.json').write_text(json.dumps(row,indent=2)+'\n')
  if err:raise AssertionError('first failed route '+route['name'])
except Exception:errors.append(traceback.format_exc())
finally:
 try:guard();after=True
 except Exception:errors.append('AFTERGUARD '+traceback.format_exc())
 result={'pass':after and not errors and len(steps)==2 and all(x['pass'] for x in steps),'steps':steps,'errors':errors,'pins_and_sources_unchanged':after,'scope':'Fixture-only one pre-capture frame, original1089/136 source and samepacked comparison; unchanged strict helper discard0. Original packed failure and telemetry retained. No native visual acceptance.'}
 (out/'RESULT.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps({k:v for k,v in result.items() if k!='steps'}),flush=True)
sys.exit(0 if result['pass'] else 1)
