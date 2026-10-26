"""Finish the declared standalone inventory and audit success summaries without rerunning clean entries."""
from pathlib import Path
import json,re,hashlib,shutil,subprocess,os,time
r=Path(__file__).resolve().parent;p=r/'final-cold';o=r/'final-regression';rej=r/'rejected-runner';rej.mkdir(exist_ok=False)
for n in ['summary.json','result.json']:shutil.copyfile(o/n,rej/n)
shutil.copyfile(r/'run_cold_suite.py',rej/'run_cold_suite.py')
rows=json.loads((o/'summary.json').read_text()); corrected=[]
for row in rows:
 if row['success_marker'] is False:
  s=(o/(row['test']+'.log')).read_text()
  assert re.search(r'(?:\d+ passed; 0 failed|\d+ passed; failures=\[\]|\d+ checks, 0 failures)',s),row
  assert row['exit']==0 and not row['error'];row['success_marker']=True;row['pass']=True;corrected.append(row['test'])
env=os.environ.copy()
for key,name in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_DATA_HOME','data'),('XDG_CACHE_HOME','cache')]:env[key]=str(o/'profile'/name)
for rel in ['docs/art/check_icons.gd','docs/art/check_mechanism_icons.gd','docs/art/check_build_expansion_icons.gd']:
 t=time.monotonic();q=subprocess.run(['godot','--headless','--path',str(p),'--script',str(p/rel)],env=env,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=180);s=q.stdout;(o/(Path(rel).name+'.log')).write_text(s)
 error=bool(re.search(r'(^|\n)(?:SCRIPT )?ERROR:',s));marker=bool(re.search(r'PASS|"failures"\s*:\s*\[\s*\]',s));row={'test':Path(rel).name,'exit':q.returncode,'error':error,'success_marker':marker,'seconds':round(time.monotonic()-t,3),'pass':q.returncode==0 and not error and marker};rows.append(row);print(json.dumps(row),flush=True)
before=json.loads((r/'SOURCE_COPY.json').read_text())['files'];h=lambda q:hashlib.sha256(q.read_bytes()).hexdigest();changes=[n for n,v in before.items() if not (p/n).is_file() or h(p/n)!=v];assert not changes
result={'entrypoints':73,'completed':len(rows),'passed':sum(x['pass'] for x in rows),'failures':[x for x in rows if not x['pass']],'original_source_files_reverified':540,'input_changes':changes,'scope':'cold import +73 standalone scripts + Python3 safety checks; no GUI inference','runner_correction':'17 clean summaries initially rejected by overly narrow marker regex; three docs/art standalone entrypoints initially omitted, executed separately before acceptance. Original provisional report/runner preserved.'}
assert len(rows)==75 and all(x['pass'] for x in rows)
(o/'summary.json').write_text(json.dumps(rows,indent=2)+'\n');(o/'result.json').write_text(json.dumps(result,indent=2)+'\n')
(r/'RUNNER_ORACLE_CORRECTION.json').write_text(json.dumps({'incorrect_marker_results':corrected,'additional_executed_scripts':['docs/art/check_icons.gd','docs/art/check_mechanism_icons.gd','docs/art/check_build_expansion_icons.gd'],'source_changes':[],'not_product_failures':True,'preserved_provisional_files':'rejected-runner/','final_result':result},indent=2)+'\n');print(json.dumps(result))
