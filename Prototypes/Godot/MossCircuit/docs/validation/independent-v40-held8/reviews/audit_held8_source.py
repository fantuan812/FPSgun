from pathlib import Path
import json,hashlib,math,re
B=Path('workspace/shared');Q=B/'moss-held8-integration-review';R=Q/'source-gate-first';J=lambda p:json.loads(Path(p).read_text());H=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest();p=J(Q/'SOURCE_PLAN.json');checks=[]
def ck(v,s):
 checks.append(s)
 if not v:raise AssertionError(s)
def inv(root):
 root=Path(root);return {str(f.relative_to(root)):H(f) for f in root.rglob('*') if f.is_file() and '.godot' not in f.relative_to(root).parts}
r=J(R/'RESULT.json');ck(r['pass'] and r['completed']==3 and len(r['phases'])==3,'three phases');base=J(Q/'BASE_926_PINS.json');cold=J(Q/'CANDIDATE_927_PINS.json');post=J(R/'POST_IMPORT_935_PINS.json');ck(len(base)==926 and len(cold)==927 and len(post)==935,'counts926927935');ck(set(post)-set(cold)==set(p['cold_expected_new_sidecars']) and all(post[k]==v for k,v in cold.items()),'exact8coldsidecars')
for path,h in p['pins'].items():ck(H(path)==h,'pin '+path)
ck(inv(p['base'])==base,'livebase926');ck(inv(p['source'])==post,'live935')
source_seconds=0
for phase,row in zip(p['phases'],r['phases']):
 name=phase['name'];ck(row['phase']==name and row['command']==phase['command'],'exact command '+name);text=(R/(name+'.log')).read_text();ck((R/(name+'.exit')).read_text().strip()=='0' and (R/(name+'.supervisor.exit')).read_text().strip()=='0' and row['native_exit']==row['supervisor_exit']==row['exit']==0 and row['termination']=='EXIT' and not row['timeout'] and row['pass'],'true native '+name)
 ck(row['budget_ok'] and row['elapsed_seconds']<=180 and not row['launch_error'] and not row['guards_error'] and not row['strict_log_findings'] and not any(x in text for x in ['SCRIPT ERROR','Parse Error','ERROR:','WARNING:','instances leaked','resources still in use']),'strict '+name)
 ck(row['base926_unchanged'] and row['test_pins_unchanged'] and row['plan_unchanged'] and not row['changed_existing'],'guards '+name)
 before=J(R/(name+'-before.json'));after=J(R/(name+'-after.json'));ck(before==(cold if name=='cold_import' else post) and after==post,'exact beforeafter '+name)
 reports=[];helpers=[]
 for line in text.splitlines():
  if line.startswith('{'):reports.append(json.loads(line))
  elif line.startswith('TEST_AUDIO_TEARDOWN '):helpers.append(json.loads(line.split(' ',1)[1]))
  elif '{' in line or 'TEST_AUDIO_TEARDOWN' in line:raise AssertionError('malformedmarker')
 if name=='cold_import':ck(not reports and not helpers and sorted(row['added'])==sorted(p['cold_expected_new_sidecars']),'cold identity');continue
 source_seconds+=row['elapsed_seconds'];ck(row['added']==[],'source noadd');report=J(R/(name+'-report.json'));ck(reports==[report] and report['checks']==phase['expected_checks'] and report['failures']==[],'actual report '+name);ck(len(helpers)==1 and helpers[0]==J(R/(name+'-teardown.json')),'one actual helper')
 h=helpers[0];rate=h['mix_rate'];ck(type(rate) in (int,float) and math.isfinite(rate) and rate>0,'mix rate finite');req=math.ceil(rate*.15);ck(h['driver']=='Dummy' and h['complete'] and h['capture_removed'] and h['prepare_errors']==[] and h['requested_owner_count']==h['tracked_owner_count']==h['game_owner_count']==1 and h['tracked_stream_count']>0,'helper owners')
 ck(len(h['observations'])>0,'helper observations')
 for o in h['observations']:ck(o['invalid']==o['discarded']==o['prepare_errors']==0 and o['owner_count']==o['game_owner_count']==1 and o['required_frames']==req,'helper eachobs')
 last=h['observations'][-1];ck(last['owners_released'] and last['streams_released'] and last['new_pushed']>=req and last['silent_frames']>=req and 150000<=last['elapsed_us']<=1000000,'freshsilence')
 if name=='actual_geometry':ck(report['poses']==4608 and report['ranges']==13824,'4608poses13824range')
 else:
  records=report['records'];ids=['rivet_gun','scrap_shotgun','rail_lance','orbit_saw','return_disc','shock_mortar','cryo_sprayer','bankshot_driver'];expected={(mode,id,slot,left,False) for mode in ['arena','rooms'] for id in ids for slot in range(4) for left in [False,True]}|{(mode,'bankshot_driver',slot,False,True) for mode in ['arena','rooms'] for slot in range(4)}
  ck(len(records)==136 and len({(v['mode'],v['id'],v['slot'],v['left'],v['coincident']) for v in records})==136 and {(v['mode'],v['id'],v['slot'],v['left'],v['coincident']) for v in records}==expected,'136exactunique128plus8')
  for v in records:ck(isinstance(v['pose'],str) and 'muzzle' in v['pose'] and 'mount' in v['pose'] and all(type(v[k]) is int and v[k]>=0 for k in ['bullet_count','blast_count','cone_count']) and type(v['target_hp']) in (int,float) and math.isfinite(v['target_hp']),'actual fire observations')
ck(source_seconds<=180,'two-source combined180');ck(inv(p['base'])==base and inv(p['source'])==post,'final live maps');
for path,h in p['pins'].items():ck(H(path)==h,'finalpin '+path)
out={'review_pass':True,'checks':len(checks),'scope':'Independent original held8 cold927to935 exact8imports +23090 geometry checks/4608real main socket poses/13824ranges +1089 checks/136paired real-fire cases including8coincident. No old21504 acceptance reuse, no PCK/native/whole combined release acceptance. Base926 immutable.','source935_and_base926_unchanged':True,'source_combined_seconds':source_seconds,'source_plan_sha256':H(Q/'SOURCE_PLAN.json'),'result_sha256':H(R/'RESULT.json'),'checks_detail':checks};f=B/'moss-v39-prep/HELD8_SOURCE_RAW_REVIEW.json';f.write_text(json.dumps(out,indent=2)+'\n');print(json.dumps({'pass':True,'checks':len(checks),'sha256':H(f)}))
