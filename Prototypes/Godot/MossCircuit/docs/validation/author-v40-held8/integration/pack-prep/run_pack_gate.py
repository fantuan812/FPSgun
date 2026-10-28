"""Held8 finite PCK gate, QA lease required; source935/base926 never edited."""
from pathlib import Path
import json,hashlib,os,sys,subprocess,time,datetime,math,re
Q=Path(__file__).parent;R=Q.parent;H=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
assert len(sys.argv)==3 and sys.argv[1]=='--plan-sha256';plan_sha=sys.argv[2];assert H(Q/'PLAN.json')==plan_sha
plan=json.loads((Q/'PLAN.json').read_text());assert plan['status']=='FROZEN_QA_APPROVED';T=Path(plan['source']);B=Path(plan['base']);O=Path(plan['output']);assert not O.exists()
def snap(root):return {str(p.relative_to(root)):H(p)for p in sorted(root.rglob('*'))if p.is_file()and '.godot'not in p.relative_to(root).parts}
def audio_ok(x):
 try:
  if type(x['mix_rate'])not in (int,float):return False
  mix=float(x['mix_rate']);obs=x['observations'];last=obs[-1]
  if x['driver']!='Dummy' or not math.isfinite(mix) or mix<=0:return False
  required=math.ceil(mix*.15)
  return (x['complete']is True and x['capture_removed']is True and x['prepare_errors']==[] and x['requested_owner_count']==1 and x['tracked_owner_count']==1 and x['tracked_stream_count']>0 and x['game_owner_count']==1 and required>0 and 150000<=last['elapsed_us']<=1000000 and last['new_pushed']>=required and last['silent_frames']>=required and last['owners_released']is True and last['streams_released']is True and all(o['required_frames']==required and o['invalid']==0 and o['discarded']==0 and o['prepare_errors']==0 and o['game_owner_count']==1 and o['owner_count']==1 for o in obs))
 except (KeyError,IndexError,TypeError,ValueError):return False
expected=json.loads(Path(plan['source_map']).read_text());base=json.loads((R/'BASE_926_PINS.json').read_text());assert len(expected)==935 and snap(T)==expected and snap(B)==base;assert all(H(p)==h for p,h in plan['pins'].items());assert json.loads((R/'source-gate-first/RESULT.json').read_text())['pass']is True
review=json.loads(Path(plan['source_raw_independent_receipt']).read_text());assert review['review_pass']is True and review['checks']==220 and review['source935_and_base926_unchanged']is True and review['result_sha256']==H(R/'source-gate-first/RESULT.json') and review['source_plan_sha256']==H(R/'SOURCE_PLAN.json')
assert [x['name']for x in plan['phases']]==['engine-version','python-safety','linux-pack','windows-pack','actual-pck-enumeration','source-fingerprint','packed-resources','actual_geometry','actual_fire']
O.mkdir();env=os.environ.copy()
for key in list(env):
 if key=='GODOT_SCRIPT_ENCRYPTION_KEY' or key.startswith('GODOT_WINDOWS_CODESIGN_'):env.pop(key)
