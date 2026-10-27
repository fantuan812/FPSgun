from pathlib import Path
import json,hashlib,shutil
r=Path('evidence-workspace/moss-v39-work');p=r/'data/catalog.json';raw=p.read_text();before=json.loads(raw)
weapons=[dict(id='tether_emitter',name='Tether Emitter',kind='weapon',behavior='tether_pulse',damage=10,interval=1.2,projectiles=1,spread=0,pierce=0,range=280,price=38,rarity='uncommon',tags=['electric'],max_stack=4,pulse_count=4,description='Four timed pulses lock one target per cycle. Moving out of range breaks the beam; no pull or slow. No instant launch damage.'),dict(id='seismic_drum',name='Seismic Drum',kind='weapon',behavior='expanding_ring',damage=22,interval=1.4,projectiles=1,spread=0,pierce=0,range=180,price=38,rarity='uncommon',tags=['melee'],max_stack=4,inner_start_radius=24,band_half_width=12,outward_seconds=.6,max_live_per_slot=3,description='A fixed-center narrow ring expands from radius24 to reach in0.6s. Each target once per outward leg; real inner hole. Max3 waves per slot.')]
items=json.loads(Path('evidence-workspace/moss-v39-items/catalog_items_A.draft.json').read_text())
pairs=[dict(id='remembered_lock',name='REMEMBERED LOCK',requires=['tether_emitter','lock_memory'],description='One observed range-loss grace per beam, up to0.20s. No damage outside range; next shot may be skipped.'),dict(id='returning_resonance',name='RETURNING RESONANCE',requires=['seismic_drum','return_collar'],description='A second inward leg over0.45s at half launch damage, once per target. Not Return Disc; longer waves can fill the cap.')]
links=[['tether_emitter','lock_memory'],['seismic_drum','return_collar']]
def append_array(text,key,rows):
 start=text.index('[',text.index('"'+key+'"'));depth=0;quote=False;escape=False
 for i in range(start,len(text)):
  c=text[i]
  if quote:
   if escape:escape=False
   elif c=='\\':escape=True
   elif c=='"':quote=False
  elif c=='"':quote=True
  elif c=='[':depth+=1
  elif c==']':
   depth-=1
   if depth==0:break
 pos=i
 while text[pos-1].isspace():pos-=1
 insertion=',\n'+',\n'.join('\n'.join('    '+line for line in json.dumps(row,ensure_ascii=False,indent=2).splitlines()) for row in rows)
 return text[:pos]+insertion+text[pos:],insertion
insertions=[]
for key,rows in [('weapons',weapons),('items',items),('mechanism_synergies',pairs),('affinity_links',links)]:raw,add=append_array(raw,key,rows);insertions.append(add)
p.write_text(raw)
after=json.loads(raw)
for key,rows in [('weapons',weapons),('items',items),('mechanism_synergies',pairs),('affinity_links',links)]:assert after[key]==before[key]+rows
fixture=dict(version=39,baseline_sha256=hashlib.sha256(Path('evidence-workspace/moss-v38-svg-candidate/data/catalog.json').read_bytes()).hexdigest(),raw_insertions=insertions,weapons=weapons,items=items,mechanism_synergies=pairs,affinity_links=links)
(r/'tests/fixtures/v39_catalog_additions.json').write_text(json.dumps(fixture,ensure_ascii=False,indent=2)+'\n')
p=r/'data/starting_loadouts.json';raw=p.read_text();rows=[dict(id='tether',name='Tether Starter',weapon='tether_emitter',starting_scrap=21,strength='Four pulses track one live target.',limitation='Range loss cancels remaining pulses.'),dict(id='seismic',name='Seismic Starter',weapon='seismic_drum',starting_scrap=21,strength='Narrow expanding ring hits a crowd.',limitation='Fixed center; enemies can stay in the hole.')];raw,add=append_array(raw,'loadouts',rows);p.write_text(raw)
(r/'tests/fixtures/v39_loadout_additions.json').write_text(json.dumps(dict(rows=rows,raw_insertions=[add],baseline_sha256=hashlib.sha256(Path('evidence-workspace/moss-v38-svg-candidate/data/starting_loadouts.json').read_bytes()).hexdigest()),indent=2)+'\n')
# Independent SVG art staging, never the held AI-reference images.
a=Path('evidence-workspace/moss-v39-art');art=r/'art_source/build_expansion_A';(art/'svg').mkdir(parents=True)
for f in (a/'svg').glob('*.svg'):shutil.copy2(f,art/'svg'/f.name)
for name in ['build_svg.py','export_assets.py','README.md','manifest.draft.json']:
 if(a/name).exists():shutil.copy2(a/name,art/name)
rows=json.loads((a/'manifest.draft.json').read_text())['assets'];icons={};world=json.loads((r/'assets/weapon_mounts/world_weapon_manifest.json').read_text())
for row in rows:
 rel=row['path'].removeprefix('res://');dst=r/rel;dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(a/rel,dst);assert hashlib.sha256(dst.read_bytes()).hexdigest()==row['sha256']
 name=row['id'];source='art_source/build_expansion_A/'+row['editable_source']
 if name.endswith('_held'):
  id=name.removesuffix('_held');entry={k:row[k] for k in ['path','region','alpha_bbox','grip','muzzle','projectile_anchor','visible_length','reference_width','sha256','asset_kind','source_review']};entry.update(editable_source=source,editable_sha256=row['svg_sha256']);world['weapons'][id]=entry
 else:
  id=name.removesuffix('_icon');icons[id]=dict(atlas=row['path'],rect=row['rect'],name=id.replace('_',' ').title(),category=row['category'],source_sha256=row['sha256'],editable_source=source,editable_sha256=row['svg_sha256'])
(r/'assets/weapon_mounts/world_weapon_manifest.json').write_text(json.dumps(world,indent=2)+'\n')
(r/'assets/items/expansion_A_icon_manifest.json').write_text(json.dumps(dict(version=1,icons=icons),indent=2)+'\n')
# UI lane completed draft, preapproved focus fix remains a separately recorded patch.
u=Path('evidence-workspace/moss-v39-ui')
for name in ['ui/moss_ui.gd','scripts/weapon_readout.gd']:shutil.copy2(u/name,r/name)
p=r/'ui/moss_ui.gd';s=p.read_text().replace('"res://assets/items/scavenger_icon_manifest.json"]:','"res://assets/items/scavenger_icon_manifest.json", "res://assets/items/expansion_A_icon_manifest.json"]:');p.write_text(s)
print('A catalog',len(after['weapons']),len(after['items']),'loadouts',len(json.loads((r/'data/starting_loadouts.json').read_text())['loadouts']),'original entries preserved; SVG formal sources7')
