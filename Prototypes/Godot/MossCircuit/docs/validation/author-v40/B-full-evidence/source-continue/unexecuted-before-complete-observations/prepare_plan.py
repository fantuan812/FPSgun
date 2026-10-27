from pathlib import Path
import json,hashlib,ast
q=Path(__file__).resolve().parent;old=q.parent/'source';schema=q.parent/'report-schema-review';h=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
original=json.loads((old/'PLAN.json').read_text());raw=old/'raw-first';steps=json.loads((raw/'STEPS.json').read_text());assert len(steps)==36 and all(r['pass'] for r in steps[:35]) and steps[35]['name']=='tests__independent_feedback_authority' and not steps[35]['pass']
assert [r['name'] for r in original['routes'][:36]]==[r['name'] for r in steps]
plan={k:v for k,v in original.items() if k not in ['routes','exact_routes','pins','preconditions']};plan['routes']=original['routes'][36:];assert len(plan['routes'])==129
policies=json.loads((schema/'POLICIES.json').read_text())['policies']
for route in plan['routes']:
 if route.get('write_report'):route['report_policy']=policies[route['name']]
plan['exact_routes']=129;plan['status']='STATIC_REVIEW_ONLY_NO_ENGINE_LEASE';plan['continuation']='First35 original source routes + actual original435 complete report independently accepted, then remaining129. Original36-stop aggregate FAIL retained; not new all165 single run.'
receipt=Path('evidence-workspace/moss-v39-B-qa/B_SOURCE_STOP36_FULL435_REVIEW.json')
plan['preconditions']=original['preconditions']+[{'path':str(receipt),'pass_key':k} for k in ['review_pass','prior35_original_routes_pass','actual_435_semantic_pass','source907_all_live_pins_unchanged']]+[{'path':str(schema/'PYTHON_NEGATIVES.json'),'pass_key':'pass'}]
pins=dict(original['pins']);pins[str(old/'PLAN.json')]=h(old/'PLAN.json');pins[str(receipt)]=h(receipt)
for f in [q/'run_remaining.py',q/'prepare_plan.py',q/'warning_policy.py',q/'report_policy.py',schema/'REPORT_SCHEMA.md',schema/'POLICIES.json',schema/'PYTHON_NEGATIVES.json',schema/'prepare_policy.py',schema/'report_policy.py',raw/'RESULT.json',raw/'STEPS.json',raw/'BEFORE.json',raw/'AFTER.json']:pins[str(f)]=h(f)
for row in steps:
 for f in (raw/row['name']).iterdir():
  if f.is_file():pins[str(f)]=h(f)
plan['pins']=pins
(q/'PLAN.json').write_text(json.dumps(plan,indent=2)+'\n');ast.parse((q/'run_remaining.py').read_text());print('129 only PLAN',h(q/'PLAN.json'))
