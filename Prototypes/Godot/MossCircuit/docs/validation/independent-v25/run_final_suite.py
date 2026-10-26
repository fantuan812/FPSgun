"""Independent complete standalone inventory; source reuse and import provenance are explicit."""
import argparse,hashlib,json,os,re,subprocess,time
from pathlib import Path
ap=argparse.ArgumentParser();ap.add_argument('--project',type=Path,required=True);ap.add_argument('--output',type=Path,required=True);ap.add_argument('--source-map',type=Path,required=True);a=ap.parse_args()
p=a.project.resolve();o=a.output.resolve();assert p.is_dir() and not o.exists();o.mkdir(parents=True)
source=json.loads(a.source_map.read_text());before=source['files'];h=lambda q:hashlib.sha256(q.read_bytes()).hexdigest();assert all(h(p/n)==v for n,v in before.items())
env=os.environ.copy()
for key,name in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_DATA_HOME','data'),('XDG_CACHE_HOME','cache')]:
 q=o/'profile'/name;q.mkdir(parents=True);env[key]=str(q)
rows=[]
def run(name,args,marker):
 t=time.monotonic()
 try:r=subprocess.run(args,cwd=p,env=env,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=180);s=r.stdout;code=r.returncode
 except subprocess.TimeoutExpired as e:s=str(e.stdout or '')+'\nTIMEOUT';code=-1
 (o/(name+'.log')).write_text(s)
 error=bool(re.search(r'(^|\n)(?:SCRIPT )?ERROR:',s))
 success=not marker or bool(re.search(r'PASS|"failures"\s*:\s*\[\s*\]|^OK$|\d+ passed; 0 failed|\d+ passed; failures=\[\]|\d+ checks, 0 failures',s,re.M))
 row={'test':name,'exit':code,'engine_error':error,'success_marker':success if marker else None,'seconds':round(time.monotonic()-t,3),'pass':code==0 and not error and success};rows.append(row);print(json.dumps(row),flush=True)
 (o/'progress.json').write_text(json.dumps(rows,indent=2)+'\n')
run('import-revalidation',['godot','--headless','--editor','--path',str(p),'--import','--quit'],False)
entrypoints=sorted(q for q in (p/'tests').glob('*.gd') if re.search(r'^extends SceneTree\s*$',q.read_text(),re.M))+[p/q for q in ['ui/test_ui.gd','docs/art/check_icons.gd','docs/art/check_mechanism_icons.gd','docs/art/check_build_expansion_icons.gd']]
assert len(entrypoints)==76
(o/'entrypoints.json').write_text(json.dumps([str(q.relative_to(p)) for q in entrypoints],indent=2)+'\n')
if rows[0]['pass']:
 for q in entrypoints:run(q.name,['godot','--headless','--path',str(p),'--script',str(q)],True)
 run('python-export-tools',['python3',str(p/'tests/test_export_tools.py')],True)
after={n:h(p/n) if (p/n).is_file() else None for n in before};changes=[n for n in before if before[n]!=after[n]]
(o/'input-hashes.json').write_text(json.dumps({'before':before,'after':after,'changes':changes},indent=2)+'\n')
(o/'summary.json').write_text(json.dumps(rows,indent=2)+'\n')
result={'entrypoints':len(entrypoints),'completed':len(rows),'passed':sum(x['pass'] for x in rows),'failures':[x for x in rows if not x['pass']],'original_source_file_count':len(before),'input_changes':changes,'scope':'Final 76 standalone scripts, Python safety and reused-cache import revalidation; genuinely cold import of identical production retained separately; not GUI.'}
(o/'result.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result),flush=True)
raise SystemExit(0 if all(x['pass'] for x in rows) and not changes and len(rows)==len(entrypoints)+2 else 1)
