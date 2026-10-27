from pathlib import Path
import json, hashlib, subprocess, os, time
p=Path(__file__).parent; r=Path('<WORKSPACE>/moss-v39-qa/policy-source')
h=lambda f:hashlib.sha256(f.read_bytes()).hexdigest()
planpath=p/'RUNTIME_EXECUTION_FREEZE.json'; planhash=h(planpath); plan=json.loads(planpath.read_text()); mp=Path(plan['input_map']); source=json.loads(mp.read_text()); pins=plan['pins']
def actual(): return {str(f.relative_to(r)):h(f) for f in sorted(r.rglob('*')) if f.is_file() and '.godot' not in f.relative_to(r).parts}
author=Path('<WORKSPACE>/moss-v39-work')
def author_actual():return {str(f.relative_to(author)):h(f) for f in sorted(author.rglob('*')) if f.is_file() and '.godot' not in f.relative_to(author).parts}
assert len(source)==836 and actual()==source and author_actual()==source
assert all(h(Path(n))==v for n,v in pins.items())
out=p/'runtime-first'; assert not out.exists(); out.mkdir()
env=dict(os.environ)
for k,n in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_DATA_HOME','data'),('XDG_CACHE_HOME','cache')]:
 (out/n).mkdir(); env[k]=str(out/n)
t=time.monotonic(); timed=False
try:
 z=subprocess.run(['godot','--headless','--audio-driver','Dummy','--path',str(r),'--script',plan['script']],capture_output=True,env=env,timeout=180); a,b,rc=z.stdout,z.stderr,z.returncode
except subprocess.TimeoutExpired as e: a,b,rc=e.stdout or b'',e.stderr or b'',124; timed=True
(out/'runtime.stdout').write_bytes(a);(out/'runtime.stderr').write_bytes(b);(out/'runtime.exit').write_text(str(rc)+'\n')
reports=[]; helpers=[]; errors=[]
for line in a.decode(errors='replace').splitlines():
 try:
  if line.startswith('{'): reports.append(json.loads(line))
  elif line.startswith('TEST_AUDIO_TEARDOWN '): helpers.append(json.loads(line.split(' ',1)[1]))
 except ValueError as e: errors.append(str(e))
clean=not errors and not any(x in (a+b).decode(errors='replace') for x in ['SCRIPT ERROR','ERROR:','instances leaked','resources still in use'])
semantic=len(reports)==1 and reports[0].get('pass') is True and reports[0].get('checks')==46 and len(reports[0].get('observations',[]))==2 and reports[0].get('failures')==[]
cleanup=len(helpers)==1
for x in helpers:
 try:
  obs=x['observations']; z=obs[-1]
  cleanup=cleanup and x['complete'] is True and x['capture_removed'] is True and x['prepare_errors']==[] and x['requested_owner_count']==x['tracked_owner_count']==x['game_owner_count']==1 and x['tracked_stream_count']>0 and z['owner_count']==z['game_owner_count']==1 and z['prepare_errors']==0 and z['owners_released'] is True and z['streams_released'] is True and z['new_pushed']>=z['required_frames']>0 and z['silent_frames']>=z['required_frames'] and 150000<=z['elapsed_us']<=1000000 and all(v['invalid']==v['discarded']==0 for v in obs)
 except (KeyError,IndexError,TypeError): cleanup=False
post=actual(); changes=[n for n in set(source)|set(post) if source.get(n)!=post.get(n)]; pinchanges=[n for n,v in pins.items() if not Path(n).exists() or h(Path(n))!=v]
result=dict(native_exit=rc,timeout=timed,seconds=time.monotonic()-t,clean=clean,semantic=semantic,helper_ok=cleanup,reports=reports,helpers=helpers,parse_errors=errors,source_changes=sorted(changes),pin_changes=pinchanges,plan_unchanged=h(planpath)==planhash,scope=plan['scope'])
author_post=author_actual();author_changes=[n for n in set(source)|set(author_post) if source.get(n)!=author_post.get(n)];result['author_source_changes']=author_changes
result['pass']=not author_changes and rc==0 and not timed and clean and semantic and cleanup and not changes and not pinchanges and result['plan_unchanged']
(out/'POST_INPUTS.json').write_text(json.dumps(post,indent=2)+'\n');(out/'RESULT.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result),flush=True)
raise SystemExit(0 if result['pass'] else 1)
