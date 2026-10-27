"""Finite first-plan exact PCK routes. The verification plan approved partitions, not single180 acceptance."""
from pathlib import Path
import json,hashlib,subprocess,os,time,shutil,sys
q=Path(__file__).parent;r=q.parent;src=r/'moss-v37-final';project=q/'project';out=q/'packed-first';packroot=r/'moss-v37-pack';pack=packroot/'linux/MossCircuit.pck';h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
freeze=json.loads((q/'PACKED_EXECUTION_FREEZE.json').read_text());assert h(q/'PACKED_EXECUTION_PLAN.json')==freeze['plan_sha256'] and h(Path(__file__))==freeze['runner_sha256']
plan=json.loads((q/'PACKED_EXECUTION_PLAN.json').read_text());pins=json.loads((q/'FINAL_INPUTS.json').read_text());hplan=json.loads((q/'PACKED_HARNESS_FREEZE.json').read_text());audit=json.loads((q/'AUTHOR_FULL_RAW_REVIEW.json').read_text())
assert audit['status']=='PASS_INDEPENDENT_RAW_REVIEW_AUTHOR_FULL' and audit['source_map_sha256']==h(q/'FINAL_INPUTS.json')
assert h(q/'FINAL_INPUTS.json')==plan['source_map_sha256'] and h(pack)==plan['pck_sha256'] and pack.read_bytes()==(packroot/'windows/MossCircuit.pck').read_bytes()
assert all(h(src/n)==s for n,s in pins.items());assert not project.exists() and not out.exists();project.mkdir();out.mkdir()
for n in pins:
 p=project/n;p.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(src/n,p)
assert all(h(project/n)==s for n,s in pins.items())
frozen={str(src/n):s for n,s in pins.items()}|{str(project/n):s for n,s in pins.items()}|plan['execution_pins']|{str(q/'PACKED_EXECUTION_PLAN.json'):freeze['plan_sha256'],str(q/'PACKED_EXECUTION_FREEZE.json'):h(q/'PACKED_EXECUTION_FREEZE.json'),str(Path(__file__)):freeze['runner_sha256']}
assert all(h(Path(n))==s for n,s in frozen.items());(out/'INPUT_PINS_BEFORE.json').write_text(json.dumps(frozen,indent=2)+'\n');reader=out/'empty-reader';reader.mkdir();rows=[]
def run(name,args,expected_checks=None,needs_helper=False,report_file=None,cwd=reader):
 env=os.environ.copy();env['GODOT_SILENCE_ROOT_WARNING']='1'
 for key,folder in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_DATA_HOME','data'),('XDG_CACHE_HOME','cache')]:
  p=out/'profiles'/name/folder;p.mkdir(parents=True);env[key]=str(p)
 start=time.monotonic();timeout=False
 try:
  p=subprocess.run(args,cwd=cwd,env=env,capture_output=True,timeout=180);stdout,stderr,code=p.stdout,p.stderr,p.returncode
 except subprocess.TimeoutExpired as e:stdout,stderr,code=e.stdout or b'',e.stderr or b'',124;timeout=True
 (out/(name+'.stdout')).write_bytes(stdout);(out/(name+'.stderr')).write_bytes(stderr);text=(stdout+stderr).decode(errors='replace');reports=[];helpers=[];parse_error=''
 try:
  for line in stdout.decode(errors='replace').splitlines():
   if line.startswith('TEST_AUDIO_TEARDOWN '):helpers.append(json.loads(line.removeprefix('TEST_AUDIO_TEARDOWN ')))
   elif line.startswith('{'):
    try:reports.append(json.loads(line))
    except json.JSONDecodeError:pass
  if report_file is not None:reports.append(json.loads(report_file.read_text()))
 except (ValueError,OSError) as e:parse_error=repr(e)
 clean=not any(x in text for x in ['ERROR:','SCRIPT ERROR:','instances leaked','resources still in use']);semantic=True;helper_clean=not needs_helper
 if expected_checks is not None:semantic=bool(reports and reports[-1].get('checks')==expected_checks and reports[-1].get('failures')==[])
 if name=='python-export-safety':semantic='Ran 3 tests' in text and any(line.strip()=='OK' for line in text.splitlines())
 if needs_helper:
  helper_clean=len(helpers)==1
  for d in helpers:
   try:
    z=d['observations'][-1];helper_clean=helper_clean and d['complete'] and d['capture_removed'] and not d['prepare_errors'] and d['requested_owner_count']==d['tracked_owner_count']>0 and d['game_owner_count']>0 and d['tracked_stream_count']>0 and z['owners_released'] and z['streams_released'] and z['new_pushed']>=z['required_frames']>0 and z['silent_frames']>=z['required_frames'] and 150000<=z['elapsed_us']<=1000000 and all(o['invalid']==o['discarded']==0 for o in d['observations'])
   except (KeyError,IndexError,TypeError):helper_clean=False
 row={'case':name,'native_exit':code,'timeout':timeout,'seconds':round(time.monotonic()-start,3),'clean':clean,'semantic':semantic,'helper_clean':helper_clean,'parse_error':parse_error,'reports':reports,'helpers':helpers,'pass':code==0 and not timeout and clean and semantic and helper_clean and not parse_error};rows.append(row);(out/'STEPS.json').write_text(json.dumps(rows,indent=2)+'\n');print(json.dumps({k:v for k,v in row.items() if k not in ['reports','helpers']}),flush=True)
 if not row['pass']:raise RuntimeError('Rejected '+name+'; no retry')
 return reports
