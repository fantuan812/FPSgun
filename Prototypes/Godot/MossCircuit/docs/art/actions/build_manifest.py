"""Read pixels, write metadata only. Never alters source PNGs."""
from pathlib import Path
from PIL import Image
import json, hashlib
ROOT=Path(__file__).resolve().parents[3]; actions={}
for p in sorted((ROOT/'assets/actions').glob('*.png')):
 im=Image.open(p).convert('RGBA');a=im.getchannel('A');w=im.width//3; fh=340; frames=[]; origins=[]
 # Source rows have unequal visual baselines. One translation per entire row,
 # never per-pose bbox fitting; identical 418x340 canvas and foot anchor.
 for lo,hi in [(0,480),(480,870),(870,1254)]:
  b=a.crop((0,lo,im.width,hi)).point(lambda v:255 if v>8 else 0).getbbox(); baseline=lo+b[3]; origins.append(baseline-328)
 for i in range(9):
  x=i%3*w;y=origins[i//3]; cell=im.crop((x,y,x+w,y+fh)); b=cell.getchannel('A').point(lambda v:255 if v>8 else 0).getbbox()
  frames.append({'region':[x,y,w,fh],'alpha_bbox':[b[0],b[1],b[2]-b[0],b[3]-b[1]],'source_frame':i})
 e={'path':'res://assets/actions/'+p.name,'frames':frames,'anchor':[.5,328/340],'reference_height':frames[0]['alpha_bbox'][3],'sheet_size':list(im.size),'row_region_origins_y':origins,'loop':False,'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'alpha_threshold':8}
 if 'attack' in p.stem:e['release_frame']=5 if 'warden' in p.stem else (3 if p.stem=='hero_attack' else 4)
 actions[p.stem]=e
(ROOT/'assets/actions/action_manifest.json').write_text(json.dumps({'schema_version':1,'actions':actions},indent=2)+'\n')
