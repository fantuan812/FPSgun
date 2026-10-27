from pathlib import Path
import json,hashlib,ast
q=Path(__file__).resolve().parent;project=Path('evidence-workspace/moss-v39-B-full');evidence=q.parent;scope=Path('evidence-workspace/moss-v39-items/B-whole-scope');h=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
ref=json.loads((scope/'SOURCE_DISCOVERY_REFERENCE_DRAFT.json').read_text());inputs=json.loads((evidence/'post-cold/INPUTS.json').read_text());logs=Path('evidence-workspace/moss-v39-prep/final-full/full-first/aggregate');routes=[];pins={}
for r in ref['new_top_level_tests']:
 routes.append({'name':Path(r['path']).stem,'script':'res://'+r['path'],'domain':'actual B' if 'cache' not in r['path'] and 'projection' not in r['path'] else 'explicit historical fixture integrity','marker':{'kind':'json','prefix':'','counts':{'checks':r['checks']}},'helper_schemas':[{'owners':r['owners'],'game_owners':r['owners']}] if r['helpers'] else []})
for r in ref['external_current_B_routes']:
 x={'name':r['name'],'script':r['script'],'domain':'actual B pure/resource or controlled chain as original explicit scope','marker':{'kind':'json','prefix':'','counts':{r['marker']:r['checks']}},'helper_schemas':[{'owners':r['owners'],'game_owners':r['owners']}] if r['helpers'] else []}
 if r.get('observations') is not None:x['observations']=r['observations']
 if r.get('expected'):x['expected_file']=r['expected'];x['write_report']=True;pins[r['expected']]=r['expected_sha256']
 pins[r['script']]=r['sha256'];routes.append(x)
for r in ref['routes']:
 name=Path(r['path']).name;m=r['planned_markers'][0]
 marker={'kind':'json','prefix':m['prefix'],'counts':m['counts']} if 'counts' in m else {'kind':'text','text':m['text_reference']}
 schemas=[]
 for line in (logs/(name+'.log')).read_text().splitlines():
  if line.startswith('TEST_AUDIO_TEARDOWN '):
   d=json.loads(line.split(' ',1)[1]);schemas.append({'owners':d['requested_owner_count'],'game_owners':d['game_owner_count']})
 x={'name':r['path'].replace('/','__').removesuffix('.gd'),'script':'res://'+r['path'],'domain':r['domain'],'marker':marker,'helper_schemas':schemas,'reference_old_raw':r['reference_log']}
 if name in ['independent_feedback_authority.gd','independent_feedback_authority_rooms.gd','independent_feedback_mixer.gd','independent_feedback_views.gd','independent_settlement_types.gd']:x['write_report']=True
 if name=='independent_feedback_mixer.gd':x['mixer_pcm']=True
 routes.append(x)
assert len(routes)==165 and len({r['name'] for r in routes})==165
assert len({r['script'] for r in routes})==165
actual=sorted('res://'+str(p.relative_to(project)) for p in list((project/'tests').glob('*.gd'))+[project/'ui/test_ui.gd']+list((project/'docs/art').glob('check*.gd')) if p.read_text().lstrip().startswith('extends SceneTree'))
assert len(actual)==154 and actual==sorted(r['script'] for r in routes if r['script'].startswith('res://'))
original=json.load(open('evidence-workspace/moss-v39-items/B-evidence/INTEGRATION_R2_INPUTS.json'))['inputs'];pins.update({str(Path('evidence-workspace/moss-v39-B-r2')/k):v for k,v in original.items()})
files=[q/'run_full.py',q/'prepare_plan.py',evidence/'post-cold/INPUTS.json',evidence/'post-cold/DIFF.json',evidence/'post-cold/INPUTS.cold-original.json',evidence/'cold/raw-first/RESULT.json',Path('evidence-workspace/moss-v39-B-qa/B_FULL_COLD_RAW_REVIEW.json'),Path('evidence-workspace/moss-v39-B-qa/B_FULL_ASSEMBLY_STATIC_REVIEW.json'),scope/'WHOLE_SCOPE_REVIEW.json',scope/'SOURCE_DISCOVERY_REFERENCE_DRAFT.json',Path('evidence-workspace/moss-v39-B-qa/assets/STATIC_EXPECTATION_FREEZE.json'),Path('evidence-workspace/moss-v39-B-qa/pretarget/FREEZE.json')]
files+=list(Path('evidence-workspace/moss-v39-items/B-final-review').glob('B_*'))
for f in files:
 if f.is_file():pins[str(f)]=h(f)
plan={'status':'STATIC_REVIEW_NO_ENGINE_LEASE','project':str(project),'inputs':inputs,'pins':pins,'preconditions':[{'path':str(evidence/'cold/raw-first/RESULT.json'),'pass_key':'pass'},{'path':'evidence-workspace/moss-v39-B-qa/B_FULL_COLD_RAW_REVIEW.json','pass_key':'pass'}],'routes':routes,'exact_routes':165,'seconds_each':180,'cold_excluded':True,'first_failure_stops':True,'helper_policy':'per-route requested/tracked versus game owners distinct; every obs prepare_errors/invalid/discarded0, exact fresh0.15s frames, final released/capture removed,150000..1000000us; no helper for pure/resource routes','original_runner_difference':'explicit firstFAIL; original A generic continued all routes. Original text/json predicate counts retained with declared historical adapters and explicit new19.','limits':'Source-only; no PCK/native/ordinary acceptance; initial FAIL histories retained; no automatic retry'}
(q/'PLAN.json').write_text(json.dumps(plan,indent=2)+'\n');ast.parse((q/'run_full.py').read_text());print('165 scripts/154 project +11 external,907 source, PLAN',h(q/'PLAN.json'))
