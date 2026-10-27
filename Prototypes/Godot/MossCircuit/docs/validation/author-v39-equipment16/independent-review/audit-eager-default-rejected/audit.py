from pathlib import Path
import json,hashlib,xml.etree.ElementTree as ET
from PIL import Image
B=Path('evidence-workspace/moss-v39-final-r2');T=Path('evidence-workspace/moss-equipment16-integration-candidate');R=Path('evidence-workspace/moss-equipment16-integration-review');O=Path(__file__).parent;A=Path('evidence-workspace/moss-equipment-atlas-svg-candidate')
h=lambda b:hashlib.sha256(b).hexdigest();j=lambda p:json.loads(p.read_text())
def pins(root):
 out={}
 for p in sorted(root.rglob('*')):
  if '.godot' in p.relative_to(root).parts:continue
  assert not p.is_symlink(),str(p)
  if p.is_file():out[str(p.relative_to(root))]=h(p.read_bytes())
 return out
b=pins(B);t=pins(T);assert b==j(R/'BASE_PINS.json') and t==j(R/'CANDIDATE_PINS.json');assert len(b)==869 and len(t)==886
added=sorted(set(t)-set(b));removed=sorted(set(b)-set(t));changed=sorted(k for k in b.keys()&t.keys() if b[k]!=t[k]);r=j(R/'ASSEMBLY_RESULT.json');assert added==r['added'] and removed==r['removed'] and changed==r['changed'];assert len(added)==19 and len(removed)==2 and changed==['assets/items/icon_manifest.json','export_presets.cfg']
ops=j(Path('evidence-workspace/moss-equipment16-integration-patch/PATCH_OPERATIONS.json'));assert set(added+changed)==set(ops['payload']);assert all(t[k]==v for k,v in ops['payload'].items());assert all(b[k]==v for k,v in ops['preconditions'].items())
old=j(B/'assets/items/icon_manifest.json');new=j(T/'assets/items/icon_manifest.json');assert list(old['icons'])==list(new['icons']) and len(new['icons'])==16;assert all(old['icons'][k]['name']==v['name'] and old['icons'][k]['category']==v['category'] for k,v in new['icons'].items());assert new==j(A/'assets/items/icon_manifest.json');assert all(v['rect']==[(i%4)*64,(i//4)*64,64,64] for i,v in enumerate(new['icons'].values()))
assert new['atlas']=='res://assets/items/equipment_atlas_editable.png'
assert (T/'assets/items/equipment_atlas_editable.png').read_bytes()==(A/'assets/items/equipment_atlas_editable.png').read_bytes()
assert (T/'art_source/equipment_atlas_editable.svg').read_bytes()==(A/'art_source/equipment_atlas_editable.svg').read_bytes()
for name in added:
 if name.endswith('.svg'):
  data=(T/name).read_bytes();root=ET.fromstring(data);assert b'data:image' not in data and b'<image' not in data
  for e in root.iter():
   assert e.tag.split('}')[-1] not in ['image','foreignObject','script']
   for k,v in e.attrib.items():
    if k.split('}')[-1] in ['href','src']:assert v.startswith('#')
extra=',art_source/equipment_atlas_editable.svg,art_source/icons/*,reference_only/legacy_equipment16/*,validation_inputs/*'
assert (T/'export_presets.cfg').read_text().replace(extra,'')==(B/'export_presets.cfg').read_text();assert (T/'export_presets.cfg').read_text().count(extra)==2
expected=j(R/'EXPECTED_ICONS.json')['icons'];assert len(expected)==21
manual={**new['icons'],**j(B/'assets/items/expansion_A_icon_manifest.json')['icons']};assert set(expected)==set(manual)
for id,e in expected.items():
 d=new if id in new['icons'] else j(B/'assets/items/expansion_A_icon_manifest.json');a=d['icons'][id];assert e['rect']==a['rect'] and e['name']==a['name'] and e['category']==a['category'];assert e['atlas']==a.get('atlas',d['atlas'])
 x,y,w,z=e['rect'];im=Image.open(T/e['atlas'].removeprefix('res://')).convert('RGBA').crop((x,y,x+w,y+z));raw=im.tobytes();visible=bytearray(raw)
 for k in range(0,len(visible),4):
  if visible[k+3]==0:visible[k:k+3]=b'\0\0\0'
 assert h(raw)==e['rgba_sha256'] and h(visible)==e['visible_rgba_sha256']
assert not (T/'.godot').exists();assert not (T/'assets/items/equipment_atlas_v2.png').exists();assert not (T/'assets/items/equipment_atlas_v2.png.import').exists()
result={'pass':True,'scope':'Independent read-only full source identity and static integration/oracle review; no Godot import, export, PCK or native execution','base_files':len(b),'candidate_files':len(t),'added':added,'removed':removed,'changed':changed,'source_pin_sha256':h((R/'CANDIDATE_PINS.json').read_bytes()),'production_code_data_scenes_tests_unchanged':True,'primary_16_ids_order_names_categories_preserved':True,'rects_new_64px_grid_match_accepted_atlas':True,'audit_correction':'First read-only audit incorrectly assumed old 1254px rects/provenance should equal new 256px SVG atlas. Original AssertionError retained; corrected check uses approved atlas full manifest equality plus old IDs/order/names/categories. Not an asset or target failure.','A5_manifest_original':True,'expected_21_pixels_recomputed':True,'normalization':'Runtime visible RGBA permits RGB normalization ONLY at alpha zero; preserves every alpha and every nonzero-alpha RGB, raw hashes separately reported; not raw imported RGBA equality or visual quality proof. Source PNG raw bytes match accepted atlas exactly.','static_fixture_review':'Actual MossUI ready merge/icon and AtlasTexture paths/rect/filter_clip are used; both manifest and expected rects parsed JSON numbers. Six aliases only non-null coverage, not six extra pixel identities.','pending':['cold import and real UI icon identity','actual PCK absence old PNG/import/ctex and excluded sources/references','native visual readability'],'historical_docs':'Untouched tested baseline still contains historical private labels; eventual release must use already-published v39 presentation mapping, not publish raw historical docs.','manifest':'Source MANIFEST inherited stale until final source freeze; not claimed final release manifest.'}
(O/'REVIEW.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps({'pass':True,'review_sha256':h((O/'REVIEW.json').read_bytes()),'files':len(t)}))
