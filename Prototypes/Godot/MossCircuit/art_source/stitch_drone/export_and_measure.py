#!/usr/bin/env python3
"""Deterministic export and metadata measurement; does not read reference pixels."""
import hashlib,json,os,pathlib,subprocess,sys,tempfile
from PIL import Image,ImageDraw
R=pathlib.Path(__file__).resolve().parent
sha=lambda b:hashlib.sha256(b).hexdigest()
for name in ['exports','previews','metadata']: (R/name).mkdir(exist_ok=True)
subprocess.run([sys.executable,str(R/'source/draw_stitch.py')],check=True)
env=dict(os.environ,INKSCAPE_PROFILE_DIR=str(R/'metadata/inkscape-profile'))
version=subprocess.check_output(['inkscape','--version'],env=env,text=True).strip()
records={}; actions={}; hover={}; all_rows=[]
for kind in ['hover','channel','hurt','death']:
 src=R/'source'/f'stitch_drone_{kind}.svg';out=R/'exports'/f'stitch_drone_{kind}.png'
 cmd=['inkscape',str(src),'--export-type=png','--export-filename='+str(out)]
 result=subprocess.run(cmd,check=True,env=env,capture_output=True,text=True)
 (R/'metadata'/f'export_{kind}.log').write_text(result.stdout+result.stderr)
 with tempfile.TemporaryDirectory() as tmp:
  other=pathlib.Path(tmp)/'repeat.png'
  subprocess.run(['inkscape',str(src),'--export-type=png','--export-filename='+str(other)],check=True,env=env,capture_output=True)
  assert other.read_bytes()==out.read_bytes(),'repeat export differs '+kind
 im=Image.open(out).convert('RGBA'); assert im.size==(1254,1254)
 frames=[]; raw=[]; strip=Image.new('RGBA',(9*84,100),(24,36,44,255));draw=ImageDraw.Draw(strip)
 for i in range(9):
  x,y=i%3*418,i//3*418;cell=im.crop((x,y,x+418,y+418));a=cell.getchannel('A');box=a.point(lambda v:255 if v>=8 else 0).getbbox();assert box
  bx,by,ex,ey=box;w,h=ex-bx,ey-by;assert bx>0 and by>0 and ex<418 and ey<418,'tile edge '+kind+str(i)
  mx=(418-w)//2;my=398-h;assert my>=0
  raw.append(dict(tile_region=[x,y,418,418],alpha_bbox=[bx,by,w,h],rgba_sha256=sha(cell.tobytes()),alpha_sha256=sha(a.tobytes())))
  if kind=='hover': frames.append(dict(region=[x,y,418,418],alpha_bbox=[bx,by,w,h],minimum_clear_margin=min(bx,by,418-ex,418-ey),pixel_sha256=sha(cell.tobytes())))
  else:frames.append(dict(region=[x+bx,y+by,w,h],margin=[mx,my,418-w,418-h],alpha_bbox=[mx,my,w,h],source_frame=i))
  logical=Image.new('RGBA',(418,418))
  # Art.frames crops/pads hover too; half-pixel horizontal margins approximate to floor in this PNG preview.
  logical.alpha_composite(cell.crop(box),(mx,my))
  # ActorDirector register height57 at scale1; reference_height first-frame alpha336.
  pixel_size=round(418*57/336)
  small=logical.resize((pixel_size,pixel_size),Image.Resampling.NEAREST)
  strip.alpha_composite(small,(i*84+(84-pixel_size)//2,3));draw.text((i*84+6,80),str(i),fill='white')
  logical.save(R/'previews'/f'{kind}_frame_{i}.png')
 strip.save(R/'previews'/f'{kind}_runtime_nearest.png');all_rows.append(strip)
 name='stitch_drone' if kind=='hover' else 'stitch_drone_'+kind
 path='res://assets/enemies/stitch_drone.png' if kind=='hover' else 'res://assets/actions/stitch_drone/'+name+'.png'
 record=dict(path=path,source_sha256=sha(out.read_bytes()),editable_source='art_source/stitch_drone/source/'+src.name,editable_sha256=sha(src.read_bytes()),frames=frames)
 if kind=='hover':record.update(name='补缀蜂 / Stitch Drone',size=[1254,1254],grid=[3,3],action='hover / move');hover[name]=record
 else:record.update(anchor=[.5,398/418],reference_height=336,release_frame=6 if kind=='channel' else 1,facing='left',logical_canvas=[418,418],source_grid=[3,3],alignment='SVG-derived alpha8 crop, centered integer padding, bottom20');actions[name]=record
 records[kind]=dict(png_sha256=sha(out.read_bytes()),svg_sha256=sha(src.read_bytes()),rgba_sha256=sha(im.tobytes()),alpha_sha256=sha(im.getchannel('A').tobytes()),frames=raw,repeat_export_byte_identical=True,export_command=['inkscape','source/'+src.name,'--export-type=png','--export-filename=exports/'+out.name])
contact=Image.new('RGBA',(756,400),(24,36,44,255))
for i,row in enumerate(all_rows):contact.alpha_composite(row,(0,i*100))
contact.save(R/'previews'/'all_runtime_nearest.png')
for name,data in [('measured_assets.json',dict(tool=version,records=records,scope='Staging only, no game runtime pass claimed')),('action_manifest.json',dict(schema_version=1,actions=actions)),('enemy_manifest_entry.json',hover)]: (R/'metadata'/name).write_text(json.dumps(data,indent=2,ensure_ascii=False)+'\n')
print(json.dumps(dict(pass_export=True,sheets=4,frames=36,repeated_exports=4,tool=version)))
