"""Run only inside the agreed copy/hash window. No engine, no production mutation."""
from pathlib import Path
import json,hashlib,copy,shutil,difflib,re,datetime
R=Path(__file__).parent;B=Path('evidence-workspace/moss-v39-B-equipment16');M=Path('evidence-workspace/moss-v39-items/B-equipment16-combination/assembly-first/INPUTS.json');P=Path('evidence-workspace/moss-held8-integration-patch');T=Path('evidence-workspace/moss-held8-integration-candidate');H=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
def snap(root):return {str(p.relative_to(root)):H(p)for p in sorted(root.rglob('*'))if p.is_file()and '.godot'not in p.relative_to(root).parts}
assert H(M)=='543d43c875b72b7682c312a4811094007e679c419d2142aa86c0d59728b57440';expected=json.loads(M.read_text());assert len(expected)==926;assert not T.exists();before=snap(B);assert before==expected
ops=json.loads((P/'PATCH_OPERATIONS.json').read_text());assert all(H(P/'payload'/p)==h for p,h in ops['payload'].items());identity=json.loads((P/'HELD8_IDENTITY.json').read_text());selected=[x['id']for x in identity['records']];rel='assets/weapon_mounts/world_weapon_manifest.json';base_text=(B/rel).read_text();old=json.loads(base_text);patch=json.loads((P/'payload'/rel).read_text());new=copy.deepcopy(old)
for id in selected:
 assert all(old['weapons'][id][f]==patch['weapons'][id][f]for f in ops['geometry_fields']);new['weapons'][id]=patch['weapons'][id]
assert all(new['weapons'][id]==old['weapons'][id]for id in old['weapons']if id not in selected)
text=json.dumps(new,ensure_ascii=False,indent=2)+'\n'
def token(s,id,f):
 sub=s[s.index('"'+id+'"'):];match=re.search('"'+f+r'"\s*:\s*',sub);_,end=json.JSONDecoder().raw_decode(sub[match.end():]);return sub[match.end():match.end()+end]
for id in selected:
 for f in ops['geometry_fields']:assert token(base_text,id,f)==token(text,id,f)
shutil.copytree(B,T,ignore=lambda directory,names:['.godot']if Path(directory)==B and '.godot'in names else [])
for path in ops['payload']:
 if path in [rel,'export_presets.cfg']:continue
 dest=T/path;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(P/'payload'/path,dest)
(T/rel).write_text(text)
lines=[]
for line in (B/'export_presets.cfg').read_text().splitlines():
 if line.startswith('exclude_filter="'):
  items=line[len('exclude_filter="'):-1].split(',')
  for entry in ops['source_reference_excludes']:
   if entry not in items:items.append(entry)
  line='exclude_filter="'+','.join(items)+'"'
 lines.append(line)
(T/'export_presets.cfg').write_text('\n'.join(lines)+'\n')
for path in ops['remove_old_sidecars']:assert H(B/path)==ops['preconditions'][path];(T/path).unlink()
after=snap(T);added=sorted(set(after)-set(before));removed=sorted(set(before)-set(after));changed=sorted(k for k in set(before)&set(after)if before[k]!=after[k]);assert len(after)==927;assert len(added)==9 and len(removed)==8 and len(changed)==10;assert set(removed)==set(ops['remove_old_sidecars']);assert set(changed)=={rel,'export_presets.cfg'}|{x.removeprefix('res://')for x in ops['same_path_replacements']};assert snap(B)==before
(R/'BASE_926_PINS.json').write_text(json.dumps(before,indent=2)+'\n');(R/'CANDIDATE_927_PINS.json').write_text(json.dumps(after,indent=2)+'\n');(R/'WORLD_MANIFEST_BEFORE.json').write_text(base_text)
diff=''
for path in [rel,'export_presets.cfg']:diff+=''.join(difflib.unified_diff((B/path).read_text().splitlines(True),(T/path).read_text().splitlines(True),fromfile='B926/'+path,tofile='held8/'+path))
(R/'APPLIED_TEXT_DIFF.patch').write_text(diff)
result={'status':'isolated held8 next-candidate only; B not yet published and held8 may not bypass B release','utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'base':str(B),'base_map':str(M),'base_map_sha256':H(M),'base_count':926,'candidate':str(T),'candidate_count_before_cold':927,'future_count_if_exact8sidecars_generated':935,'added':added,'removed':removed,'changed':changed,'all_base926_before_after_unchanged':True,'old6geometry_value_tokens_exact':True,'other_weapon_records_unchanged':True,'B_catalog_gameplay_UI_and_equipment16_unchanged':True,'historical_docs_and_MANIFEST':'preserved currentB bytes; external927 map authority until explicit newdeliverymetadata','engine_or_PCK_or_native_run':False,'legacy_active_formal':55,'held8_candidate_not_counted':True}
(R/'ASSEMBLY_RESULT.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2))
