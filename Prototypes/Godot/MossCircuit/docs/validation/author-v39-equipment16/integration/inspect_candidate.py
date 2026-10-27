from pathlib import Path
import json,hashlib
from PIL import Image
R=Path(__file__).parent;T=Path('evidence-workspace/moss-equipment16-integration-candidate');B=Path('evidence-workspace/moss-v39-final-r2');C=Path('evidence-workspace/moss-equipment-atlas-svg-candidate');checks=[]
m=json.loads((T/'assets/items/icon_manifest.json').read_text());old=json.loads((B/'assets/items/icon_manifest.json').read_text());assert set(m['icons'])==set(old['icons']) and len(m['icons'])==16;im=Image.open(T/m['atlas'].removeprefix('res://')).convert('RGBA');assert im.size==(256,256)
for id,e in m['icons'].items():
 x,y,w,h=e['rect'];assert w==h==64;cell=im.crop((x,y,x+w,y+h));ref=Image.open(C/'validation_inputs/accepted_png'/f'{id}.png').convert('RGBA');assert cell.tobytes()==ref.tobytes();assert set(cell.getchannel('A').tobytes())=={0,255};checks.append({'id':id,'rect':e['rect'],'RGBA_sha256':hashlib.sha256(cell.tobytes()).hexdigest(),'old_name_category_unchanged':all(e[k]==old['icons'][id][k] for k in ['name','category'])})
extra=['mechanism','build_expansion','cryo','bankshot','feedback','scavenger','expansion_A'];merged=dict(m['icons'])
for name in extra:
 d=json.loads((T/'assets/items'/f'{name}_icon_manifest.json').read_text())
 for id,e in d.get('icons',{}).items():
  if id not in merged:merged[id]={**e,'atlas':e.get('atlas',d.get('atlas',''))}
a=json.loads((T/'assets/items/expansion_A_icon_manifest.json').read_text());assert len(a['icons'])==5
for id,e in a['icons'].items():assert merged[id]=={**e,'atlas':e.get('atlas',a.get('atlas',''))}
oldneedle=[b'equipment_atlas_v2',b'chrklnkaqwl6m'];bad=[]
for root in ['assets','data','scripts','ui','scenes']:
 for p in (T/root).rglob('*'):
  if p.is_file() and p.suffix in ['.gd','.json','.tscn','.tres','.import'] and any(v in p.read_bytes() for v in oldneedle):bad.append(str(p.relative_to(T)))
assert not bad;assert not (T/'.godot').exists();assert all(not (T/p).exists() for p in ['assets/items/equipment_atlas_v2.png','assets/items/equipment_atlas_v2.png.import']);assert (T/'ui/moss_ui.gd').read_bytes()==(B/'ui/moss_ui.gd').read_bytes()
(R/'STATIC_ACTUAL_CANDIDATE.json').write_text(json.dumps({'status':'author static actual source PASS; no engine','candidate_icons':checks,'merged_icon_count':len(merged),'A5_extra_entries_unchanged':sorted(a['icons']),'old_runtime_text_references':bad,'old_png_import_absent':True,'cold_cache_absent':True,'ui_code_unchanged':True,'limits':'no actual Godot merge/crop/PCK/native proof'},ensure_ascii=False,indent=2)+'\n');print('16cell actual source identity +',len(merged),'merged icons / A5 exact; old runtime refs absent')
