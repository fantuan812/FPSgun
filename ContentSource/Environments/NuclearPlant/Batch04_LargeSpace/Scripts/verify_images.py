import pathlib,json,math
from PIL import Image,ImageDraw,ImageFont
R=pathlib.Path(__file__).resolve().parents[1];manifest=json.loads((R/'manifest.json').read_text());allreports=[]
font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',22);small=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',17)
for e in manifest['assets']:
 p=R/e['path'];sp=json.loads((p/'spec.json').read_text());d=sp['dimensions'];ppm=1024/sp.get('ortho_scale_m',10.24);report={'asset_id':e['asset_id'],'pixels_per_meter':ppm,'views':{}}
 sheet=Image.new('RGB',(1920,750),(229,234,234));draw=ImageDraw.Draw(sheet);draw.text((26,16),e['asset_id'],fill=(24,45,53),font=font);draw.text((26,49),f'BLENDER GEOMETRY  |  ORTHO  |  {ppm:g} px/m source  |  uniform 0.625 preview scale',fill=(75,92,98),font=small)
 for i,(v,expected) in enumerate([('front',(d[0]*ppm,d[2]*ppm)),('right',(d[1]*ppm,d[2]*ppm)),('top',(d[0]*ppm,d[1]*ppm))]):
  im=Image.open(p/(v+'.png')).convert('RGBA');alpha=im.getchannel('A').point(lambda a:255 if a>127 else 0);box=alpha.getbbox();actual=(box[2]-box[0],box[3]-box[1]);err=[abs(a-b) for a,b in zip(actual,expected)]
  report['views'][v]={'expected_silhouette_px':expected,'measured_silhouette_px':actual,'maximum_error_px':max(err),'status':'PASS' if max(err)<=2 else 'FAIL'}
  bg=Image.new('RGBA',im.size,(229,234,234,255));bg.alpha_composite(im);bg=bg.convert('RGB').resize((640,640),Image.Resampling.LANCZOS);sheet.paste(bg,(i*640,90));draw.text((i*640+24,93),v.upper(),fill=(24,45,53),font=font)
 draw.text((26,720),'SOURCE DIMENSIONS  '+ ' x '.join(str(x) for x in d)+' m  |  See spec.json and validation.json',fill=(75,92,98),font=small)
 sheet.save(p/'orthographic_sheet.png');report['status']='PASS' if all(v['status']=='PASS' for v in report['views'].values()) else 'FAIL';(p/'image_validation.json').write_text(json.dumps(report,indent=2));allreports.append(report)
(R/'Validation/image_validation.json').write_text(json.dumps(allreports,indent=2))
print([(r['asset_id'],r['status']) for r in allreports])
