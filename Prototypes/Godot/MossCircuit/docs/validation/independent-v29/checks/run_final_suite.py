"""Independent serial source regression runner. Explicit roots; no network or mutation of source."""
import argparse,hashlib,json,os,re,subprocess,time
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--project',type=Path,required=True);p.add_argument('--output',type=Path,required=True);p.add_argument('--profile',type=Path,required=True);a=p.parse_args()
root=a.project.resolve();out=a.output.resolve();out.mkdir(parents=True,exist_ok=True)
env=dict(os.environ)
for key,part in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_DATA_HOME','data'),('XDG_CACHE_HOME','cache')]:
 d=a.profile.resolve()/part;d.mkdir(parents=True,exist_ok=True);env[key]=str(d)
def inputs():
 return {x.relative_to(root).as_posix():hashlib.sha256(x.read_bytes()).hexdigest() for x in sorted(root.rglob('*')) if x.is_file() and '.godot' not in x.relative_to(root).parts and '__pycache__' not in x.relative_to(root).parts}
before=inputs();(out/'inputs-before.json').write_text(json.dumps(before,indent=2)+'\n')
entries=sorted(x for folder in ('tests','ui','docs/art') for x in (root/folder).rglob('*.gd') if x.read_text().lstrip().startswith('extends SceneTree'))
(out/'ENTRYPOINTS.json').write_text(json.dumps([x.relative_to(root).as_posix() for x in entries],indent=2)+'\n')
results=[]
def run(label,cmd,marker=True):
 t=time.monotonic();rc=None;timed=False
 try:
  r=subprocess.run(cmd,env=env,cwd=root,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=180);rc=r.returncode;b=r.stdout
 except subprocess.TimeoutExpired as e:
  timed=True;b=(e.stdout or b'')+b'\nRUNNER_TIMEOUT_180_SECONDS\n'
 txt=b.decode('utf8',errors='replace');err=bool(re.search(r'ERROR:|SCRIPT ERROR:|Parse Error:',txt));good=bool(re.search(r'\bPASS\b|PASS_|_PASS|"failures"\s*:\s*\[\s*\]|"passed"\s*:\s*true',txt)) if marker else None
 result={'entry':label,'exit':rc,'timeout':timed,'engine_error':err,'success_marker':good,'seconds':round(time.monotonic()-t,3),'pass':rc==0 and not timed and not err and (good if marker else True)}
 (out/(label.replace('/','__')+'.log')).write_bytes(b);results.append(result);(out/'results.json').write_text(json.dumps(results,indent=2)+'\n');print(json.dumps(result),flush=True)
 return result['pass']
import_pass=run('import_reused_cache',['godot','--headless','--editor','--path',str(root),'--import','--quit'],False)
if import_pass:
 for x in entries:run(x.relative_to(root).as_posix(),['godot','--headless','--path',str(root),'--script',x.relative_to(root).as_posix()])
after=inputs();changes=[n for n in sorted(set(before)|set(after)) if before.get(n)!=after.get(n)]
summary={'source_scope':'exact frozen candidate; existing QA import cache reused after earlier true cold import','entries':len(results),'standalone_expected':len(entries),'passed':sum(x['pass'] for x in results),'failed':[x for x in results if not x['pass']],'input_count':len(before),'input_changes':changes}
(out/'SUMMARY.json').write_text(json.dumps(summary,indent=2)+'\n');print(json.dumps(summary),flush=True)
raise SystemExit(0 if not changes and all(x['pass'] for x in results) and len(results)==len(entries)+1 else 1)
