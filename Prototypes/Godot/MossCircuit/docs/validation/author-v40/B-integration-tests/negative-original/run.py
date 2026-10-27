from pathlib import Path
import argparse,hashlib,json,subprocess,os,time,traceback,sys
q=Path(__file__).resolve().parent;p=q/'PLAN.json';out=q/'raw-first';project=Path('evidence-workspace/moss-v39-B-integration')
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
out.mkdir();plan={};issues=[];error=None;before={};after={};stdout=stderr=b'';rc=None;timed=False;spawned=False;records=[];marker_errors=[];start=time.monotonic()
def guard():
 if h(p)!=approved:raise ValueError('approved plan changed')
 for name,sha in plan['pins'].items():
  if h(Path(name))!=sha:raise ValueError('changed pin '+name)
 state=inventory()
 if state!=plan['inputs']:raise ValueError('original894 source set changed')
 return state
try:
 if h(p)!=approved:raise ValueError('caller plan mismatch')
 plan=json.loads(p.read_text());before=guard();(out/'BEFORE.json').write_text(json.dumps(before,indent=2)+'\n')
 env=dict(os.environ)
 for key,leaf in [('HOME','home'),('XDG_DATA_HOME','data'),('XDG_CONFIG_HOME','config'),('XDG_CACHE_HOME','cache')]:
  folder=out/leaf;folder.mkdir();env[key]=str(folder)
 command=['/usr/local/bin/godot','--headless','--path',str(project),'--script',plan['fixture']];spawned=True
 try:
  r=subprocess.run(command,capture_output=True,env=env,timeout=180);stdout,stderr,rc=r.stdout,r.stderr,r.returncode
 except subprocess.TimeoutExpired as e:stdout,stderr=e.stdout or b'',e.stderr or b'';timed=True
 for line in stdout.decode(errors='replace').splitlines():
  if line.lstrip().startswith('{') or 'B_rules_configuration_checks' in line:
   try:
    value=json.loads(line)
    if not isinstance(value,dict) or 'B_rules_configuration_checks' not in value:raise ValueError('unexpected marker schema')
    records.append(value)
   except Exception:marker_errors.append(traceback.format_exc())
except Exception:error=traceback.format_exc()
finally:
 (out/'stdout.raw').write_bytes(stdout);(out/'stderr.raw').write_bytes(stderr);(out/'native.exit').write_text(str(rc)+'\n' if rc is not None else ('TIMEOUT\n' if timed else 'NO_NATIVE_EXIT\n'))
 try:after=guard()
 except Exception:issues.append(traceback.format_exc())
 (out/'AFTER.json').write_text(json.dumps(after,indent=2)+'\n')
 text=(stdout+stderr).decode(errors='replace');tags=[tag for tag in ['SCRIPT ERROR','ERROR:','Parse Error','WARNING:','ObjectDB instances leaked','resources still in use'] if tag in text]
 strict=rc==0 and not timed and error is None and not stderr and not tags and not issues and not marker_errors and len(records)==1 and type(records[0].get('B_rules_configuration_checks')) is int and records[0]['B_rules_configuration_checks']==63 and records[0].get('failures')==[]
 result={'strict_pass':strict,'purpose':'PRE-FIX diagnostic; a known semantic failure is still STRICT FAIL, not acceptance','native_exit':rc,'spawned':spawned,'timed_out':timed,'seconds':time.monotonic()-start,'stderr_bytes':len(stderr),'strict_tags':tags,'exception':error,'after_issues':issues,'records':records,'marker_errors':marker_errors,'approved_plan':approved}
 (out/'RESULT.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result),flush=True)
sys.exit(0 if result['strict_pass'] else 1)
