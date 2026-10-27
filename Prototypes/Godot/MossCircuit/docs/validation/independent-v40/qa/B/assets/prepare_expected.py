from pathlib import Path
import json,hashlib
from PIL import Image
Q=Path(__file__).parent; A=Path('evidence-workspace/moss-v39-final-r2'); B=Path('evidence-workspace/moss-v39-B-r2'); art=Path('evidence-workspace/moss-v39-B-art')
h=lambda b:hashlib.sha256(b).hexdigest()
names=['icon_manifest','mechanism_icon_manifest','build_expansion_icon_manifest','cryo_icon_manifest','bankshot_icon_manifest','feedback_icon_manifest','scavenger_icon_manifest','expansion_A_icon_manifest']
icons={};pins={}
for n in names:
 p=A/'assets/items'/f'{n}.json';raw=p.read_bytes();pins[str(p)]=h(raw);assert (B/p.relative_to(A)).read_bytes()==raw
 d=json.loads(raw)
 for k,v in d['icons'].items():
  if k not in icons:icons[k]={'atlas':v.get('atlas',d.get('atlas','')),'rect':v['rect'],'name':v['name'],'category':v['category']}
assert len(icons)==43
old_ids=sorted(icons)
manifest=json.loads((B/'assets/items/expansion_B_icon_manifest.json').read_text()); new={}
for k in ['crossfire_pin','salvage_capacitor','medic_winch']:
 e=manifest['icons'][k];p=art/'assets/items'/f'{k}.png';raw=p.read_bytes();assert raw==(B/e['atlas'].removeprefix('res://')).read_bytes();assert h(raw)==e['source_sha256']
 im=Image.open(p).convert('RGBA');assert im.size==(64,64);rgba=im.tobytes();v=bytearray(rgba)
 for i in range(0,len(v),4):
  if v[i+3]==0:v[i:i+3]=b'\0\0\0'
 alpha=im.getchannel('A');bbox=alpha.getbbox();assert sorted(set(alpha.tobytes()))==[0,255]
 new[k]={'rgba_sha256':h(rgba),'visible_rgba_sha256':h(v),'alpha_sha256':h(alpha.tobytes()),'bbox':[bbox[0],bbox[1],bbox[2]-bbox[0],bbox[3]-bbox[1]],'png_sha256':h(raw)}
 icons[k]={x:e[x] for x in ['atlas','rect','name','category']};pins[str(p)]=h(raw)
assert len(icons)==46
(Q/'EXPECTED.json').write_text(json.dumps({'old_ids':old_ids,'icons':icons,'new':new,'provenance':'43 bindings from accepted A; 3 independent Pillow identities from accepted B art, alpha0 RGB only normalized'},ensure_ascii=False,indent=2)+'\n')
(Q/'EXPECTED_SOURCE_PINS.json').write_text(json.dumps(pins,indent=2)+'\n')
print('EXPECTED46 BINDINGS +3 PIL identities; no engine')
