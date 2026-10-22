"""Non-destructive metadata builder. Reads PNGs; never edits pixels."""
from PIL import Image
from pathlib import Path
import json,hashlib
R=Path(__file__).resolve().parents[3];A=R/'assets/weapon_mounts'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
p=A/'clean_hero_attack.png';im=Image.open(p).convert('RGBA');a=im.getchannel('A');origins=[]
for lo,hi in [(0,480),(480,870),(870,1254)]:
 b=a.crop((0,lo,1254,hi)).point(lambda v:255 if v>8 else 0).getbbox();origins.append(lo+b[3]-328)
# Hand centers measured from visual review, sheet coordinates (reference displayed 1280px).
hands=[(227,294),(708,250),(1128,254),(306,661),(703,621),(1128,663),(253,1094),(646,1084),(1054,1088)]
frames=[]
for i,(hx,hy) in enumerate(hands):
 x=i%3*418;y=origins[i//3];cell=im.crop((x,y,x+418,y+340));b=cell.getchannel('A').point(lambda v:255 if v>8 else 0).getbbox();frames.append({'region':[x,y,418,340],'alpha_bbox':[b[0],b[1],b[2]-b[0],b[3]-b[1]],'grip':[(hx*1254/1280-x)/418,(hy*1254/1280-y)/340]})
e={'path':'res://assets/weapon_mounts/clean_hero_attack.png','frames':frames,'anchor':[.5,328/340],'reference_height':frames[0]['alpha_bbox'][3],'release_frame':3,'sha256':sha(p),'row_origins_y':origins,'grip_basis':'visually measured empty glove center; normalized frame coordinates'}
(A/'hero_modular_manifest.json').write_text(json.dumps({'schema_version':1,'actions':{'hero_attack':e}},indent=2)+'\n')
weapons={}
data=[('rivet_gun',[550,520],[1343,350],28),('scrap_shotgun',[330,540],[1650,385],34),('rail_lance',[270,515],[1725,430],42),('orbit_saw',[887,445],[887,445],30),('return_disc',[624,669],[624,669],30),('shock_mortar',[680,560],[1285,410],32)]
for key,grip,muzzle,length in data:
 p=A/(key+'.png'); im=Image.open(p).convert('RGBA'); w,h=im.size; b=im.getchannel('A').point(lambda v:255 if v>8 else 0).getbbox()
 weapons[key]={'path':'res://assets/weapon_mounts/'+p.name,'region':[0,0,w,h],'alpha_bbox':[b[0],b[1],b[2]-b[0],b[3]-b[1]],'grip':[grip[0]/w,grip[1]/h],'muzzle':[muzzle[0]/w,muzzle[1]/h],'projectile_anchor':[muzzle[0]/w,muzzle[1]/h],'visible_length':length,'reference_width':b[2]-b[0],'sha256':sha(p),'asset_kind':'dedicated_world_sprite_not_inventory_icon','source_review':'individual sprite; no obvious environmental halo in source review; minor low-alpha edge specks remain'}
(A/'world_weapon_manifest.json').write_text(json.dumps({'schema_version':2,'weapons':weapons},indent=2)+'\n')
