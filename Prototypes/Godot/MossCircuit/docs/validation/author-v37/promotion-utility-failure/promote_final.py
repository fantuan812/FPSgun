from pathlib import Path
import json,hashlib,shutil
r=Path('workspace/shared');src=r/'moss-v37-work';dst=r/'moss-v37-final';out=r/'moss-v37-final-prep';assert not dst.exists() and not out.exists();dst.mkdir();out.mkdir();h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();m=json.loads((r/'moss-v37-prep/POSTIMPORT_INPUTS.json').read_text())
for n,s in m.items():
 p=src/n;assert h(p)==s;q=dst/n;q.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,q)
rows=json.loads((r/'moss-v37-qa/PROMOTION_TESTS.json').read_text())['files']
for row in rows:
 p=Path(row['source']);assert h(p)==row['sha256'];q=dst/row['destination'];assert not q.exists();shutil.copy2(p,q)
docs=json.loads((r/'moss-v37-prep/PREPARED_DOC_INPUTS.json').read_text())
for n,s in docs.items():
 p=r/'moss-v37-prep/prepared-docs'/n;assert h(p)==s;shutil.copy2(p,dst/n)
prodkeys=list(json.loads((r/'moss-v36-r2-prep/PRODUCTION_FINAL.json').read_text()))+['scripts/gameplay/build_forecast.gd','ui/forecast_glyph.gd'];prod={n:h(src/n) for n in prodkeys};assert all(h(dst/n)==s for n,s in prod.items());assert h(dst/'tests/run_regression.py')==h(src/'tests/run_regression.py');assert not (dst/'.godot').exists()
new={str(p.relative_to(dst)):h(p) for p in sorted(dst.rglob('*')) if p.is_file()};changed={n:{'before':m[n],'after':s} for n,s in new.items() if n in m and m[n]!=s};added={n:s for n,s in new.items() if n not in m};assert set(changed)==set(docs)-set(added)
for name,obj in [('PREIMPORT_INPUTS.json',new),('PRODUCTION_FINAL.json',prod),('PROMOTION.json',{'tests':rows,'docs':docs,'production133_exact_focused_candidate':True,'runner_exact':True,'added':added,'changed':changed,'removed':[],'historical_work_inputs':723})]:(out/name).write_text(json.dumps(obj,indent=2,sort_keys=True)+'\n')
print({'preimport':len(new),'production':len(prod),'added':list(added),'changed':list(changed)})
