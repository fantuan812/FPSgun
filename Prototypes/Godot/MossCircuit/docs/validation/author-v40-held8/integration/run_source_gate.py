"""Finite held8-only cold+actual source gates; explicit QA lease and CLI plan SHA required."""
from pathlib import Path
import json,hashlib,subprocess,os,time,datetime,re,sys,math
R=Path(__file__).parent;H=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
assert len(sys.argv)==3 and sys.argv[1]=='--plan-sha256';plan_sha=sys.argv[2];assert H(R/'SOURCE_PLAN.json')==plan_sha
plan=json.loads((R/'SOURCE_PLAN.json').read_text());assert plan['status']=='FROZEN_QA_APPROVED';T=Path(plan['source']);B=Path(plan['base']);O=R/'source-gate-first';assert not O.exists(),'preserve original execution'
def snap(root):return {str(p.relative_to(root)):H(p)for p in sorted(root.rglob('*'))if p.is_file()and '.godot'not in p.relative_to(root).parts}
source_expected=json.loads((R/'CANDIDATE_927_PINS.json').read_text());base_expected=json.loads((R/'BASE_926_PINS.json').read_text());assert snap(T)==source_expected and snap(B)==base_expected and not(T/'.godot').exists();assert all(H(p)==h for p,h in plan['pins'].items())
def audio_ok(x):
 try:
  obs=x['observations'];last=obs[-1];required=last['required_frames'];mix=float(x['mix_rate'])
  if x['driver']!='Dummy' or not math.isfinite(mix) or mix<=0:return False
  exact_required=math.ceil(mix*0.15)
  return (x['complete'] is True and x['capture_removed'] is True and x['prepare_errors']==[] and x['requested_owner_count']==1 and x['tracked_owner_count']==1 and x['tracked_stream_count']>0 and x['game_owner_count']==1 and required>0 and 150000<=last['elapsed_us']<=1000000 and last['new_pushed']>=required and last['silent_frames']>=required and last['owners_released'] is True and last['streams_released'] is True and all(o['required_frames']==exact_required and o['invalid']==0 and o['discarded']==0 and o['prepare_errors']==0 and o['game_owner_count']==1 and o['owner_count']==1 for o in obs))
 except (KeyError,IndexError,TypeError):return False
