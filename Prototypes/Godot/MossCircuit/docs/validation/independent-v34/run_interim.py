from pathlib import Path
import argparse,os,subprocess,json,hashlib,time,shutil
ap=argparse.ArgumentParser();ap.add_argument('--label',default='r1');ap.add_argument('--only',default='');ap.add_argument('--skip-import',action='store_true');a=ap.parse_args()
q=Path(__file__).parent;r=q/'project';out=q/'results'/a.label;assert not out.exists();out.mkdir(parents=True);env=os.environ.copy();h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();inputs=json.loads((q/'CANDIDATE_INPUTS_R1.json').read_text());assert all(h(r/p)==v for p,v in inputs.items())
for key,name in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_CACHE_HOME','cache'),('XDG_DATA_HOME','data')]:
 p=q/'private-profile'/name;p.mkdir(parents=True,exist_ok=True);env[key]=str(p)
env['GODOT_SILENCE_ROOT_WARNING']='1'
steps=[] if a.skip_import else [('cold-import',['--editor','--import'],None)]
for name in ['authority','combat','views','old-transactions','old-combat']:
 if a.only and name not in a.only.split(','):continue
 script=q/'checks'/({'old-transactions':'no_temper_transactions.gd','old-combat':'no_reorder_trace.gd'}.get(name,'independent_focus_'+name+'.gd'))
 shutil.copy2(script,out/script.name);steps.append((name,['--script',str(script),'--',str(out/(name+'.json'))],script))
rows=[]
for name,args,script in steps:
 t=time.monotonic();p=subprocess.run(['godot','--headless','--path',str(r)]+args,env=env,capture_output=True,text=True,timeout=600);log=p.stdout+p.stderr;(out/(name+'.log')).write_text(log)
 row={'name':name,'exit':p.returncode,'seconds':round(time.monotonic()-t,3),'engine_error':'ERROR:' in log,'pass':p.returncode==0 and 'ERROR:' not in log}
 if script:row['script_sha256']=h(script)
 if (out/(name+'.json')).exists():
  result=json.loads((out/(name+'.json')).read_text());row['checks']=result.get('checks',len(result.get('cases',[])));row['failures']=result.get('failures',['missing']);row['pass'] &=not row['failures']
 if name.startswith('old-') and row['pass']:
  baseline=q/'baseline'/('transactions.json' if name=='old-transactions' else 'combat.json');row['baseline_byte_equal']=(out/(name+'.json')).read_bytes()==baseline.read_bytes();row['pass'] &=row['baseline_byte_equal']
 rows.append(row);(out/'STEPS.json').write_text(json.dumps(rows,indent=2)+'\n');print(json.dumps(row),flush=True)
 if not row['pass']:print(log[-5000:],flush=True);break
changes=[p for p,v in inputs.items() if h(r/p)!=v];receipt={'pass':len(rows)==len(steps) and all(x['pass'] for x in rows) and not changes,'steps':rows,'input_changes':changes,'source_inputs':len(inputs),'source_map_sha256':h(q/'CANDIDATE_INPUTS_R1.json')}
(out/'SUMMARY.json').write_text(json.dumps(receipt,indent=2)+'\n');print(json.dumps(receipt),flush=True);raise SystemExit(0 if receipt['pass'] else 1)
