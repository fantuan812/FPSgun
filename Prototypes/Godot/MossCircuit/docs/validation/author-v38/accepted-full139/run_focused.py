from pathlib import Path
import json,hashlib,subprocess,os,time
r=Path('workspace/shared');s=r/'moss-v38-final-r2';p=Path(__file__).parent;h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();mapping=p/'FINAL_INPUTS.json';pins=json.loads(mapping.read_text());assert len(pins)==772 and all(h(s/n)==v for n,v in pins.items());out=p/'focused';assert not out.exists();out.mkdir();env=os.environ.copy()
for k,n in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_DATA_HOME','data'),('XDG_CACHE_HOME','cache')]:
 (out/n).mkdir();env[k]=str(out/n)
cases=[('arena','independent_feedback_authority.gd',435,1),('rooms','independent_feedback_authority_rooms.gd',338,1),('settlement','independent_settlement_types.gd',1164,2),('actor','test_actor_actions.gd',418,1),('support-death','independent_support_death_disposal.gd',8,1),('support-assets','independent_support_assets.gd',120,0)]
metadata={str(mapping):h(mapping),str(Path(__file__)):h(Path(__file__)),str(p/'REVISION_PLAN.json'):h(p/'REVISION_PLAN.json')};(out/'PLAN.json').write_text(json.dumps({'cases':cases,'source_map_sha256':h(mapping),'source_inputs':772,'per_command_seconds':180,'source_audio_explicit_total_max_seconds':360,'stop_first_rejection':True,'metadata_pins':metadata},indent=2)+'\n');rows=[]
for name,filename,count,helpercount in cases:
 t=time.monotonic();timeout=False;cmd=['godot','--headless','--audio-driver','Dummy','--path',str(s),'--script','res://tests/'+filename]
 if name in ['arena','rooms','settlement']:cmd+=['--',str(out/(name+'.json'))]
 try:
  result=subprocess.run(cmd,env=env,capture_output=True,timeout=180);stdout,stderr,code=result.stdout,result.stderr,result.returncode
 except subprocess.TimeoutExpired as e:stdout,stderr,code=e.stdout or b'',e.stderr or b'',124;timeout=True
 (out/(name+'.stdout')).write_bytes(stdout);(out/(name+'.stderr')).write_bytes(stderr);reports=[];helpers=[];errors=[]
 for line in stdout.decode(errors='replace').splitlines():
  try:
   if line.startswith('{'):reports.append(json.loads(line))
   elif line.startswith('TEST_AUDIO_TEARDOWN '):helpers.append(json.loads(line.split(' ',1)[1]))
  except ValueError as e:errors.append(str(e))
 clean=not errors and not any(z in (stdout+stderr).decode(errors='replace') for z in ['ERROR:','instances leaked','resources still in use']);semantic=len(reports)==1 and reports[0].get('checks',reports[0].get('passed'))==count and reports[0].get('failures')==[]
 cleanup=len(helpers)==helpercount
 for helper in helpers:
  try:
   last=helper['observations'][-1];cleanup=cleanup and helper['complete'] and helper['capture_removed'] and not helper['prepare_errors'] and helper['requested_owner_count']==helper['tracked_owner_count']>0 and helper['tracked_stream_count']>0 and last['owners_released'] and last['streams_released'] and last['new_pushed']>=last['required_frames']>0 and last['silent_frames']>=last['required_frames'] and 150000<=last['elapsed_us']<=1000000 and all(z['invalid']==z['discarded']==0 for z in helper['observations'])
  except (KeyError,IndexError,TypeError):cleanup=False
 row={'case':name,'native_exit':code,'timeout':timeout,'seconds':round(time.monotonic()-t,3),'clean':clean,'semantic':semantic,'helper_ok':cleanup,'parse_errors':errors,'reports':reports,'helpers':helpers,'pass':code==0 and clean and semantic and cleanup};rows.append(row);(out/'STEPS.json').write_text(json.dumps(rows,indent=2)+'\n');print(json.dumps({k:v for k,v in row.items() if k not in ['reports','helpers']}),flush=True)
 if not row['pass']:break
changed=[n for n,v in pins.items() if not (s/n).is_file() or h(s/n)!=v];metachange=[n for n,v in metadata.items() if h(Path(n))!=v];x={'pass':len(rows)==len(cases) and all(z['pass'] for z in rows) and not changed and not metachange,'cases':len(rows),'planned':len(cases),'input_changes':changed,'metadata_changes':metachange,'source_map_sha256':h(mapping),'scope':'New finite changed-tests focused gate; source audio split435/338 each180,total360 distinct from original single180FAIL. Original full135/138 and settlement diagnosis retained.'};(out/'RESULT.json').write_text(json.dumps(x,indent=2)+'\n');print(json.dumps(x),flush=True);raise SystemExit(0 if x['pass'] else 1)
