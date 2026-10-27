from pathlib import Path
import json,hashlib,re,datetime
p=Path('<WORKSPACE_ROOT>/shared');q=p/'moss-v39-prep/final-full';out=q/'full-first';a=out/'aggregate';plan=json.loads((q/'FULL_PLAN.json').read_text());h=lambda f:hashlib.sha256(f.read_bytes()).hexdigest();checks=[];helper_count=0;semantic_count=0;failures=[];warnings=[]
def ck(ok,label):
 assert ok,label
 checks.append(label)
ck(h(q/'FULL_PLAN.json')=='ac1fdaac1fd3073a9661161706238bd92bfc4e9e290860dc2c693f8332d4b938','actual frozen full plan')
ck((q/'full-wrapper.exit').is_file() and (out/'native.exit').is_file(),'original true terminal artifacts present')
rows=json.loads((a/'summary.json').read_text());aggregate=json.loads((a/'result.json').read_text());result=json.loads((out/'RESULT.json').read_text())
ck([r['test'] for r in rows]==['import']+[Path(x).name for x in plan['discovery_scripts']] and len(rows)==151,'all actual151 exact ordered discovery')
for k,v in plan['pins'].items():ck(h(Path(k))==v,'frozen pin '+k)
for root,mp in [(Path(plan['source']),Path(plan['input_map'])),(Path(plan['r3_source']),Path(plan['r3_map']))]:
 expected=json.loads(mp.read_text());actual={str(f.relative_to(root)):h(f) for f in root.rglob('*') if f.is_file() and '.godot' not in f.relative_to(root).parts};ck(actual==expected,'full source exact '+str(root))
input_hashes=json.loads((a/'input-hashes.json').read_text());ck(input_hashes['before']==input_hashes['after'] and input_hashes['changed']==[],'generic input beforeafter unchanged')
for row in rows:
 name=row['test'];path=a/(name+'.log');raw=path.read_text();ck(path.is_file(),'original raw '+name)
 reports=[];helpers=[]
 for line in raw.splitlines():
  if line.startswith('TEST_AUDIO_TEARDOWN '):helpers.append(json.loads(line.split(' ',1)[1]))
  if 'WARNING' in line:warnings.append({'test':name,'line':line})
 consumed=0;decoder=json.JSONDecoder()
 for match in re.finditer(r'(?m)^[ \t]*\{',raw):
  start=raw.index('{',match.start())
  if start<consumed:continue
  j,end=decoder.raw_decode(raw[start:]);consumed=start+end
  if isinstance(j,dict):reports.append(j)
 semantic_count+=len(reports)
 bad=[tag for tag in ['SCRIPT ERROR','ERROR:','Parse Error','instances leaked','resources still in use'] if tag in raw]
 ck(bool('ERROR:' in raw)==row['error'],'generic error flag actual '+name)
 semantic_fail=[j.get('failures') for j in reports if j.get('failures') not in [None,[]]]
 if row['pass']:ck(row['exit']==0 and not bad and not semantic_fail and row['seconds']<=180,'passed route strict raw '+name)
 else:failures.append({'test':name,'native_exit':row['exit'],'seconds':row['seconds'],'strict_tags':bad,'semantic_failures':semantic_fail,'raw_sha256':h(path),'reports':reports})
 if name in plan['declared_exact_counts_for_raw_review']:
  for key,value in plan['declared_exact_counts_for_raw_review'][name].items():ck(any(j.get(key)==value for j in reports),'declared exact count '+name+' '+key)
 for helper in helpers:
  helper_count+=1;obs=helper['observations'];last=obs[-1]
  ck(helper['complete'] and helper['capture_removed'] and helper['prepare_errors']==[] and helper['requested_owner_count']==helper['tracked_owner_count']>0 and helper['game_owner_count']>0 and helper['tracked_stream_count']>0,'helper owners/preparation '+name)
  ck(last['owners_released'] and last['streams_released'] and 150000<=last['elapsed_us']<=1000000 and last['new_pushed']>=last['required_frames']>0 and last['silent_frames']>=last['required_frames'] and all(x['invalid']==x['discarded']==x['prepare_errors']==0 for x in obs),'helper bounded fresh silence '+name)
passed=sum(x['pass'] for x in rows);target_pass=passed==151
ck(aggregate['entries']==150 and aggregate['passed']==passed and aggregate['all_pass']==target_pass,'actual summary matches raw route outcomes')
ck(int((out/'native.exit').read_text())==(0 if target_pass else 1) and int((q/'full-wrapper.exit').read_text())==(0 if result['pass_gate'] else 1),'original native and wrapper exits truthful')
ck(result['full_source_unchanged'] and result['all_pins_unchanged'] and result['original_r3_unchanged'] and result['exact_discovery_order'],'wrapper full guards truthful')
r={'audit_pass':True,'target_pass':target_pass,'separate_reviewer':True,'scope':'Independent complete original full151 raw/semantic/helper and source identity audit; no target rerun. Audit pass is not target acceptance if any route failed.','checks':len(checks),'source_map_sha256':h(Path(plan['input_map'])),'plan_sha256':h(q/'FULL_PLAN.json'),'routes':151,'passed':passed,'failed':len(failures),'semantic_reports':semantic_count,'shared_helper_records':helper_count,'warning_lines':warnings,'failures':failures,'native_exit':int((out/'native.exit').read_text()),'wrapper_exit':int((q/'full-wrapper.exit').read_text()),'time_utc':datetime.datetime.now(datetime.timezone.utc).isoformat()}
path=p/'moss-v39-qa/FIRST_FULL151_RAW_REVIEW.json';path.write_text(json.dumps(r,indent=2)+'\n');print(json.dumps({'audit_pass':True,'target_pass':target_pass,'passed':passed,'failed':len(failures),'receipt_sha256':h(path)}))