for k,d in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_CACHE_HOME','cache'),('XDG_DATA_HOME','data')]:p=O/d;p.mkdir();env[k]=str(p)
for d in ['linux','windows','empty-runtime']:(O/d).mkdir()
rows=[];pck_hash=None;windows_ready=False;resource_start=time.monotonic();held_start=None;failed=False
for phase in plan['phases']:
 name=phase['name'];held=name in ['actual_geometry','actual_fire']
 if held and held_start is None:held_start=time.monotonic()
 before={};after={};guards=[];rc=None;started=False;timed=False;launch_error=None;effective=None;tick=time.monotonic();utc=datetime.datetime.now(datetime.timezone.utc).isoformat();log=O/(name+'.log')
 try:
  before=snap(T);assert before==expected and snap(B)==base and H(Q/'PLAN.json')==plan_sha and all(H(p)==h for p,h in plan['pins'].items());assert not any((O/'empty-runtime').iterdir())
  if pck_hash:assert H(O/'linux/MossCircuit.pck')==pck_hash
  if windows_ready:assert H(O/'windows/MossCircuit.pck')==pck_hash
  effective=(180-(time.monotonic()-held_start))if held else(240-(time.monotonic()-resource_start))
  if effective<=0:raise subprocess.TimeoutExpired(phase['command'],180 if held else 240)
  started=True
  with log.open('wb')as f:rc=subprocess.run(phase['command'],env=env,cwd=O/'empty-runtime',stdout=f,stderr=subprocess.STDOUT,timeout=effective).returncode
 except subprocess.TimeoutExpired:timed=True
 except Exception as e:launch_error=repr(e)
 base_ok=False;pins_ok=False;plan_ok=False;text=''
 try:after=snap(T)
 except Exception as e:guards.append('source_after: '+repr(e))
 try:base_ok=snap(B)==base
 except Exception as e:guards.append('base_after: '+repr(e))
 try:pins_ok=all(H(p)==h for p,h in plan['pins'].items())
 except Exception as e:guards.append('pins_after: '+repr(e))
 try:plan_ok=H(Q/'PLAN.json')==plan_sha
 except Exception as e:guards.append('plan_after: '+repr(e))
 try:text=log.read_text(errors='replace')if log.exists()else''
 except Exception as e:guards.append('log_read: '+repr(e))
 findings=[{'line':i+1,'text':line}for i,line in enumerate(text.splitlines())if any(t in line for t in ['SCRIPT ERROR','Parse Error','ERROR:','WARNING:','ObjectDB instances leaked','resources still in use'])]
 budget_ok=(time.monotonic()-held_start<=180)if held else(time.monotonic()-resource_start<=240)
 ok=started and rc==0 and not timed and launch_error is None and not guards and not findings and after==expected and base_ok and pins_ok and plan_ok and budget_ok
 row={'phase':name,'command':phase['command'],'start_utc':utc,'end_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'elapsed_seconds':time.monotonic()-tick,'effective_timeout_seconds':effective,'group_elapsed_seconds':time.monotonic()-(held_start if held else resource_start),'process_exit':rc,'native_exit':rc,'supervisor_exit':124 if timed else(125 if launch_error else rc),'termination':'TIMEOUT'if timed else('LAUNCH_ERROR'if launch_error else'EXIT'),'timeout':timed,'budget_ok':budget_ok,'launch_error':launch_error,'guards_error':guards,'strict_log_findings':findings,'source935_unchanged':after==expected,'base926_unchanged':base_ok,'test_pins_unchanged':pins_ok,'plan_unchanged':plan_ok,'raw_stream':'original stdout/stderr merged'}
 try:
  if name=='engine-version':assert text.strip().startswith('4.6.3.stable.')
  if name=='python-safety':assert re.search(r'^Ran 3 tests in [0-9.]+s$',text,re.M)and re.search(r'^OK$',text,re.M)
  if name=='linux-pack':pck_hash=H(O/'linux/MossCircuit.pck')
  if name=='windows-pack':assert H(O/'windows/MossCircuit.pck')==pck_hash;windows_ready=True
  if name=='actual-pck-enumeration':
   d=json.loads((O/'PCK_INVENTORY.json').read_text());assert d['pass']is True and d['errors']==[] and d['count']==273 and d['pack_sha256']==pck_hash
  if name=='source-fingerprint':
   d=json.loads((O/'source-imported-fingerprints.json').read_text());assert d['schema_version']==2 and len(d['exact_files'])==84 and len(d['images'])==72 and len(d['actions'])==28
  if name=='packed-resources':
   d=json.loads((O/'packed-resource-report.json').read_text());assert d['checks']==998 and d['failures']==[] and d['exact_files']==84 and d['images']==72 and d['actions']==28 and d['action_frames']==308
  if held:
   reports=[];teardowns=[]
   for line in text.splitlines():
    if line.startswith('TEST_AUDIO_TEARDOWN '):teardowns.append(json.loads(line[len('TEST_AUDIO_TEARDOWN '):]))
    elif line.startswith('{'):reports.append(json.loads(line))
    elif any(marker in line for marker in ['TEST_AUDIO_TEARDOWN','checks','failures']):raise ValueError('malformed bare marker '+line)
   assert len(reports)==1 and reports[0]['failures']==[];assert len(teardowns)==1 and audio_ok(teardowns[0]);d=reports[0]
   if name=='actual_geometry':assert d['checks']==23090 and d['poses']==4608 and d['ranges']==13824
   else:
    source=json.loads((R/'source-gate-first/actual_fire-report.json').read_text());assert d['checks']==1089 and len(d['records'])==136 and d['records']==source['records']
   row['checks']=d['checks'];row['helper_pass']=True;(O/(name+'-report.json')).write_text(json.dumps(d,indent=2)+'\n');(O/(name+'-teardown.json')).write_text(json.dumps(teardowns[0],indent=2)+'\n')
  if pck_hash:assert H(O/'linux/MossCircuit.pck')==pck_hash
  if windows_ready:assert H(O/'windows/MossCircuit.pck')==pck_hash
 except Exception as e:row['postcondition_error']=repr(e);ok=False
 if time.monotonic()-(held_start if held else resource_start)>(180 if held else 240):row['budget_ok']=False;row['group_budget_timeout']=True;ok=False
 row['pass']=ok;rows.append(row);(O/(name+'.exit')).write_text(json.dumps(rc)+'\n');(O/(name+'.supervisor.exit')).write_text(str(row['supervisor_exit'])+'\n');(O/(name+'-before.json')).write_text(json.dumps(before,indent=2)+'\n');(O/(name+'-after.json')).write_text(json.dumps(after,indent=2)+'\n');(O/'RESULT.json').write_text(json.dumps({'pass':all(x['pass']for x in rows)and len(rows)==9,'completed':len(rows),'pck_sha256':pck_hash,'phases':rows,'scope':plan['scope']},indent=2)+'\n')
 if not ok:failed=True;break
raise SystemExit(1 if failed else 0)
