from pathlib import Path
from PIL import Image
import hashlib,json
root=Path(__file__).resolve().parents[2]
records=[];icons={}
prompts=json.loads((root/'docs/art/cryo_generation_prompts.json').read_text())
for id,file,kind,name in [('cryo_sprayer','assets/items/cryo_sprayer_icon.png','weapon','霜雾喷射器'),('fracture_coil','assets/items/fracture_coil.png','item','裂霜线圈'),('cryo_sprayer_world','assets/weapon_mounts/cryo_sprayer.png','mount','霜雾喷射器世界挂载')]:
 p=root/file;im=Image.open(p);a=im.getchannel('A');b=a.point(lambda v:255 if v>32 else 0).getbbox();rect=[b[0],b[1],b[2]-b[0],b[3]-b[1]];sha=hashlib.sha256(p.read_bytes()).hexdigest()
 records.append({'id':id,'path':file,'sha256':sha,'size':list(im.size),'mode':im.mode,'visible_alpha_bbox_xywh':rect,'tool':'image_gen.imagegen built-in','generated_date_utc':'2026-10-25','prompt_key':'cryo_sprayer' if kind=='mount' else ('cryo_sprayer_icon' if id=='cryo_sprayer' else id),'pixel_edits':'None. Byte-identical copied generated PNG. Runtime AtlasTexture cropping only.','license_note':'AI-generated original asset for this project; no third-party source assets used; no claim of third-party license or guaranteed exclusive copyright.'})
 if kind!='mount':icons[id]={'atlas':'res://'+file,'rect':rect,'name':name,'category':kind,'source_sha256':sha}
 else:
  world={'schema_version':2,'weapons':{'cryo_sprayer':{'path':'res://'+file,'region':[0,0,*im.size],'alpha_bbox':rect,'grip':[400/1774,580/887],'muzzle':[1580/1774,467/887],'projectile_anchor':[1580/1774,467/887],'visible_length':32,'reference_width':rect[2],'sha256':sha,'asset_kind':'dedicated_world_sprite_not_inventory_icon','source_review':'Single right-facing gun, transparent background, no environmental halo; cold reservoir/nozzle readable at small scale.'}}}
(root/'assets/items/cryo_icon_manifest.json').write_text(json.dumps({'version':1,'icons':icons},indent=2,ensure_ascii=False)+'\n')
(root/'assets/weapon_mounts/cryo_world_weapon_manifest.json').write_text(json.dumps(world,indent=2)+'\n')
(root/'docs/art/cryo_provenance.json').write_text(json.dumps({'schema':1,'assets':records,'limitations':['High-resolution pixel-art aesthetic, not strict native low-resolution pixel grid.','Near-transparent generated edge residue preserved.','Inventory and world views differ in tank placement, while sharing palette, nozzle and reservoir identity.']},indent=2)+'\n')
print('Wrote manifests/provenance; all 3 sources RGBA with transparent padding and unique hashes.')
