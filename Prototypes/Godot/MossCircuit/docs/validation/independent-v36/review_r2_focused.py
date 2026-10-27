from pathlib import Path
import json,hashlib,re,datetime
r=Path('<WORKSPACE>');q=r/'moss-v36-qa';p=r/'moss-v36-r2-prep';s=r/'moss-v36-r2';h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();gate=json.loads((p/'FOCUSED_GATE.json').read_text());rows=gate['steps'];plan=json.loads((r/'moss-v36-catalog-plan/PLAN.json').read_text());assert gate['pass'] and len(rows)==14 and [x['case'] for x in rows]==['cold-import']+plan['focused_cases'];expected=[None,320,102,299,3254,114,112,147,321,48,178,46,132,30];records=[];helpers=[]
for i,row in enumerate(rows):
 assert row['exit']==0 and row['pass'] and row['seconds']<180 and not row['error'] and not row['resource_warning']
 name=row['case'];a=p/'focused'/(name+'.stdout');b=p/'focused'/(name+'.stderr');text=a.read_text()+b.read_text();assert all(x not in text for x in ['ERROR:','SCRIPT ERROR:','instances leaked','resources still in use']);data=[]
 for line in text.splitlines():
  if line.startswith('{'):
   d=json.loads(line)
   if 'failures' in d:data.append(d)
  if line.startswith('TEST_AUDIO_TEARDOWN '):
   d=json.loads(line.split('TEST_AUDIO_TEARDOWN ',1)[1]);assert d['complete'] and d['capture_removed'] and not d['prepare_errors'];assert d['requested_owner_count']==d['tracked_owner_count']>0 and d['game_owner_count']>0;obs=d['observations'];assert all(x['discarded']==0 and x['invalid']==0 for x in obs);last=obs[-1];assert last['owners_released'] and last['streams_released'] and last['new_pushed']>=last['required_frames']>0 and last['silent_frames']>=last['required_frames'] and 150000<=last['elapsed_us']<=1000000;helpers.append({'case':name,'elapsed':last['elapsed_us'],'fresh':last['new_pushed'],'silent':last['silent_frames']})
 if i:
  assert len(data)==1 and data[0]['failures']==[];d=data[0];value=d.get('checks',d.get('bankshot_build_checks',d.get('modifier_copy_checks',d.get('passed'))));assert value==expected[i],(name,value,expected[i])
 records.append({'case':name,'stdout':h(a),'stderr':h(b),'checks':expected[i],'seconds':row['seconds']})
pins=json.loads((p/'R2_INPUTS.json').read_text());assert len(pins)==717 and all(h(s/n)==v for n,v in pins.items());assert h(p/'R2_INPUTS.json')==json.loads((q/'R2_FREEZE_REVIEW.json').read_text())['source_map_sha256'];prod=json.loads((p/'PRODUCTION_FINAL.json').read_text());assert all(h(s/n)==v for n,v in prod.items())
result={'status':'PASS_INDEPENDENT_REVIEW_AUTHOR_R2_FOCUSED','utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'source_map_sha256':h(p/'R2_INPUTS.json'),'records':records,'helper_observations':helpers,'source717_unchanged':True,'production131_unchanged':True,'count_delta':'Reservation 286→299 = projection1+negative11+readonly1; bank113→114 and modifier111→112 +projection1 each. Others unchanged.','scope':'Independent exhaustive raw review, NOT independent focused reexecution. Original first full117/125 remains FAIL. New full125 still mandatory before pack.'};(q/'R2_FOCUSED_RAW_REVIEW.json').write_text(json.dumps(result,indent=2)+'\n');print(result['status'],len(rows),len(helpers))
