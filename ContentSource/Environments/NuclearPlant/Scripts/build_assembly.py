import bpy,json,pathlib,math,sys
from mathutils import Vector,Matrix
R=pathlib.Path(__file__).resolve().parents[1];manifest=json.loads((R/'manifest.json').read_text());specs={};protos={};entries={}
bpy.ops.wm.read_factory_settings(use_empty=True)
s=bpy.context.scene;s.unit_settings.system='METRIC';s.unit_settings.scale_length=1;s.render.engine='CYCLES';s.cycles.samples=64;s.cycles.use_denoising=False;s.cycles.max_bounces=5
s.render.resolution_x=1800;s.render.resolution_y=1200;s.render.resolution_percentage=100;s.view_settings.view_transform='AgX'
s.world=bpy.data.worlds.new('Assembly world');s.world.use_nodes=True;s.world.node_tree.nodes['Background'].inputs[0].default_value=(.35,.44,.50,1);s.world.node_tree.nodes['Background'].inputs[1].default_value=.6
for e in manifest['assets']:
 sp=json.loads((R/e['path']/'spec.json').read_text());specs[sp['builder']]=sp;entries[sp['builder']]=e
 with bpy.data.libraries.load(str(R/e['path']/'model.blend'),link=False) as (a,b):b.objects=[sp['asset_id']]
 protos[sp['builder']]=b.objects[0]
instances={};socket_pairs=[]
def instance(key,kind,loc,deg=0):
 p=protos[kind];o=bpy.data.objects.new(key,p.data);bpy.context.collection.objects.link(o);o.hide_render=False;o.hide_set(False);o.matrix_world=Matrix.Translation(Vector(loc))@Matrix.Rotation(math.radians(deg),4,'Z');o['asset_id']=specs[kind]['asset_id'];instances[key]=(kind,o);return o
placements=[('A','straight',(0,0,4),0),('B','tee',(4,0,4),0),('C','straight',(8,0,4),0),('D','corner',(12,0,4),0),('E','straight',(15,3,4),90),('F','stairs',(15,7,4),90),('G','straight',(15,11,6),90),('H','straight',(6,3,4),90),('I','straight',(-4,0,4),0)]
for args in placements:instance(*args)
links=[('I','end','A','start'),('A','end','B','start'),('B','end','C','start'),('C','end','D','start'),('D','turn','E','start'),('E','end','F','lower'),('F','upper','G','start'),('B','branch','H','start')]
for a,sa,b,sb in links:
 def world_socket(key,sid):
  kind,o=instances[key];sp=next(x for x in specs[kind]['connection_sockets'] if x['id']==sid);return o.matrix_world@Vector(sp['position_m']),o.matrix_world.to_3x3()@Vector(sp['outward_normal'])
 pa,na=world_socket(a,sa);pb,nb=world_socket(b,sb);gap=(pa-pb).length;dot=na.dot(nb)
 socket_pairs.append({'a':a+':'+sa,'b':b+':'+sb,'position_error_m':gap,'opposed_normals_dot':dot,'status':'PASS' if gap<1e-5 and abs(dot+1)<1e-6 else 'FAIL'})
for i,x in enumerate([-3,1,5,9,13]):
 for j,y in enumerate([-.75,.75]):instance('Support_'+str(i)+'_'+str(j),'column',(x,y,-.2))
for i,y in enumerate([3.5,6.5]):
 for j,x in enumerate([14.25,15.75]):instance('TurnSupport_'+str(i)+'_'+str(j),'column',(x,y,-.2))
for j,x in enumerate([5.25,6.75]):instance('BranchSupport_'+str(j),'column',(x,5.75,-.2))
instance('BranchTerminal','rail_infill',(5,7,4));instance('UpperTerminal','rail_infill',(14,15,6));instance('WestTerminal','rail_infill',(-4,-1,4),90)
instance('UtilityRail','rail_open',(-2,-4,0));instance('PipeSupport_01','pipe_support',(4,-3.5,0),90);instance('PipeSupport_02','pipe_support',(8,-3.5,0),90)
def material(n,c,metal=0,rough=.6):
 m=bpy.data.materials.new(n);m.diffuse_color=(*c,1);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*c,1);p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=rough;return m
