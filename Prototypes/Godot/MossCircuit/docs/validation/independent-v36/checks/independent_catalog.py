"""Finite value-preservation/schema checks, independent of production validator."""
import json,sys,math,hashlib
from pathlib import Path
base=Path(sys.argv[1]);candidate=Path(sys.argv[2]);old=json.loads((base/'data/catalog.json').read_text());new=json.loads((candidate/'data/catalog.json').read_text());checks=[]
def ck(ok,label):
 checks.append({'label':label,'pass':bool(ok)})
 if not ok:raise AssertionError(label)
ck(set(new)==set(old),'no new unrelated catalog top-level system')
for key in old:
 if key not in ('version','items','mechanism_synergies','affinity_links'):ck(new[key]==old[key],'old exact values '+key)
olditems={v['id']:v for v in old['items']};newitems={v['id']:v for v in new['items']};ck(len(newitems)==len(olditems)+1 and set(newitems)-set(olditems)=={'scavenger_reel'},'one unique module only')
for ident,row in olditems.items():ck(newitems[ident]==row,'old row value exact '+ident)
row=newitems['scavenger_reel']
for key,want in {'id':'scavenger_reel','name':'Scavenger Reel','price':28,'rarity':'rare','max_stack':1,'tags':['returning','salvage'],'effects':{},'return_pickup_radius':18.0,'return_pickup_limit':3,'pickup_sources':['normal','energy']}.items():ck(row.get(key)==want,'new authored value '+key)
ck(new['affinity_links'][:len(old['affinity_links'])]==old['affinity_links'],'old affinity order unchanged')
ck(len(new['affinity_links'])==len(old['affinity_links'])+1 and set(new['affinity_links'][-1])=={'return_disc','scavenger_reel'},'one return affinity only')
ck(new['mechanism_synergies'][:len(old['mechanism_synergies'])]==old['mechanism_synergies'],'old mechanism rows exact')
ck(len(new['mechanism_synergies'])==len(old['mechanism_synergies'])+1,'one mechanism row')
mechanism=new['mechanism_synergies'][-1];ck(mechanism['name']=='SCAVENGER RETURN' and set(mechanism['requires'])=={'return_disc','scavenger_reel'},'actual two prerequisites')
for relative in ['data/balance.json','data/starting_loadouts.json','data/encounters.json','data/room_encounters.json','assets/audio/player_damage.wav','assets/audio/shield_block.wav']:
 # Asset locations discovered from baseline source without guessing alternative content.
 if (base/relative).exists():ck((base/relative).read_bytes()==(candidate/relative).read_bytes(),'unchanged scoped baseline '+relative)
print(json.dumps({'status':'PASS_INDEPENDENT_CATALOG_ONLY','checks':len(checks),'records':checks},indent=2))
