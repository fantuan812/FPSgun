from pathlib import Path
import json,hashlib
from PIL import Image
q=Path(__file__).resolve().parent;s=Path('<WORKSPACE>/moss-v38-work')
rows={}
for name in ['stitch_drone','stitch_drone_channel','stitch_drone_hurt','stitch_drone_death']:
 p=s/('assets/enemies/'+name+'.png' if name=='stitch_drone' else 'assets/actions/stitch_drone/'+name+'.png')
 im=Image.open(p).convert('RGBA');assert im.size==(1254,1254);frames=[]
 for i in range(9):
  ox=i%3*418;oy=i//3*418;tile=im.crop((ox,oy,ox+418,oy+418));box=tile.getchannel('A').point(lambda n:255 if n>8 else 0).getbbox();x,y,ex,ey=box;w=ex-x;h=ey-y
  frames.append({'tile_region':[ox,oy,418,418],'alpha_bbox':[x,y,w,h],'crop_region':[ox+x,oy+y,w,h],'margin':[(418-w)//2,398-h,418-w,418-h],'tile_rgba_sha256':hashlib.sha256(tile.tobytes()).hexdigest()})
 rows[name]={'path':'res://'+str(p.relative_to(s)),'png_sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'rgba_sha256':hashlib.sha256(im.tobytes()).hexdigest(),'frames':frames}
(q/'ASSET_REFERENCE.json').write_text(json.dumps({'scope':'Independent PIL decode and alpha>8 bounding boxes of original generated PNG bytes; identity/crop oracle, not independent artistic generation or engine behavior','images':rows},indent=2)+'\n')
print(json.dumps(rows,separators=(',',':')))
