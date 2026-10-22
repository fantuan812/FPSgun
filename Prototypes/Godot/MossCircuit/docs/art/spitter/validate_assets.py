"""Read-only PNG QA; only JSON metadata is written. No raster editing."""
from pathlib import Path
import hashlib,json
from PIL import Image
ROOT=Path(__file__).resolve().parents[3]
DIR=ROOT/'assets/actions/spitter'
SPECS={'spitter_shoot':([36,451,840],213),'spitter_hurt':([40,458,857],222),'spitter_death':([68,492,885],252)}
actions,reports={},{}
for name,(ys,height) in SPECS.items():
 p=DIR/(name+'.png');im=Image.open(p)
 assert im.mode=='RGBA' and im.size==(1254,1254)
 frames,hashes,margins,bottoms,transparent,low=[],[],[],[],[],[]
 for i in range(9):
  x,y=i%3*418,ys[i//3]
  assert x+418<=1254 and y+320<=1254
  crop=im.crop((x,y,x+418,y+320));a=crop.getchannel('A');h=a.histogram()
  l,t,r,b=a.point(lambda v:255 if v>8 else 0).getbbox()
  margin=min(l,t,418-r,320-b);assert margin>=12
  assert h[0]/(418*320)>.4
  frames.append({'region':[x,y,418,320],'alpha_bbox':[l,t,r-l,b-t]})
  hashes.append(hashlib.sha256(crop.tobytes()).hexdigest());margins.append(margin);bottoms.append(b)
  transparent.append(h[0]/(418*320));low.append(sum(h[1:9])/(418*320))
 assert len(set(hashes))==9
 assert bottoms[0]==300
 if name=='spitter_death':assert bottoms[1]==300
 actions[name]={'path':'res://assets/actions/spitter/'+name+'.png','frames':frames,'anchor':[.5,.9375],'reference_height':height,'release_frame':4 if name=='spitter_shoot' else 0,'facing':'left','source_sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'row_origins_y':ys}
 reports[name]={'nonempty_unique_frames':9,'minimum_effective_alpha_margin':min(margins),'frame_sha256':hashes,'contact_bottom_y':bottoms,'anchor_y':300,'transparent_fraction':transparent,'low_alpha_1_8_fraction':low,'large_environmental_halo_seen':False,'gui_integration_reviewed':False}
(DIR/'action_manifest.json').write_text(json.dumps({'schema_version':1,'actions':actions},indent=2)+'\n')
(ROOT/'docs/art/spitter/validation.json').write_text(json.dumps(reports,indent=2)+'\n')
print(json.dumps({k:{'margin':v['minimum_effective_alpha_margin'],'bottoms':v['contact_bottom_y']} for k,v in reports.items()},indent=2))
print('PASS: 27 nonempty unique RGBA frames, safe margins, grounded neutral and death 0/1. PNG bytes not modified.')
