from pathlib import Path
import json,hashlib,subprocess,os,time
p=Path(__file__).parent;r=Path('evidence-workspace/moss-v39-work');h=lambda x:hashlib.sha256(x.read_bytes()).hexdigest();plan=json.loads((p/'PLAN.json').read_text());source=json.loads(Path(plan['input_map']).read_text());pins=dict(plan['pins']);pins[str(p/'PLAN.json')]=h(p/'PLAN.json');out=p/'raw-first';assert not out.exists();out.mkdir();assert not(r/'.godot').exists()
assert all(h(Path(n))==v for n,v in pins.items());assert all(h(r/n)==v for n,v in source.items())
env=dict(os.environ)
for k,n in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_DATA_HOME','data'),('XDG_CACHE_HOME','cache')]: (out/n).mkdir();env[k]=str(out/n)
rows=[]
for name,args in [('cold',['--editor','--import']),('geometry',['--script',plan['geometry_script']])]:
 cmd=['godot','--headless','--audio-driver','Dummy','--path',str(r)]+args;t=time.monotonic();timed=False
 try:z=subprocess.run(cmd,env=env,capture_output=True,timeout=180);a,b,code=z.stdout,z.stderr,z.returncode
 except subprocess.TimeoutExpired as e:a,b,code=e.stdout or b'',e.stderr or b'',124;timed=True
 (out/(name+'.stdout')).write_bytes(a);(out/(name+'.stderr')).write_bytes(b);(out/(name+'.exit')).write_text(str(code)+'\n')
 reports=[];parse=[]
 for line in a.decode(errors='replace').splitlines():
  if line.startswith('{'):
   try:reports.append(json.loads(line))
   except ValueError as e:parse.append(str(e))
 clean=not parse and not any(x in (a+b).decode(errors='replace') for x in ['ERROR:','instances leaked','resources still in use'])
 semantic=len(reports)==0 if name=='cold' else len(reports)==1 and reports[0].get('pass') is True and reports[0].get('checks')==850 and reports[0].get('failures')==[] and len(reports[0].get('observations',[]))==205
 row=dict(case=name,exit=code,timeout=timed,seconds=time.monotonic()-t,clean=clean,semantic=semantic,reports=reports,parse_errors=parse);row['pass']=code==0 and clean and semantic;rows.append(row);(out/'STEPS.json').write_text(json.dumps(rows,indent=2)+'\n');print(json.dumps({k:v for k,v in row.items() if k!='reports'}),flush=True)
 if not row['pass']:break
actual={str(f.relative_to(r)):h(f) for f in sorted(r.rglob('*')) if f.is_file() and '.godot' not in f.relative_to(r).parts};changed=[n for n,v in source.items() if actual.get(n)!=v];added=sorted(set(actual)-set(source));pinchanged=[n for n,v in pins.items() if h(Path(n))!=v]
result=dict(pass_gate=len(rows)==2 and all(x['pass'] for x in rows) and not changed and not pinchanged and added==plan['exact_import_additions'],changed=changed,pinchanged=pinchanged,added=added,exact_import_additions=added==plan['exact_import_additions'],input_count=len(source),scope=plan['scope'])
(out/'RESULT.json').write_text(json.dumps(result,indent=2)+'\n');(out/'POST_INPUTS.json').write_text(json.dumps(actual,indent=2)+'\n');print(json.dumps(result),flush=True);raise SystemExit(0 if result['pass_gate'] else 1)
