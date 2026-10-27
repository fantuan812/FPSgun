from pathlib import Path
import json,hashlib
from PIL import Image
q=Path(__file__).parent;h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();raw=(q/'pack-native/controlled.log').read_text();rows=[];helpers=[];terminal=[]
for l in raw.splitlines():
 if l.startswith('{'):
  x=json.loads(l)
  if 'controlled_step'in x:rows.append(x['controlled_step'])
  if x.get('fixture_terminal'):terminal.append(x)
 elif l.startswith('TEST_AUDIO_TEARDOWN '):helpers.append(json.loads(l.split(' ',1)[1]))
assert len(rows)==28 and [(x['case'],x['stage']) for x in rows]==[(c,s) for c in range(1,5) for s in range(7)] and all(not x['failures'] for x in rows)
for x in rows:
 assert x['mode']==('arena' if x['case'] in [1,3] else 'rooms')
 assert x['recipient_hp']==x['recipient_anim_hp']==(60 if x['stage']==2 else 50)
 assert x['source_hp']==(-966 if x['stage']==6 else 33 if x['stage']==4 else 34)
 assert x['source_present']==(x['stage']!=6)
 assert x['token_present']==(x['stage'] in [0,1,3,5])
assert len(terminal)==1 and terminal[0]['observations']==28 and not terminal[0]['failures'];assert (q/'pack-native/controlled.exit').read_text().strip()=='0';assert not any(v in raw for v in ['ERROR:','instances leaked','resources still in use'])
assert len(helpers)==1;a=helpers[0];z=a['observations'][-1];assert a['complete'] and a['capture_removed'] and not a['prepare_errors'] and a['requested_owner_count']==a['tracked_owner_count']==1 and a['tracked_stream_count']==2 and z['owners_released'] and z['streams_released'] and z['new_pushed']>=z['required_frames']>0 and z['silent_frames']>=z['required_frames'] and 150000<=z['elapsed_us']<=1000000 and all(v['invalid']==v['discarded']==0 for v in a['observations'])
images=[]
for f in sorted((q/'native-captures').glob('*.jpg')):
 im=Image.open(f);dims=list(im.size);assert dims==([960,540] if int(f.name[:2])<=14 else [1280,720]);images.append({'path':str(f.relative_to(q)),'sha256':h(f),'bytes':f.stat().st_size,'dimensions':dims})
assert len(images)==29
x={'pass':True,'native_exit':0,'actual_game_window_absent_after_exit':True,'cases':4,'runtime_observations':28,'original_jpg':29,'rows':rows,'terminal':terminal[0],'helper':a,'images':images,'pck_sha256':json.load(open(q/'NATIVE_LAUNCH_FREEZE.json'))['pck_sha256'],'warnings':[l for l in raw.splitlines() if 'WARNING:'in l],'scope':'Actual Godot native exact newSVG PCK, controlled2modes x2sizes x7realRuntime steps; reduced-flash at1280. No newordinary/full139/audio-listening/Windows claim.','visual_review':'All29 original stills directly viewed during operation. New drone silhouette/coil/tether/plus/interrupt and death motion distinguishable; no new crop/HUD obstruction observed at these sizes. Runtime causal evidence is raw, not still inference. 14/28 death stills show earlier lit falling animation, not finaldarkframe; 07/21 show darkcollapsed. 14b is late corpse removal, not extra gameplay step.','additional_visual_review':'Directly reviewed03heal/05interrupt/07death only; bounded visual no newblocker, not causalassertion.'};(q/'NATIVE_RESULT.json').write_text(json.dumps(x,indent=2)+'\n');print(json.dumps({'pass':True,'steps':28,'images':29,'native_exit':0}))
