from pathlib import Path
import json,hashlib,subprocess,os,time
p=Path(__file__).parent;r=Path('evidence-workspace/moss-v39-r2');h=lambda f:hashlib.sha256(f.read_bytes()).hexdigest();pp=p/'PLAN.json';ph=h(pp);plan=json.loads(pp.read_text());source=json.loads(Path(plan['input_map']).read_text());pins=plan['pins']
def actual():return {str(f.relative_to(r)):h(f) for f in r.rglob('*') if f.is_file() and '.godot' not in f.relative_to(r).parts}
assert len(source)==853 and actual()==source;assert all(h(Path(n))==v for n,v in pins.items());out=p/'raw-first';assert not out.exists();out.mkdir();env=dict(os.environ)
for k,n in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_DATA_HOME','data'),('XDG_CACHE_HOME','cache')]:
 (out/n).mkdir();env[k]=str(out/n)
rows=[]
for route in plan['routes']:
 name=route['name'];trace=out/(name+'.json');t=time.monotonic();timed=False
 try:z=subprocess.run(['godot','--headless','--audio-driver','Dummy','--path',str(r),'--script',route['fixture'],'--',str(trace)],env=env,capture_output=True,timeout=180);a,b,rc=z.stdout,z.stderr,z.returncode
 except subprocess.TimeoutExpired as e:a,b,rc=e.stdout or b'',e.stderr or b'',124;timed=True
 (out/(name+'.stdout')).write_bytes(a);(out/(name+'.stderr')).write_bytes(b);(out/(name+'.exit')).write_text(str(rc)+'\n');reports=[];helpers=[];errors=[]
 for line in a.decode(errors='replace').splitlines():
  try:
   if line.startswith('{'):reports.append(json.loads(line))
   elif line.startswith('TEST_AUDIO_TEARDOWN '):helpers.append(json.loads(line.split(' ',1)[1]))
  except ValueError as e:errors.append(str(e))
 clean=not errors and not any(x in a+b for x in [b'SCRIPT ERROR',b'ERROR:',b'instances leaked',b'resources still in use']);semantic=len(reports)==1 and reports[0].get('cases')==route['case_count'] and reports[0].get('failures')==[];cleanup=len(helpers)==1
 for x in helpers:
  try:
   obs=x['observations'];z=obs[-1];cleanup=cleanup and x['complete'] is True and x['capture_removed'] is True and x['prepare_errors']==[] and x['requested_owner_count']==x['tracked_owner_count']==x['game_owner_count']==1 and x['tracked_stream_count']>0 and z['owner_count']==z['game_owner_count']==1 and z['owners_released'] is True and z['streams_released'] is True and z['new_pushed']>=z['required_frames']>0 and z['silent_frames']>=z['required_frames'] and 150000<=z['elapsed_us']<=1000000 and all(v['invalid']==v['discarded']==v['prepare_errors']==0 for v in obs)
  except(KeyError,IndexError,TypeError):cleanup=False
 equal=trace.is_file() and trace.read_bytes()==Path(route['retained_trace']).read_bytes();row=dict(name=name,native_exit=rc,timeout=timed,seconds=time.monotonic()-t,clean=clean,semantic=semantic,helper_ok=cleanup,whole_trace_equal_held=equal,trace_sha256=h(trace) if trace.exists() else None,reports=reports,helpers=helpers,parse_errors=errors);row['pass']=rc==0 and not timed and clean and semantic and cleanup and equal;rows.append(row);(out/'STEPS.json').write_text(json.dumps(rows,indent=2)+'\n');print(json.dumps({k:v for k,v in row.items() if k not in ['reports','helpers']}),flush=True)
 if not row['pass']:break
post=actual();pinchanged=[n for n,v in pins.items() if not Path(n).is_file() or h(Path(n))!=v];result={'pass':len(rows)==2 and all(x['pass'] for x in rows) and post==source and not pinchanged and h(pp)==ph,'source853_unchanged':post==source,'pinchanged':pinchanged,'plan_unchanged':h(pp)==ph,'scope':plan['scope']};(out/'POST_INPUTS.json').write_text(json.dumps(post,indent=2)+'\n');(out/'RESULT.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result),flush=True);raise SystemExit(0 if result['pass'] else 1)
