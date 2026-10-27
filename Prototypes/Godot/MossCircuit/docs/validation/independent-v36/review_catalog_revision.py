from pathlib import Path
import json,hashlib,difflib,copy
R=Path('<WORKSPACE>'); p=R/'moss-v36-catalog-plan'; a=R/'moss-v36-final'; b=R/'moss-v36-r2'
h=lambda x:hashlib.sha256(x).hexdigest()
plan=json.loads((p/'PLAN.json').read_text()); pins=json.loads((p/'PREIMPORT_INPUTS.json').read_text()); old=json.loads((R/'moss-v36-final-prep/FINAL_INPUTS.json').read_text()); prod=json.loads((R/'moss-v36-final-prep/PRODUCTION_FINAL.json').read_text())
assert len(pins)==716 and len(old)==714 and len(prod)==131
assert all(h((b/n).read_bytes())==s for n,s in pins.items())
assert all(h((a/n).read_bytes())==s for n,s in old.items())
assert set(n for n in old if old[n]!=pins[n])==set(plan['changes']) and len(plan['changes'])==8
assert set(pins)-set(old)==set(plan['new_files']) and len(plan['new_files'])==2
assert all(pins[n]==s for n,s in prod.items())
audit=[]
for n,v in plan['changes'].items():
 before=(a/n).read_text();after=(b/n).read_text();patch=(p/'diffs'/(Path(n).name+'.patch')).read_text()
 expected=''.join(difflib.unified_diff(before.splitlines(True),after.splitlines(True),fromfile='rejected714/'+n,tofile='r2/'+n))
 assert patch==expected and h(before.encode())==v['before'] and h(after.encode())==v['after']
 # Independently reconstruct both sides of every hunk and match unchanged spans.
 lines=patch.splitlines(True); source=before.splitlines(True); dest=after.splitlines(True); i=2
 import re
 while i<len(lines):
  m=re.match(r'@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@',lines[i]); assert m; i+=1; left=[];right=[]
  while i<len(lines) and not lines[i].startswith('@@'):
   ln=lines[i];assert ln[0] in ' +-';
   if ln[0] in ' -':left.append(ln[1:])
   if ln[0] in ' +':right.append(ln[1:])
   i+=1
  x,y=int(m[1])-1,int(m[3])-1; assert source[x:x+len(left)]==left and dest[y:y+len(right)]==right
 audit.append({'path':n,'before':v['before'],'after':v['after'],'hunks_exact':True})
d=json.loads((b/'tests/fixtures/v36_catalog_additions.json').read_text());raw=(b/'data/catalog.json').read_text();c=json.loads(raw)
for key,dk in [('items','item'),('mechanism_synergies','pair'),('affinity_links','link')]:
 assert c[key][-1]==d[dk]; c[key].pop()
for dk,ins in zip(['item','pair','link'],d['raw_insertions']):
 value=d[dk];ls=json.dumps(value,indent=2).splitlines();close='}' if isinstance(value,dict) else ']'
 assert ins=='    '+close+',\n'+'\n'.join('    '+line for line in ls[:-1])+'\n'
 assert raw.count(ins)==1;raw=raw.replace(ins,'')
assert raw.encode()==(R/'moss-v35-r4/data/catalog.json').read_bytes()
assert h(raw.encode())=='317a2d343ba1a005cd44cc1c2ee91e894adf059d77e57c24f7a5ee9439ec56a0'
assert json.loads(raw)==c
profile='  "weapon_tempering": {\n    "max_tier": 1,\n    "primary_damage_multiplier": 1.6\n  },\n'
assert raw.count(profile)==1 and h(raw.replace(profile,'').encode())=='88002883c5f1141e8d9adf2f95418c81b52b397a44feee46946876bbf8a984d7'
result={'status':'STATIC_PASS_NO_ENGINE_EXECUTION','plan_sha256':h((p/'PLAN.json').read_bytes()),'map_sha256':h((p/'PREIMPORT_INPUTS.json').read_bytes()),'inputs':716,'production_unchanged':131,'changed_fixtures':audit,'new_files':plan['new_files'],'declaration_review':'Explicit authored expected values agree C2; raw insertions independently regenerated from declaration, not inferred from candidate bytes. Exactly three append blocks removed; held v35 full bytes and old 317a/8800 assertions retained.','semantics':'Current catalog used for existing behavioral tests; only historical copy/pair/raw projections use duplicated validated history. Original failed aggregate remains FAIL.','limitations':'Static only; actual Godot parser and 11 mutation rejection probes pending focused execution.'}
(R/'moss-v36-qa/CATALOG_REVISION_STATIC_REVIEW.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2))
