from pathlib import Path
import json,hashlib,difflib
r=Path('workspace/shared');w=r/'moss-v38-work';p=r/'moss-v38-prep';assert not (w/'.godot').exists();m={str(f.relative_to(w)):hashlib.sha256(f.read_bytes()).hexdigest() for f in sorted(w.rglob('*')) if f.is_file()};(p/'PREIMPORT_INPUTS.json').write_text(json.dumps(m,indent=2)+'\n');base=json.loads((p/'BASELINE_INPUTS.json').read_text());changes={n:{'old':base.get(n),'new':h} for n,h in m.items() if base.get(n)!=h};(p/'PREIMPORT_CHANGES.json').write_text(json.dumps(changes,indent=2)+'\n');diff=[]
for n,d in changes.items():
 if not n.endswith(('.gd','.json')):continue
 before=(r/'moss-v37-final'/n).read_text() if n in base else ''
 diff.extend(difflib.unified_diff(before.splitlines(True),(w/n).read_text().splitlines(True),fromfile='v37/'+n,tofile='v38/'+n))
(p/'PREIMPORT_DIFF.patch').write_text(''.join(diff));print({'inputs':len(m),'changed_existing':sum(n in base for n in changes),'new':sum(n not in base for n in changes),'mapsha':hashlib.sha256((p/'PREIMPORT_INPUTS.json').read_bytes()).hexdigest()})
