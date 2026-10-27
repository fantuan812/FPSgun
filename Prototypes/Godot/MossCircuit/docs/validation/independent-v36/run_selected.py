from pathlib import Path
import argparse,hashlib,json,os,shutil,subprocess,time,datetime,re
ap=argparse.ArgumentParser();ap.add_argument('--source',type=Path,required=True);ap.add_argument('--inputs',type=Path,required=True);ap.add_argument('--label',required=True);a=ap.parse_args();q=Path(__file__).parent;out=q/'results'/a.label;assert not out.exists();out.mkdir(parents=True);project=out/'project';project.mkdir();h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();pins=json.loads(a.inputs.read_text());assert not (project/'.godot').exists()
for rel,sha in pins.items():
 p=a.source/rel;assert p.is_file() and not p.is_symlink() and h(p)==sha;d=project/rel;d.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,d)
(out/'INPUTS.json').write_bytes(a.inputs.read_bytes());shutil.copy2(__file__,out/'executed-runner.py');env=os.environ.copy();env['GODOT_SILENCE_ROOT_WARNING']='1'
for key,n in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_CACHE_HOME','cache'),('XDG_DATA_HOME','data')]:p=out/'private-profile'/n;p.mkdir(parents=True);env[key]=str(p)
commands=[('cold-import',['--editor','--import','--quit'])]
for name in ['authority','events','views']:
 source=q/'checks'/('independent_scavenger_'+name+'.gd');p=out/source.name;shutil.copy2(source,p);commands.append((name,['--script',str(p),'--',str(out/(name+'.json'))]))
plan={'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'source':str(a.source),'input_map_sha256':h(a.inputs),'inputs':len(pins),'true_cold_copy':True,'per_case_timeout':180,'stop_on_first_failure':True,'commands':commands,'script_sha256':{p.name:h(p) for p in out.glob('*.gd')}};(out/'PLAN.json').write_text(json.dumps(plan,indent=2)+'\n');rows=[]
for name,args in commands:
 start=time.monotonic();code=None;timeout=False
 try:
  p=subprocess.run(['/usr/local/bin/godot','--headless','--audio-driver','Dummy','--path',str(project),*args],env=env,capture_output=True,timeout=180);stdout=p.stdout;stderr=p.stderr;code=p.returncode
 except subprocess.TimeoutExpired as e:stdout=e.stdout or b'';stderr=e.stderr or b'';timeout=True
 (out/(name+'.stdout')).write_bytes(stdout);(out/(name+'.stderr')).write_bytes(stderr);log=(stdout+stderr).decode(errors='replace');errors=any(x in log for x in ['ERROR:','SCRIPT ERROR:','instances leaked','resources still in use']);semantic=name=='cold-import'
 if name!='cold-import' and (out/(name+'.json')).exists():
  d=json.loads((out/(name+'.json')).read_text());semantic=d.get('checks',0)>0 and d.get('failures')==[]
 row={'case':name,'native_exit':code,'timeout':timeout,'elapsed':round(time.monotonic()-start,3),'error_or_resource_warning':errors,'semantic_pass':semantic,'pass':code==0 and not timeout and not errors and semantic};rows.append(row);(out/'STEPS.json').write_text(json.dumps(rows,indent=2)+'\n');print(json.dumps(row),flush=True)
 if not row['pass']:break
changed=[p for p,sha in pins.items() if h(project/p)!=sha];origin_changed=[p for p,sha in pins.items() if h(a.source/p)!=sha];added=[str(p.relative_to(project)) for p in project.rglob('*') if p.is_file() and '.godot' not in p.parts and str(p.relative_to(project)) not in pins]
result={'pass':len(rows)==len(commands) and all(x['pass'] for x in rows) and not changed and not origin_changed,'steps':rows,'copied_input_changes':changed,'origin_input_changes':origin_changed,'new_source_sidecars':added,'scope':'Independent exact-copy cold import and three selected controlled target scripts, not full aggregate/packed/native/ordinary acceptance'};(out/'RESULT.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result),flush=True);raise SystemExit(0 if result['pass'] else 1)
