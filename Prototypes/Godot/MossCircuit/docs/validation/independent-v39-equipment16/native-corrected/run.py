#!/usr/bin/env python3
"""Exact-PCK native developer gate; no execution before QA freezes approval."""
import hashlib,json,os,pathlib,subprocess,sys,time,math
from PIL import Image
Q=pathlib.Path('<WORKSPACE>/moss-v39-ui/equipment16-native-r2');plan_bytes=(Q/'PLAN.json').read_bytes();plan=json.loads(plan_bytes)
assert len(sys.argv)==2 and hashlib.sha256(plan_bytes).hexdigest()==sys.argv[1],'fixed CLI plan SHA required'
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
  obs=x['observations'];last=obs[-1];required=last['required_frames'];mix=x['mix_rate']
  if type(mix) not in (int,float) or not math.isfinite(mix) or mix<=0:return False
  if type(required) is not int or required!=math.ceil(mix*.15):return False
  return (x['complete'] is True and x['capture_removed'] is True and x['prepare_errors']==[] and x['requested_owner_count']==1 and x['tracked_owner_count']==1 and x['tracked_stream_count']>0 and x['game_owner_count']==1 and required>0 and 150000<=last['elapsed_us']<=1000000 and last['new_pushed']>=required and last['silent_frames']>=required and last['owners_released'] is True and last['streams_released'] is True and all(type(o['required_frames']) is int and o['required_frames']==required and o['invalid']==0 and o['discarded']==0 and o['prepare_errors']==0 and o['game_owner_count']==1 and o['owner_count']==1 for o in obs))
 except (KeyError,IndexError,TypeError,ValueError,OverflowError):return False
assert pins_ok() and snapshot(source)==snapshot(author_source)==expected,'initial pins/source mismatch'
packed_receipt=json.loads(pathlib.Path(plan['packed_receipt_path']).read_text())
assert packed_receipt.get('pass') is True and packed_receipt.get('pck_sha256')==plan['pck_sha256'] and packed_receipt.get('UI_unique_icons')==21 and packed_receipt.get('packed_UI_raw_source_imported_exact') is True,'new asset-only actual resource receipt required'
assert plan['packed_receipt_path'] in plan['pins'],'asset receipt must be pinned'
prior_plan=json.loads(pathlib.Path(plan['prior_plan']).read_text())
prior_178=json.loads(pathlib.Path(plan['prior_178_result']).read_text())
prior_cards=json.loads(pathlib.Path(plan['prior_cards_result']).read_text())
assert prior_plan['pck_sha256']==plan['pck_sha256'] and prior_178['strict_pass'] is True and prior_178['report']['checks']==178 and prior_178['report']['failures']==[],'original178 exactPCK PASS required'
assert prior_cards['strict_pass'] is False and prior_cards['report']['checks']==79 and len(prior_cards['report']['failures'])==2,'original79/2FAIL must remain'
env=os.environ.copy()
for key,folder in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_DATA_HOME','data'),('XDG_CACHE_HOME','cache')]:
 p=Q/folder;p.mkdir(exist_ok=True);env[key]=str(p)
