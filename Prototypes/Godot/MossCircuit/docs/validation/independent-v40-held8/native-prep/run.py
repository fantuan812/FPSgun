from pathlib import Path
import json,hashlib,os,sys,subprocess,time,math,re
from PIL import Image
Q=Path(__file__).parent;R=Q.parent
H=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
def save(p,x):Path(p).write_text(json.dumps(x,indent=2)+'\n')
def snap(p):return {str(f.relative_to(p)):H(f)for f in sorted(p.rglob('*'))if f.is_file()and '.godot'not in f.relative_to(p).parts}
def audio_ok(x):
 try:
  if type(x['mix_rate'])not in (int,float):return False
  mix=float(x['mix_rate']);obs=x['observations'];last=obs[-1]
  if x['driver']!='Dummy' or not math.isfinite(mix) or mix<=0:return False
  required=math.ceil(mix*.15)
  return (x['complete']is True and x['capture_removed']is True and x['prepare_errors']==[] and x['requested_owner_count']==1 and x['tracked_owner_count']==1 and x['tracked_stream_count']>0 and x['game_owner_count']==1 and required>0 and 150000<=last['elapsed_us']<=1000000 and last['new_pushed']>=required and last['silent_frames']>=required and last['owners_released']is True and last['streams_released']is True and all(type(o['required_frames'])is int and o['required_frames']==required and o['invalid']==0 and o['discarded']==0 and o['prepare_errors']==0 and o['game_owner_count']==1 and o['owner_count']==1 for o in obs))
 except (KeyError,IndexError,TypeError,ValueError):return False
assert len(sys.argv)==2;sha=sys.argv[1];assert H(Q/'PLAN.json')==sha
p=json.loads((Q/'PLAN.json').read_text());assert p['status']=='FROZEN_QA_APPROVED'
assert os.environ.get('DISPLAY')or os.environ.get('WAYLAND_DISPLAY'),'actual desktop required'
T=Path(p['source']);B=Path(p['base']);O=Path(p['output']);assert not O.exists()
source=json.loads(Path(p['source_map']).read_text());base=json.loads(Path(p['base_map']).read_text())
def pins():return all(H(f)==h for f,h in p['pins'].items())
preflight_error=None
try:
 assert pins() and snap(T)==source and snap(B)==base
 # Composite authority: original first8 PASS + separately corrected fire pair, never original9 PASS.
 pack=json.loads(Path(p['original_pack_result']).read_text());fire=json.loads(Path(p['fire_independent_review']).read_text())
 assert pack['pass']is False and pack['completed']==9 and all(x['pass']is True for x in pack['phases'][:8])and pack['phases'][8]['pass']is False
 assert pack['pck_sha256']==p['pck_sha256'] and fire['review_pass']is True
 assert H(p['pck'])==p['pck_sha256']
 # Independent first8 raw acceptance must be supplied before freeze.
 review=json.loads(Path(p['resource_independent_review']).read_text());assert review['review_pass']is True and review['checks']==1658 and review['actual_records']==273 and review['pck_sha256']==p['pck_sha256'] and review['original_first8_pass']is True and review['original_ninth_strict_failure_retained']is True and review['source935_base926_allpins_exact']is True and review['result_sha256']==H(p['original_pack_result']) and review['repair_result_sha256']==fire['result_sha256']
except Exception as e:preflight_error=repr(e)
if preflight_error is not None:
 O.mkdir();checks={}
 for label,fn in [('source',lambda:snap(T)==source),('base',lambda:snap(B)==base),('pins',pins),('plan',lambda:H(Q/'PLAN.json')==sha),('pack',lambda:H(p['pck'])==p['pck_sha256'])]:
  try:checks[label]=fn()
  except Exception as e:checks[label]=repr(e)
 save(O/'RESULT.json',{'pass':False,'termination':'PREFLIGHT_ERROR','native_exit':None,'spawned':False,'error':preflight_error,'after_guards':checks})
 raise SystemExit(1)
O.mkdir();(O/'empty-runtime').mkdir();(O/'images').mkdir()
env=os.environ.copy()
for k,d in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_CACHE_HOME','cache'),('XDG_DATA_HOME','data')]:
 (O/d).mkdir();env[k]=str(O/d)
env['MOSS_HELD_IMAGES']=str(O/'images')
cmd=['godot','--path',str(O/'empty-runtime'),'--main-pack',p['pck'],'--audio-driver','Dummy','--resolution','960x540','--position','0,60','--script',p['fixture']]
save(O/'COMMAND.json',{'argv':cmd,'timeout':180,'display':env.get('DISPLAY'),'wayland':env.get('WAYLAND_DISPLAY')})
errors=[];rc=None;timed=False;started=False;tick=time.monotonic();before={};after={};baseafter={};guards={}
try:
 before=snap(T);save(O/'SOURCE_BEFORE.json',before);base_before=snap(B);save(O/'BASE_BEFORE.json',base_before);assert before==source and base_before==base and pins()
 started=True
 with (O/'native.log').open('wb')as f:rc=subprocess.run(cmd,env=env,cwd=O/'empty-runtime',stdout=f,stderr=subprocess.STDOUT,timeout=180).returncode
