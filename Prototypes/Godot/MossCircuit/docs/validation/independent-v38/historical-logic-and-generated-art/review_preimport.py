from pathlib import Path
import json,hashlib
from PIL import Image
r=Path('<WORKSPACE_ROOT>/shared'); w=r/'moss-v38-work'; p=r/'moss-v38-prep'; q=r/'moss-v38-qa'; base=r/'moss-v37-final'
h=lambda f:hashlib.sha256(f.read_bytes()).hexdigest()
m=json.loads((p/'PREIMPORT_INPUTS.json').read_text()); assert len(m)==745
assert all(h(w/n)==v for n,v in m.items()); assert not (w/'.godot').exists()
changes=json.loads((p/'PREIMPORT_CHANGES.json').read_text()); assert len(changes)==23
assert sum(v['old'] is None for v in changes.values())==11
for n,row in changes.items():
 assert h(w/n)==row['new']
 if row['old']:assert h(base/n)==row['old']
for n in ['scripts/gameplay/weapon_combat.gd','scripts/gameplay/effect_runtime.gd','scripts/effects.gd','scripts/rules.gd','scripts/gameplay/run_flow.gd','tools/run_regression.py']:
 if (w/n).exists():assert (w/n).read_bytes()==(base/n).read_bytes()
a=json.loads((w/'assets/enemies/enemy_manifest.json').read_text()); b=json.loads((base/'assets/enemies/enemy_manifest.json').read_text())
# Existing manifest entries recursively unchanged except the one reviewed addition.
def subset(old,new):
 if isinstance(old,dict):return all(k in new and subset(v,new[k]) for k,v in old.items())
 return old==new
assert subset(b,a)
assets=[]
for n in ['assets/enemies/stitch_drone.png']+['assets/actions/stitch_drone/stitch_drone_'+x+'.png' for x in ['channel','hurt','death']]:
 im=Image.open(w/n); im.load(); assert im.mode=='RGBA' and im.size==(1254,1254)
 assets.append({'path':n,'sha256':h(w/n),'rgba_sha256':hashlib.sha256(im.tobytes()).hexdigest(),'size':list(im.size),'alpha_extrema':im.getchannel('A').getextrema()})
main=(w/'scripts/main.gd').read_text(); assert 'state = "won" if won else "dead"\n\tEnemySupport.settle(enemies,[],false)' in main
out={'pass':True,'scope':'Independent pre-execution static review only; no target import/run','inputs':745,'map_sha256':h(p/'PREIMPORT_INPUTS.json'),'changed_existing':12,'new':11,'runner_sha256':h(p/'run_initial.py'),'changes_sha256':h(p/'PREIMPORT_CHANGES.json'),'projection_review_sha256':h(q/'PROJECTION_STATIC_REVIEW.json'),'policy_review':['warning/nonwarning schema','detached pending exact fields','invalid identity mutators clear failclosed','recover later tick expiry may acquire without entry dt','rounded zero increase emits no completion','A after all AI/clamp/spawns; B after death/pickup; no second death flush','immediate terminal cleanup before delayed result'],'assets':assets,'visual_review':'Directly viewed all four original full source sheets: distinct cyan spool/needle hover enemy, channel/hurt/death sequences. Static only, no in-game size/alignment/native claims.','first_run':'Author cold import + eight focused scripts, 180s each, strict exit/errors/resource warnings/semantic marker, first failure stops, original inputs checked after; independent four oracles separate','limitations':['Runtime/parser untested','Windows and physical audible unverified','Independent source/PCK/native/ordinary/full-suite still pending']}
(q/'PREIMPORT_STATIC_REVIEW.json').write_text(json.dumps(out,indent=2)+'\n'); print(json.dumps({'pass':True,'receipt_sha256':h(q/'PREIMPORT_STATIC_REVIEW.json'),'map_sha256':out['map_sha256']}))
