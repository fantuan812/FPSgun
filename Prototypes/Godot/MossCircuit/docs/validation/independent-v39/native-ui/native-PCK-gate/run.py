#!/usr/bin/env python3
"""Exact-PCK native developer gate; no execution before QA freezes approval."""
import hashlib,json,os,pathlib,subprocess,sys,time
Q=pathlib.Path('<WORKSPACE>/moss-v39-ui/native-PCK-gate');plan_bytes=(Q/'PLAN.json').read_bytes();plan=json.loads(plan_bytes)
assert plan['status']=='FROZEN_QA_APPROVED','exact PCK identity and QA approval required'
assert os.environ.get('DISPLAY') or os.environ.get('WAYLAND_DISPLAY'),'native display required; no headless fallback'
assert not (Q/'validation.exit').exists(),'no automatic rerun'
freeze_sha=hashlib.sha256(plan_bytes).hexdigest();source=pathlib.Path(plan['source_path']);author_source=pathlib.Path(plan['original_source_path']);expected=json.loads(pathlib.Path(plan['source_input_map_path']).read_text())
def digest(p):return hashlib.sha256(pathlib.Path(p).read_bytes()).hexdigest()
def pins_ok():return all(pathlib.Path(p).is_file() and digest(p)==s for p,s in plan['pins'].items())
def snapshot(root):return {str(p.relative_to(root)):digest(p) for p in root.rglob('*') if p.is_file() and '.godot' not in p.relative_to(root).parts}
def save(p,x):p.write_text(json.dumps(x,indent=2)+'\n')
def strict_audio(x):
 try:
  obs=x['observations'];last=obs[-1];required=last['required_frames']
  return (x['complete'] is True and x['capture_removed'] is True and x['prepare_errors']==[] and x['requested_owner_count']==1 and x['tracked_owner_count']==1 and x['tracked_stream_count']>0 and x['game_owner_count']==1 and required>0 and 150000<=last['elapsed_us']<=1000000 and last['new_pushed']>=required and last['silent_frames']>=required and last['owners_released'] is True and last['streams_released'] is True and all(o['invalid']==0 and o['discarded']==0 and o['prepare_errors']==0 and o['game_owner_count']==1 and o['owner_count']==1 for o in obs))
 except (KeyError,IndexError,TypeError):return False
assert pins_ok() and snapshot(source)==snapshot(author_source)==expected,'initial pins/source mismatch'
packed_receipt=json.loads(pathlib.Path(plan['packed_receipt_path']).read_text())
assert packed_receipt.get('pass') is True and packed_receipt.get('completed')==17 and packed_receipt.get('pck_sha256')==plan['pck_sha256'] and packed_receipt.get('source_map_sha256')==digest(plan['source_input_map_path']),'independent packed17 actual PASS required'
assert plan['packed_receipt_path'] in plan['pins'],'packed17 receipt must be pinned'

env=os.environ.copy()
for key,folder in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_DATA_HOME','data'),('XDG_CACHE_HOME','cache')]:
 p=Q/folder;p.mkdir(exist_ok=True);env[key]=str(p)
