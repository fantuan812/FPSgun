from pathlib import Path
from PIL import Image
import json,hashlib,xml.etree.ElementTree as E
B=Path('workspace/shared');R=B/'moss-equipment-atlas-svg-candidate';O=B/'moss-equipment-atlas-independent-review'
def h(p):return hashlib.sha256(p.read_bytes()).hexdigest()
layout=json.loads((R/'layout.json').read_text());m=json.loads((R/'assets/items/icon_manifest.json').read_text());old=json.loads((B/'moss-v39-r3/assets/items/icon_manifest.json').read_text())
assert h(R/'assets/items/icon_manifest.json')=='7b873a7ca56109d3b351cac7a4d6e415d718ade3cd48afb3fc08dc909da0f430'
assert h(B/'moss-v39-r3/assets/items/icon_manifest.json')==layout['old_manifest_sha256']
rows=layout['icons'];assert len(rows)==16 and list(m['icons'])==[r['id'] for r in rows]==list(old['icons'])
svg=E.parse(R/'art_source/equipment_atlas_editable.svg').getroot();assert svg.attrib['viewBox']=='0 0 256 256'
groups={n.attrib.get('data-icon-id'):n for n in svg if 'data-icon-id' in n.attrib};assert set(groups)==set(m['icons'])
ids=[]
for n in svg.iter():
 assert n.tag.rsplit('}',1)[-1] not in ['image','foreignObject','script']
 if 'id' in n.attrib:ids.append(n.attrib['id'])
 for k,v in n.attrib.items():assert 'href' not in k and 'data:image' not in v and 'file:' not in v and 'http' not in v
assert len(ids)==len(set(ids))
image=Image.open(R/'assets/items/equipment_atlas_editable.png').convert('RGBA');assert image.size==(256,256)
assert h(R/'assets/items/equipment_atlas_editable.png')==m['source_sha256'] and h(R/'art_source/equipment_atlas_editable.svg')==m['svg_sha256']
for i,row in enumerate(rows):
 ident=row['id'];s=R/row['source'];ref=R/row['reference_runtime_png'];pkg=B/row['accepted_source_package']
 assert h(s)==row['source_sha256'] and h(ref)==row['accepted_reference_PNG_sha256']
 # Resolve by exact basename and expected content identity within the original accepted package.
 sources=[p for p in pkg.rglob(s.name) if '.godot' not in p.parts and h(p)==h(s)]
 pngs=[p for p in pkg.rglob(ref.name) if '.godot' not in p.parts and h(p)==h(ref)]
 assert sources and pngs,(ident,'missing original accepted bytes')
 assert row['rect']==[64*(i%4),64*(i//4),64,64]==m['icons'][ident]['rect']
 assert row['old_rect']==old['icons'][ident]['rect']
 for k in ['name','category']:assert row[k]==m['icons'][ident][k]==old['icons'][ident][k]
 x,y,w,hh=row['rect'];crop=image.crop((x,y,x+w,y+hh));expected=Image.open(ref).convert('RGBA')
 assert expected.size==(64,64) and crop.tobytes()==expected.tobytes()
 assert hashlib.sha256(crop.tobytes()).hexdigest()==m['icons'][ident]['cell_rgba_sha256']
 assert list(crop.getchannel('A').getbbox())==m['icons'][ident]['visible_alpha_bbox_local']
 # Independently normalize namespaced child IDs then compare complete editable geometry trees.
 source=E.parse(s).getroot();g=groups[ident];assert g.attrib['transform']==f'translate({x} {y})'
 assert len(source)==len(g)
 for child in g.iter():
  if 'id' in child.attrib and child is not g:
   assert child.attrib['id'].startswith(ident+'--');child.attrib['id']=child.attrib['id'][len(ident)+2:]
 def norm(n):return (n.tag,dict(n.attrib),(n.text or '').strip(),[norm(c) for c in n])
 assert [norm(c) for c in source]==[norm(c) for c in g],ident
assert (R/'validation_inputs/.gdignore').is_file()
result={'pass':True,'scope':'Independent static/source and all16 actual PNG cell comparison; no fresh export, import, PCK or native integration performed','icons':16,'semantic_groups':16,'old_id_name_category_order_exact':True,'all_cells_equal_accepted_original_package_png':True,'all_svg_children_exact_accepted_original_source_except_namespaced_ids':True,'no_embedded_raster_external_refs':True,'candidate_manifest_sha256':h(R/'assets/items/icon_manifest.json'),'pending':['independent fresh export','candidate integration','cold import and actual PCK absence/presence gates','native consumers visual review']}
(O/'STATIC_REVIEW.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result))
