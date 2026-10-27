import argparse,datetime,gzip,hashlib,json,os,pathlib,shutil,subprocess,time
ap=argparse.ArgumentParser();ap.add_argument('--label',required=True);ap.add_argument('--only',default='authority,mixer,views,old-transactions,old-combat');ap.add_argument('--skip-import',action='store_true');ap.add_argument('--inputs',default='receipts/HELD_R1_INPUTS.json');a=ap.parse_args()
q=pathlib.Path(__file__).parent;project=q/'project';out=q/'results'/a.label;assert not out.exists();out.mkdir(parents=True)
def h(p):return hashlib.sha256(p.read_bytes()).hexdigest()
input_path=q/a.inputs;inputs=json.load(open(input_path));assert all(h(project/p)==v for p,v in inputs.items())
env=os.environ.copy();env['GODOT_SILENCE_ROOT_WARNING']='1'
for key,suffix in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_CACHE_HOME','cache'),('XDG_DATA_HOME','data')]:
 p=q/'private-profile'/suffix;p.mkdir(parents=True,exist_ok=True);env[key]=str(p)
steps=[]
if not a.skip_import:steps.append(('cold-import',['--editor','--import'],None))
for name in a.only.split(','):
 script=q/'checks'/({'old-transactions':'no_temper_transactions.gd','old-combat':'no_reorder_trace.gd'}.get(name,'independent_feedback_'+name+'.gd'))
 archived=out/script.name;shutil.copy2(script,archived)
 args=['--script',str(script),'--',str(out/(name+'.json'))]
 if name=='mixer':args.append(str(out/'mixer-raw'))
 steps.append((name,args,script))
rows=[]
for name,args,script in steps:
 stamp=datetime.datetime.now(datetime.timezone.utc).isoformat();t=time.monotonic();log_path=out/(name+'.log')
 try:
  with log_path.open('w') as log:p=subprocess.run(['/usr/local/bin/godot','--headless','--audio-driver','Dummy','--path',str(project)]+args,env=env,stdout=log,stderr=subprocess.STDOUT,timeout=600)
  code=p.returncode;failure=None
 except subprocess.TimeoutExpired:code=None;failure='bounded process timeout (not successful terminal)'
 log=log_path.read_text();row={'name':name,'started_utc':stamp,'exit':code,'seconds':round(time.monotonic()-t,3),'engine_error':'ERROR:' in log,'pass':code==0 and 'ERROR:' not in log,'log_sha256':h(log_path)}
 if failure:row['failure']=failure
 if script:row['script_sha256']=h(script)
 result_path=out/(name+'.json')
 if script:
  if result_path.exists():
   result=json.loads(result_path.read_text());row['checks']=result.get('checks',len(result.get('cases',[])));row['failures']=result.get('failures',['missing failures']);row['pass']=row['pass'] and not row['failures'];row['result_sha256']=h(result_path)
  else:row['pass']=False;row['failure']='missing terminal JSON'
 if name.startswith('old-') and row['pass']:
  expected='22e28521ba76fb7285a59b98593aecc7c4af9e24d497853119f73495324feaf8' if name=='old-transactions' else 'e7d93a1fcf01345c540bf9f868632310fd3e85572dbe431dbe12d43bf19212ec'
  row['historical_v34_output_sha256']=expected;row['baseline_byte_identity']=h(result_path)==expected;row['pass'] &=row['baseline_byte_identity']
 rows.append(row);(out/'STEPS.json').write_text(json.dumps(rows,indent=2)+'\n');print(json.dumps(row),flush=True)
 if not row['pass']:print(log[-6000:],flush=True);break
changes=[p for p,v in inputs.items() if h(project/p)!=v]
summary={'pass':len(rows)==len(steps) and all(r['pass'] for r in rows) and not changes,'steps':rows,'source_inputs':len(inputs),'input_changes':changes,'source_map_sha256':h(input_path),'import_scope':'reused cache' if a.skip_import else 'initial exact slim copy had no .godot cache'}
(out/'SUMMARY.json').write_text(json.dumps(summary,indent=2)+'\n');print(json.dumps(summary),flush=True)
raise SystemExit(0 if summary['pass'] else 1)
