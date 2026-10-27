from pathlib import Path
import argparse,hashlib,json,subprocess,os,time,traceback,sys
q=Path(__file__).resolve().parent;p=q/'PLAN.json';out=q/'raw-first';project=Path('evidence-workspace/moss-v39-B-r2')
a=argparse.ArgumentParser();a.add_argument('--plan-sha256',required=True);approved=a.parse_args().plan_sha256
h=lambda f:hashlib.sha256(f.read_bytes()).hexdigest()
def inventory():
 result={}
 for f in project.rglob('*'):
  rel=f.relative_to(project)
  if '.godot' in rel.parts:continue
  if f.is_symlink():raise ValueError('symlink '+str(rel))
  if f.is_file():result[str(rel)]=h(f)
 return result
if out.exists():raise SystemExit('REFUSE OVERWRITE')
out.mkdir();plan={};rows=[];issues=[];error=None;before={};after={}
def guard():
 if h(p)!=approved:raise ValueError('approved plan changed')
 for name,sha in plan['pins'].items():
  if h(Path(name))!=sha:raise ValueError('changed pin '+name)
 state=inventory()
 if state!=plan['inputs']:raise ValueError('R2 exact894 source set changed')
 return state
try:
 if h(p)!=approved:raise ValueError('caller plan mismatch')
 plan=json.loads(p.read_text());before=guard();(out/'BEFORE.json').write_text(json.dumps(before,indent=2)+'\n')
 cold=json.loads(Path(plan['cold_result']).read_text())
 if not (cold.get('pass') is True and cold.get('native_exit')==0 and cold.get('stderr_bytes')==0 and cold.get('after_issues')==[] and cold.get('generated')=={}):raise ValueError('R2 cold strict prerequisite absent')
 for route in plan['routes']:
  folder=out/route['name'];folder.mkdir();stdout=stderr=b'';rc=None;timed=False;exception=None;records=[];marker_errors=[];start=time.monotonic();env=dict(os.environ)
  for key,leaf in [('HOME','home'),('XDG_DATA_HOME','data'),('XDG_CONFIG_HOME','config'),('XDG_CACHE_HOME','cache')]:
   target=folder/leaf;target.mkdir();env[key]=str(target)
  try:
   guard()
   try:
    result=subprocess.run(['/usr/local/bin/godot','--headless','--path',str(project),'--script',route['script']],capture_output=True,env=env,timeout=180);stdout,stderr,rc=result.stdout,result.stderr,result.returncode
   except subprocess.TimeoutExpired as e:stdout,stderr=e.stdout or b'',e.stderr or b'';timed=True
   for line in stdout.decode(errors='replace').splitlines():
    if line.lstrip().startswith('{') or route['marker'] in line:
     try:
      value=json.loads(line)
      if not isinstance(value,dict) or route['marker'] not in value:raise ValueError('unexpected marker schema')
      records.append(value)
     except Exception:marker_errors.append(traceback.format_exc())
   guard()
  except Exception:exception=traceback.format_exc()
  (folder/'stdout.raw').write_bytes(stdout);(folder/'stderr.raw').write_bytes(stderr);(folder/'native.exit').write_text(str(rc)+'\n' if rc is not None else ('TIMEOUT\n' if timed else 'NO_NATIVE_EXIT\n'))
  text=(stdout+stderr).decode(errors='replace');tags=[tag for tag in ['SCRIPT ERROR','ERROR:','Parse Error','WARNING:','ObjectDB instances leaked','resources still in use'] if tag in text]
  good=rc==0 and not timed and exception is None and not stderr and not tags and not marker_errors and len(records)==1 and type(records[0].get(route['marker'])) is int and records[0][route['marker']]==route['checks'] and records[0].get('failures')==[]
  row={'name':route['name'],'pass':good,'native_exit':rc,'timed_out':timed,'seconds':time.monotonic()-start,'stderr_bytes':len(stderr),'strict_tags':tags,'exception':exception,'records':records,'marker_errors':marker_errors};rows.append(row);(folder/'RESULT.json').write_text(json.dumps(row,indent=2)+'\n');print(json.dumps(row),flush=True)
  if not good:break
except Exception:error=traceback.format_exc()
finally:
 try:after=guard()
 except Exception:issues.append(traceback.format_exc())
 (out/'AFTER.json').write_text(json.dumps(after,indent=2)+'\n')
 result={'pass':error is None and not issues and len(rows)==3 and all(row['pass'] for row in rows),'scope':'three separate author routes: validator63, controlled actual-chain56, pure UI20; not independent phase/native/full acceptance','completed':len(rows),'exception':error,'after_issues':issues,'rows':rows,'approved_plan':approved};(out/'RESULT.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result),flush=True)
sys.exit(0 if result['pass'] else 1)
