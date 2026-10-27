from pathlib import Path
import os,json,hashlib,time,subprocess
r=Path('workspace/shared');src=r/'moss-v35-final';out=r/'moss-v35-final-diagnostic';h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();env=os.environ.copy()
for k,v in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_DATA_HOME','data'),('XDG_CACHE_HOME','cache')]:env[k]=str(out/v)
names=['independent_charger_lifecycle.gd','test_game.gd','test_warden_charge.gd'];inputs=json.loads((r/'moss-v35-final-prep/FINAL_INPUTS.json').read_text());assert all(h(src/k)==v for k,v in inputs.items())
plan={'mode':'single unchanged exact-script verbose diagnostic per each of3 new strict failures','names':{n:h(src/'tests'/n) for n in names},'timeout_each':180,'no_source_edits':True,'not_an_acceptance_rerun':True};(out/'VERBOSE_PLAN.json').write_text(json.dumps(plan,indent=2)+'\n')
rows=[]
for n in names:
 t=time.monotonic();p=subprocess.run(['godot','--headless','--audio-driver','Dummy','--verbose','--path',str(src),'--script','res://tests/'+n],env=env,capture_output=True,text=True,timeout=180)
 (out/(n+'.stdout')).write_text(p.stdout);(out/(n+'.stderr')).write_text(p.stderr)
 rows.append({'test':n,'exit':p.returncode,'seconds':time.monotonic()-t,'stdout_sha256':h(out/(n+'.stdout')),'stderr_sha256':h(out/(n+'.stderr')),'error':'ERROR:' in p.stdout+p.stderr});(out/'VERBOSE_STEPS.json').write_text(json.dumps(rows,indent=2)+'\n');print(rows[-1],flush=True)
changed=[k for k,v in inputs.items() if h(src/k)!=v];(out/'VERBOSE_RESULT.json').write_text(json.dumps({'steps':rows,'inputs':len(inputs),'changed':changed,'diagnostic_not_acceptance':True},indent=2)+'\n');assert not changed
