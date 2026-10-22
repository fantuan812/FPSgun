"""Read-only PNG validation; writes reproducible metadata only, never changes images."""
from pathlib import Path
from PIL import Image
import hashlib,json
root=Path(__file__).resolve().parents[3]
names={'crawler':'锈甲虫','charger':'琥珀犀牛机','spitter':'青紫炮口虫','flanker':'蓝刀足蛛','brood_keeper':'苔绿巢母','boss_warden':'废铁守卫','boss_core':'孢子反应堆'}
result={'schema_version':1,'bbox_format':'xywh, frame-local','alpha_threshold':8,'slice_policy':'integer floor equal 3x3 row-major; unmodified PNG','enemies':{}}
for id,name in names.items():
 path='assets/beetle_walk.png' if id=='crawler' else f'assets/enemies/{id}.png'
 p=root/path; im=Image.open(p).convert('RGBA'); w,h=im.size
 frames=[]; hashes=[]
 for i in range(9):
  c,r=i%3,i//3; x,y=c*w//3,r*h//3; x1,y1=(c+1)*w//3,(r+1)*h//3
  frame=im.crop((x,y,x1,y1)); a=frame.getchannel('A'); box=a.point(lambda value: 255 if value>8 else 0).getbbox(); assert box, (id,i,'empty')
  l,t,rr,b=box; margin=min(l,t,x1-x-rr,y1-y-b)
  assert margin>0,(id,i,'touches boundary',box)
  digest=hashlib.sha256(frame.tobytes()).hexdigest();hashes.append(digest)
  frames.append({'region':[x,y,x1-x,y1-y],'alpha_bbox':[l,t,rr-l,b-t],'minimum_clear_margin':margin,'pixel_sha256':digest})
 assert len(set(hashes))==9,(id,'duplicate frames')
 entry={'name':name,'path':'res://'+path,'size':[w,h],'grid':[3,3],'action':'hover_pulse' if id=='boss_core' else 'body_pulse' if id=='boss_warden' else 'walk','frames':frames,'source_sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'alpha_extrema':im.getchannel('A').getextrema()}
 result['enemies'][id]=entry
 print(id,im.size,'9 distinct frames; min clear margin',min(f['minimum_clear_margin'] for f in frames))
(root/'assets/enemies/enemy_manifest.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
print('PASS: 7 atlases, 63 nonempty distinct cells, alpha and grid clearance')
