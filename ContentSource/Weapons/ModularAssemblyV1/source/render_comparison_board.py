import bpy,json,math
from pathlib import Path
from mathutils import Matrix,Vector
R=Path(__file__).resolve().parents[1]
bpy.ops.wm.open_mainfile(filepath=str(R/'AetherLab_ThreePlatform_Modular.blend'))
s=bpy.context.scene
for c in bpy.data.collections:c.hide_viewport=False
bpy.context.view_layer.update()
for o in bpy.data.objects:
 if o.type=='MESH':o.hide_render=True
labelmat=bpy.data.materials.new('BoardLabel');labelmat.use_nodes=True;bs=labelmat.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(.75,.85,.85,1);bs.inputs['Emission Color'].default_value=(.55,.65,.65,1);bs.inputs['Emission Strength'].default_value=.5
m=json.loads((R/'config/Visual_Module_Manifest.json').read_text())
for row,plat in enumerate(['kite01','wisp02','mote03']):
 for col,variant in enumerate(['standard','compact_optic']):
  preset=plat+'.'+variant;offset=Vector((-.55+col*1.10,0,.65-row*.50))
  collection=bpy.data.collections['ASSEMBLY_'+preset]
  for o in collection.objects:
   cp=o.copy();cp.data=o.data;s.collection.objects.link(cp);cp.name='BOARD_'+o.name;cp.matrix_world=Matrix.Translation(offset)@o.matrix_world;cp.hide_render=False
  curve=bpy.data.curves.new('Label','FONT');curve.body=plat.upper()+' / '+variant.replace('_',' ').upper();curve.size=.027;curve.align_x='CENTER';curve.materials.append(labelmat);tx=bpy.data.objects.new('Board_Label',curve);s.collection.objects.link(tx);tx.location=(offset.x,-.10,offset.z-.245);tx.rotation_euler=(math.pi/2,0,0)
s.camera.location=(0,-4,.10);s.camera.rotation_euler=(math.pi/2,0,0);s.camera.data.ortho_scale=2.45
s.render.resolution_x=1900;s.render.resolution_y=1250;s.cycles.samples=64;s.cycles.use_denoising=False;s.render.filepath=str(R/'renders/ThreePlatform_Comparison.png');bpy.ops.render.render(write_still=True)
