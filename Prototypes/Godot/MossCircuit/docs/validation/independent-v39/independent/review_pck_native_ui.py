from pathlib import Path
import json,hashlib
from PIL import Image
p=Path('<WORKSPACE>/moss-v39-ui/native-PCK-gate');plan=json.load(open(p/'PLAN.json'));h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();checks=[]
def ck(v,s):
 assert v,s
 checks.append(s)
ck(h(p/'PLAN.json')=='e1d3df704c2af25a2db4be6819cb284a62f3ff5ed54407b38ff852a4d4929219','frozen plan')
ck((p/'wrapper.exit').read_text().strip()=='0' and (p/'validation.exit').read_text().strip()=='0','true terminal')
for f,v in plan['pins'].items():ck(h(Path(f))==v,'pin '+f)
images={};rows=[]
for phase in plan['phases']:
 n=phase['name'];d=p/n;j=json.load(open(d/'RESULT.json'));raw=(d/'native.log').read_text();report=[json.loads(x) for x in raw.splitlines() if x.startswith('{')];helpers=[json.loads(x.split(' ',1)[1]) for x in raw.splitlines() if x.startswith('TEST_AUDIO_TEARDOWN ')]
 ck((d/'native.exit').read_text().strip()=='0' and j['exit']==0 and not j['timeout'] and 0<j['monotonic_seconds']<=180,'native bounded '+n)
 ck(not any(x in raw for x in ['SCRIPT ERROR','ERROR:','Parse Error','instances leaked','resources still in use']),'strict raw '+n)
 ck(len(report)==1 and report[0]==j['report'] and report[0]['checks']==phase['expected_checks'] and report[0]['failures']==[],'raw semantics '+n)
 ck(len(helpers)==1 and helpers==j['helper_records'],'raw helper '+n);x=helpers[0];z=x['observations'][-1]
 ck(x['complete'] and x['capture_removed'] and x['prepare_errors']==[] and x['requested_owner_count']==x['tracked_owner_count']==x['game_owner_count']==1 and x['tracked_stream_count']>0,'owners tracked '+n)
 ck(z['owners_released'] and z['streams_released'] and 150000<=z['elapsed_us']<=1000000 and z['new_pushed']>=z['required_frames']>0 and z['silent_frames']>=z['required_frames'] and all(o['invalid']==o['discarded']==o['prepare_errors']==0 for o in x['observations']),'fresh cleanup '+n)
 ck({x['os_window_size'] for x in j['dimensions']}=={'(1180, 812)','(960, 540)','(1280, 720)'} and all(x['logical_visible_rect']=='[P: (0.0, 0.0), S: (960.0, 540.0)]' for x in j['dimensions']),'logical960 physical960/1280 '+n)
 ck(sorted(f.name for f in (d/'images').glob('*.png'))==sorted(phase['expected_images']),'all images '+n)
 for f in (d/'images').glob('*.png'):
  im=Image.open(f);ck(im.size==(960,540) and im.convert('RGB').getextrema()!=((0,0),(0,0),(0,0)),'actual image dimensions/nonblack '+f.name);images[str(f)]={'sha256':h(f),'size':list(im.size)}
 rows.append({'phase':n,'seconds':j['monotonic_seconds'],'checks':report[0]['checks'],'helper_final':z})
 if n=='hud_buttons':
  rr=report[0]['records'];ck(len(rr)==8 and len({v['case'] for v in rr})==8,'eight actual button flows')
  for v in rr:
   ck(v['selected_before_after']==1 and v['behind_enemy_id']==2 and len(v['buttons'])==2,'no behind-selection '+v['case'])
   for b in v['buttons']:ck(b['text_width']+b['left_margin']+b['right_margin']<= (78 if b['text']=='BUILD [I]' else 101)+.001,'exact text/padding width '+v['case']+b['text'])
 if n=='hud_width':
  expected={'two_lock_six_out':'LOCK 3/4x2 · RING ↑6 ↓0','two_lock_mixed':'LOCK 3/4x2 · RING ↑3 ↓3','three_lock_three_in':'LOCK 3/4x3 · RING ↑0 ↓3','one_lock_nine_out':'LOCK 3/4 · RING ↑9 ↓0','twelve_out':'RING ↑12 ↓0','twelve_in':'RING ↑0 ↓12','old_four_control':''}
  records=report[0]['records'];ck(len(records)==28 and len({x['case'] for x in records})==28,'28 distinct bounded HUD cases')
  for x in records:ck(x['status']==expected[x['case'].split('/')[-1]] and x['hp_width']>=130 and x['xp_width']>=130 and x['action'].startswith('ATTACK  /  DASH READY'),'literal status/full bars '+x['case'])
m=json.load(open(plan['source_input_map_path']))
for root in [plan['source_path'],plan['original_source_path']]:
 r=Path(root);a={str(f.relative_to(r)):h(f) for f in r.rglob('*') if f.is_file() and '.godot' not in f.relative_to(r).parts};ck(a==m and len(a)==869,'actual full source '+root)
receipt={'pass':True,'checks':len(checks),'scope':'Independent raw and all68 PNG identity/dimensions of exact PCK native178/140/200.8actualGUI button flows and28 HUD snapshots; logical960 at two OS sizes, startup1180x812. Not hardware mouse, natural acquisition or ordinary acceptance.','original_fail_retained':'Source native150/6 fixture-coordinate failures retained; external one-argument correction previously validated.','images':images,'routes':rows,'checks_detail':checks,'directly_viewed':['hud_buttons/images/arena_960_pause_before.png','hud_buttons/images/rooms_1280_build_modal.png'],'visual_scope':'Two original stills directly viewed plus live native desktop; other66 image bytes/dimensions only. No new blocker in these bounded visuals.'};out=Path('<WORKSPACE>/moss-v39-qa/PCK_NATIVE_UI_RAW_REVIEW.json');out.write_text(json.dumps(receipt,indent=2)+'\n');print(len(checks),h(out))
