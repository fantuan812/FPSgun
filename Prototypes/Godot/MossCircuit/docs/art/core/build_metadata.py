"""Read PNGs without modification; write manifests and analysis to explicit output."""
from pathlib import Path
from PIL import Image
import argparse,json,hashlib
p=argparse.ArgumentParser();p.add_argument('--project',type=Path);p.add_argument('--output',type=Path,required=True);args=p.parse_args()
ROOT=Path(__file__).resolve().parent;OUT=args.output.resolve()
if args.project and (args.project.resolve()==OUT or args.project.resolve() in OUT.parents):p.error('Output must be outside project')
OUT.mkdir(parents=True,exist_ok=True)
config={
 'boss_core_hurt':{'n':3,'ys':[0,418,836,1254],'xs':[[0,418,836,1254]]*3,'order':list(range(9)),'duration':.27,'registration_x_offset':-12,'row_dy':[-73,-473,-865]},
 'boss_core_death':{'n':4,'ys':[0,390,730,1000,1254],'xs':[[0,313,627,940,1254]]*4,'order':list(range(16)),'duration':.72,'registration_x_offset':-16,'row_dy':[-17,-337,-635,-880]}}
manifest={'schema_version':1,'alpha_threshold':8,'actions':{}};qa={}
for name,cfg in config.items():
 png=args.project/'assets/actions/boss_core'/(name+'.png') if args.project else ROOT/(name+'.png')
 im=Image.open(png);assert im.mode=='RGBA';a=im.getchannel('A');m=a.point(lambda v:255 if v>=8 else 0);n=cfg['n'];raw=[];baselines=[]
 for r in range(n):
  bottom=[]
  for c in range(n):
   x,xx=cfg['xs'][r][c:c+2];y,yy=cfg['ys'][r:r+2];b=m.crop((x,y,xx,yy)).getbbox();assert b
   bb=[x+b[0],y+b[1],x+b[2],y+b[3]];raw.append(bb);bottom.append(bb[3])
  baselines.append(max(bottom))
 frames=[];facts=[]
 for i in cfg['order']:
  r,c=divmod(i,n);x,y,xx,yy=raw[i];w,h=xx-x,yy-y;region=[x-4,y-4,w+8,h+8]
  assert region[0]>=0 and region[1]>=0 and region[0]+region[2]<=im.width and region[1]+region[3]<=im.height
  center=im.width/n*(c+.5);dx=round(256-center)+cfg['registration_x_offset'];dy=cfg['row_dy'][r];mx=x-4+dx;my=y-4+dy
  assert mx>=0 and my>=0 and mx<=512-region[2] and my<=400-region[3]
  box=[x+dx,y+dy,w,h];rec={'region':region,'margin':[mx,my,512-region[2],400-region[3]],'alpha_bbox':box,'source_pose_index':i};frames.append(rec)
  facts.append({'source_pose_index':i,'source_alpha_bbox':[x,y,w,h],'source_cell_center_x':center,'source_row_registration_y':320-cfg['row_dy'][r],'translation':[dx,dy],'logical_alpha_bbox':box,'visible_bottom':yy+dy,'pixel_sha256':hashlib.sha256(im.crop((x,y,xx,yy)).tobytes()).hexdigest()})
 assert len(set(f['pixel_sha256'] for f in facts))==n*n
 tops=[f['logical_alpha_bbox'][1] for f in facts];heights=[f['logical_alpha_bbox'][3] for f in facts]
 if 'death' in name:
  assert heights==sorted(heights,reverse=True),(name,heights)
  assert all(tops[i]>=tops[i-1]-1 for i in range(1,len(tops))),(name,tops)
 manifest['actions'][name]={'path':'res://assets/actions/boss_core/'+name+'.png','frames':frames,'anchor':[.5,.8],'reference_height':facts[0]['source_alpha_bbox'][3],'duration_seconds':cfg['duration'],'action_registration_offset_x':cfg['registration_x_offset'],'source_row_translation_y':cfg['row_dy'],'loop':False,'source':'Built-in image_gen identity-preserving candidate; original PNG bytes unmodified.'}
 qa[name]={'size':list(im.size),'mode':im.mode,'sha256':hashlib.sha256(png.read_bytes()).hexdigest(),'git_blob_sha1':hashlib.sha1(f'blob {png.stat().st_size}\0'.encode()+png.read_bytes()).hexdigest(),'bytes':png.stat().st_size,'alpha_zero_pixels':sum(v==0 for v in a.tobytes()),'alpha_nonzero_pixels':sum(v>0 for v in a.tobytes()),'frame_count':len(frames),'unique_pose_hashes':len(set(f['pixel_sha256'] for f in facts)),'source_row_registration_y':[320-dy for dy in cfg['row_dy']],'explicit_source_row_translation_y':cfg['row_dy'],'registration_policy':'Manually chosen fixed row layout registration using hover/core trajectory; no automatic tail-bottom alignment.','source_partition_x_by_row':cfg['xs'],'source_partition_y':cfg['ys'],'source_pose_order':cfg['order'],'logical_canvas':[512,400],'fixed_action_anchor':[.5,.8],'fixed_action_registration_x_offset':cfg['registration_x_offset'],'registration_calibration':'One constant X offset per action; calibrated from independent cyan-core first-frame center to original hover, with centered anchor for correct horizontal flip. Never per-frame.','height_trajectory':heights,'logical_top_trajectory':tops,'visible_lower_edge_trajectory':[f['visible_bottom'] for f in facts],'frames':facts}
(OUT/'action_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n');(OUT/'fresh-art-qa.json').write_text(json.dumps(qa,indent=2)+'\n')
print(json.dumps({k:{a:v[a] for a in ['frame_count','height_trajectory','logical_top_trajectory','visible_lower_edge_trajectory']} for k,v in qa.items()},indent=2))
