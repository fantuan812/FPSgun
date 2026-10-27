"""Do not execute before independent static acceptance and explicit QA lease."""
from pathlib import Path
import os,json,hashlib,subprocess,time,datetime,re,sys
R=Path(__file__).parent;assert len(sys.argv)==3 and sys.argv[1]=='--plan-sha256';assert hashlib.sha256((R/'COLD_GATE_PLAN.json').read_bytes()).hexdigest()==sys.argv[2],'launch-bound plan mismatch';plan=json.loads((R/'COLD_GATE_PLAN.json').read_text());assert plan['status']=='FROZEN_QA_APPROVED';T=Path(plan['source']);B=Path(plan['base']);O=R/'cold-gate';assert not O.exists(),'no retry over original result'
H=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
def snap(root):return {str(p.relative_to(root)):H(p)for p in sorted(root.rglob('*'))if p.is_file()and '.godot'not in p.relative_to(root).parts}
plan_digest=H(R/'COLD_GATE_PLAN.json')
expected=json.loads((R/'CANDIDATE_PINS.json').read_text());base=json.loads((R/'BASE_PINS.json').read_text());assert snap(T)==expected and snap(B)==base and not(T/'.godot').exists();assert all(H(Path(p))==h for p,h in plan['test_pins'].items())
O.mkdir();env=os.environ.copy()
for k,d in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_CACHE_HOME','cache'),('XDG_DATA_HOME','data')]:p=O/d;p.mkdir();env[k]=str(p)
rows=[];failed=False
for phase in plan['phases']:
 before=snap(T);start=datetime.datetime.now(datetime.timezone.utc).isoformat();tick=time.monotonic();log=O/(phase['name']+'.log');rc=None;timed=False;launch_error=None
 try:
  with log.open('wb')as f:rc=subprocess.run(phase['command'],env=env,cwd=O,stdout=f,stderr=subprocess.STDOUT,timeout=phase['timeout_seconds']).returncode
 except subprocess.TimeoutExpired:rc=124;timed=True
 except Exception as e:rc=-1;launch_error=repr(e)
 guards_error=[];after={};base_unchanged=False;test_unchanged=False;plan_unchanged=False
 try:text=log.read_text(errors='replace')
 except Exception as e:text='';guards_error.append('read_log: '+repr(e))
 try:after=snap(T)
 except Exception as e:guards_error.append('source_after: '+repr(e))
 try:base_unchanged=snap(B)==base
 except Exception as e:guards_error.append('base_after: '+repr(e))
 try:test_unchanged=all(H(Path(p))==h for p,h in plan['test_pins'].items())
 except Exception as e:guards_error.append('test_pins_after: '+repr(e))
 try:plan_unchanged=H(R/'COLD_GATE_PLAN.json')==plan_digest
 except Exception as e:guards_error.append('plan_after: '+repr(e))
 changed=[k for k in before if k not in after or after[k]!=before[k]];added=sorted(set(after)-set(before));allowed={'assets/items/equipment_atlas_editable.png.import','art_source/equipment_atlas_editable.svg.import'} if phase['name']=='cold_import' else set();badlines=[{'line':i+1,'text':line}for i,line in enumerate(text.splitlines())if re.search(r'ERROR|WARNING|SCRIPT ERROR|Parse Error|leaked|Orphan',line,re.I)]
 row={'name':phase['name'],'command':phase['command'],'start_utc':start,'end_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'elapsed_seconds':time.monotonic()-tick,'exit':rc,'timeout':timed,'launch_error':launch_error,'strict_log_findings':badlines,'changed_existing':changed,'added':added,'base_unchanged':base_unchanged,'test_pins_unchanged':test_unchanged,'plan_unchanged':plan_unchanged,'guards_error':guards_error,'raw_stream':'stdout and stderr merged into original log'}
 ok=rc==0 and launch_error is None and not timed and not badlines and not changed and set(added)==allowed and row['base_unchanged'] and row['test_pins_unchanged'] and plan_unchanged and not guards_error
 if phase['name']=='actual_UI21_source_identity':
  try:
   data=json.loads((O/'identity.json').read_text());jsonlines=[json.loads(l)for l in text.splitlines()if l.startswith('{')];ok=ok and data['checks']==240 and data['failures']==[] and len(data['observations'])==21 and len({e['id']for e in data['observations']})==21 and jsonlines==[data];row['identity_checks']=data['checks'];row['observations']=len(data['observations'])
  except Exception as e:row['identity_parse_error']=repr(e);ok=False
 row['pass']=ok;rows.append(row);(O/(phase['name']+'.exit')).write_text(str(rc)+'\n');(O/(phase['name']+'-source-before.json')).write_text(json.dumps(before,indent=2)+'\n');(O/(phase['name']+'-source-after.json')).write_text(json.dumps(after,indent=2)+'\n');(O/'RESULT.json').write_text(json.dumps({'pass':all(x['pass']for x in rows)and len(rows)==len(plan['phases']),'completed':len(rows),'phases':rows,'scope':'cold+source actual UI21 only; no packed/native acceptance'},indent=2)+'\n')
 if not ok:failed=True;break
raise SystemExit(1 if failed else 0)
