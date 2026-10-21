import pathlib,bpy
P=pathlib.Path(__file__).resolve().parent
for c in bpy.data.collections:
 if c.name=='B06_Pumps' and c.name not in bpy.context.scene.collection.children:bpy.context.scene.collection.children.link(c)
bpy.context.view_layer.update()
exec((P/'check_expansion.py').read_text().split("paths={'outer_loop'")[0])
route('main_aisle',[(42,8,0),(66,8,0)])
route('service_hall_approach',[(56,8,0),(57.5,9,0),(57.5,18.5,0),(56,20,0)])
(P/'pump_independent.json').write_text(json.dumps(R,indent=2));print({n:len(v['issues']) for n,v in R['routes'].items()})
