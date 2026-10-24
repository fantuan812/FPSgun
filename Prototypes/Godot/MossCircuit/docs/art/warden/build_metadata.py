"""Read PNGs without modification; write manifests and analysis to explicit output."""
from pathlib import Path
from PIL import Image
import argparse,json,hashlib
p=argparse.ArgumentParser();p.add_argument('--project',type=Path);p.add_argument('--output',type=Path,required=True);args=p.parse_args()
ROOT=Path(__file__).resolve().parent;OUT=args.output.resolve()
if args.project and (args.project.resolve()==OUT or args.project.resolve() in OUT.parents):p.error('Output must be outside project')
OUT.mkdir(parents=True,exist_ok=True)
config={
 'boss_warden_hurt':{'n':3,'ys':[0,418,836,1254],'xs':[[0,418,836,1254]]*3,'order':[0,1,2,3,4,5,7,6,8],'duration':.27},
 'boss_warden_death':{'n':4,'ys':[0,400,730,1030,1254],'xs':[[0,330,630,940,1254],[0,330,630,925,1254],[0,330,630,940,1254],[0,330,630,940,1254]],'order':[0,1,4,5,2,6,3,8,7,9,10,11,12,13,14,15],'duration':.72}}
manifest={'schema_version':1,'alpha_threshold':8,'actions':{}};qa={}
for name,cfg in config.items():
 png=args.project/'assets/actions/boss_warden'/(name+'.png') if args.project else ROOT/(name+'.png')
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
  center=im.width/n*(c+.5);dx=round(256-center);dy=320-baselines[r];mx=x-4+dx;my=y-4+dy
  assert mx>=0 and my>=0 and mx<=512-region[2] and my<=400-region[3]
  box=[x+dx,y+dy,w,h];rec={'region':region,'margin':[mx,my,512-region[2],400-region[3]],'alpha_bbox':box,'source_pose_index':i};frames.append(rec)
  facts.append({'source_pose_index':i,'source_alpha_bbox':[x,y,w,h],'source_cell_center_x':center,'source_row_baseline_y':baselines[r],'translation':[dx,dy],'logical_alpha_bbox':box,'visible_bottom':yy+dy,'pixel_sha256':hashlib.sha256(im.crop((x,y,xx,yy)).tobytes()).hexdigest()})
 assert len(set(f['pixel_sha256'] for f in facts))==n*n
 tops=[f['logical_alpha_bbox'][1] for f in facts];heights=[f['logical_alpha_bbox'][3] for f in facts]
 if 'death' in name:assert tops==sorted(tops),(name,tops)
 manifest['actions'][name]={'path':'res://assets/actions/boss_warden/'+name+'.png','frames':frames,'anchor':[.5,.8],'reference_height':facts[0]['source_alpha_bbox'][3],'duration_seconds':cfg['duration'],'loop':False,'source':'Built-in image_gen identity-preserving candidate; original PNG bytes unmodified.'}
 qa[name]={'size':list(im.size),'mode':im.mode,'sha256':hashlib.sha256(png.read_bytes()).hexdigest(),'git_blob_sha1':hashlib.sha1(f'blob {png.stat().st_size}\0'.encode()+png.read_bytes()).hexdigest(),'bytes':png.stat().st_size,'alpha_zero_pixels':sum(v==0 for v in a.getdata()),'alpha_nonzero_pixels':sum(v>0 for v in a.getdata()),'frame_count':len(frames),'unique_pose_hashes':len(set(f['pixel_sha256'] for f in facts)),'source_row_baselines_y':baselines,'source_partition_x_by_row':cfg['xs'],'source_partition_y':cfg['ys'],'source_pose_order':cfg['order'],'logical_canvas':[512,400],'height_trajectory':heights,'logical_top_trajectory':tops,'foot_trajectory':[f['visible_bottom'] for f in facts],'frames':facts}
(OUT/'action_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n');(OUT/'fresh-art-qa.json').write_text(json.dumps(qa,indent=2)+'\n')
print(json.dumps({k:{a:v[a] for a in ['frame_count','height_trajectory','logical_top_trajectory','foot_trajectory']} for k,v in qa.items()},indent=2))
