import pathlib, bpy
for c in bpy.data.collections:
 if c.name.startswith("B06_") and c.name not in bpy.context.scene.collection.children: bpy.context.scene.collection.children.link(c)
bpy.context.view_layer.update()
P=pathlib.Path(__file__).resolve().parent
exec((P/'check_expansion.py').read_text().split("paths={'outer_loop'")[0])
if 'maintenance' in bpy.data.filepath:
 route('east_entry',[(-41,0,0),(-55,0,0)])
 route('south_entry',[(-54,-17,0),(-54,-10,0)])
 route('stair',[(-62.5,.48+(i+.5)*.28,(i+1)*6/34) for i in range(34)])
 route('upper',[(-62.5,10,6),(-62.5,14,6),(-54,14,6),(-54,19,6)])
else:
 route('entry',[(42,-41,0),(42,-50,0)])
 route('ramp',[(19.8,-45,0),(19.8,-56.5,1.1),(19.8,-57.8,1.1),(25,-57.8,1.1)])
 route('stairs',[(22.5,-54.58-(i+.5)*.32,(i+1)*1.1/6) for i in range(6)])
name=pathlib.Path(bpy.data.filepath).stem
(P/(name+'_independent.json')).write_text(json.dumps(R,indent=2));print({n:len(v['issues']) for n,v in R['routes'].items()})
