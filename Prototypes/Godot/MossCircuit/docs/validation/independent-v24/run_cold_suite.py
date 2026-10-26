"""Independent finite runner. Supply isolated project, fresh report directory and Godot binary."""
import argparse,hashlib,json,os,re,subprocess,time
from pathlib import Path
ap=argparse.ArgumentParser();ap.add_argument('--project',type=Path,required=True);ap.add_argument('--output',type=Path,required=True);ap.add_argument('--godot',default='godot');a=ap.parse_args()
p=a.project.resolve();o=a.output.resolve();assert p.is_dir() and not (p/'.godot').exists(),'cold copy required';assert not o.exists(),'fresh output required';o.mkdir(parents=True)
env=os.environ.copy()
for key,name in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_DATA_HOME','data'),('XDG_CACHE_HOME','cache')]:
 q=o/'profile'/name;q.mkdir(parents=True);env[key]=str(q)
h=lambda q:hashlib.sha256(q.read_bytes()).hexdigest()
def inputs():
 roots=['scripts','ui','data','scenes','assets'];out={}
 for root in roots:
  for q in (p/root).rglob('*'):
   if q.is_file() and q.suffix in ['.gd','.json','.tscn','.png','.import']:out[str(q.relative_to(p))]=h(q)
 for q in (p/'tests').rglob('*'):
  if q.is_file() and q.suffix in ['.gd','.json','.py']:out[str(q.relative_to(p))]=h(q)
 for rel in ['project.godot','export_presets.cfg','art_source/alpha_bounds.json']:out[rel]=h(p/rel)
 return dict(sorted(out.items()))
before=inputs();rows=[]
def run(name,args,marker):
 t=time.monotonic()
 try:r=subprocess.run(args,cwd=p,env=env,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=180);s=r.stdout;code=r.returncode
 except subprocess.TimeoutExpired as e:s=str(e.stdout or '')+'\nTIMEOUT';code=-1
 (o/(name+'.log')).write_text(s)
 error=bool(re.search(r'(^|\n)(?:SCRIPT )?ERROR:',s))
 success=not marker or bool(re.search(r'PASS|"failures"\s*:\s*\[\s*\]|^OK$',s,re.M))
 row={'test':name,'exit':code,'error':error,'success_marker':success if marker else None,'seconds':round(time.monotonic()-t,3),'pass':code==0 and not error and success};rows.append(row);print(json.dumps(row),flush=True)
run('import',[a.godot,'--headless','--editor','--path',str(p),'--import','--quit'],False)
entrypoints=sorted(q for q in (p/'tests').glob('*.gd') if re.search(r'^extends SceneTree\s*$',q.read_text(),re.M))+[p/'ui/test_ui.gd']
if rows[0]['pass']:
 for q in entrypoints:run(q.name,[a.godot,'--headless','--path',str(p),'--script',str(q)],True)
 run('python-export-tools',['python3',str(p/'tests/test_export_tools.py')],True)
after=inputs();changes=[n for n in sorted(before.keys()|after.keys()) if before.get(n)!=after.get(n)]
(o/'input-hashes.json').write_text(json.dumps({'before':before,'after':after,'changes':changes},indent=2)+'\n')
(o/'summary.json').write_text(json.dumps(rows,indent=2)+'\n')
result={'entrypoints':len(entrypoints),'completed':len(rows),'passed':sum(x['pass'] for x in rows),'failures':[x for x in rows if not x['pass']],'input_count':len(before),'input_changes':changes,'scope':'headless cold import, standalone regression and Python safety tests; not GUI'}
(o/'result.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result),flush=True)
raise SystemExit(0 if all(x['pass'] for x in rows) and not changes and len(rows)==len(entrypoints)+2 else 1)
