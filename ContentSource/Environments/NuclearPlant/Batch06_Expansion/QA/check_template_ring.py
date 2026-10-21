"""Supplemental original-core route test using Epic example capsule dimensions, not Manny mesh measurement."""
import pathlib
p=pathlib.Path(__file__).with_name('check_expansion.py')
code=p.read_text().split('paths=')[0].replace("'height':2.10,'radius':.50","'height':1.92,'radius':.42").replace('[-.5,0,.5]','[-.42,0,.42]').replace('(0,0,1),2.04','(0,0,1),1.86').replace('[.5,1.0,1.65,2.05]','[.5,1.0,1.65,1.90]')
exec(compile(code,str(p),'exec'))
route('core_ring_r6p3',[(6.3*math.cos(a*math.pi/180),6.3*math.sin(a*math.pi/180),4.512) for a in range(0,361,3)])
R['basis']='Epic official Multiplayer Programming Quick Start example InitCapsuleSize(42,96) in centimetres. NOT official Manny mesh measured and NOT engine capsule sweep.'
R['source_url']='https://dev.epicgames.com/documentation/en-us/unreal-engine/multiplayer-programming-quick-start-for-unreal-engine'
(P/'core_template_capsule_static.json').write_text(json.dumps(R,indent=2));print('TEMPLATE_RING',len(R['routes']['core_ring_r6p3']['issues']))
