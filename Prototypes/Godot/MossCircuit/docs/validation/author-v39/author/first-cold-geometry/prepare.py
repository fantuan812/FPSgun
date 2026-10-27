from pathlib import Path
import json,hashlib
r=Path('evidence-workspace/moss-v39-work');p=Path(__file__).parent;h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
files={str(f.relative_to(r)):h(f) for f in sorted(r.rglob('*')) if f.is_file() and '.godot' not in f.relative_to(r).parts and f.name!='MANIFEST.json'}
(r/'MANIFEST.json').write_text(json.dumps(files,indent=2,ensure_ascii=False)+'\n');files['MANIFEST.json']=h(r/'MANIFEST.json')
(p/'INPUTS.json').write_text(json.dumps(files,indent=2)+'\n')
base=json.loads(Path('evidence-workspace/moss-v39-prep/BASELINE_787.json').read_text());diff=dict(changed=[dict(path=n,old=base[n],new=files[n]) for n in base if files[n]!=base[n]],added=[dict(path=n,sha256=files[n]) for n in sorted(set(files)-set(base))],removed=[])
(p/'DIFF.json').write_text(json.dumps(diff,indent=2)+'\n')
allowed=[]
for n in files:
 if n.endswith('.gd') and n+'.uid' not in files:allowed.append(n+'.uid')
 if n.endswith(('.png','.svg')) and n+'.import' not in files:allowed.append(n+'.import')
plan=dict(scope='First author cold import then independent frozen850 geometry checks, no full/runtime/native claim',input_count=len(files),input_map=str(p/'INPUTS.json'),per_case_seconds=180,exact_import_additions=sorted(allowed),geometry_script='evidence-workspace/moss-v39-qa/checks/independent_new_weapon_geometry.gd',pins={str(p/'INPUTS.json'):h(p/'INPUTS.json'),str(p/'DIFF.json'):h(p/'DIFF.json'),str(p/'run.py'):h(p/'run.py'),'evidence-workspace/moss-v39-qa/checks/independent_new_weapon_geometry.gd':h(Path('evidence-workspace/moss-v39-qa/checks/independent_new_weapon_geometry.gd')),'evidence-workspace/moss-v39-qa/pretarget/GEOMETRY_API_CASES.json':h(Path('evidence-workspace/moss-v39-qa/pretarget/GEOMETRY_API_CASES.json')),'evidence-workspace/moss-v39-qa/pretarget/FREEZE.json':h(Path('evidence-workspace/moss-v39-qa/pretarget/FREEZE.json'))})
(p/'PLAN.json').write_text(json.dumps(plan,indent=2)+'\n');print(json.dumps(dict(inputs=len(files),changed=len(diff['changed']),added=len(diff['added']),expected_import_additions=len(allowed),plan_sha256=h(p/'PLAN.json'))))
