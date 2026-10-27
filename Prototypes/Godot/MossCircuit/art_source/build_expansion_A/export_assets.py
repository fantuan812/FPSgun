#!/usr/bin/env python3
"""Render editable SVG via Inkscape, inspect pixels, publish only local staging files."""
from pathlib import Path
import subprocess,json,hashlib,xml.etree.ElementTree as ET
from PIL import Image,ImageDraw
R=Path(__file__).resolve().parent
anchors={'tether_emitter_held':{'grip_px':[28,46],'muzzle_px':[118,32],'review':'Grip within lower-left olive handle. Muzzle is virtual firing axis between twin right prongs; intentionally transparent.'},'seismic_drum_held':{'grip_px':[30,46],'muzzle_px':[117,32],'review':'Grip within olive handle. Muzzle at rightmost front rim edge, discharge axis through amber membrane center.'}}
rows=[]
for f in sorted((R/'svg').glob('*.svg')):
 name=f.stem;held=name.endswith('_held');sub='weapon_mounts' if held else 'items';out=R/'assets'/sub/(name+'.png');out.parent.mkdir(parents=True,exist_ok=True)
 subprocess.run(['inkscape',str(f),'--export-type=png','--export-png-antialias=0','--export-filename='+str(out)],check=True,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
 im=Image.open(out).convert('RGBA');w,h=im.size;b=im.getchannel('A').getbbox();box=[b[0],b[1],b[2]-b[0],b[3]-b[1]]
 row={'id':name,'path':'res://assets/'+sub+'/'+out.name,'editable_source':'svg/'+f.name,'region':[0,0,w,h],'alpha_bbox':box,'sha256':hashlib.sha256(out.read_bytes()).hexdigest(),'svg_sha256':hashlib.sha256(f.read_bytes()).hexdigest(),'alpha_values':[i for i,n in enumerate(im.getchannel('A').histogram()) if n],'status':'draft_pending_independent_qa','category':'weapon' if ('emitter' in name or 'drum' in name) else 'item'}
 if held:
  an=anchors[name];row.update({'asset_kind':'dedicated_world_sprite_not_inventory_icon','grip':[an['grip_px'][0]/w,an['grip_px'][1]/h],'muzzle':[an['muzzle_px'][0]/w,an['muzzle_px'][1]/h],'projectile_anchor':[an['muzzle_px'][0]/w,an['muzzle_px'][1]/h],'grip_px':an['grip_px'],'muzzle_px':an['muzzle_px'],'visible_length':32,'reference_width':box[2],'source_review':an['review']})
 else:row['rect']=box
 rows.append(row)
(R/'manifest.draft.json').write_text(json.dumps({'schema':1,'authority':'SVG is editable source; PNG is deterministic runtime export, AI PNG is reference only.','assets':rows},indent=2)+'\n')
canvas=Image.new('RGB',(800,600),'#15252b');d=ImageDraw.Draw(canvas)
for i,r in enumerate(rows):
 x=(i%2)*400;y=(i//2)*150;im=Image.open(R/r['path'].removeprefix('res://'));large=im.resize((im.width*2,im.height*2),Image.Resampling.NEAREST);canvas.paste(large,(x+8,y+4),large);d.text((x+8,y+134),r['id'],fill='white')
 b=im.getbbox();crop=im.crop(b);targetw=32 if r['id'].endswith('_held') else 40;small=crop.resize((targetw,max(1,round(crop.height*targetw/crop.width))),Image.Resampling.NEAREST);canvas.paste(small,(x+290,y+30),small);d.text((x+276,y+85),str(targetw)+'px',fill='white')
canvas.save(R/'svg-review.png')
print('Exported 7 PNGs, draft manifest and visual review')
