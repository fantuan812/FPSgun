from pathlib import Path
import json,hashlib,re,difflib,xml.etree.ElementTree as ET
from PIL import Image
R=Path('evidence-workspace/moss-held8-integration-review');C=Path('evidence-workspace/moss-held8-integration-candidate');B=Path('evidence-workspace/moss-v39-B-equipment16');P=Path('evidence-workspace/moss-held8-integration-patch');O=Path(__file__).parent
H=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
def snap(root):return {str(p.relative_to(root)):H(p) for p in sorted(root.rglob('*')) if p.is_file() and '.godot' not in p.relative_to(root).parts}
b=json.loads((R/'BASE_926_PINS.json').read_text());c=json.loads((R/'CANDIDATE_927_PINS.json').read_text());assert len(b)==926 and len(c)==927
assert snap(B)==b;assert snap(C)==c
res=json.loads((R/'ASSEMBLY_RESULT.json').read_text());assert sorted(c.keys()-b.keys())==res['added'];assert sorted(b.keys()-c.keys())==res['removed'];assert sorted(k for k in b.keys()&c.keys() if b[k]!=c[k])==res['changed']
assert (len(res['added']),len(res['removed']),len(res['changed']))==(9,8,10)
rel='assets/weapon_mounts/world_weapon_manifest.json';old=json.loads((B/rel).read_text());new=json.loads((C/rel).read_text());fields=['region','grip','muzzle','projectile_anchor','reference_width','visible_length'];ops=json.loads((P/'PATCH_OPERATIONS.json').read_text());inventory=json.loads((R/'TEST_DRAFT_INVENTORY.json').read_text());assert set(inventory['cold_expected_new_files'])==set(res['removed'])
ids=['rivet_gun','scrap_shotgun','rail_lance','orbit_saw','return_disc','shock_mortar','cryo_sprayer','bankshot_driver'];lengths=[28,34,42,30,30,32,32,32];assets=[]
for id,length in zip(ids,lengths):
 a=new['weapons'][id];z=old['weapons'][id]
 for field in fields:
  assert a[field]==z[field]
  def token(text):
   text=text[text.index('"'+id+'"'):];m=re.search('"'+field+r'"\s*:\s*',text);s=text[m.end():];_,n=json.JSONDecoder().raw_decode(s);return s[:n]
  assert token((C/rel).read_text())==token((B/rel).read_text())
 assert a['visible_length']==length
 q=C/a['path'].removeprefix('res://');assert H(q)==a['sha256'];assert q.read_bytes()==(P/'payload'/q.relative_to(C)).read_bytes()
 im=Image.open(q).convert('RGBA');box=im.getchannel('A').point(lambda x:255 if x>8 else 0).getbbox();assert box
 xywh=[box[0],box[1],box[2]-box[0],box[3]-box[1]];assert xywh==a['alpha_bbox'],(id,xywh,a['alpha_bbox'])
 assert list(im.size)==a['region'][2:]
 gp=a['grip_px'];assert im.getpixel((round(gp[0]),round(gp[1])))[3]==255
 svg=C/a['source_svg'];assert H(svg)==a['svg_sha256'];assert svg.read_bytes()==(P/'payload'/svg.relative_to(C)).read_bytes()
 tree=ET.parse(svg)
 assert not any(e.tag.split('}')[-1] in ['image','text','foreignObject','script'] for e in tree.iter())
 assert b'data:image' not in svg.read_bytes()
 if id in ['orbit_saw','return_disc']:assert a['grip']==a['muzzle']==a['projectile_anchor']
 assets.append({'id':id,'png_sha256':H(q),'svg_sha256':H(svg),'alpha_gt8_bbox':xywh,'grip_alpha':255,'visible_length':length})
assert {k:v for k,v in old['weapons'].items() if k not in ids}=={k:v for k,v in new['weapons'].items() if k not in ids}
assert (C/'art_source/legacy_held_L1_C2/.gdignore').exists()
for line in (C/'export_presets.cfg').read_text().splitlines():
 if line.startswith('exclude_filter='):
  assert all(x in line for x in ops['source_reference_excludes'])
actual_diff=''
for f in [rel,'export_presets.cfg']:actual_diff+=''.join(difflib.unified_diff((B/f).read_text().splitlines(True),(C/f).read_text().splitlines(True),fromfile='B926/'+f,tofile='held8/'+f))
assert actual_diff==(R/'APPLIED_TEXT_DIFF.patch').read_text()
for f,h in inventory['tests'].items():assert H(R/'tests'/f)==h
assert inventory['tests']['support/audio_teardown.gd']=='9e9676e34296cb55d4560b1169c5954a82508f70e9051fcc942d1bb6839c23bd'
assert snap(C)==c;assert snap(B)==b
out={'review_pass':True,'scope':'Independent source/asset full bytes and finite fixture static review only; no engine, fresh export, PCK or native acceptance.','base_files':926,'candidate_files':927,'exact_added':res['added'],'exact_removed':res['removed'],'exact_changed':res['changed'],'candidate_map_sha256':H(R/'CANDIDATE_927_PINS.json'),'all_base_candidate_before_after_exact':True,'png_svg_payload_and_alpha':assets,'geometry_6_tokens_exact':True,'other_weapon_records_exact':True,'future_cold_exact_new_sidecars':inventory['cold_expected_new_files'],'future_count':935,'fixture_static':{'geometry_expected_checks':23090,'poses':4608,'range_comparisons':13824,'fire_expected_checks':1089,'paired_cases':136,'actual_fire_calls':272,'same_runtime_golden_comparison_not_independent_solver':True,'unexecuted':True},'limits':['Old C2 21504 receipt not reused as current target acceptance.','Return Disc alpha width1102 retains old calibration reference1092; actual runtime pose/fire gates remain pending.','Historical docs/MANIFEST remain tested baseline bytes, not a publishable new version.','Cold import must add exactly the eight declared sidecars; no other source mutation.']}
q=O/'FULL_STATIC_REVIEW.json';q.write_text(json.dumps(out,indent=2)+'\n');print('PASS',H(q))
