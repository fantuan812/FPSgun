from pathlib import Path
import json,hashlib
from PIL import Image
q=Path('<WORKSPACE>/moss-v39-prep/native-mechanics');o=q/'raw-first';h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();p=json.loads((q/'PLAN.json').read_text());r=json.loads((o/'RESULT.json').read_text());checks=[]
def ck(v,s):
 assert v,s
 checks.append(s)
ck((q/'wrapper-r2.exit').read_text().strip()=='0' and (o/'native.exit').read_text().strip()=='0','actual exits');ck((q/'wrapper.exit').read_text().strip()=='127','old infrastructure127 retained')
for f,v in p['pins'].items():ck(h(Path(f))==v,'pin '+f)
a=(o/'native.stdout').read_text();b=(o/'native.stderr').read_text();reports=[json.loads(x) for x in a.splitlines() if x.startswith('{')];hs=[json.loads(x.split(' ',1)[1]) for x in a.splitlines() if x.startswith('TEST_AUDIO_TEARDOWN ')]
ck(reports==r['reports'] and hs==r['helpers'] and len(reports)==len(hs)==1,'raw JSON exact');j=reports[0];ck(j['checks']==128 and j['failures']==[] and len(j['observations'])==36,'128/36 exact');ck(not any(x in a+b for x in ['SCRIPT ERROR','ERROR:','Parse Error','instances leaked','resources still in use']),'strict raw');ck(r['pass_gate'] and r['seconds']<=180 and not r['timeout'],'strict bounded gate')
x=hs[0];z=x['observations'][-1];ck(x['complete'] and x['capture_removed'] and x['prepare_errors']==[] and x['requested_owner_count']==x['tracked_owner_count']==x['game_owner_count']==1 and x['tracked_stream_count']>0,'helper prepared');ck(z['owners_released'] and z['streams_released'] and 150000<=z['elapsed_us']<=1000000 and z['new_pushed']>=z['required_frames']>0 and z['silent_frames']>=z['required_frames'] and all(t['invalid']==t['discarded']==t['prepare_errors']==0 for t in x['observations']),'helper fresh silence')
expected={'memory_reacquire':([100,90,90,80,80],[0,.3,.3,.6,.6],[0,.3,.4,.7,.71]),'memory_hardlife':([100,70,70,60],[0,.9,.9,1.2],[0,.9,1.1,1.4]),'drum_collar':([100,78,78,67,67],None,None)}
for mode in ['arena','rooms']:
 for case,(hp,active,wall) in expected.items():
  rows=[v for v in j['observations'] if v['case']==mode+'_'+case];ck([v['authority']['enemies'][0]['hp'] for v in rows]==hp,'literal HP '+mode+case)
  if active is not None:
   ck(all(abs(v['held_entity']['active_age']-t)<1e-8 for v,t in zip(rows,active)),'active ages '+mode+case);ck(all(abs(v['held_entity']['wall_age']-t)<1e-8 for v,t in zip(rows,wall)),'wall ages '+mode+case)
 rows=[v for v in j['observations'] if v['case']==mode+'_recoil'];ck([v['authority']['enemies'][0]['pos'] for v in rows]==['(480.0, 300.0)','(535.0, 300.0)','(480.0, 300.0)','(535.0, 300.0)'],'actual55/CD '+mode);ck(all(v['authority']['enemies'][1]['pos']=='(501.0, 300.0)' and v['authority']['enemies'][2]['pos']=='(470.0, 300.0)' and all(e['hp']==100 for e in v['authority']['enemies']) for v in rows),'boss/far/no damage '+mode);ck([v['authority']['stats']['hp'] for v in rows]==[100,99,98,97],'real player HP loss '+mode)
imgs={};ck([v['image'] for v in j['observations']]==p['expected_images'],'stage image names');ck(sorted(x.name for x in (o/'images').glob('*.png'))==sorted(p['expected_images']),'exact36 files')
for v in j['observations']:
 f=o/'images'/v['image'];ck(Image.open(f).size==(960,540),'logical PNG '+v['image']);imgs[v['image']]=h(f)
root=Path(p['source']);actual={str(f.relative_to(root)):h(f) for f in root.rglob('*') if f.is_file() and '.godot' not in f.relative_to(root).parts};ck(actual==json.loads(Path(p['input_map']).read_text())==json.loads((o/'POST_INPUTS.json').read_text()),'full869 source unchanged')
res={'pass':True,'checks':len(checks),'native_exit':0,'seconds':r['seconds'],'source_map_sha256':h(Path(p['input_map'])),'pck_sha256':p['pins']['<WORKSPACE>/moss-v39-pack/linux/MossCircuit.pck'],'cases':8,'checks_executed':128,'stage_images':imgs,'stderr_preserved':b,'directly_viewed':['arena_memory_reacquire_recovered.png','rooms_drum_collar_inward.png','arena_recoil_push.png'],'visual_boundary':'Three original stills and live native window. Beam/LOCK and inward ring readable. Recoil white ring visible but existing large boss occludes some crawler sprites; positions/HP/CD proven by raw, not claimed visually measurable55px. Other33 image identities/dimensions only.','scope':'Controlled trueRuntime launches, supplied actors/build, fixed manual steps and realmain hurt. Not ordinary acquisition/hardwareinput/Windows; source149/151 and launcher127 retained.'};out=Path('<WORKSPACE>/moss-v39-qa/NATIVE_MECHANICS_RAW_REVIEW.json');out.write_text(json.dumps(res,indent=2)+'\n');print(len(checks),h(out))
