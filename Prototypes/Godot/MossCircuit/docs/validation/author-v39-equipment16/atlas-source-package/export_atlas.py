"""One SVG render per invocation; obtain QA heavy-window permission first."""
from pathlib import Path
import json,subprocess,hashlib
from PIL import Image,ImageDraw
R=Path(__file__).resolve().parent;layout=json.load(open(R/'layout.json'));s=R/'art_source/equipment_atlas_editable.svg';p=R/'assets/items/equipment_atlas_editable.png'
subprocess.run(['inkscape',str(s),'--export-type=png','--export-png-antialias=0','--export-filename='+str(p)],check=True,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
im=Image.open(p).convert('RGBA');assert im.size==(256,256);assert [i for i,n in enumerate(im.getchannel('A').histogram()) if n]==[0,255]
icons={};checks=[]
for row in layout['icons']:
 x,y,w,h=row['rect'];cell=im.crop((x,y,x+w,y+h));expected=Image.open(R/row['reference_runtime_png']).convert('RGBA');same=cell.size==expected.size and cell.tobytes()==expected.tobytes();assert same,row['id']+' composition changed accepted source pixels'
 bbox=cell.getbbox();icons[row['id']]={'rect':row['rect'],'name':row['name'],'category':row['category'],'visible_alpha_bbox_local':list(bbox),'cell_rgba_sha256':hashlib.sha256(cell.tobytes()).hexdigest()};checks.append({'id':row['id'],'source_sha256':row['source_sha256'],'accepted_source_package':row['accepted_source_package'],'rect':row['rect'],'composed_cell_RGBA_equals_accepted_independent_PNG':same,'cell_rgba_sha256':hashlib.sha256(cell.tobytes()).hexdigest()})
manifest={'version':1,'atlas':'res://assets/items/equipment_atlas_editable.png','size':[256,256],'grid':{'columns':4,'rows':4,'order':'row-major','edges':'exact 64-pixel cells'},'source_sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'editable_source':'art_source/equipment_atlas_editable.svg','svg_sha256':hashlib.sha256(s.read_bytes()).hexdigest(),'icons':icons}
(R/'assets/items/icon_manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n');(R/'composition-checks.json').write_text(json.dumps({'scope':'asset composition identity only, not cold/PCK/native acceptance','all_16_exact_RGBA':True,'checks':checks},indent=2)+'\n')
canvas=Image.new('RGB',(640,700),'#15252b');big=im.resize((512,512),Image.Resampling.NEAREST);canvas.paste(big,(0,0),big);small=im.resize((160,160),Image.Resampling.NEAREST);canvas.paste(small,(0,530),small);d=ImageDraw.Draw(canvas);d.text((180,540),'16 semantic cells / 64px source / 40px preview',fill='white');canvas.save(R/'review.png');print('1 atlas rendered; all 16 cell RGBA exactly match accepted source PNGs')
