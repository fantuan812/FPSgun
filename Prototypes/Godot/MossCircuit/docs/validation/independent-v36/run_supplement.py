from pathlib import Path
import hashlib,json,os,subprocess,shutil,time
q=Path(__file__).parent;project=q/'results/first/project';out=q/'supplement-first';assert not out.exists();out.mkdir();h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();pins=json.loads((q/'results/first/INPUTS.json').read_text());assert all(h(project/p)==s for p,s in pins.items());env=os.environ.copy();env['GODOT_SILENCE_ROOT_WARNING']='1'
for key,n in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_CACHE_HOME','cache'),('XDG_DATA_HOME','data')]:p=out/'private-profile'/n;p.mkdir(parents=True);env[key]=str(p)
commands=[]
for name,script,args in [('settlement','independent_scavenger_settlement.gd',[str(out/'settlement.json')]),('source-icon','independent_scavenger_icon.gd',['write-oracle',str(out/'source-icon-oracle.json')])]:
 p=q/'checks'/script;shutil.copy2(p,out/script);commands.append((name,p,args))
(out/'PLAN.json').write_text(json.dumps({'inputs_sha256':h(q/'results/first/INPUTS.json'),'scripts':{p.name:h(p) for _,p,_ in commands},'source':'exact703 independent copied candidate, reused imported cache','budget_per_case':180,'stop_on_first_failure':True},indent=2)+'\n');rows=[]
for name,script,args in commands:
 start=time.monotonic();code=None;timeout=False
 try:
  proc=subprocess.run(['/usr/local/bin/godot','--headless','--audio-driver','Dummy','--path',str(project),'--script',str(script),'--',*args],env=env,capture_output=True,timeout=180);stdout=proc.stdout;stderr=proc.stderr;code=proc.returncode
 except subprocess.TimeoutExpired as e:stdout=e.stdout or b'';stderr=e.stderr or b'';timeout=True
 (out/(name+'.stdout')).write_bytes(stdout);(out/(name+'.stderr')).write_bytes(stderr);text=(stdout+stderr).decode(errors='replace');reports=[]
 for line in text.splitlines():
  try:d=json.loads(line)
  except:continue
  if type(d) is dict and 'failures' in d:reports.append(d)
 semantic=len(reports)==1 and reports[0]['failures']==[];error=any(s in text for s in ['ERROR:','SCRIPT ERROR:','instances leaked','resources still in use']);row={'case':name,'native_exit':code,'timeout':timeout,'elapsed':round(time.monotonic()-start,3),'semantic':semantic,'error':error,'checks':reports[0].get('checks') if reports else None};row['pass']=code==0 and not timeout and semantic and not error;rows.append(row);(out/'STEPS.json').write_text(json.dumps(rows,indent=2)+'\n');print(json.dumps(row),flush=True)
 if not row['pass']:raise SystemExit(1)
changed=[p for p,s in pins.items() if h(project/p)!=s];result={'pass':not changed,'steps':rows,'source_changes':changed,'scope':'Independent selected source settlement and dedicated source SVG texture oracle; not packed or native results'};(out/'RESULT.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result));raise SystemExit(0 if result['pass'] else 1)
