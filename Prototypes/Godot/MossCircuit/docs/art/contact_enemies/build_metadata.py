"""Read-only PNG analysis; emits metadata only. Never writes/crops raster assets."""
from pathlib import Path
from PIL import Image
import hashlib,json,argparse
parser=argparse.ArgumentParser(description="Read-only PNG analysis; emit metadata only, never rewrite project assets.")
parser.add_argument("--project",type=Path,help="Godot project containing assets/actions/<kind>/<action>.png")
parser.add_argument("--output",type=Path,required=True,help="Metadata destination; must not be inside the project when --project is supplied")
args=parser.parse_args()
OUT=args.output.resolve();OUT.mkdir(parents=True,exist_ok=True)
if args.project and (OUT==args.project.resolve() or args.project.resolve() in OUT.parents):parser.error("--output must be outside the project")
ROOT=Path(__file__).resolve().parent
CONFIG={
 'crawler_hurt':([0,422,845,1268],[0,413,827,1241],list(range(9))),
 'flanker_hurt':([0,418,836,1254],[0,418,836,1254],list(range(9))),
 'crawler_death':([0,354,708,1062,1417],[0,330,610,875,1110],[0,1,4,2,3,5,8,6,9,7,10,12,11,13,14,15]),
 'flanker_death':([0,330,637,940,1254],[0,440,750,1040,1254],[0,1,4,2,5,3,8,6,9,7,10,11,12,13,14,15])}
qa={};manifests={k:{'schema_version':1,'alpha_threshold':8,'actions':{}} for k in ['crawler','flanker']}
for name,(xs,ys,order) in CONFIG.items():
 png=(args.project/'assets'/'actions'/name.split('_')[0]/(name+'.png')) if args.project else ROOT/(name+'.png')
 im=Image.open(png);a=im.getchannel('A');mask=a.point(lambda v:255 if v>=8 else 0);records=[];facts=[]
 row_baselines=[]
 for row in range(len(ys)-1):
  bottoms=[]
  for col in range(len(xs)-1):
   box=mask.crop((xs[col],ys[row],xs[col+1],ys[row+1])).getbbox();bottoms.append(ys[row]+box[3])
  row_baselines.append(max(bottoms))
 for source_index in order:
  r,c=divmod(source_index,len(xs)-1);x,y,xx,yy=xs[c],ys[r],xs[c+1],ys[r+1]
  b=mask.crop((x,y,xx,yy)).getbbox();assert b
  x0,y0,x1,y1=x+b[0],y+b[1],x+b[2],y+b[3];w,h=x1-x0,y1-y0
  assert x0-4>=x and x1+4<=xx and y0-4>=y and y1+4<=yy,(name,source_index,b)
  region=[x0-4,y0-4,w+8,h+8];source_center=im.width/(len(xs)-1)*(c+.5);shift_x=round(256-source_center);shift_y=320-row_baselines[r];left=region[0]+shift_x;top=region[1]+shift_y
  rec={'region':region,'margin':[left,top,512-region[2],400-region[3]],'alpha_bbox':[left+4,top+4,w,h],'source_pose_index':source_index}
  records.append(rec);facts.append({'source_pose_index':source_index,'source_alpha_bbox':[x0,y0,w,h],'height':h,'visible_bottom':y1+shift_y,'source_cell_center_x':source_center,'source_row_baseline_y':row_baselines[r],'source_to_canvas_translation':[shift_x,shift_y],'registration_reason':'Fixed source-column center and common source-row baseline; retains within-row pose offsets; no per-pose bbox centering.','pixel_sha256':hashlib.sha256(im.crop((x0,y0,x1,y1)).tobytes()).hexdigest()})
 kind=name.split('_')[0];duration=.72 if 'death' in name else .27
 asset={'path':f'res://assets/actions/{kind}/{name}.png','frames':records,'anchor':[.5,.8],'reference_height':facts[0]['height'],'duration_seconds':duration,'loop':False,'source':'Recovered original Git blob, unchanged raster; new 2026-10-24 region/margin metadata'}
 manifests[kind]['actions'][name]=asset
 unique=len({f['pixel_sha256'] for f in facts});assert unique==len(order)
 heights=[f['height'] for f in facts]
 if 'death' in name:assert heights==sorted(heights,reverse=True),(name,heights)
 qa[name]={'png_size':list(im.size),'frame_count':len(order),'unique_pixel_hashes':unique,'source_pose_order':order,'heights':heights,'fixed_logical_canvas':[512,400],'foot_anchor_px':[256,320],'alpha_threshold':8,'source_row_baselines_y':row_baselines,'source_cell_centers_x':[im.width/(len(xs)-1)*(i+.5) for i in range(len(xs)-1)],'foot_baseline_range':[min(f['visible_bottom'] for f in facts),max(f['visible_bottom'] for f in facts)],'frames':facts,'sha256':hashlib.sha256(png.read_bytes()).hexdigest()}
for kind,m in manifests.items():
 (OUT/(kind+'_action_manifest.json')).write_text(json.dumps(m,indent=2)+'\n')
(OUT/'fresh-art-qa.json').write_text(json.dumps(qa,indent=2)+'\n')
print(json.dumps({k:{x:v[x] for x in ['frame_count','unique_pixel_hashes','heights']} for k,v in qa.items()},indent=2))
