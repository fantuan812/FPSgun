from pathlib import Path
import shutil,json,hashlib,datetime
B=Path('evidence-workspace/moss-v39-final-r2');P=Path('evidence-workspace/moss-equipment16-integration-patch');T=Path('evidence-workspace/moss-equipment16-integration-candidate');R=Path(__file__).parent
H=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
def pins(root):return {str(p.relative_to(root)):H(p) for p in sorted(root.rglob('*')) if p.is_file() and '.godot' not in p.relative_to(root).parts}
assert not T.exists(),'do not overwrite an existing candidate'
ops=json.loads((P/'PATCH_OPERATIONS.json').read_text());before=pins(B)
for rel,h in ops['preconditions'].items():assert H(B/rel)==h,rel
shutil.copytree(B,T,ignore=lambda directory,names:['.godot'] if Path(directory)==B and '.godot'in names else [])
for rel,h in ops['payload'].items():
 src=P/'payload'/rel;assert H(src)==h;dst=T/rel;dst.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(src,dst)
for rel in ops['remove_runtime_paths']:(T/rel).unlink()
after=pins(T);added=sorted(set(after)-set(before));removed=sorted(set(before)-set(after));changed=sorted(k for k in set(before)&set(after) if before[k]!=after[k]);assert set(removed)==set(ops['remove_runtime_paths']);assert set(added+changed)==set(ops['payload']);assert pins(B)==before
receipt={'status':'assembled isolated source candidate, not runtime/PCK accepted','time_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'baseline':str(B),'source_release_commit_reported_by_root':'1af3c47c0b9b308b44d3defde82171bf95286fab','commit_tree_mapping':'not independently verified by art lane; local full source pins are authority for this copy','candidate':str(T),'base_file_count':len(before),'candidate_file_count':len(after),'base_identity':hashlib.sha256(json.dumps(before,sort_keys=True,separators=(',',':')).encode()).hexdigest(),'added':added,'removed':removed,'changed':changed,'base_unchanged':True,'omitted_cache':'.godot only; historical docs retained byte-for-byte','no_other_candidate_or_branch_modified':True}
(R/'BASE_PINS.json').write_text(json.dumps(before,indent=2)+'\n');(R/'CANDIDATE_PINS.json').write_text(json.dumps(after,indent=2)+'\n');(R/'ASSEMBLY_RESULT.json').write_text(json.dumps(receipt,indent=2)+'\n');print(json.dumps(receipt,indent=2))
