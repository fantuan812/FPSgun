from pathlib import Path
import json,hashlib
from PIL import Image
R=Path(__file__).parent;T=Path('evidence-workspace/moss-equipment16-integration-candidate');m=json.loads((T/'assets/items/icon_manifest.json').read_text());a=json.loads((T/'assets/items/expansion_A_icon_manifest.json').read_text());expected={}
for d in [m,a]:
 for id,e in d['icons'].items():
  path=e.get('atlas',d.get('atlas'));x,y,w,h=e['rect'];im=Image.open(T/path.removeprefix('res://')).convert('RGBA').crop((x,y,x+w,y+h));raw=bytearray(im.tobytes())
  for k in range(0,len(raw),4):
   if raw[k+3]==0:raw[k:k+3]=b'\0\0\0'
  expected[id]={'atlas':path,'rect':e['rect'],'name':e['name'],'category':e['category'],'rgba_sha256':hashlib.sha256(im.tobytes()).hexdigest(),'visible_rgba_sha256':hashlib.sha256(raw).hexdigest()}
(R/'EXPECTED_ICONS.json').write_text(json.dumps({'icons':expected,'normalization':'Only alpha==0 RGB set0 for runtime visible identity; all nonzero alpha and RGB exact. Raw image hash separately reported; source PNG crops already full-RGBA exact.'},ensure_ascii=False,indent=2)+'\n')
