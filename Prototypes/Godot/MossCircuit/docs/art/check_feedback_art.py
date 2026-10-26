#!/usr/bin/env python3
"""Portable read-only Feedback Diode asset checks. Explicit project root required."""
import argparse,hashlib,json
from pathlib import Path
from PIL import Image
p=argparse.ArgumentParser();p.add_argument('source_root',type=Path);root=p.parse_args().source_root
r=json.loads((root/'docs/art/feedback_provenance.json').read_text());f=root/r['path'];im=Image.open(f);a=im.getchannel('A');b=a.point(lambda x:255 if x>32 else 0).getbbox();rect=[b[0],b[1],b[2]-b[0],b[3]-b[1]];checks=[]
def check(v,label):
 assert v,label
 checks.append(label)
sha=hashlib.sha256(f.read_bytes()).hexdigest()
check(sha==r['sha256'],'original PNG SHA256 unchanged')
check(im.mode=='RGBA','RGBA source')
check(list(im.size)==r['size'],'source dimensions')
check(a.getextrema()==(0,255),'transparent and opaque coverage')
check(rect==r['visible_alpha_bbox_xywh'],'measured alpha>32 bounds')
check(0<b[0]<b[2]<im.width and 0<b[1]<b[3]<im.height,'visible transparent padding')
m=json.loads((root/'assets/items/feedback_icon_manifest.json').read_text())
check(set(m['icons'])=={'feedback_diode'},'exact one icon mapping')
e=m['icons']['feedback_diode'];check(e['atlas']=='res://'+r['path'],'correct PNG path')
check(e['rect']==rect,'exact UI crop')
check(e['source_sha256']==sha,'mapped source hash')
check(e['category']=='item','module category')
print(json.dumps({'evidence_label':'v26-feedback-diode-source-art','passed':len(checks),'checks':checks,'sha256':sha,'limits':'Source resource checks; native integrated appearance acceptance separate.'},indent=2))
