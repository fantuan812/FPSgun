"""Finite resource-only gate. Requires explicit QA lease and exact frozen plan CLI pin."""
from pathlib import Path
import sys,os,json,hashlib,subprocess,datetime,time,re
Q=Path(__file__).parent;R=Q.parent
H=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
assert len(sys.argv)==3 and sys.argv[1]=='--plan-sha256';plan_sha=sys.argv[2];assert H(Q/'PLAN.json')==plan_sha
plan=json.loads((Q/'PLAN.json').read_text());assert plan['status']=='FROZEN_QA_APPROVED';T=Path(plan['source']);B=Path(plan['base']);O=Path(plan['output']);assert not O.exists()
def snap(root):return {str(p.relative_to(root)):H(p)for p in sorted(root.rglob('*'))if p.is_file()and '.godot'not in p.relative_to(root).parts}
assert [x['name'] for x in plan['phases']]==['actual-pck-enumeration','source-fingerprint','packed-resources','actual_UI21_packed_identity']
expected=json.loads(Path(plan['source_input_map']).read_text());base=json.loads((R/'BASE_PINS.json').read_text());assert snap(T)==expected and snap(B)==base;assert all(H(p)==h for p,h in plan['pins'].items());assert json.loads((R/'cold-gate/RESULT.json').read_text())['pass'] is True
pack_linux=Path(plan['existing_linux_pck']);pack_windows=Path(plan['existing_windows_pck']);assert H(pack_linux)==H(pack_windows)==plan['existing_pck_sha256']
O.mkdir();env=os.environ.copy()
for k,d in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_CACHE_HOME','cache'),('XDG_DATA_HOME','data')]:p=O/d;p.mkdir();env[k]=str(p)
for key in list(env):
 if key=='GODOT_SCRIPT_ENCRYPTION_KEY' or key.startswith('GODOT_WINDOWS_CODESIGN_'):env.pop(key)
for folder in ['empty-runtime']:(O/folder).mkdir()
rows=[];pck_hash=plan['existing_pck_sha256'];windows_ready=True;failed=False;resource_start=time.monotonic()
for phase in plan['phases']:
 guard_errors=[];before={};rc=None;launch_error=None;timed=False;started=False;effective_timeout=None;tick=time.monotonic();start=datetime.datetime.now(datetime.timezone.utc).isoformat();log=O/(phase['name']+'.log')
 try:
  before=snap(T);assert before==expected and snap(B)==base and H(Q/'PLAN.json')==plan_sha and all(H(p)==h for p,h in plan['pins'].items());assert not any((O/'empty-runtime').iterdir())
  if pck_hash is not None:assert H(pack_linux)==pck_hash
  if windows_ready:assert H(pack_windows)==pck_hash
  remaining=180.0-(time.monotonic()-resource_start) if phase['name']!='actual_UI21_packed_identity' else 90.0
  effective_timeout=min(float(phase['timeout_seconds']),remaining)
  if effective_timeout<=0:raise subprocess.TimeoutExpired(phase['command'],180)
  started=True
  with log.open('wb')as f:rc=subprocess.run(phase['command'],env=env,cwd=O/'empty-runtime',stdout=f,stderr=subprocess.STDOUT,timeout=effective_timeout).returncode
 except subprocess.TimeoutExpired:rc=124;timed=True
 except Exception as e:rc=-1;launch_error=repr(e)
 after={};base_ok=False;pins_ok=False;plan_ok=False;text=''
 try:after=snap(T)
 except Exception as e:guard_errors.append('source_after: '+repr(e))
 try:base_ok=snap(B)==base
 except Exception as e:guard_errors.append('base_after: '+repr(e))
 try:pins_ok=all(H(p)==h for p,h in plan['pins'].items())
 except Exception as e:guard_errors.append('test_pins_after: '+repr(e))
 try:plan_ok=H(Q/'PLAN.json')==plan_sha
 except Exception as e:guard_errors.append('plan_after: '+repr(e))
 try:text=log.read_text(errors='replace') if log.exists() else ''
 except Exception as e:guard_errors.append('log_read: '+repr(e))
 findings=[{'line':i+1,'text':line}for i,line in enumerate(text.splitlines())if re.search(r'ERROR|WARNING|SCRIPT ERROR|Parse Error|leaked|Orphan',line,re.I)]
 ok=started and rc==0 and not timed and launch_error is None and not findings and not guard_errors and after==expected and base_ok and pins_ok and plan_ok
 row={'phase':phase['name'],'command':phase['command'],'start_utc':start,'end_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'elapsed_seconds':time.monotonic()-tick,'started':started,'effective_timeout_seconds':effective_timeout,'resource_group_elapsed_seconds':time.monotonic()-resource_start if phase['name']!='actual_UI21_packed_identity' else None,'exit':rc,'timeout':timed,'launch_error':launch_error,'guards_error':guard_errors,'strict_log_findings':findings,'source_888_unchanged':after==expected,'base_869_unchanged':base_ok,'test_pins_unchanged':pins_ok,'plan_unchanged':plan_ok,'raw_stream':'original stdout/stderr merged'}
 try:
  name=phase['name']
  if name!='actual_UI21_packed_identity' and time.monotonic()-resource_start>180.0:
   row['resource_group_timeout']=True;ok=False
  if name=='actual-pck-enumeration':
   d=json.loads((O/'PCK_INVENTORY.json').read_text());assert d['pass'] is True and d['errors']==[] and d['pack_sha256']==pck_hash
  if name=='source-fingerprint':
   d=json.loads((O/'source-imported-fingerprints.json').read_text());assert d['schema_version']==2 and len(d['exact_files'])==78 and len(d['images'])==69 and len(d['actions'])==28
  if name=='packed-resources':
   d=json.loads((O/'packed-resource-report.json').read_text());assert d['checks']==968 and d['failures']==[] and d['exact_files']==78 and d['images']==69 and d['actions']==28 and d['action_frames']==308
  if name=='actual_UI21_packed_identity':
   d=json.loads((O/'identity.json').read_text());source=json.loads((R/'cold-gate/identity.json').read_text());lines=[json.loads(l)for l in text.splitlines()if l.startswith('{')];assert d['checks']==240 and d['failures']==[] and len(d['observations'])==21 and lines==[d];assert d['observations']==source['observations'];row['packed21_raw_source_imported_exact']=True
  if pck_hash is not None:assert H(pack_linux)==pck_hash
  if windows_ready:assert H(pack_windows)==pck_hash
 except Exception as e:row['postcondition_error']=repr(e);ok=False
 row['pass']=ok;rows.append(row)
 (O/(phase['name']+'.exit')).write_text(str(rc)+'\n');(O/(phase['name']+'-source-before.json')).write_text(json.dumps(before,indent=2)+'\n');(O/(phase['name']+'-source-after.json')).write_text(json.dumps(after,indent=2)+'\n')
 (O/'RESULT.json').write_text(json.dumps({'pass':all(x['pass']for x in rows)and len(rows)==len(plan['phases']),'completed':len(rows),'pck_sha256':pck_hash,'phases':rows,'scope':plan['scope']},indent=2)+'\n')
 if not ok:failed=True;break
raise SystemExit(1 if failed else 0)
