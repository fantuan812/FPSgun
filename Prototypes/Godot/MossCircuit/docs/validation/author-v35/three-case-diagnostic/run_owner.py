from pathlib import Path
import json,hashlib,subprocess,os,time
r=Path('workspace/shared');out=r/'moss-v35-final-diagnostic';src=r/'moss-v35-final';h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();plan=json.loads((out/'OWNER_PLAN.json').read_text());env=os.environ.copy()
for k,v in [('HOME','owner-home'),('XDG_CONFIG_HOME','owner-config'),('XDG_DATA_HOME','owner-data'),('XDG_CACHE_HOME','owner-cache')]:env[k]=str(out/v)
rows=[]
for c in plan['cases']:
 name=c['case'];script=out/('owner_'+name);assert h(script)==c['external_sha256'];assert h(src/'tests'/name)==c['source_sha256'];result=out/('owner_'+name+'.json');t=time.monotonic()
 p=subprocess.run(['godot','--headless','--audio-driver','Dummy','--path',str(src),'--script',str(script),'--',str(result)],env=env,capture_output=True,text=True,timeout=180)
 (out/('owner_'+name+'.stdout')).write_text(p.stdout);(out/('owner_'+name+'.stderr')).write_text(p.stderr)
 row={'case':name,'exit':p.returncode,'seconds':time.monotonic()-t,'error':'ERROR:' in p.stdout+p.stderr,'result':json.loads(result.read_text()) if result.exists() else None};rows.append(row);(out/'OWNER_STEPS.json').write_text(json.dumps(rows,indent=2)+'\n');print({k:v for k,v in row.items() if k!='result'},flush=True)
inputs=json.loads((r/'moss-v35-final-prep/FINAL_INPUTS.json').read_text());changes=[k for k,v in inputs.items() if h(src/k)!=v];passed=not changes and all(x['exit']==0 and not x['error'] and x['result'] and x['result']['complete'] and x['result']['capture_removed'] for x in rows)
(out/'OWNER_RESULT.json').write_text(json.dumps({'diagnostic_pass':passed,'cases':rows,'source_count':len(inputs),'source_changes':changes,'scope':'Current external owner observations only; original119aggregate remains rejected and other2 original resource identities unknown.'},indent=2)+'\n');raise SystemExit(0 if passed else 1)
