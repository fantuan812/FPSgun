"""Read-only PNG/manifest validation; does not synthesize or edit images."""
from pathlib import Path
from PIL import Image
import json,hashlib
R=Path(__file__).resolve().parents[3];A=R/'assets/weapon_mounts'
for name,root in [('hero_modular_manifest.json','actions'),('world_weapon_manifest.json','weapons')]:
 m=json.loads((A/name).read_text())
 for key,e in m[root].items():
  p=R/e['path'].removeprefix('res://'); im=Image.open(p).convert('RGBA'); assert hashlib.sha256(p.read_bytes()).hexdigest()==e['sha256']; hashes=[]
  for f in e.get('frames',[e]):
   x,y,w,h=f['region'];assert 0<=x and 0<=y and x+w<=im.width and y+h<=im.height
   c=im.crop((x,y,x+w,y+h));a=c.getchannel('A');b=a.point(lambda v:255 if v>8 else 0).getbbox();assert b
   assert [b[0],b[1],b[2]-b[0],b[3]-b[1]]==f['alpha_bbox'];assert min(b[0],b[1],w-b[2],h-b[3])>=8
   assert a.histogram()[0]/(w*h)>.4
   for field in ['grip','muzzle']:
    if field in f:assert all(0<=v<=1 for v in f[field])
   hashes.append(hashlib.sha256(c.tobytes()).hexdigest())
  assert len(hashes)==len(set(hashes))
  print('PASS',key,'regions, alpha, safe gutters, unique frames, normalized anchors, checksum')
print('LIMITATION: archived atlas has visible halo and is no longer loaded. Individual sprites visually improved; minor low-alpha edge specks remain; GUI acceptance not established.')
print('PASS: empty-hand and six weapon identity were visually inspected; code cannot prove semantic absence of baked weapons. GUI compositing/timing not covered.')
