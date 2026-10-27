from pathlib import Path
import json,hashlib,subprocess,os,time
r=Path('<WORKSPACE_ROOT>/shared');q=Path(__file__).parent;s=r/'moss-v38-svg-candidate';out=q/'packed-first';assert not out.exists();out.mkdir();h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();plan=json.load(open(q/'PACKED_EXECUTION_PLAN.json'));pins=dict(plan['pins']);pins[str(q/'PACKED_EXECUTION_PLAN.json')]=h(q/'PACKED_EXECUTION_PLAN.json');source=json.load(open(r/'moss-v38-svg-candidate-prep/FINAL_INPUTS.json'))
def guard():
 assert all(h(Path(n))==v for n,v in pins.items());assert all(h(s/n)==v for n,v in source.items())
guard();(out/'PINS_BEFORE.json').write_text(json.dumps(pins,indent=2)+'\n');env=os.environ.copy()
for k,n in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_DATA_HOME','data'),('XDG_CACHE_HOME','cache')]:
 (out/n).mkdir();env[k]=str(out/n)
(out/'empty-reader').mkdir();rows=[]
for name,key,count,helpercount in [('assets','checks',121,0),('actor','passed',418,1),('animation','independent_actions_passed',35,1)]:
 cmd=['godot','--headless','--audio-driver','Dummy','--main-pack',plan['pck'],'--script',str(q/'packed-harness'/(name+'.gd'))]
 if name=='assets':cmd+=['--','--expected-imported',str(q/'SOURCE_IMPORTED_BASELINE.json')]
 start=time.monotonic();timeout=False
 try:z=subprocess.run(cmd,cwd=out/'empty-reader',env=env,capture_output=True,timeout=180);a,b,code=z.stdout,z.stderr,z.returncode
 except subprocess.TimeoutExpired as e:a,b,code=e.stdout or b'',e.stderr or b'',124;timeout=True
 (out/(name+'.stdout')).write_bytes(a);(out/(name+'.stderr')).write_bytes(b);reports=[];helpers=[];errors=[]
 for line in a.decode(errors='replace').splitlines():
  try:
   if line.startswith('{'):reports.append(json.loads(line))
   elif line.startswith('TEST_AUDIO_TEARDOWN '):helpers.append(json.loads(line.split(' ',1)[1]))
  except ValueError as e:errors.append(str(e))
 clean=not errors and not any(x in (a+b).decode(errors='replace') for x in ['ERROR:','instances leaked','resources still in use']);semantic=len(reports)==1 and reports[0].get(key)==count and reports[0].get('failures')==[] and (name!='assets' or reports[0].get('pass') is True);cleanup=len(helpers)==helpercount
 for x in helpers:
  try:
   z=x['observations'][-1];cleanup=cleanup and x['complete'] and x['capture_removed'] and not x['prepare_errors'] and x['requested_owner_count']==x['tracked_owner_count']>0 and x['tracked_stream_count']>0 and z['owners_released'] and z['streams_released'] and z['new_pushed']>=z['required_frames']>0 and z['silent_frames']>=z['required_frames'] and 150000<=z['elapsed_us']<=1000000 and all(v['invalid']==v['discarded']==0 for v in x['observations'])
  except (KeyError,IndexError,TypeError):cleanup=False
 row=dict(case=name,native_exit=code,timeout=timeout,seconds=round(time.monotonic()-start,3),clean=clean,semantic=semantic,helper_ok=cleanup,reports=reports,helpers=helpers,parse_errors=errors);row['pass']=code==0 and clean and semantic and cleanup;rows.append(row);(out/'STEPS.json').write_text(json.dumps(rows,indent=2)+'\n');print(json.dumps({k:v for k,v in row.items() if k not in ['reports','helpers']}),flush=True)
 if not row['pass']:break
guard();(out/'PINS_AFTER.json').write_text(json.dumps(pins,indent=2)+'\n');result={'pass':len(rows)==3 and all(x['pass'] for x in rows),'source_inputs_unchanged':len(source),'scope':'New SVG exactPCK121 imported pixel/Atlas plus418actor/35animation, unchanged gameplay scope notrerunfull139/ordinary.','pck_sha256':h(Path(plan['pck']))};(out/'RESULT.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result),flush=True);raise SystemExit(0 if result['pass'] else 1)