failure=''
try:
 run('source-cold-import',['godot','--headless','--audio-driver','Dummy','--path',str(project),'--editor','--import','--quit'])
 exact={};images={}
 for folder in ['scripts','ui','data','assets']:
  for p in (project/folder).rglob('*'):
   if not p.is_file():continue
   rel=p.relative_to(project).as_posix()
   if rel=='ui/test_ui.gd':continue
   if p.suffix in ['.gd','.json']:exact[rel]=h(p)
   if p.suffix=='.png':images[rel]={}
 exact['art_source/alpha_bounds.json']=h(project/'art_source/alpha_bounds.json');assert len(exact)==70 and len(images)==58
 expected=out/'expected-resources.json';expected.write_text(json.dumps({'exact_files':exact,'images':images},indent=2)+'\n');oracle=out/'source-imported-fingerprints.json'
 run('source-resource-fingerprint',['godot','--headless','--audio-driver','Dummy','--path',str(project),'--script','res://tools/export_source_fingerprint.gd','--',str(expected),str(oracle)])
 assert json.loads(oracle.read_text())==json.loads((packroot/'source-imported-fingerprints.json').read_text())
 run('packed-resources',['godot','--headless','--audio-driver','Dummy','--main-pack',str(pack),'--script',str(project/'tools/verify_export_pack.gd'),'--',str(oracle),str(out/'resources.json')],862,report_file=out/'resources.json')
 for binding in hplan['bindings']:
  name=binding['case'];cmd=['godot','--headless','--audio-driver','Dummy','--main-pack',str(pack),'--script',binding['script']];result=None
  if name.startswith('audio-'):
   result=out/(name+'.json');cmd+=['--',str(result)]
   if name=='audio-mixer':cmd.append(str(out/'audio-mixer-raw'))
  run(name,cmd,binding['expected_checks'],binding['helper_required'],result)
  if name=='audio-mixer':
   import struct,math
   d=json.loads(result.read_text());windows=d['windows'];assert len(windows)==51 and d['status']=='PASS' and d['checks']==236 and d['failures']==[]
   for w in windows:assert w['discarded_before']==w['discarded_after']==0 and w['nonfinite']==0 and w['fresh_pushed_frames']>=2048 and w['frames']>=2048 and w['pushed_after']-w['pushed_before']==w['fresh_pushed_frames']
   raw=list(sorted((out/'audio-mixer-raw').glob('*.f32le')));assert len(raw)==7;raw_rows=[]
   for f in raw:
    data=f.read_bytes();ws=[w for w in windows if w.get('raw_file')==f.name];assert len(ws)==1 and h(f)==ws[0]['pcm_f32le_stereo_sha256'] and len(data)==ws[0]['frames']*8
    samples=struct.unpack('<'+'f'*(len(data)//4),data);assert all(math.isfinite(x) for x in samples);peak=max(abs(x) for x in samples);rms=math.sqrt(sum(x*x for x in samples)/len(samples));assert abs(peak-ws[0]['peak'])<1e-6 and abs(rms-ws[0]['rms'])<1e-6;raw_rows.append({'file':f.name,'sha256':h(f),'frames':len(data)//8,'finite':True,'peak_rms_match':True})
   (out/'MIXER_RAW_READBACK.json').write_text(json.dumps({'pass':True,'windows':51,'raw':raw_rows,'cleanup':'original dedicated capture/bus-layout/weakref checks among236, no shared helper expected','queued_start_windows':[w for w in windows if w['queued_frames_at_start']>0],'scope':'at least2048 fresh AND read per window, not a claim all frames freshly pushed; Dummy internal capture only'},indent=2)+'\n')
 icon=run('packed-svg',['godot','--headless','--audio-driver','Dummy','--main-pack',str(pack),'--script',str(q/'packed-harness/independent_scavenger_icon.gd'),'--','verify',str(q/'packed-harness/svg-oracle.json')])
 assert len(icon)==1 and icon[0]['status']=='PASS' and icon[0]['failures']==[]
 run('python-pcm',['python',str(q/'packed-harness/independent_feedback_pcm.py'),str(project),str(out/'pcm.json')],38,report_file=out/'pcm.json')
 run('python-export-safety',['python',str(project/'tests/test_export_tools.py')])
 assert len(rows)==14, len(rows)
except Exception as e:failure=repr(e)
after={n:h(Path(n)) if Path(n).is_file() else None for n in frozen};(out/'INPUT_PINS_AFTER.json').write_text(json.dumps(after,indent=2)+'\n');changed=[n for n in frozen if after[n]!=frozen[n]]
summary={'status':'PASS_INDEPENDENT_PACKED_FINITE_SCOPE' if not failure and not changed else 'REJECTED_INDEPENDENT_PACKED_FIRST','pass':not failure and not changed,'exception':failure,'changed_frozen_inputs':changed,'completed':len(rows),'pck_sha256':h(pack),'source_map_sha256':plan['source_map_sha256'],'scope':'Independent exactfinal cold copy/resource fingerprints, 4forecasts, mixer/views, explicit Arena435/Rooms338 each180 total360 authority, SVG/PCM/export safety; no singlepacked180 authority pass claim. Native/ordinary pending.'};(out/'SUMMARY.json').write_text(json.dumps(summary,indent=2)+'\n');print(json.dumps(summary),flush=True);sys.exit(0 if summary['pass'] else 1)
