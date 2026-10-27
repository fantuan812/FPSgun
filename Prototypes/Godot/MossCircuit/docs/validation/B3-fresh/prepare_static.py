from pathlib import Path
import json,hashlib,xml.etree.ElementTree as ET
from PIL import Image
R=Path('<WORKSPACE>/moss-v39-B-art');T=Path('<WORKSPACE>/moss-v39-B-r2');O=Path(__file__).parent
h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();m=json.loads((R/'manifest.concept.json').read_text());n=json.loads((T/'assets/items/expansion_B_icon_manifest.json').read_text());assert h(R/'manifest.concept.json')=='e58cffbdab068e2d76236326661fd01680dfbf9f740e1661ee237de98d4df4f6';assert set(m['icons'])=={'crossfire_pin','salvage_capacitor','medic_winch'}
pins={};rows=[]
for id,e in m['icons'].items():
 s=R/e['editable_source'];p=R/e['atlas'].removeprefix('res://');assert h(s)==e['svg_sha256'] and h(p)==e['source_sha256'];b=s.read_bytes();root=ET.fromstring(b);assert root.attrib['viewBox']=='0 0 64 64' and b'data:image' not in b
 ids=[];layers=[]
 for x in root.iter():
  tag=x.tag.split('}')[-1];assert tag not in ['image','foreignObject','script','text']
  if 'id' in x.attrib:ids.append(x.attrib['id'])
  if tag=='g':layers.append(x.attrib['id'])
  for k,v in x.attrib.items():
   if k.split('}')[-1] in ['href','src']:assert v.startswith('#')
 assert len(ids)==len(set(ids)) and len(layers)>=3
 im=Image.open(p).convert('RGBA');assert im.size==(64,64);bbox=im.getbbox();assert [bbox[0],bbox[1],bbox[2]-bbox[0],bbox[3]-bbox[1]]==e['alpha_bbox'];assert [i for i,v in enumerate(im.getchannel('A').histogram()) if v]==[0,255]
 te=n['icons'][id];expected={**e,'editable_source':'res://art_source/build_expansion_B/svg/'+id+'.svg'};assert te==expected
 ts=T/te['editable_source'].removeprefix('res://');tp=T/te['atlas'].removeprefix('res://');assert ts.read_bytes()==b and tp.read_bytes()==p.read_bytes()
 for f in [s,p,ts,tp]:pins[str(f)]=h(f)
 rows.append({'id':id,'svg':str(s),'png':str(p),'svg_sha256':h(s),'png_sha256':h(p),'rgba_sha256':hashlib.sha256(im.tobytes()).hexdigest(),'bbox_xywh':e['alpha_bbox'],'semantic_layers':layers})
for f in [R/'manifest.concept.json',R/'provenance.json',R/'export-receipt.json',T/'assets/items/expansion_B_icon_manifest.json']:pins[str(f)]=h(f)
r={'pass':True,'scope':'Static XML/PNG and exact concept-to-current-integration binding; no fresh export/import/PCK/native','manifest_sha256':h(R/'manifest.concept.json'),'assets':rows,'input_pins':pins,'visual':'Independent direct contact-sheet inspection at 128px/40px: distinguishable locator pins, charge cells/grid, medical winch/hook. Not actual native UI readability acceptance.','provenance':'Author original semantic SVG; no embedded or external raster, no text/fonts. Prior 3x2 author exporter suppressed stdout/stderr, so native0 and repeat identity do not establish clean logs.'};(O/'STATIC_REVIEW.json').write_text(json.dumps(r,indent=2)+'\n');print(hashlib.sha256((O/'STATIC_REVIEW.json').read_bytes()).hexdigest())
