#!/usr/bin/env python3
"""Read-only deterministic source-resource checks; not a substitute for native visual QA."""
import sys,json,hashlib,math
from pathlib import Path
from PIL import Image
if len(sys.argv)!=3: raise SystemExit('Usage: python3 docs/art/check_cryo_resources.py CANDIDATE_ROOT V20_SOURCE_ROOT')
root=Path(sys.argv[1]);baseline=Path(sys.argv[2])
art=Path(__file__).resolve().parents[2]
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
checks=[]
def check(ok,label):
 assert ok,label
 checks.append(label)
prov=json.loads((art/'docs/art/cryo_provenance.json').read_text())
for r in prov['assets']:
 p=root/r['path'];im=Image.open(p)
 check(sha(p)==r['sha256'],'unchanged PNG bytes '+r['id'])
 check(im.mode=='RGBA' and list(im.size)==r['size'],'RGBA/dimensions '+r['id'])
 alpha=im.getchannel('A');box=alpha.point(lambda x:255 if x>32 else 0).getbbox();rect=[box[0],box[1],box[2]-box[0],box[3]-box[1]]
 check(rect==r['visible_alpha_bbox_xywh'] and alpha.getextrema()==(0,255),'alpha/bounds '+r['id'])
 check(0<box[0]<box[2]<im.width and 0<box[1]<box[3]<im.height,'transparent padding '+r['id'])
icons=json.loads((root/'assets/items/cryo_icon_manifest.json').read_text())['icons']
for id in ('cryo_sprayer','fracture_coil'):
 e=icons[id];im=Image.open(root/e['atlas'].removeprefix('res://'));x,y,w,h=e['rect']
 check(x>=0 and y>=0 and w>0 and h>0 and x+w<=im.width and y+h<=im.height,'valid UI crop '+id)
 check(e['source_sha256']==sha(root/e['atlas'].removeprefix('res://')),'UI source identity '+id)
world=json.loads((root/'assets/weapon_mounts/world_weapon_manifest.json').read_text())['weapons']
old=json.loads((baseline/'assets/weapon_mounts/world_weapon_manifest.json').read_text())['weapons']
check(len(old)==6,'six baseline weapon records')
for id,entry in old.items():check(world[id]==entry,'unchanged baseline geometry '+id)
g=world['cryo_sprayer']; expected=json.loads((art/'assets/weapon_mounts/cryo_world_weapon_manifest.json').read_text())['weapons']['cryo_sprayer']
check(g==expected,'integrated Cryo geometry identity')
for k in ('grip','muzzle','projectile_anchor'):
 check(len(g[k])==2 and all(math.isfinite(v) and 0<=v<=1 for v in g[k]),'finite normalized '+k)
check(g['muzzle'][0]>g['grip'][0],'muzzle in front of grip')
scale=g['visible_length']/g['reference_width'];check(abs(scale*g['alpha_bbox'][2]-32)<1e-9,'32 world-unit visible mount')
offset=((g['muzzle'][0]-g['grip'][0])*g['region'][2]*scale,(g['muzzle'][1]-g['grip'][1])*g['region'][3]*scale)
poses=[]
for left in (False,True):
 angle=math.pi if left else 0;oy=-offset[1] if left else offset[1]
 p=(offset[0]*math.cos(angle)-oy*math.sin(angle),offset[0]*math.sin(angle)+oy*math.cos(angle))
 check(all(math.isfinite(v) for v in p),'finite '+('left' if left else 'right')+' muzzle pose')
 poses.append(p)
check(abs(poses[0][0]+poses[1][0])<1e-9 and abs(poses[0][1]-poses[1][1])<1e-9,'both-facing mirror geometry')
rig=(root/'scripts/weapon_rig.gd').read_text()
check('TEXTURE_FILTER_NEAREST' in rig and 'flip_v' in rig,'runtime nearest filter/mirror contract present')
report={'passed':len(checks),'checks':checks,'candidate':'supplied v21 r2 source root','source_sha256':{r['path']:sha(root/r['path']) for r in prov['assets']},'manifest_sha256':{p:sha(root/p) for p in ['assets/items/cryo_icon_manifest.json','assets/weapon_mounts/world_weapon_manifest.json']},'analytic_muzzle_offsets':poses,'limit':'Analytic/static resource acceptance. Native stills separately inspected; no full-motion or balance certification.'}
print(json.dumps(report,indent=2))
