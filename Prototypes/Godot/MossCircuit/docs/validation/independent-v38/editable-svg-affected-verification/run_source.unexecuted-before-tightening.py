from pathlib import Path
import json,hashlib,subprocess,os,time
r=Path('<WORKSPACE_ROOT>/shared');s=r/'moss-v38-svg-candidate';p=Path(__file__).parent;h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();plan=json.loads((p/'SOURCE_PLAN.json').read_text());pins=json.loads(Path(plan['input_map']).read_text());out=p/'source-first';assert not out.exists();out.mkdir();env=os.environ.copy()
for k,n in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_DATA_HOME','data'),('XDG_CACHE_HOME','cache')]:
 (out/n).mkdir();env[k]=str(out/n)
assert not (s/'.godot').exists()
meta=dict(plan['pins']);meta[str(p/'SOURCE_PLAN.json')]=h(p/'SOURCE_PLAN.json');assert all(h(Path(n))==v for n,v in meta.items());assert all(h(s/n)==v for n,v in pins.items())
rows=[]
for name,script,key,count,helpercount in [('import',None,None,None,0),('svg-assets','tests/independent_support_assets.gd','checks',120,0),('actor','tests/test_actor_actions.gd','checks',418,1),('animation','tests/independent_actions.gd','independent_actions_passed',35,1)]:
 cmd=['godot','--headless','--audio-driver','Dummy','--path',str(s)]+(['--editor','--import'] if script is None else ['--script','res://'+script]);t=time.monotonic();timeout=False
 try:z=subprocess.run(cmd,env=env,capture_output=True,timeout=180);stdout,stderr,code=z.stdout,z.stderr,z.returncode
 except subprocess.TimeoutExpired as e:stdout,stderr,code=e.stdout or b'',e.stderr or b'',124;timeout=True
 (out/(name+'.stdout')).write_bytes(stdout);(out/(name+'.stderr')).write_bytes(stderr);reports=[];helpers=[];errors=[]
 for line in stdout.decode(errors='replace').splitlines():
  try:
   if line.startswith('{'):reports.append(json.loads(line))
   elif line.startswith('TEST_AUDIO_TEARDOWN '):helpers.append(json.loads(line.split(' ',1)[1]))
  except ValueError as e:errors.append(str(e))
 clean=not errors and not any(v in (stdout+stderr).decode(errors='replace') for v in ['ERROR:','instances leaked','resources still in use']);semantic=script is None or len(reports)==1 and reports[0].get(key,reports[0].get('passed'))==count and reports[0].get('failures')==[];cleanup=len(helpers)==helpercount
 for a in helpers:
  try:
   z=a['observations'][-1];cleanup=cleanup and a['complete'] and a['capture_removed'] and not a['prepare_errors'] and a['requested_owner_count']==a['tracked_owner_count']>0 and a['tracked_stream_count']>0 and z['owners_released'] and z['streams_released'] and z['new_pushed']>=z['required_frames']>0 and z['silent_frames']>=z['required_frames'] and 150000<=z['elapsed_us']<=1000000 and all(v['invalid']==v['discarded']==0 for v in a['observations'])
  except (KeyError,IndexError,TypeError):cleanup=False
 row=dict(case=name,native_exit=code,timeout=timeout,seconds=round(time.monotonic()-t,3),clean=clean,semantic=semantic,helper_ok=cleanup,reports=reports,helpers=helpers,parse_errors=errors);row['pass']=code==0 and clean and semantic and cleanup;rows.append(row);(out/'STEPS.json').write_text(json.dumps(rows,indent=2)+'\n');print(json.dumps({k:v for k,v in row.items() if k not in ['reports','helpers']}),flush=True)
 if not row['pass']:break
changed=[n for n,v in pins.items() if not(s/n).is_file() or h(s/n)!=v];metachange=[n for n,v in meta.items() if h(Path(n))!=v];actual={str(f.relative_to(s)):h(f) for f in sorted(s.rglob('*')) if f.is_file() and '.godot' not in f.relative_to(s).parts};added=sorted(set(actual)-set(pins));allowed=all(x.startswith('art_source/stitch_drone/source/') and x.endswith('.svg.import') for x in added)
result=dict(pass_gate=len(rows)==4 and all(x['pass'] for x in rows) and not changed and not metachange and allowed,changed=changed,metadata_changes=metachange,added_import_files=added,added_allowed=allowed,scope='New SVG asset-only source gate, not rerun full139 or ordinary; old evidence remains old-hash bound.')
(out/'POSTIMPORT_INPUTS.json').write_text(json.dumps(actual,indent=2)+'\n');(out/'RESULT.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result),flush=True);raise SystemExit(0 if result['pass_gate'] else 1)
