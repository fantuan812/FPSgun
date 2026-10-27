from pathlib import Path
import hashlib,json,subprocess,time,os,shutil,sys
q=Path(__file__).resolve().parent;p=q/'PLAN.json';h=lambda f:hashlib.sha256(f.read_bytes()).hexdigest();ph=h(p);plan=json.loads(p.read_text());src=Path(plan['author_source']);project=q/'project';out=q/'raw-first'
def inventory(root):
 return {str(f.relative_to(root)):h(f) for f in root.rglob('*') if f.is_file() and '.godot' not in f.relative_to(root).parts}
def pins_ok():return h(p)==ph and all(h(Path(k))==v for k,v in plan['pins'].items())
def source_ok():
 actual=inventory(src)
 return {k:v for k,v in actual.items() if not k.endswith('.gd.uid')}==plan['source_files'] and all(k[:-4] in plan['source_files'] for k in actual if k.endswith('.gd.uid'))
assert pins_ok() and source_ok() and not out.exists() and not project.exists()
author=json.loads(Path(plan['author_result']).read_text());assert author['status']=='PASS' and author['native_exit']==0 and author['records'][0]['B_author_checks']==318 and not author['before_issues'] and not author['after_issues']
project.mkdir();out.mkdir()
for rel in plan['source_files']:
 dest=project/rel;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(src/rel,dest)
assert inventory(project)==plan['source_files']
before=inventory(src);(out/'AUTHOR_INPUTS_BEFORE.json').write_text(json.dumps(before,indent=2)+'\n');rows=[];error=None
try:
 for route in plan['routes']:
  dest=out/route['name'];dest.mkdir();env=dict(os.environ)
  for k,n in [('HOME','home'),('XDG_DATA_HOME','data'),('XDG_CONFIG_HOME','config'),('XDG_CACHE_HOME','cache')]:
   (dest/n).mkdir();env[k]=str(dest/n)
  command=['/usr/local/bin/godot','--headless','--path',str(project),'--script',route['script']];start=time.monotonic();a=b=b'';rc=None;timed=False;exception=None;reports=[];parse_errors=[]
  try:
   z=subprocess.run(command,capture_output=True,env=env,timeout=180);a,b,rc=z.stdout,z.stderr,z.returncode
  except subprocess.TimeoutExpired as e:a,b=e.stdout or b'',e.stderr or b'';timed=True
  except Exception as e:exception=repr(e)
  (dest/'stdout.raw').write_bytes(a);(dest/'stderr.raw').write_bytes(b);(dest/'native.exit').write_text('NOT_EXITED_TIMEOUT\n' if timed else ('UNAVAILABLE\n' if rc is None else str(rc)+'\n'))
  for line in a.decode(errors='replace').splitlines():
   if line.lstrip().startswith('{'):
    try:
     report=json.loads(line)
     if not isinstance(report,dict) or 'checks' not in report:raise ValueError('unexpected marker schema')
     reports.append(report)
    except Exception as e:parse_errors.append(repr(e))
  tags=[tag for tag in ['SCRIPT ERROR','ERROR:','Parse Error','WARNING:','instances leaked','resources still in use'] if tag in (a+b).decode(errors='replace')]
  good=rc==0 and not timed and not exception and not b and not tags and not parse_errors and len(reports)==1 and type(reports[0].get('checks')) is int and reports[0]['checks']==route['checks'] and reports[0].get('failures')==[]
  row={'name':route['name'],'pass':good,'native_exit':rc,'timeout':timed,'seconds':time.monotonic()-start,'exception':exception,'stderr_bytes':len(b),'strict_tags':tags,'parse_errors':parse_errors,'reports':reports};rows.append(row);(dest/'RESULT.json').write_text(json.dumps(row,indent=2)+'\n');print(json.dumps(row),flush=True)
  if not good:break
except Exception as e:error=repr(e)
finally:
 after=inventory(src);actual=inventory(project);extra={k:v for k,v in actual.items() if k not in plan['source_files']};copy_same=all(actual.get(k)==v for k,v in plan['source_files'].items()) and all(k.endswith('.gd.uid') and k[:-4] in plan['source_files'] for k in extra)
 (out/'AUTHOR_INPUTS_AFTER.json').write_text(json.dumps(after,indent=2)+'\n');(out/'PROJECT_INPUTS_AFTER.json').write_text(json.dumps(actual,indent=2)+'\n')
 result={'pass':error is None and len(rows)==4 and all(r['pass'] for r in rows) and before==after and source_ok() and copy_same and pins_ok(),'scope':'Four independent pure-helper fixtures; not main/Effects/loop/native integration','exception':error,'completed':len(rows),'expected_total_checks':647,'actual_total_checks':sum(r['reports'][0]['checks'] for r in rows if len(r['reports'])==1 and type(r['reports'][0].get('checks')) is int),'author_source_unchanged':before==after,'copy_authored_inputs_unchanged':copy_same,'allowed_generated_uids':extra,'all_pins_unchanged':pins_ok(),'rows':rows};(out/'RESULT.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result),flush=True)
sys.exit(0 if result['pass'] else 1)
