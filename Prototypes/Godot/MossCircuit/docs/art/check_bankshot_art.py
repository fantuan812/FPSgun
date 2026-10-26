#!/usr/bin/env python3
"""Read-only checks. Usage: python3 docs/art/check_bankshot_art.py SOURCE_ROOT"""
import argparse,json,hashlib,math
from pathlib import Path
from PIL import Image
p=argparse.ArgumentParser();p.add_argument('source_root',type=Path);root=p.parse_args().source_root
checks=[]
def check(v,s):
 assert v,s
 checks.append(s)
sha=lambda f:hashlib.sha256(f.read_bytes()).hexdigest()
prov=json.loads((root/'docs/art/bankshot_provenance.json').read_text())
for r in prov['assets']:
 im=Image.open(root/r['path']);a=im.getchannel('A');b=a.point(lambda v:255 if v>32 else 0).getbbox();rect=[b[0],b[1],b[2]-b[0],b[3]-b[1]]
 check(sha(root/r['path'])==r['sha256'],r['id']+' original bytes')
 check(im.mode=='RGBA' and list(im.size)==r['size'],r['id']+' RGBA/size')
 check(rect==r['visible_alpha_bbox_xywh'],r['id']+' measured bounds')
 check(a.getextrema()[0]==0 and a.getextrema()[1]>=250,r['id']+' transparent/opaque coverage')
 check(0<b[0]<b[2]<im.width and 0<b[1]<b[3]<im.height,r['id']+' visible padding')
icons=json.loads((root/'assets/items/bankshot_icon_manifest.json').read_text())['icons']
check(set(icons)=={'bankshot_driver','bounce_guide'},'exact two icon mappings')
for id,e in icons.items():
 f=root/e['atlas'].removeprefix('res://');im=Image.open(f);x,y,w,h=e['rect']
 check(x>=0 and y>=0 and w>0 and h>0 and x+w<=im.width and y+h<=im.height,id+' crop containment')
 check(sha(f)==e['source_sha256'],id+' icon hash')
g=json.loads((root/'assets/weapon_mounts/bankshot_world_weapon_manifest.json').read_text())['weapons']['bankshot_driver']
for key in ('grip','muzzle','projectile_anchor'):check(len(g[key])==2 and all(math.isfinite(v) and 0<=v<=1 for v in g[key]),key+' finite normalized')
check(g['muzzle']==g['projectile_anchor'],'shared projectile/muzzle anchor')
check(g['muzzle'][0]>g['grip'][0],'forward muzzle')
check(abs(g['visible_length']/g['reference_width']*g['alpha_bbox'][2]-32)<1e-9,'32-unit visible mount')
check(sha(root/g['path'].removeprefix('res://'))==g['sha256'],'world source hash')
print(json.dumps({'evidence_label':'v23-bankshot-art-source','passed':len(checks),'checks':checks,'source_sha256':{r['path']:r['sha256'] for r in prov['assets']},'limits':'Source resource checks only; native integration/visual acceptance separate.'},indent=2))
