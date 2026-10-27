from pathlib import Path
import json,hashlib,re
from PIL import Image
R=Path('evidence-workspace/moss-v39-final-r2');O=Path(__file__).resolve().parent
exact=[];images=[]
for folder in ['scripts','ui','data','assets']:
 for p in sorted((R/folder).rglob('*')):
  if not p.is_file():continue
  rel=p.relative_to(R).as_posix()
  if rel=='ui/test_ui.gd':continue
  if p.suffix in ['.gd','.json']:exact.append(rel)
  if p.suffix=='.png':images.append(rel)
exact.append('art_source/alpha_bounds.json')
config=json.loads((R/'data/actor_actions.json').read_text());read=lambda s:json.loads((R/s.removeprefix('res://')).read_text())
actions=read(config['manifest'])['actions'];actions.pop('hero_attack',None);actions.update(read(config['hero_modular_manifest']).get('actions',{}))
for path in config['additional_manifests']:
 for key,val in read(path)['actions'].items():
  if key not in actions:actions[key]=val
frames={}
for key,a in actions.items():
 p=R/a['path'].removeprefix('res://');assert p.is_file();im=Image.open(p);w,h=im.size
 assert isinstance(a['frames'],list) and len(a['frames'])>=2
 for f in a['frames']:
  x,y,ww,hh=f['region'];assert x>=0 and y>=0 and ww>0 and hh>0 and x+ww<=w and y+hh<=h
 frames[key]=len(a['frames'])
settings=[];section=None
for line in (R/'project.godot').read_text().splitlines():
 line=line.strip()
 if line.startswith('['):section=line[1:-1]
 elif section and '=' in line:
  key=section+'/'+line.split('=',1)[0]
  if key!='application/config/features':settings.append(key)
c=read('data/catalog.json');catalog_ids=[x['id'] for x in c['weapons']+c['items']]
terms={'schema_scene':2,'project_settings':len(settings),'exact_file_exists_and_bytes':2*len(exact),'image_five_predicates':5*len(images),'excluded_dirs_and_files':8,'action_asset_count':1,'per_action_frame_atlas':sum(frames.values()),'per_action_frame_count':len(frames),'total_frame_count':1,'two_modes_32_each':64,'catalog_icons':len(catalog_ids)}
result={'status':'STATIC_EXPECTATIONS_NOT_TARGET_EXECUTION','exact_files':len(exact),'images':len(images),'actions':len(frames),'action_frames':sum(frames.values()),'settings':len(settings),'catalog_icons':len(catalog_ids),'expected_checks':sum(terms.values()),'formula_terms':terms,'exact_file_paths':sorted(exact),'image_paths':sorted(images),'action_frame_map':frames,'settings_keys':settings,'catalog_ids':catalog_ids,'scope':'Independently enumerated frozen source using reviewed builder/fingerprint/ActorDirector/verifier semantics; assumes all texture/action loads and Bankshot launch branch succeed. No engine or generated target output used. PNG-only generic image enumeration excludes SVG and WAV; specialized probes remain required.'}
result['basis_sha256']={p:hashlib.sha256((R/p).read_bytes()).hexdigest() for p in ['tools/build_desktop.py','tools/export_source_fingerprint.gd','tools/verify_export_pack.gd','scripts/actor_director.gd','project.godot','data/actor_actions.json','data/catalog.json']}
(O/'EXPORT_RESOURCE_STATIC_EXPECTATIONS.json').write_text(json.dumps(result,indent=2)+'\n');print({k:result[k] for k in ['exact_files','images','actions','action_frames','settings','catalog_icons','expected_checks','formula_terms']})
