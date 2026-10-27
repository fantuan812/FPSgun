from pathlib import Path
import os,subprocess,json,hashlib,time
R=Path('workspace/shared');src=R/'moss-v35-work';out=R/'moss-v35-prep';env=os.environ.copy()
for k,v in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_CACHE_HOME','cache'),('XDG_DATA_HOME','data')]:env[k]=str(out/v)
steps=[]
def run(name,script,args=[]):
 start=time.monotonic();p=subprocess.run(['godot','--headless','--audio-driver','Dummy','--path',str(src),'--script',script,*(['--',*args] if args else [])],capture_output=True,text=True,env=env,timeout=180);s=p.stdout+p.stderr;(out/'logs'/f'{name}.log').write_text(s);row={'name':name,'exit':p.returncode,'engine_error':'ERROR:' in s,'seconds':round(time.monotonic()-start,3),'pass':p.returncode==0 and 'ERROR:' not in s};steps.append(row);(out/'FOCUSED_STEPS.json').write_text(json.dumps(steps,indent=2)+'\n');print(row,flush=True);assert row['pass'],name+' failed; log preserved'
for name in ['test_player_feedback','test_feedback_mixer','test_combat_focus','test_focus_fire','test_actor_actions']:run(name+'-final','res://tests/'+name+'.gd')
run('legacy-ui-final','res://ui/test_ui.gd')
run('old-six-transactions',str(R/'moss-v33-qa/checks/no_temper_transactions.gd'),[str(out/'old-transactions.json')])
run('old-24-combat',str(R/'moss-v33-qa/baseline/no_reorder_trace.gd'),[str(out/'old-combat.json')])
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
assert (out/'old-transactions.json').read_bytes()==(R/'moss-v34-qa/baseline/transactions.json').read_bytes()
assert (out/'old-combat.json').read_bytes()==(R/'moss-v34-qa/baseline/combat.json').read_bytes()
report={'pass':True,'steps':steps,'transactions_sha256':sha(out/'old-transactions.json'),'combat_sha256':sha(out/'old-combat.json'),'baseline':'Eligible actual v34 replay with pinned final production identity; not a fresh v34 baseline run','engine_scope':'Headless source only; independent/native/pack still pending'};(out/'FOCUSED_PARITY.json').write_text(json.dumps(report,indent=2)+'\n');print(report,flush=True)
