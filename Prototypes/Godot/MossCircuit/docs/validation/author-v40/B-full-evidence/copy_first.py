from pathlib import Path
import json,hashlib,shutil,traceback
src=Path('evidence-workspace/moss-v39-B-r2');dst=Path('evidence-workspace/moss-v39-B-full');out=Path(__file__).parent;prep=Path('evidence-workspace/moss-v39-items/B-legacy-proposal');h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
expected=json.loads(Path('evidence-workspace/moss-v39-items/B-evidence/INTEGRATION_R2_INPUTS.json').read_text())['inputs'];changes=json.loads((prep/'PROPOSED_TEST_CHANGES.json').read_text())['changes'];result={'pass':False}
def inventory(root):return {str(p.relative_to(root)):h(p) for p in sorted(root.rglob('*')) if p.is_file() and '.godot' not in p.relative_to(root).parts}
try:
 assert len(expected)==894 and inventory(src)==expected
 assert not dst.exists();dst.mkdir()
 for rel,sha in expected.items():
  p=dst/rel;p.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(src/rel,p);assert h(p)==sha
 assert inventory(dst)==expected
 for rel,v in changes.items():
  p=dst/rel
  assert (h(p) if p.exists() else None)==v['old_sha256']
  candidate=prep/'candidate-tests'/rel;assert h(candidate)==v['new_sha256']
  p.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(candidate,p)
 before_manifest=inventory(dst)
 manifest={k:v for k,v in before_manifest.items() if k!='MANIFEST.json'}
 (dst/'MANIFEST.json').write_text(json.dumps(manifest,indent=2)+'\n')
 actual=inventory(dst);assert len(actual)==901
 changed={k:{'old':expected.get(k),'new':actual.get(k)} for k in sorted(expected.keys()|actual.keys()) if expected.get(k)!=actual.get(k)}
 assert len(changed)==19 and set(changed)==set(changes)|{'MANIFEST.json'}
 assert inventory(src)==expected
 (out/'INPUTS.json').write_text(json.dumps(actual,indent=2)+'\n')
 (out/'DIFF.json').write_text(json.dumps(changed,indent=2)+'\n')
 result.update(pass_=True,source_unchanged=True,base_count=894,new_count=901,changed_existing=12,added=7,map_sha256=h(out/'INPUTS.json'),diff_sha256=h(out/'DIFF.json'))
 result['pass']=True
except Exception as e:result['error']=repr(e);result['traceback']=traceback.format_exc()
finally:
 result['original_map_still_exact']=inventory(src)==expected
 (out/'COPY_FIRST_RESULT.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result));raise SystemExit(0 if result['pass'] else 1)
