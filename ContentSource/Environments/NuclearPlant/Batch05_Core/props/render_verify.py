import bpy, os, math, json
from mathutils import Vector
ROOT=os.path.dirname(os.path.abspath(__file__))
bpy.ops.wm.open_mainfile(filepath=os.path.join(ROOT,'props.blend'))
cols=[c for c in bpy.data.collections if c.name.startswith('CP_')]
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=12;scene.cycles.use_denoising=False
scene.render.resolution_x=500;scene.render.resolution_y=500;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG';scene.world.color=(.4,.4,.4)
scene.view_settings.view_transform='AgX'
world=scene.world;world.use_nodes=True;world.node_tree.nodes['Background'].inputs[0].default_value=(.26,.3,.32,1);world.node_tree.nodes['Background'].inputs[1].default_value=.7
for name,loc,power,size in [('key',(4,-7,9),1800,7),('fill',(-5,-2,5),1200,6),('rim',(2,5,8),1800,5)]:
    d=bpy.data.lights.new(name,'AREA');d.energy=power;d.shape='DISK';d.size=size;o=bpy.data.objects.new(name,d);scene.collection.objects.link(o);o.location=loc;o.rotation_euler=(Vector((0,0,1.5))-o.location).to_track_quat('-Z','Y').to_euler()
d=bpy.data.cameras.new('OrthoValidation');d.type='ORTHO';o=bpy.data.objects.new('OrthoValidation',d);scene.collection.objects.link(o);scene.camera=o
os.makedirs(os.path.join(ROOT,'orthographic'),exist_ok=True)
manifest=[]
for c in cols:
    if os.environ.get('ONLY_PROP') and c.name!=os.environ['ONLY_PROP']:continue
    for cc in cols:cc.hide_render=(cc!=c)
    pts=[ob.matrix_world@Vector(v) for ob in c.objects if ob.type=='MESH' for v in ob.bound_box]
    lo=Vector([min(p[i] for p in pts) for i in range(3)]);hi=Vector([max(p[i] for p in pts) for i in range(3)]);center=(lo+hi)/2;dim=hi-lo
    for view,direction,scale in [('front',(0,-1,0),max(dim.x,dim.z)),('side',(1,0,0),max(dim.y,dim.z)),('top',(0,0,1),max(dim.x,dim.y))]:
        o.location=center+Vector(direction)*20;o.rotation_euler=(center-o.location).to_track_quat('-Z','Y').to_euler();d.ortho_scale=scale*1.22
        path=os.path.join(ROOT,'orthographic',c.name+'_'+view+'.png');scene.render.filepath=path;bpy.ops.render.render(write_still=True)
        manifest.append({'collection':c.name,'view':view,'camera_type':d.type,'ortho_scale_m':d.ortho_scale,'camera_location':list(o.location),'target':list(center),'dimensions_m':list(dim),'path':os.path.basename(path)})
if os.environ.get('ONLY_PROP'):
    old=json.load(open(os.path.join(ROOT,'orthographic','camera_manifest.json')))
    manifest=[x for x in old if x['collection']!=os.environ['ONLY_PROP']]+manifest
json.dump(manifest,open(os.path.join(ROOT,'orthographic','camera_manifest.json'),'w'),indent=2)
