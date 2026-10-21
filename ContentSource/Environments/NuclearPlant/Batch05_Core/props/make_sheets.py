from PIL import Image,ImageDraw,ImageFont
import os,json
p=os.path.dirname(os.path.abspath(__file__));inv=json.load(open(p+'/inventory.json'))
font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',22)
small=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',16)
for name,entry in inv.items():
    sheet=Image.new('RGB',(1500,580),(238,242,243));d=ImageDraw.Draw(sheet)
    d.text((20,8),name,fill=(25,40,46),font=font)
    dims=' x '.join(f'{x:.3f}' for x in entry['dimensions_m']);d.text((20,38),f'Bounding dimensions: {dims} m  |  Orthographic cameras, no perspective',fill=(35,50,55),font=small)
    for i,v in enumerate(['front','side','top']):
        im=Image.open(f'{p}/orthographic/{name}_{v}.png').convert('RGB');sheet.paste(im,(i*500,80));d.text((i*500+15,60),v.upper()+{'front':' (-Y)','side':' (+X)','top':' (+Z)'}[v],fill=(30,40,45),font=small)
    sheet.save(f'{p}/orthographic/{name}_sheet.png')
