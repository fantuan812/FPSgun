"""Not auto-executed. Exact reviewed907 + accepted equipment16 delta, unique new destination only."""
from pathlib import Path
import argparse,json,hashlib,shutil,traceback,sys
q=Path(__file__).resolve().parent
ap=argparse.ArgumentParser();ap.add_argument('--plan-sha256',required=True);args=ap.parse_args()
h=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
plan_path=q/'COPY_PLAN.json';out=q/'assembly-first'
if out.exists():raise SystemExit('REFUSE OVERWRITE')
out.mkdir();plan={};result={'pass':False};original={};after={}
def inv(root):
 result={}
 for p in sorted(root.rglob('*')):
  if '.godot' in p.relative_to(root).parts:continue
  assert not p.is_symlink(),str(p)
  if p.is_file():result[str(p.relative_to(root))]=h(p)
 return result
def pins():
 assert h(plan_path)==args.plan_sha256
 for p,sha in plan['pins'].items():assert h(p)==sha,p
try:
 assert h(plan_path)==args.plan_sha256;plan=json.loads(plan_path.read_text());pins()
 for record in plan['acceptance_receipts']:
  value=json.loads(Path(record['path']).read_text())
  for key in record['required_true']:assert value.get(key) is True
 base=Path(plan['base']);art=Path(plan['accepted_art']);dst=Path(plan['destination']);expected=plan['base_inputs'];delta=plan['delta']
 assert len(expected)==907 and inv(base)==expected
 assert len(plan['art_inputs'])==888 and inv(art)==plan['art_inputs']
 assert not dst.exists();dst.mkdir()
 for rel,sha in expected.items():
  target=dst/rel;target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(base/rel,target);assert h(target)==sha
 assert inv(dst)==expected
 for rel,sha in delta['remove_files'].items():assert h(dst/rel)==sha;(dst/rel).unlink()
 for rel,sha in delta['add_files'].items():
  assert not (dst/rel).exists() and h(art/rel)==sha
  (dst/rel).parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(art/rel,dst/rel)
 for rel,values in delta['replace_files'].items():
  assert h(dst/rel)==values['base_sha256'] and h(art/rel)==values['equipment16_sha256']
  shutil.copyfile(art/rel,dst/rel)
 before_manifest=inv(dst);assert len(before_manifest)==926
 (out/'MANIFEST.base-original.json').write_bytes((dst/'MANIFEST.json').read_bytes())
 (dst/'MANIFEST.json').write_text(json.dumps({k:v for k,v in before_manifest.items() if k!='MANIFEST.json'},indent=2)+'\n')
 after=inv(dst);assert len(after)==926
 diff={k:{'old':expected.get(k),'new':after.get(k)} for k in sorted(expected.keys()|after.keys()) if expected.get(k)!=after.get(k)}
 assert set(diff)==set(delta['add_files'])|set(delta['remove_files'])|set(delta['replace_files'])|{'MANIFEST.json'}
 assert len(diff)==26
 assert inv(base)==expected and inv(art)==plan['art_inputs'];pins()
 (out/'INPUTS.json').write_text(json.dumps(after,indent=2)+'\n');(out/'DIFF.json').write_text(json.dumps(diff,indent=2)+'\n')
 result.update(pass_=True,base_unchanged=True,added=21,removed=2,changed_existing=3,source_count=926,input_map_sha256=h(out/'INPUTS.json'),diff_sha256=h(out/'DIFF.json'));result['pass']=True
except Exception:result['exception']=traceback.format_exc()
finally:
 try:
  pins()
  if inv(Path(plan['base']))!=plan['base_inputs']:result['pass']=False;result['base_changed']=True
  if inv(Path(plan['accepted_art']))!=plan['art_inputs']:result['pass']=False;result['art_changed']=True
 except Exception:result['guard_exception']=traceback.format_exc();result['pass']=False
 (out/'RESULT.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result),flush=True)
sys.exit(0 if result['pass'] else 1)