runtime=Q/'empty-runtime';runtime.mkdir(exist_ok=True)
assert not any(runtime.iterdir()),'runtime cwd must be empty; no source fallback'
result_code=0
for phase in plan['phases']:
 name=phase['name'];out=Q/name;assert not out.exists(),'preserve original attempt';out.mkdir();images=out/'images';images.mkdir()
 env['MOSS_A_UI_IMAGES']=str(images);env['MOSS_A_HUD_IMAGES']=str(images);env['MOSS_PCK_BUTTON_IMAGES']=str(images);env['MOSS_E16_IMAGES']=str(images)
 errors=[];json_errors=[];reports=[];teardowns=[];sizes=[];image_sizes=[];rc=None;timed_out=False;elapsed_seconds=0.0;started=False;text='';before={};author_before={};after={};author_after={};pins_after=False
 try:
  before=snapshot(source);author_before=snapshot(author_source);save(out/'SOURCE_BEFORE.json',before);save(out/'AUTHOR_SOURCE_BEFORE.json',author_before)
  if not (before==author_before==expected and pins_ok()):raise RuntimeError('phase preflight mismatch')
  cmd=['godot','--path',str(runtime),'--main-pack',plan['pck_path'],'--audio-driver','Dummy','--resolution','960x540','--position','0,60','--script',phase['script']]
  if phase.get('args'):cmd+=['--']+phase['args']
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
   for marker,target in [('TEST_AUDIO_TEARDOWN ',teardowns),('UI_NATIVE_DIMENSIONS ',sizes),('UI_IMAGE_DIMENSIONS ',image_sizes),('E16_NATIVE_IMAGE ',image_sizes)]:
    if line.startswith(marker):bucket=target;payload=line[len(marker):];break
   if payload is None and line.startswith('{'):payload=line;bucket=reports
   if payload is None and any(marker in line for marker in ['TEST_AUDIO_TEARDOWN','UI_NATIVE_DIMENSIONS','UI_IMAGE_DIMENSIONS','E16_NATIVE_IMAGE','\"checks\"','\"failures\"']):
    json_errors.append({'line':n,'raw':line,'error':'known JSON marker with invalid prefix'})
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
 report=reports[0] if len(reports)==1 else {};report_ok=False;decoded=[];actual_images=[];image_ok=False;helper_ok=False
 try:
  report_ok=isinstance(report,dict) and type(report.get('checks')) is int and report['checks']==phase['expected_checks'] and isinstance(report.get('failures'),list) and report['failures']==[]
  if 'expected_records' in phase:
   records=report.get('records');report_ok=report_ok and isinstance(records,list) and len(records)==phase['expected_records'] and all(isinstance(x,dict) for x in records)
  if 'expected_groups' in phase:
   groups=report.get('groups');report_ok=report_ok and isinstance(groups,list) and len(groups)==phase['expected_groups'] and all(isinstance(x,dict) for x in groups)
   if report_ok:report_ok=sorted(x.get('id','') for x in records)==sorted(phase['expected_ids']) and sorted(x.get('name','') for x in groups)==['expansion_A','legacy_first','legacy_rest'] and all(type(x.get('save_error')) is int and x['save_error']==0 for x in records) and sorted(x.get('image','') for x in records)==sorted(phase['expected_images'])
  helper_ok=len(teardowns)==1 and strict_audio(teardowns[0])
  actual_images=sorted(p.name for p in images.glob('*.png'));image_ok=actual_images==sorted(phase['expected_images'])
  for image_name in actual_images:
   f=images/image_name
   with Image.open(f) as im:
    im.load();decoded.append({'name':image_name,'format':im.format,'size':list(im.size),'sha256':digest(f)})
   if decoded[-1]['format']!='PNG' or decoded[-1]['size']!=[960,540]:image_ok=False
 except Exception as e:
  errors.append('result schema/image validation: '+repr(e));report_ok=False;image_ok=False
 strict=(not errors and not json_errors and started and not timed_out and 0<elapsed_seconds<=180 and rc==0 and report_ok and helper_ok and image_ok and bool(sizes) and after==before==author_before==author_after==expected and pins_after and not any(x in text for x in ['SCRIPT ERROR','Parse Error','ERROR:','ObjectDB instances leaked','resources still in use']))
 result={'phase':name,'exit':rc,'monotonic_seconds':elapsed_seconds,'timeout':timed_out,'strict_pass':strict,'runner_errors':errors,'json_marker_errors':json_errors,'report':report,'helper_pass':helper_ok,'helper_records':teardowns,'dimensions':sizes,'image_dimensions':image_sizes,'image_names':actual_images,'decoded_images':decoded,'expected_image_names_match':image_ok,'source_before_after_expected_equal':after==before==author_before==author_after==expected,'all_pins_and_same_plan_after':pins_after,'visual_pixels_reviewed':False,'scope':'exact PCK controlled UI, not ordinary acquisition or hardware mouse'}
 save(out/'RESULT.json',result);print(json.dumps(result))
 if not strict:result_code=1;break
(Q/'validation.exit').write_text(str(result_code)+'\n');sys.exit(result_code)
