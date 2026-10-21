from PIL import Image,ImageDraw,ImageFont
import pathlib,json,hashlib
R=pathlib.Path(__file__).resolve().parent.parent;report=[]
try:font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',22)
except OSError:font=ImageFont.load_default(size=22)
for name in ['site_overview','pump_eye','logistics_eye','pump_connection_eye','receiving_connection_eye','cargo_detail_eye','cargo_front_detail']:
 a=R/'renders'/('before_'+name+'.png');b=R/'renders'/(name+'.png')
 if not a.exists() or not b.exists():continue
 old=Image.open(a).convert('RGB');new=Image.open(b).convert('RGB');old.thumbnail((960,600));new.thumbnail((960,600));out=Image.new('RGB',(1920,660),'#e5e8e4');out.paste(old,(0,60));out.paste(new,(960,60));d=ImageDraw.Draw(out);d.text((22,17),'BATCH07 / BEFORE',font=font,fill='#20343b');d.text((982,17),'BATCH08 / AFTER  |  SAME CAMERA + LIGHT',font=font,fill='#20343b');p=R/'renders'/('comparison_'+name+'.png');out.save(p);report.append({'view':name,'before':a.name,'after':b.name,'comparison':p.name,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
(R/'QA/comparison_manifest.json').write_text(json.dumps(report,indent=2));print('COMPARISONS',len(report))