runtime=Q/'empty-runtime';runtime.mkdir(exist_ok=True)
assert not any(runtime.iterdir()),'runtime cwd must be empty; no source fallback'
result_code=0
for phase in plan['phases']:
 name=phase['name'];out=Q/name;assert not out.exists(),'preserve original attempt';out.mkdir();images=out/'images';images.mkdir()
 env['MOSS_A_UI_IMAGES']=str(images);env['MOSS_A_HUD_IMAGES']=str(images);env['MOSS_PCK_BUTTON_IMAGES']=str(images)
 errors=[];json_errors=[];reports=[];teardowns=[];sizes=[];image_sizes=[];rc=None;timed_out=False;elapsed_seconds=0.0;started=False;text='';before={};author_before={};after={};author_after={};pins_after=False
 try:
  before=snapshot(source);author_before=snapshot(author_source);save(out/'SOURCE_BEFORE.json',before);save(out/'AUTHOR_SOURCE_BEFORE.json',author_before)
  if not (before==author_before==expected and pins_ok()):raise RuntimeError('phase preflight mismatch')
  cmd=['godot','--path',str(runtime),'--main-pack',plan['pck_path'],'--audio-driver','Dummy','--resolution','960x540','--position','0,60','--script',phase['script']]
  save(out/'COMMAND.json',{'cmd':cmd,'timeout_seconds':180,'env':{k:env.get(k) for k in ['HOME','XDG_CONFIG_HOME','XDG_DATA_HOME','XDG_CACHE_HOME','DISPLAY','WAYLAND_DISPLAY']}})
  started=True;start=time.monotonic()
  try:
   with (out/'native.log').open('wb') as log:p=subprocess.run(cmd,env=env,cwd=runtime,stdout=log,stderr=subprocess.STDOUT,timeout=180)
   rc=p.returncode
  except subprocess.TimeoutExpired:rc=124;timed_out=True
  finally:elapsed_seconds=time.monotonic()-start
  (out/'native.exit').write_text(str(rc)+'\n');text=(out/'native.log').read_text(errors='replace')
  for n,line in enumerate(text.splitlines(),1):
   bucket=None;payload=None
   for marker,target in [('TEST_AUDIO_TEARDOWN ',teardowns),('UI_NATIVE_DIMENSIONS ',sizes),('UI_IMAGE_DIMENSIONS ',image_sizes)]:
    if line.startswith(marker):bucket=target;payload=line[len(marker):];break
   if payload is None and line.startswith('{'):payload=line;bucket=reports
   if payload is not None:
    try:
     x=json.loads(payload)
     if not isinstance(x,dict):raise ValueError('marker payload not object')
     if bucket is reports and not ('checks' in x and 'failures' in x):raise ValueError('unexpected bare JSON report')
     bucket.append(x)
    except (json.JSONDecodeError,ValueError,TypeError) as e:json_errors.append({'line':n,'raw':line,'error':repr(e)})
 except Exception as e:errors.append(repr(e))
 finally:
  # Always perform both complete source readbacks and the same-freeze/all-pin checks,
  # even on timeout, parser/runtime errors or malformed report JSON.
  for root,filename,target in [(source,'SOURCE_AFTER.json','source'),(author_source,'AUTHOR_SOURCE_AFTER.json','author')]:
   try:
    value=snapshot(root);save(out/filename,value)
    if target=='source':after=value
    else:author_after=value
   except Exception as e:errors.append(filename+': '+repr(e))
  try:pins_after=pins_ok() and digest(Q/'PLAN.json')==freeze_sha
  except Exception as e:errors.append('after pins: '+repr(e))
 report=reports[0] if len(reports)==1 else {};report_ok=report.get('checks')==phase['expected_checks'] and report.get('failures')==[] and ('expected_records' not in phase or len(report.get('records',[]))==phase['expected_records'])
 helper_ok=len(teardowns)==1 and strict_audio(teardowns[0]);actual_images=sorted(p.name for p in images.glob('*.png'));image_ok=actual_images==sorted(phase['expected_images'])
 strict=(not errors and not json_errors and started and not timed_out and 0<elapsed_seconds<=180 and rc==0 and report_ok and helper_ok and image_ok and bool(sizes) and after==before==author_before==author_after==expected and pins_after and not any(x in text for x in ['SCRIPT ERROR','Parse Error','ERROR:','ObjectDB instances leaked','resources still in use']))
 result={'phase':name,'exit':rc,'monotonic_seconds':elapsed_seconds,'timeout':timed_out,'strict_pass':strict,'runner_errors':errors,'json_marker_errors':json_errors,'report':report,'helper_pass':helper_ok,'helper_records':teardowns,'dimensions':sizes,'image_dimensions':image_sizes,'image_names':actual_images,'expected_image_names_match':image_ok,'source_before_after_expected_equal':after==before==author_before==author_after==expected,'all_pins_and_same_plan_after':pins_after,'visual_pixels_reviewed':False,'scope':'exact PCK controlled UI, not ordinary acquisition or hardware mouse'}
 save(out/'RESULT.json',result);print(json.dumps(result))
 if not strict:result_code=1;break
(Q/'validation.exit').write_text(str(result_code)+'\n');sys.exit(result_code)
