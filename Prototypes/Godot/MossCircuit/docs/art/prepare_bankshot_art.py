#!/usr/bin/env python3
"""Measure original PNGs and write portable additive metadata. Explicit source root required."""
import argparse,json,hashlib
from pathlib import Path
from PIL import Image
p=argparse.ArgumentParser();p.add_argument('source_root',type=Path);a=p.parse_args();root=a.source_root
icons={};records=[]
for id,path,kind,name in [('bankshot_driver','assets/items/bankshot_driver_icon.png','weapon','Bankshot Driver'),('bounce_guide','assets/items/bounce_guide.png','item','Bounce Guide'),('bankshot_driver_world','assets/weapon_mounts/bankshot_driver.png','world','Bankshot Driver world')]:
 f=root/path;im=Image.open(f);alpha=im.getchannel('A');b=alpha.point(lambda v:255 if v>32 else 0).getbbox();rect=[b[0],b[1],b[2]-b[0],b[3]-b[1]];sha=hashlib.sha256(f.read_bytes()).hexdigest()
 records.append({'id':id,'path':path,'sha256':sha,'size':list(im.size),'mode':im.mode,'alpha_extrema':list(alpha.getextrema()),'visible_alpha_bbox_xywh':rect,'tool':'image_gen.imagegen built-in','date_utc':'2026-10-25','pixel_edits':'None; original generated PNG bytes preserved. Runtime crop/nearest sampling only.','prompt_key':'bankshot_driver' if kind=='world' else ('bankshot_driver_icon' if kind=='weapon' else id),'license_note':'AI-generated original project asset. No third-party source art; no exclusive-copyright or third-party-license claim.'})
 if kind!='world':icons[id]={'atlas':'res://'+path,'rect':rect,'name':name,'category':kind,'source_sha256':sha}
 else:world={'schema_version':2,'weapons':{'bankshot_driver':{'path':'res://'+path,'region':[0,0,*im.size],'alpha_bbox':rect,'grip':[320/1774,610/887],'muzzle':[1639/1774,420/887],'projectile_anchor':[1639/1774,420/887],'visible_length':32,'reference_width':rect[2],'sha256':sha,'asset_kind':'dedicated_world_sprite_not_inventory_icon','source_review':'Right-facing compact fork launcher, center-gap muzzle. Original low-alpha edge residue retained.'}}}
for path,obj in [('assets/items/bankshot_icon_manifest.json',{'version':1,'icons':icons}),('assets/weapon_mounts/bankshot_world_weapon_manifest.json',world),('docs/art/bankshot_provenance.json',{'schema':1,'assets':records,'limitations':['High-resolution pixel-art aesthetic, not strict low-resolution grid.','Original near-transparent edge/glow residue retained; alpha>32 crops exclude outer padding.','Native integrated acceptance remains separate.']})]: (root/path).write_text(json.dumps(obj,indent=2)+'\n')
print('Prepared three measured resource records and additive manifests.')
