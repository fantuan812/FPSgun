"""Add a rotated, separately occupied side accessory fixture after base assets are built."""
import bpy,json,math,copy
from pathlib import Path
from mathutils import Matrix,Quaternion,Vector
R=Path(__file__).resolve().parents[1];p=R/'config/Visual_Module_Manifest.json';m=json.loads(p.read_text())
slot={'translation_m':[.115,-.0275,.006],'rotation_xyzw':[-math.sqrt(.5),0,0,math.sqrt(.5)],'scale':[1,1,1],'mount_type':'utility','occupancy_group':'side_utility'}
m['modules']['wisp02.handguard.standard']['slots']['side_light']=slot
preset=copy.deepcopy(next(p for p in m['presets'] if p['id']=='wisp02.standard'));preset['id']='wisp02.side_light';preset['nodes'].append({'instance_id':'side_light','module_id':'shared.light.compact','parent_id':'handguard.standard','slot_id':'side_light'})
m['presets']=[p for p in m['presets'] if p['id']!=preset['id']]+[preset]
bpy.ops.wm.open_mainfile(filepath=str(R/'AetherLab_ThreePlatform_Modular.blend'))
col=bpy.data.collections.get('ASSEMBLY_'+preset['id'])
if col:
 for o in list(col.objects):bpy.data.objects.remove(o,do_unlink=True)
else:col=bpy.data.collections.new('ASSEMBLY_'+preset['id']);bpy.context.scene.collection.children.link(col)
col.hide_viewport=False
for o in bpy.data.objects:
 if o.type=='MESH' and o.name!='Studio_Floor':o.hide_render=True
world={};ids={};obs=[]
for n in preset['nodes']:
 if n['parent_id'] is None:w=Matrix.Identity(4)
 else:
  s=m['modules'][ids[n['parent_id']]]['slots'][n['slot_id']];q=s['rotation_xyzw'];w=world[n['parent_id']]@Matrix.Translation(Vector(s['translation_m']))@Quaternion((q[3],q[0],q[1],q[2])).to_matrix().to_4x4()
 world[n['instance_id']]=w;ids[n['instance_id']]=n['module_id'];orig=bpy.data.objects[m['modules'][n['module_id']]['object']];o=orig.copy();o.data=orig.data;o.name=preset['id']+'__'+n['instance_id'];o.matrix_world=w;o.hide_render=False;col.objects.link(o);obs.append(o)
bpy.ops.object.select_all(action='DESELECT')
for o in obs:o.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(R/'exports'/f'{preset["id"]}.glb'),export_format='GLB',use_selection=True,export_animations=False,export_extras=True)
s=bpy.context.scene;s.camera.data.ortho_scale=.81;s.camera.location=(.74,-1.3,.65);s.camera.rotation_euler=(Vector((.04,0,0))-s.camera.location).to_track_quat('-Z','Y').to_euler();bpy.data.objects['Studio_Floor'].location.z=-.23
s.render.filepath=str(R/'renders'/f'{preset["id"]}.png');s.cycles.use_denoising=False;bpy.ops.render.render(write_still=True)
for c in bpy.data.collections:
 if c.name.startswith('ASSEMBLY_'):c.hide_viewport=c!=col
p.write_text(json.dumps(m,indent=2));bpy.ops.wm.save_as_mainfile(filepath=str(R/'AetherLab_ThreePlatform_Modular.blend'),compress=True)
print('SIDE_FIXTURE_COMPLETE',len(m['presets']))
