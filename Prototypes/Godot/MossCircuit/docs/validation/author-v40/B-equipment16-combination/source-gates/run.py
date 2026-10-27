"""Exactly cold + independent201 + independent240, first FAIL, no export/native auto-follow."""
from pathlib import Path
import argparse,json,hashlib,os,subprocess,time,traceback,sys,re
q=Path(__file__).resolve().parent;ap=argparse.ArgumentParser();ap.add_argument('--plan-sha256',required=True);approved=ap.parse_args().plan_sha256
pp=q/'PLAN.json';out=q/'raw-first';h=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
if out.exists():raise SystemExit('REFUSE OVERWRITE')
out.mkdir();plan={};before={};after={};issues=[];rows=[];exception=None

def inventory(root):
 d={}
 for p in root.rglob('*'):
  rel=p.relative_to(root)
  if '.godot' in rel.parts:continue
  if p.is_symlink():raise ValueError('symlink '+str(p))
  if p.is_file():d[str(rel)]=h(p)
 return d

def guard():
 assert h(pp)==approved
 for path,sha in plan['pins'].items():assert h(path)==sha,path
 for root,expected in plan['original_sources'].items():assert inventory(Path(root))==expected,root

def valid_report(report,route,expected):
 assert isinstance(report,dict) and set(report)=={'checks','failures','observations','scope'}
 assert type(report['checks']) is int and report['checks']==route['checks'] and report['failures']==[] and report['scope']==route['scope']
 obs=report['observations'];assert isinstance(obs,list) and len(obs)==route['observations'] and all(isinstance(o,dict) for o in obs)
 ids=sorted(expected['new'] if route['kind']=='B3' else expected['icons'])
 assert sorted(o['id'] for o in obs)==ids
 for o in obs:
  id=o['id'];e=expected['new'][id] if route['kind']=='B3' else expected['icons'][id]
  keys={'id','atlas','raw_rgba_sha256','visible_rgba_sha256','source_png_rgba_sha256','alpha_sha256'} if route['kind']=='B3' else {'id','atlas','raw_rgba_sha256','source_raw_rgba_sha256','visible_rgba_sha256'}
  assert set(o)==keys and o['atlas']==expected['icons'][id]['atlas'] and o['visible_rgba_sha256']==e['visible_rgba_sha256']
  assert o['source_png_rgba_sha256' if route['kind']=='B3' else 'source_raw_rgba_sha256']==e['rgba_sha256']
  if route['kind']=='B3':assert o['alpha_sha256']==e['alpha_sha256']
  for key in keys-{'id','atlas'}:assert isinstance(o[key],str) and len(o[key])==64 and all(c in '0123456789abcdef' for c in o[key])
 imported=json.loads(Path(route['accepted_imported_report']).read_text())
 assert imported['failures']==[] and imported['checks']==route['checks']
 assert obs==imported['observations']
 return True

def run(route):
 folder=out/route['name'];folder.mkdir();stdout=stderr=b'';native=None;timeout=False;error=None;report_ok=False;parse_errors=[];reports=[];t=time.monotonic()
 try:
  cmd=['/usr/local/bin/godot','--headless','--audio-driver','Dummy','--path',plan['project']]
  if route['name']=='cold':cmd+=['--editor','--import','--quit']
  else:cmd+=['--script',route['script'],'--',route['expected'],str(folder/'report.json')]
  (folder/'COMMAND.json').write_text(json.dumps(cmd,indent=2)+'\n')
  try:
   r=subprocess.run(cmd,env=env,cwd=folder,capture_output=True,timeout=180);stdout,stderr,native=r.stdout,r.stderr,r.returncode
  except subprocess.TimeoutExpired as e:stdout,stderr=e.stdout or b'',e.stderr or b'';timeout=True
  for line in stdout.decode('utf-8',errors='strict').splitlines():
   if 'TEST_AUDIO_TEARDOWN' in line:parse_errors.append('unexpected helper, UI-only routes require0')
   elif '{' in line:
    try:
     assert line.startswith('{');reports.append(json.loads(line))
    except Exception:parse_errors.append('malformed or prefixed JSON')
   elif route['name']=='cold' and re.match(r'^\[\s*(?:[0-9]{1,3}%|DONE)\s*\]',re.sub(r'\x1b\[[0-9;]*m','',line)):
    pass  # Editor-only percentage/DONE progress, not a business-report marker.
   elif 'checks' in line or 'failures' in line or line.lstrip().startswith(('"','[',']','}')):parse_errors.append('malformed apparent marker')
  if route['name']=='cold':report_ok=not reports
  elif len(reports)==1:
   full=json.loads((folder/'report.json').read_text());assert full==reports[0]
   report_ok=valid_report(full,route,json.loads(Path(route['expected']).read_text()))
 except Exception:error=traceback.format_exc()
 finally:
  (folder/'stdout.raw').write_bytes(stdout);(folder/'stderr.raw').write_bytes(stderr);(folder/'native.exit').write_text(('TIMEOUT' if timeout else 'NOT_COMPLETED')+'\n' if native is None else str(native)+'\n')
  text=(stdout+stderr).decode(errors='replace');tags=[v for v in ['SCRIPT ERROR','ERROR:','Parse Error','WARNING:','ObjectDB instances leaked','resources still in use'] if v in text]
  row={'name':route['name'],'native_exit':native,'timeout':timeout,'seconds':time.monotonic()-t,'stderr_bytes':len(stderr),'tags':tags,'parse_errors':parse_errors,'report_ok':report_ok,'exception':error}
  row['pass']=native==0 and not timeout and not stderr and not tags and not parse_errors and report_ok and error is None
  (folder/'RESULT.json').write_text(json.dumps(row,indent=2)+'\n');rows.append(row);(out/'STEPS.json').write_text(json.dumps(rows,indent=2)+'\n');print(json.dumps(row),flush=True)
 if not row['pass']:raise RuntimeError('first FAIL '+route['name'])
try:
 assert h(pp)==approved;plan=json.loads(pp.read_text());guard();project=Path(plan['project']);before=inventory(project)
 assert before==plan['inputs'] and len(before)==926 and not (project/'.godot').exists()
 for record in plan['preconditions']:
  d=json.loads(Path(record['path']).read_text())
  for k in record['required_true']:assert d.get(k) is True
 (out/'BEFORE.json').write_text(json.dumps(before,indent=2)+'\n');env=dict(os.environ)
 for key,name in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_DATA_HOME','data'),('XDG_CACHE_HOME','cache')]:
  p=out/name;p.mkdir();env[key]=str(p)
 for route in plan['routes']:run(route)
except Exception:exception=traceback.format_exc()
finally:
 try:
  guard();after=inventory(Path(plan['project']))
  if after!=plan['inputs']:issues.append('926 exactset/hash changed; zero generated additions expected')
 except Exception:issues.append(traceback.format_exc())
 (out/'AFTER.json').write_text(json.dumps(after,indent=2)+'\n');result={'pass':exception is None and not issues and len(rows)==3 and all(r['pass'] for r in rows),'completed':len(rows),'exception':exception,'after_issues':issues,'plan':approved,'scope':'combined926 cold+actualB201/3+acceptedatlas240/21; not PCK/native/ordinary'}
 (out/'RESULT.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result),flush=True)
sys.exit(0 if result['pass'] else 1)
