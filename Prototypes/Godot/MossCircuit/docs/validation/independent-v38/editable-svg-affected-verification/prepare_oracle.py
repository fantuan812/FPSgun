from pathlib import Path
import json,hashlib
from PIL import Image
r=Path('<WORKSPACE>/moss-v38-svg-redraw');o=Path(__file__).parent
expected={}
for kind in ['hover','channel','hurt','death']:
 name='stitch_drone'+('' if kind=='hover' else '_'+kind);p=r/'exports'/('stitch_drone_'+kind+'.png');im=Image.open(p).convert('RGBA');sha=lambda b:hashlib.sha256(b).hexdigest();fs=[]
 for i in range(9):
  x,y=i%3*418,i//3*418;c=im.crop((x,y,x+418,y+418));l,t,rr,bb=c.getchannel('A').point(lambda v:255 if v>=8 else 0).getbbox();w,h=rr-l,bb-t
  fs.append(dict(tile_region=[x,y,418,418],alpha_bbox=[l,t,w,h],crop_region=[x+l,y+t,w,h],margin=[(418-w)//2,398-h,418-w,418-h],tile_rgba_sha256=sha(c.tobytes()),tile_alpha_sha256=sha(c.getchannel('A').tobytes())))
 expected[name]=dict(path='res://assets/enemies/stitch_drone.png' if kind=='hover' else 'res://assets/actions/stitch_drone/'+name+'.png',png_sha256=sha(p.read_bytes()),rgba_sha256=sha(im.tobytes()),alpha_sha256=sha(im.getchannel('A').tobytes()),frames=fs)
s=Path('<WORKSPACE>/moss-v38-qa/checks/independent_support_assets.gd').read_text();lines=s.splitlines();lines[1]='# SVG-derived PNG identity; independent alpha8 geometry, source/PCK reusable.';lines[3]="const EXPECTED_JSON='"+json.dumps(expected,separators=(',',':'))+"'"
s='\n'.join(lines)+'\n';s=s.replace('4 original PNG alpha identities','4 SVG-derived PNG alpha identities');(o/'independent_support_svg_assets.gd').write_text(s);(o/'EXPECTED_ASSETS.json').write_text(json.dumps(expected,indent=2)+'\n')
print(hashlib.sha256(s.encode()).hexdigest())
