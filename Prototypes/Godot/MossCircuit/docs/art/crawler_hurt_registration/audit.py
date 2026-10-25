"""Read-only semantic-feature and exact-change audit. Never rewrites PNG pixels."""
from pathlib import Path
from PIL import Image
import argparse,json,hashlib
import numpy as np
p=argparse.ArgumentParser();p.add_argument('--baseline',type=Path,required=True);p.add_argument('--candidate',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args()
source=a.baseline/'assets/actions/crawler/crawler_hurt.png';image=np.asarray(Image.open(source));old=json.loads((a.baseline/'assets/actions/crawler/action_manifest.json').read_text());new=json.loads((a.candidate/'assets/actions/crawler/action_manifest.json').read_text());before=old['actions']['crawler_hurt'];after=new['actions']['crawler_hurt'];records=[]
assert old['actions']['crawler_death']==new['actions']['crawler_death']
for key in before:
 if key!='frames':assert before[key]==after[key],key
for i,(b,c) in enumerate(zip(before['frames'],after['frames'])):
 correction=[-25,-4,26][i%3];assert c['region']==b['region'] and c['margin'][1:]==b['margin'][1:] and c['alpha_bbox'][1:]==b['alpha_bbox'][1:];assert c['margin'][0]-b['margin'][0]==correction and c['alpha_bbox'][0]-b['alpha_bbox'][0]==correction
 x,y,w,h=map(int,b['region']);clip=image[y:y+h,x:x+w];r,g,blue=[clip[:,:,j].astype(int) for j in range(3)];mask=(clip[:,:,3]>128)&(r>220)&(g>220)&(blue>200);yy,xx=np.where(mask);assert 200<len(xx)<500;cx,cy=float(xx.mean()),float(yy.mean())
 records.append({'source_pose_index':i,'column':i%3,'source_region':b['region'],'source_eye_centroid':[x+cx,y+cy],'before_eye':[cx+b['margin'][0],cy+b['margin'][1]],'after_eye':[cx+c['margin'][0],cy+c['margin'][1]],'column_x_correction':correction,'before_record':b,'after_record':c})
report={'scope':'Authored fixed-column registration candidate, pending native small-scale GUI acceptance. Original source and gameplay authority unchanged.', 'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'source_size':list(Image.open(source).size),'frame_count':9,'reference_height':260,'duration':.27,'method':'Visually identified two white eyes: alpha>128 & R>220 & G>220 & B>200; not whole-body bbox normalization. Column offsets [0,21,51] plus action-wide neutral-eye registration -25.','fixed_column_x_corrections':[-25,-4,26],'death_unchanged':True,'unchanged_contract':['source regions','source PNG bytes','all Y coordinates','logical canvas','fixed scale/reference_height','anchor','frame order/count','reaction duration','all death data'],'frames':records,'before_column_mean_eye_x':[float(np.mean([f['before_eye'][0] for f in records if f['column']==c])) for c in range(3)],'after_column_mean_eye_x':[float(np.mean([f['after_eye'][0] for f in records if f['column']==c])) for c in range(3)],'before_terminal_eye_delta':[records[-1]['before_eye'][j]-records[0]['before_eye'][j] for j in range(2)],'after_terminal_eye_delta':[records[-1]['after_eye'][j]-records[0]['after_eye'][j] for j in range(2)]}
a.output.write_text(json.dumps(report,indent=2)+'\n');print(json.dumps({k:report[k] for k in ['before_column_mean_eye_x','after_column_mean_eye_x','before_terminal_eye_delta','after_terminal_eye_delta']},indent=2))
