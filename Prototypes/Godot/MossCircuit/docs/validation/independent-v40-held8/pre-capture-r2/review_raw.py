import pathlib,json,hashlib,math,re
q=pathlib.Path(__file__).parent;h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();p=json.loads((q/'PLAN.json').read_text());r=json.loads((q/'raw-first/RESULT.json').read_text());expected=json.loads(pathlib.Path(p['source_fire_report']).read_text())['records'];assert r['pass'] and not r['errors'] and r['pins_and_sources_unchanged'] and len(r['steps'])==2
rows=[]
for step in r['steps']:
 d=q/'raw-first'/step['name'];assert step['native_exit']==0 and step['pass'] and not step['timeout'] and step['seconds']<180 and (d/'native.exit').read_text().strip()=='0';assert (d/'stderr.raw').read_bytes()==b''
 text=(d/'stdout.raw').read_text();assert not re.search(r'\b(?:ERROR|WARNING|SCRIPT ERROR)\b',text)
 guards=[];helpers=[];reports=[]
 for line in text.splitlines():
  if line.startswith('HELD_PRE_CAPTURE_GUARD '):guards.append(json.loads(line.split(' ',1)[1]))
  elif line.startswith('TEST_AUDIO_TEARDOWN '):helpers.append(json.loads(line.split(' ',1)[1]))
  elif line.startswith('{'):reports.append(json.loads(line))
  elif any(x in line for x in ('HELD_PRE_CAPTURE_GUARD','TEST_AUDIO_TEARDOWN','checks','failures','{')):raise AssertionError(line)
 assert len(guards)==len(helpers)==len(reports)==1;g,a,b=guards[0],helpers[0],reports[0]
 assert b['checks']==1089 and b['failures']==[] and b['records']==expected and len(expected)==136
 assert g['pass'] and g['before_current_owner_live_main_disabled'] and g['after_current_owner_live_main_disabled'] and g['capture_not_constructed_yet'] and g['authority_before']==g['authority_after'] and g['records_before']==g['records_after'] and g['records_count']==136
 assert a['driver']=='Dummy' and a['complete'] and a['capture_removed'] and a['prepare_errors']==[] and a['requested_owner_count']==a['tracked_owner_count']==a['game_owner_count']==1
 assert type(a['mix_rate']) in (int,float) and math.isfinite(a['mix_rate']) and a['mix_rate']>0;req=math.ceil(a['mix_rate']*.15)
 for o in a['observations']:assert o['discarded']==o['invalid']==o['prepare_errors']==0 and o['required_frames']==req and o['owner_count']==o['game_owner_count']==1
 o=a['observations'][-1];assert o['owners_released'] and o['streams_released'] and 150000<=o['elapsed_us']<=1000000 and min(o['new_pushed'],o['silent_frames'])>=req
 rows.append({'route':step['name'],'native_exit':0,'seconds':step['seconds'],'checks':1089,'records':136,'pre_capture_frame_us':g['elapsed_us'],'guard':g,'last_helper_observation':o,'stdout_sha256':h(d/'stdout.raw')})
small=0
for f,s in p['pins'].items():
 f=pathlib.Path(f)
 if f.stat().st_size<2000000:assert h(f)==s;small+=1
out={'review_pass':True,'result_sha256':h(q/'raw-first/RESULT.json'),'plan_sha256':h(q/'PLAN.json'),'routes':rows,'small_live_pins_checked':small,'live_full_source_or_pck_rehashed':False,'runner_recorded_935_926_and_all_pins_after':True,'scope':'Independent original raw audit. Original packed nine-phase FAIL and telemetry remain; corrected source and packed fire only, no new export or native visual acceptance.'};f=q/'QA_RAW_REVIEW.json';f.write_text(json.dumps(out,indent=2)+'\n');print(f,h(f))
