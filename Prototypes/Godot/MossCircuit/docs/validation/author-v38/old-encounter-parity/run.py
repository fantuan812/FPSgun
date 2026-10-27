from pathlib import Path
import json,hashlib,subprocess,os,time
root=Path('workspace/shared');here=root/'moss-v38-parity';source=root/'moss-v38-work';plan_path=here/'PLAN.json';plan=json.loads(plan_path.read_text());h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();mapping=Path(plan['source_map']);assert h(mapping)==plan['source_map_sha256'];source_pins=json.loads(mapping.read_text());pins={str(mapping):h(mapping),str(plan_path):h(plan_path),str(here/'run.py'):h(here/'run.py')}
for name,sha in plan['inputs'].items():pins[str(here/name)]=sha
for route in plan['routes']:
 for pathkey,hashkey in [('fixture','fixture_sha256'),('original','original_sha256'),('retained_trace','retained_sha256')]:pins[route[pathkey]]=route[hashkey]
assert all((source/n).is_file() and h(source/n)==sha for n,sha in source_pins.items());assert all(h(Path(n))==sha for n,sha in pins.items())
out=here/'results';assert not out.exists();out.mkdir();(out/'PINS_BEFORE.json').write_text(json.dumps(pins,indent=2)+'\n');env=os.environ.copy()
for key,name in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_DATA_HOME','data'),('XDG_CACHE_HOME','cache')]:
 (out/name).mkdir();env[key]=str(out/name)
rows=[]
for route in plan['routes']:
 name=route['name'];trace=out/(name+'.json');start=time.monotonic();timed_out=False
 try:
  p=subprocess.run(['godot','--headless','--audio-driver','Dummy','--path',str(source),'--script',route['fixture'],'--',str(trace)],capture_output=True,env=env,timeout=180);stdout,stderr,code=p.stdout,p.stderr,p.returncode
 except subprocess.TimeoutExpired as e:stdout,stderr,code=e.stdout or b'',e.stderr or b'',124;timed_out=True
 (out/(name+'.stdout')).write_bytes(stdout);(out/(name+'.stderr')).write_bytes(stderr);text=(stdout+stderr).decode(errors='replace');reports=[];helpers=[];parse_errors=[]
 for line in stdout.decode(errors='replace').splitlines():
  try:
   if line.startswith('{'):reports.append(json.loads(line))
   elif line.startswith('TEST_AUDIO_TEARDOWN '):helpers.append(json.loads(line[len('TEST_AUDIO_TEARDOWN '):]))
  except (ValueError,TypeError) as e:parse_errors.append(str(e))
 clean=not parse_errors and not any(x in text for x in ['ERROR:','instances leaked','resources still in use'])
 semantic=len(reports)==1 and reports[0].get('cases')==route['case_count'] and reports[0].get('failures')==[]
 helper_ok=len(helpers)==1 and helpers[0].get('complete') is True and helpers[0].get('capture_removed') is True and not helpers[0].get('prepare_errors')
 if helper_ok:
  last=helpers[0]['observations'][-1];helper_ok=last.get('owners_released') is True and last.get('streams_released') is True and last.get('new_pushed',0)>=last['required_frames'] and last.get('silent_frames',0)>=last['required_frames'] and last.get('discarded')==0 and last.get('invalid')==0 and last.get('elapsed_us',1000001)<=1000000
 equal=trace.exists() and trace.read_bytes()==Path(route['retained_trace']).read_bytes()
 row={'name':name,'native_exit':code,'timeout':timed_out,'seconds':round(time.monotonic()-start,3),'clean':clean,'semantic':semantic,'helper_ok':helper_ok,'parse_errors':parse_errors,'whole_trace_equal_held':equal,'trace_sha256':h(trace) if trace.exists() else None,'pass':code==0 and clean and semantic and helper_ok and equal};rows.append(row);(out/'STEPS.json').write_text(json.dumps(rows,indent=2)+'\n');print(json.dumps(row),flush=True)
 if not row['pass']:break
source_changes=[n for n,sha in source_pins.items() if not (source/n).is_file() or h(source/n)!=sha];input_changes=[n for n,sha in pins.items() if not Path(n).is_file() or h(Path(n))!=sha];after={n:h(Path(n)) if Path(n).is_file() else None for n in pins};(out/'PINS_AFTER.json').write_text(json.dumps(after,indent=2)+'\n');result={'pass':len(rows)==2 and all(x['pass'] for x in rows) and not source_changes and not input_changes,'commands_executed':len(rows),'source_changes':source_changes,'input_changes':input_changes,'scope':plan['scope']};(out/'RESULT.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result),flush=True);raise SystemExit(0 if result['pass'] else 1)
