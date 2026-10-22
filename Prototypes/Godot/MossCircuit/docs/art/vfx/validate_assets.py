"""Read-only art validation; never alters raster images. Run from any directory."""
from pathlib import Path
from PIL import Image
import json, hashlib
ROOT=Path(__file__).resolve().parents[3]
IDS=['muzzle_flash','hit_spark','explosion','chain_arc','shield_impact','dash_trail']
manifest=json.loads((ROOT/'assets/vfx/vfx_manifest.json').read_text())
for key in IDS:
 e=manifest['effects'][key]; p=ROOT/e['path'].removeprefix('res://'); im=Image.open(p).convert('RGBA'); hashes=[]
 assert im.size==tuple(e['sheet_size'])
 assert hashlib.sha256(p.read_bytes()).hexdigest()==e['sha256']
 for f in e['frames']:
  x,y,w,h=f['region']; assert x>=0 and y>=0 and x+w<=im.width and y+h<=im.height
  cell=im.crop((x,y,x+w,y+h)); a=cell.getchannel('A'); b=a.point(lambda v:255 if v>8 else 0).getbbox()
  assert b is not None, (key,'empty')
  assert [b[0],b[1],b[2]-b[0],b[3]-b[1]]==f['alpha_bbox']
  assert min(b[0],b[1],w-b[2],h-b[3])>=8,(key,'unsafe gutter',b)
  assert a.histogram()[0]/(w*h)>.2,(key,'opaque background')
  hashes.append(hashlib.sha256(cell.tobytes()).hexdigest())
 assert len(set(hashes))==9,(key,'duplicate frames')
 print('PASS',key,'9 distinct RGBA frames, >8px content gutters, transparent background, checksum')
print('PASS 6 sheets / 54 frames. Does not validate gameplay timing, GUI appearance or strict pixel-grid quantization.')
