from pathlib import Path
import argparse,hashlib,json,subprocess,os,time,traceback,sys
q=Path(__file__).resolve().parent
args=argparse.ArgumentParser();args.add_argument('--plan-sha256',required=True);approved=args.parse_args().plan_sha256
plan_path=q/'PLAN.json';out=q/'raw-first';project=Path('evidence-workspace/moss-v39-B-integration')
def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def inventory():
 result={}
 for f in project.rglob('*'):
  rel=f.relative_to(project)
  if '.godot' in rel.parts:continue
  if f.is_symlink():raise ValueError('symlink '+str(rel))
  if f.is_file():result[str(rel)]=digest(f)
 return result
if out.exists():raise SystemExit('REFUSE OVERWRITE')
out.mkdir();plan={};before={};after={};extras={};issues=[];exception=None;stdout=stderr=b'';native=None;timed=False;spawned=False;start=time.monotonic()
def check_pins():
 if digest(plan_path)!=approved:raise ValueError('approved PLAN changed')
 for path,sha in plan['pins'].items():
  if digest(Path(path))!=sha:raise ValueError('pin changed '+path)
try:
 if digest(plan_path)!=approved:raise ValueError('caller PLAN mismatch')
 plan=json.loads(plan_path.read_text());check_pins()
 before=inventory()
 if before!=plan['inputs']:raise ValueError('exact883 source set mismatch')
 if (project/'.godot').exists():raise ValueError('cold candidate cache already exists')
 (out/'BEFORE.json').write_text(json.dumps(before,indent=2)+'\n')
 env=dict(os.environ)
 for key,leaf in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_DATA_HOME','data'),('XDG_CACHE_HOME','cache')]:
  p=out/leaf;p.mkdir();env[key]=str(p)
 command=['/usr/local/bin/godot','--headless','--editor','--path',str(project),'--import']
 spawned=True
 try:
  r=subprocess.run(command,capture_output=True,env=env,timeout=180);stdout,stderr,native=r.stdout,r.stderr,r.returncode
 except subprocess.TimeoutExpired as e:stdout,stderr=e.stdout or b'',e.stderr or b'';timed=True
except Exception:exception=traceback.format_exc()
finally:
 (out/'stdout.raw').write_bytes(stdout);(out/'stderr.raw').write_bytes(stderr)
 (out/'native.exit').write_text(('TIMEOUT' if timed else ('NOT_STARTED' if not spawned else 'UNAVAILABLE'))+'\n' if native is None else str(native)+'\n')
 try:
  check_pins();after=inventory()
  if not all(after.get(k)==v for k,v in plan['inputs'].items()):issues.append('original authored input changed/missing')
  extras={k:v for k,v in after.items() if k not in plan['inputs']}
  for k in extras:
   allowed=(k.endswith('.gd.uid') and k[:-4] in plan['inputs']) or (k.endswith('.import') and k[:-7] in plan['inputs'] and Path(k[:-7]).suffix in ['.svg','.png'])
   if not allowed:issues.append('unexpected noncache addition '+k)
 except Exception:issues.append(traceback.format_exc())
 (out/'AFTER.json').write_text(json.dumps(after,indent=2)+'\n');(out/'GENERATED.json').write_text(json.dumps(extras,indent=2)+'\n')
 text=(stdout+stderr).decode(errors='replace');tags=[t for t in ['SCRIPT ERROR','ERROR:','Parse Error','WARNING:','ObjectDB instances leaked','resources still in use'] if t in text]
 result={'pass':native==0 and not timed and exception is None and len(stderr)==0 and not tags and not issues,'scope':'cold import/parser only; no author or independent gameplay acceptance','native_exit':native,'spawned':spawned,'timed_out':timed,'seconds':time.monotonic()-start,'stderr_bytes':len(stderr),'tags':tags,'exception':exception,'after_issues':issues,'generated':extras,'approved_plan':approved}
 (out/'RESULT.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result),flush=True)
sys.exit(0 if result['pass'] else 1)