O.mkdir();env=os.environ.copy()
for k,d in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_CACHE_HOME','cache'),('XDG_DATA_HOME','data')]:p=O/d;p.mkdir();env[k]=str(p)
rows=[];source_group_start=None;failed=False
for phase in plan['phases']:
 before={};after={};errors=[];started=False;rc=None;timed=False;launch_error=None;effective_timeout=None;tick=time.monotonic();utc=datetime.datetime.now(datetime.timezone.utc).isoformat();log=O/(phase['name']+'.log')
 if phase['name']!='cold_import' and source_group_start is None:source_group_start=time.monotonic()
 try:
  before=snap(T);assert before==source_expected and snap(B)==base_expected and H(R/'SOURCE_PLAN.json')==plan_sha and all(H(p)==h for p,h in plan['pins'].items())
  effective_timeout=180.0 if phase['name']=='cold_import' else 180.0-(time.monotonic()-source_group_start)
  if effective_timeout<=0:raise subprocess.TimeoutExpired(phase['command'],180)
  started=True
  with log.open('wb')as f:rc=subprocess.run(phase['command'],env=env,cwd=O,stdout=f,stderr=subprocess.STDOUT,timeout=effective_timeout).returncode
 except subprocess.TimeoutExpired:rc=124;timed=True
 except Exception as e:rc=-1;launch_error=repr(e)
 base_ok=False;pins_ok=False;plan_ok=False;text=''
 try:after=snap(T)
 except Exception as e:errors.append('source_after: '+repr(e))
 try:base_ok=snap(B)==base_expected
 except Exception as e:errors.append('base_after: '+repr(e))
 try:pins_ok=all(H(p)==h for p,h in plan['pins'].items())
 except Exception as e:errors.append('pins_after: '+repr(e))
 try:plan_ok=H(R/'SOURCE_PLAN.json')==plan_sha
 except Exception as e:errors.append('plan_after: '+repr(e))
 try:text=log.read_text(errors='replace')if log.exists()else''
 except Exception as e:errors.append('log_read: '+repr(e))
 findings=[{'line':i+1,'text':line}for i,line in enumerate(text.splitlines())if any(token in line for token in ['SCRIPT ERROR','Parse Error','ERROR:','WARNING:','ObjectDB instances leaked','resources still in use'])]
 added=sorted(set(after)-set(before));changed=sorted(k for k in before if k not in after or after[k]!=before[k]);expected_added=set(plan['cold_expected_new_sidecars'])if phase['name']=='cold_import'else set()
 budget_ok=(time.monotonic()-tick<=180.0)if phase['name']=='cold_import'else(time.monotonic()-source_group_start<=180.0)
 ok=started and rc==0 and not timed and launch_error is None and not errors and not findings and not changed and set(added)==expected_added and base_ok and pins_ok and plan_ok and budget_ok
 row={'phase':phase['name'],'command':phase['command'],'start_utc':utc,'end_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'elapsed_seconds':time.monotonic()-tick,'source_group_elapsed_seconds':time.monotonic()-source_group_start if source_group_start else None,'effective_timeout_seconds':effective_timeout,'started':started,'exit':None if timed or launch_error is not None else rc,'native_exit':None if timed or launch_error is not None else rc,'supervisor_exit':124 if timed else (125 if launch_error is not None else rc),'termination':'TIMEOUT' if timed else ('LAUNCH_ERROR' if launch_error is not None else 'EXIT'),'timeout':timed,'budget_ok':budget_ok,'launch_error':launch_error,'guards_error':errors,'strict_log_findings':findings,'changed_existing':changed,'added':added,'base926_unchanged':base_ok,'test_pins_unchanged':pins_ok,'plan_unchanged':plan_ok,'raw_stream':'original stdout/stderr merged'}
 try:
  if phase['name']=='cold_import':
   assert len(after)==935 and not(T/'art_source/legacy_held_L1_C2/rivet_gun_held.svg.import').exists()
   if ok:source_expected=after;(O/'POST_IMPORT_935_PINS.json').write_text(json.dumps(after,indent=2)+'\n')
  else:
   reports=[];teardowns=[]
   for line in text.splitlines():
    if line.startswith('TEST_AUDIO_TEARDOWN '):teardowns.append(json.loads(line[len('TEST_AUDIO_TEARDOWN '):]))
    elif line.startswith('{'):reports.append(json.loads(line))
    elif any(marker in line for marker in ['TEST_AUDIO_TEARDOWN','checks','failures']):raise ValueError('malformed bare report marker: '+line)
   assert len(reports)==1 and reports[0]['checks']==phase['expected_checks'] and reports[0]['failures']==[];assert len(teardowns)==1 and audio_ok(teardowns[0])
   report=reports[0]
   if phase['name']=='actual_geometry':assert report['poses']==4608 and report['ranges']==13824
   else:
    records=report['records'];assert len(records)==136;keys={(r['id'],r['mode'],r['slot'],r['left'],r['coincident'])for r in records};assert len(keys)==136 and sum(r['coincident']for r in records)==8
   row['checks']=report['checks'];row['helper_pass']=True;(O/(phase['name']+'-report.json')).write_text(json.dumps(report,indent=2)+'\n');(O/(phase['name']+'-teardown.json')).write_text(json.dumps(teardowns[0],indent=2)+'\n')
 except Exception as e:row['postcondition_error']=repr(e);ok=False
 row['pass']=ok;rows.append(row);(O/(phase['name']+'.exit')).write_text(json.dumps(row['native_exit'])+'\n');(O/(phase['name']+'.supervisor.exit')).write_text(str(row['supervisor_exit'])+'\n');(O/(phase['name']+'-before.json')).write_text(json.dumps(before,indent=2)+'\n');(O/(phase['name']+'-after.json')).write_text(json.dumps(after,indent=2)+'\n');(O/'RESULT.json').write_text(json.dumps({'pass':all(x['pass']for x in rows)and len(rows)==3,'completed':len(rows),'phases':rows,'scope':'new isolated held8 cold + source true socket pose and actual fire only; no PCK/native/release claim'},indent=2)+'\n')
 if not ok:failed=True;break
raise SystemExit(1 if failed else 0)
