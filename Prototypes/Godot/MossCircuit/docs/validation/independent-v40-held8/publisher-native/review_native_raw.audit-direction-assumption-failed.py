import json,pathlib,hashlib,re,math
from PIL import Image
R=pathlib.Path('evidence-workspace/moss-held8-integration-review'); O=R/'native-first'; P=R/'native-prep'; D=pathlib.Path('evidence-workspace/moss-held8-independent-integration-review')
def J(p):return json.loads(p.read_text())
def H(p):return hashlib.sha256(p.read_bytes()).hexdigest()
n=0
def ck(v):
 global n
 assert v,n
 n+=1
plan=J(P/'PLAN.json');result=J(O/'RESULT.json');report=J(O/'REPORT.json');audio=J(O/'AUDIO.json')
ck((P/'wrapper.exit').read_text().strip()=='0');ck((O/'native.exit').read_text().strip()=='0');ck(result['native_exit']==0 and result['supervisor_exit']==0 and result['termination']=='EXIT' and result['pass'] is True);ck(0<result['elapsed_seconds']<=180)
log=(O/'native.log').read_text();lines=log.splitlines();reports=[];audios=[];images=[];warn=[]
for i,l in enumerate(lines):
 if l.startswith('{'):reports.append(json.loads(l))
 elif l.startswith('TEST_AUDIO_TEARDOWN '):audios.append(json.loads(l.split(' ',1)[1]))
 elif l.startswith('HELD_NATIVE_IMAGE '):images.append(json.loads(l.split(' ',1)[1]))
 elif 'WARNING:' in l:
  ck(l=='WARNING: Could not set V-Sync mode, as changing V-Sync mode is not supported by the graphics driver.');ck(lines[i+1]=='     at: set_use_vsync (platform/linuxbsd/x11/gl_manager_x11.cpp:364)');warn.append(i)
 ck(not re.search(r'SCRIPT ERROR|ERROR:|Parse Error|ObjectDB instances leaked|resources still in use|Traceback',l))
ck(len(warn)==1);ck(reports==[report]);ck(audios==[audio]);ck(images==report['images']);ck(report['checks']==239 and report['failures']==[])
for label,count,mapkey in [('SOURCE',935,'source_map'),('BASE',926,'base_map')]:
 before=J(O/(label+'_BEFORE.json'));after=J(O/(label+'_AFTER.json'));expected=J(pathlib.Path(plan[mapkey]));ck(len(before)==count);ck(before==after==expected)
for f,h in plan['pins'].items():ck(H(pathlib.Path(f))==h)
ck(audio['complete'] and audio['capture_removed'] and audio['driver']=='Dummy' and audio['mix_rate']==44100)
ck(audio['tracked_owner_count']==1 and audio['tracked_stream_count']==2 and audio['requested_owner_count']==1 and audio['prepare_errors']==[])
obs=audio['observations'];last=obs[-1];prior=-1;frames=-1
for o in obs:
 ck(o['elapsed_us']>=prior and o['new_pushed']>=frames);prior=o['elapsed_us'];frames=o['new_pushed']
 ck(o['discarded']==o['invalid']==o['prepare_errors']==0 and o['owners_released'] and o['streams_released'] and o['owner_count']==1)
ck(150000<=last['elapsed_us']<=1000000 and last['new_pushed']>=6615 and last['silent_frames']>=6615 and last['required_frames']==6615)
ck(len(images)==36 and {x['name'] for x in images}==set(plan['expected_images'])=={p.name for p in (O/'images').iterdir()})
image_pins={}
for row in images:
 p=O/'images'/row['name'];ck(row['authority_before']==row['authority_after'] and len(row['authority_before'])==64 and row['save_error']==0 and row['owner_live_disabled'] is True)
 ck(row['width']==960 and row['height']==540 and row['crop_rect']==[400,250,160,140])
 with Image.open(p) as im: im.load();ck(im.size==(960,540) and im.format=='PNG')
 image_pins[row['name']]={'sha256':H(p),'bytes':p.stat().st_size}
old=['rivet_gun','scrap_shotgun','rail_lance','orbit_saw','return_disc','shock_mortar','cryo_sprayer','bankshot_driver']; retained=['tether_emitter','seismic_drum']
records=report['records'];ck(len(records)==20);ck([(r['id'],r['left_requested'])for r in records]==[(i,l)for i in old+retained for l in [False,True]])
for r in records:
 ck(r['retained_only']==(r['id'] in retained))
 for key in ['held_pose']+(['fire_pose'] if r['id'] in old else []):
  s=r[key];ck('nan' not in s.lower() and 'inf' not in s.lower());vecs={k:(float(x),float(y))for k,x,y in re.findall(r'"(direction|mount|muzzle|scale)": Vector2\(([^,]+), ([^)]+)\)',s)};ck(len(vecs)==4)
  ck(all(math.isfinite(x)for v in vecs.values() for x in v));ck((vecs['direction'][0]<0)==r['left_requested']);ck((vecs['scale'][1]<0)==r['left_requested']);ck(abs(math.hypot(*vecs['direction'])-1)<1e-5)
  if r['id'] in ['orbit_saw','return_disc']:ck(vecs['mount']==vecs['muzzle'])
 if r['id'] in old:ck(r['player_centered']==(r['id'] in ['orbit_saw','cryo_sprayer']) and isinstance(r['bullets'],int) and r['bullets']>=0)
 else:ck('fire_pose' not in r and 'bullets' not in r)
receipt={'pass':True,'checks':n,'scope':'Independent original native raw, finite 20 records, 36 PNG file identity/dimensions and helper review; no engine rerun, no repeated PCK parse or full source rehash, no claim of human visual review of all images.','native_exit':0,'wrapper_exit':0,'semantic_checks':239,'records':20,'old_weapon_fire_records':16,'A2_held_only_records':4,'images':image_pins,'audio_last':last,'warning_count':1,'warning_policy':'Exact existing VSync two-line block retained; not warning-free.','source_recorded_maps_exact':935,'base_recorded_maps_exact':926,'source_pins_scope':'Recorded before/after maps compared to frozen expected; all small plan pins reread. Actual whole-source and PCK guards executed by native wrapper, not duplicated here.','plan_sha256':H(P/'PLAN.json'),'result_sha256':H(O/'RESULT.json'),'report_sha256':H(O/'REPORT.json'),'audio_sha256':H(O/'AUDIO.json'),'native_log_sha256':H(O/'native.log'),'display_boundary':'960x540 saved viewport, OS window 1180x812; not a 960x540 OS window claim.','history':'Original pack fire helper FAIL retained; repaired source/packed finite gates are distinct. No new B full suite or ordinary run.'}
(D/'NATIVE_RAW_REVIEW.json').write_text(json.dumps(receipt,indent=2)+'\n');print(json.dumps({'pass':True,'checks':n,'receipt_sha256':H(D/'NATIVE_RAW_REVIEW.json')}))
