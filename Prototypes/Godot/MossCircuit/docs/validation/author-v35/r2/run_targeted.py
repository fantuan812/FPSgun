from pathlib import Path
import os,subprocess,time,json,hashlib
r=Path('workspace/shared');src=r/'moss-v35-r2';out=r/'moss-v35-r2-prep';env=os.environ.copy()
for key,val in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_CACHE_HOME','cache'),('XDG_DATA_HOME','data')]:env[key]=str(out/val)
rows=[]
for name in ['independent_annulus_runtime','independent_brood_parity','independent_weapon_rig','test_core_summon','test_feedback_teardown']:
 start=time.monotonic();p=subprocess.run(['godot','--headless','--audio-driver','Dummy','--path',str(src),'--script','res://tests/'+name+'.gd'],env=env,capture_output=True,text=True,timeout=180);log=p.stdout+p.stderr;(out/'logs'/(name+'.log')).write_text(log)
 row={'test':name,'exit':p.returncode,'seconds':round(time.monotonic()-start,3),'error':'ERROR:' in log,'resource_warning':'instances leaked' in log or 'resources still in use' in log};row['pass']=p.returncode==0 and not row['error'] and not row['resource_warning'];rows.append(row);(out/'TARGETED_STEPS.json').write_text(json.dumps(rows,indent=2)+'\n');print(row,flush=True)
m=json.loads((out/'CANDIDATE_INPUTS.json').read_text());changes=[k for k,v in m.items() if hashlib.sha256((src/k).read_bytes()).hexdigest()!=v];report={'all_pass':all(x['pass'] for x in rows) and not changes,'steps':rows,'source_count':len(m),'input_changes':changes,'scope':'Targeted fixture disposal checks only; original full109/113 remains rejected, final full aggregate after independent promotion'};(out/'TARGETED_GATE.json').write_text(json.dumps(report,indent=2)+'\n');print(report,flush=True);raise SystemExit(0 if report['all_pass'] else 1)