except subprocess.TimeoutExpired:timed=True;errors.append('TIMEOUT')
except Exception as e:errors.append('launch: '+repr(e))
elapsed=time.monotonic()-tick
for name,fn in [('source',lambda:snap(T)),('base',lambda:snap(B)),('pins',pins),('plan',lambda:H(Q/'PLAN.json')==sha),('pack',lambda:H(p['pck'])==p['pck_sha256'])]:
 try:guards[name]=fn()
 except Exception as e:guards[name]=None;errors.append(name+': '+repr(e))
save(O/'SOURCE_AFTER.json',guards.get('source'));save(O/'BASE_AFTER.json',guards.get('base'))
reports=[];audio=[];images=[];findings=[];allowed_warnings=[]
try:
 raw=(O/'native.log').read_text(errors='replace')
 lines=raw.splitlines()
 warning='WARNING: Could not set V-Sync mode, as changing V-Sync mode is not supported by the graphics driver.'
 at='     at: set_use_vsync (platform/linuxbsd/x11/gl_manager_x11.cpp:364)'
 for n,line in enumerate(lines,1):
  if line==warning and n<len(lines) and lines[n]==at and not allowed_warnings:
   allowed_warnings.append({'line':n,'text':line,'at':lines[n]});continue
  if any(s in line for s in ['SCRIPT ERROR','Parse Error','ERROR:','WARNING:','ObjectDB instances leaked','resources still in use']):findings.append({'line':n,'text':line})
  if line.startswith('TEST_AUDIO_TEARDOWN '):audio.append(json.loads(line.split(' ',1)[1]))
  elif line.startswith('HELD_NATIVE_IMAGE '):images.append(json.loads(line.split(' ',1)[1]))
  elif line.startswith('{'):reports.append(json.loads(line))
  elif any(s in line for s in ['TEST_AUDIO_TEARDOWN','HELD_NATIVE_IMAGE','checks','failures']):raise ValueError('malformed marker '+line)
 assert all(isinstance(x,dict)for x in reports+audio+images),'all structured markers must be objects'
 assert len(reports)==1 and isinstance(reports[0],dict) and reports[0]['checks']==239 and reports[0]['failures']==[] and isinstance(reports[0]['records'],list) and len(reports[0]['records'])==20 and all(isinstance(x,dict)for x in reports[0]['records'])
 assert len(audio)==1 and audio_ok(audio[0]);assert isinstance(reports[0]['images'],list)and images==reports[0]['images']and len(images)==36
 assert {x['name']for x in images}==set(p['expected_images'])and {x.name for x in(O/'images').iterdir()}==set(p['expected_images'])
 for row in images:
  assert row['save_error']==0 and row['width']==960 and row['height']==540 and re.fullmatch('[0-9a-f]{64}',row['authority_before']) and row['authority_before']==row['authority_after']and row['owner_live_disabled']is True
  with Image.open(O/'images'/row['name'])as im:im.load();assert im.size==(960,540)and im.format=='PNG'
 save(O/'REPORT.json',reports[0]);save(O/'AUDIO.json',audio[0])
except Exception as e:errors.append('validation: '+repr(e))
ok=started and rc==0 and not timed and elapsed<=180 and not errors and not findings and guards.get('source')==source and guards.get('base')==base and all(guards.get(x)is True for x in ['pins','plan','pack'])
save(O/'RESULT.json',{'pass':ok,'native_exit':rc,'supervisor_exit':124 if timed else rc,'termination':'TIMEOUT'if timed else('EXIT'if rc is not None else'LAUNCH_ERROR'),'elapsed_seconds':elapsed,'errors':errors,'strict_findings':findings,'allowed_warning_blocks':allowed_warnings,'warning_policy':'Exact approved V-Sync block at most once; not a zero-warning claim','source935_unchanged':guards.get('source')==source,'base926_unchanged':guards.get('base')==base,'pins_unchanged':guards.get('pins'),'plan_unchanged':guards.get('plan'),'pck_unchanged':guards.get('pack'),'image_count':len(images),'checks':reports[0].get('checks')if reports and isinstance(reports[0],dict) else None,'scope':'finite native runtime evidence; human original-image review remains required'})
(O/'native.exit').write_text(json.dumps(rc)+'\n');raise SystemExit(0 if ok else 1)