concrete=material('ASSEMBLY_Concrete',(.18,.23,.25));dark=material('ASSEMBLY_Ground',(.09,.13,.16));teal=material('ASSEMBLY_UtilityPipe',(.07,.3,.32),.6,.35);labelmat=material('ASSEMBLY_Label',(.92,.76,.27));white=material('ASSEMBLY_White',(.8,.85,.84))
def cube(n,loc,dim,mat):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.name=n;o.dimensions=dim;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(mat);be=o.modifiers.new('edge','BEVEL');be.width=.03;be.segments=2;return o
cube('Presentation_foundation',(6,4,-.35),(28,27,.3),dark)
# Neutral context blocks only, not additional finished modular assets.
cube('CONTEXT_upper_service_building',(18,12,3),(4,10,6),concrete)
for y in [9,11,13,15]:cube('CONTEXT_facade_joint',(15.99,y,3),(.02,.03,6),dark)
# Small service pipe beneath the catwalk. Context only, not a kit asset.
for y,z in [(-4.0,2.0),(-3.0,2.0)]:
 bpy.ops.mesh.primitive_cylinder_add(vertices=24,radius=.265,depth=13,location=(5,y,z),rotation=(0,math.pi/2,0));o=bpy.context.object;o.name='CONTEXT_UtilityPipe';o.data.materials.append(teal)
# Label set facing the overview camera, as a facility plaque.
bpy.ops.object.text_add(location=(-5,-7,.0));o=bpy.context.object;o.name='PRESENTATION_SiteName';o.data.body='NPP / SECTOR K-17';o.data.size=.8;o.data.extrude=.002;o.data.materials.append(white)
bpy.ops.object.text_add(location=(-5,-8,.0));o=bpy.context.object;o.name='PRESENTATION_Subtitle';o.data.body='MODULAR MAINTENANCE NETWORK  /  BATCH 01';o.data.size=.28;o.data.extrude=.002;o.data.materials.append(labelmat)
for name,loc,en,size in [('KEY',(-10,-12,25),6000,16),('FILL',(20,4,18),4500,14),('RIM',(5,25,15),5000,12)]:
 bpy.ops.object.light_add(type='AREA',location=loc);o=bpy.context.object;o.name=name;o.data.energy=en;o.data.shape='DISK';o.data.size=size;o.rotation_euler=(Vector((6,4,2))-o.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add(location=(31,-35,28));cam=bpy.context.object;cam.name='ASSEMBLY_BEAUTY_ORTHO';cam.rotation_euler=(Vector((6,4,2.5))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=36;s.camera=cam
bpy.ops.wm.save_as_mainfile(filepath=str(R/'ModularKit/assembly_demo.blend'))
s.render.filepath=str(R/'Previews/assembly_beauty.png');bpy.ops.render.render(write_still=True)
cam.location=(6,4,45);cam.rotation_euler=(0,0,0);cam.data.ortho_scale=31;s.render.resolution_x=1400;s.render.resolution_y=1400;s.render.filepath=str(R/'Previews/assembly_top.png');bpy.ops.render.render(write_still=True)
report={'status':'PASS' if all(r['status']=='PASS' for r in socket_pairs) else 'FAIL','tested_mates':socket_pairs,'placements':[{'instance':k,'asset_id':specs[t]['asset_id'],'matrix_world':[list(row) for row in o.matrix_world]} for k,(t,o) in instances.items()],'scope':'Eight socket connections, including 90-degree turns and 2 m stair height change. Coincident declared socket planes and opposed normals verified. UE runtime traversal and playtesting pending.'}
(R/'Validation/assembly_validation.json').write_text(json.dumps(report,indent=2));print('ASSEMBLY_COMPLETE',report['status'])
