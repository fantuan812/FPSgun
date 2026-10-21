import bpy, json, math, pathlib
from mathutils import Vector
R=pathlib.Path(__file__).resolve().parents[1]; spec=json.loads((R/'Blockout/layout_spec.json').read_text())
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
s=bpy.context.scene;s.unit_settings.system='METRIC';s.unit_settings.scale_length=1
s.render.engine='CYCLES';s.cycles.samples=64;s.cycles.use_denoising=False
s.render.resolution_x=1600;s.render.resolution_y=1100;s.render.resolution_percentage=100
s.world.color=(.24,.24,.24)
s.view_settings.view_transform='AgX'
def mat(n,c):
 m=bpy.data.materials.new(n);m.diffuse_color=(*c,1);return m
def box(n,loc,sz,m):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.name=n;o.dimensions=sz;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(m);return o
ground=mat('Graybox_Ground',(.10,.14,.16));road=mat('Graybox_Routes',(.22,.28,.29));yellow=mat('Graybox_Maintenance',(.9,.55,.10));white=mat('Graybox_Labels',(.85,.9,.86))
box('SITE_224x192',(0,0,-1),(224,192,2),ground)
for x in [-76,-24,48,96]:box('Service_lane_NS',(x,0,.03),(8,176,.06),road)
for y in [-80,-44,4,68]:box('Service_lane_EW',(0,y,.04),(208,8,.06),road)
for z in spec['zones']:
 m=mat(z['id']+'_material',z['color']);box(z['id'],z['center'],z['size'],m)
 bpy.ops.object.text_add(location=(z['center'][0]-z['size'][0]/2+2,z['center'][1]-z['size'][1]/2+2,z['size'][2]+.1));o=bpy.context.object;o.name='Label_'+z['id'];o.data.body=z['id'];o.data.size=2;o.data.extrude=.008;o.data.materials.append(white)
# A distinct offset service route between main zones; four meter level.
for a,b in [((-48,-16),(-48,8)),((-48,8),(16,8)),((16,8),(16,24)),((16,8),(72,8)),((72,8),(72,-20))]:
 x=(a[0]+b[0])/2;y=(a[1]+b[1])/2;dx=abs(a[0]-b[0]);dy=abs(a[1]-b[1]);box('Elevated_route_Z4',(x,y,3.9),(dx or 2,dy or 2,.2),yellow)
for x,y in [(-48,0),(-24,8),(0,8),(24,8),(48,8),(72,0)]:box('Route_support',(x,y,2),(.5,.5,4),road)
# Reactor dome is explicitly a placeholder.
bpy.ops.mesh.primitive_uv_sphere_add(segments=32,ring_count=16,radius=17,location=(-48,32,23));o=bpy.context.object;o.name='HERO_PLACEHOLDER_containment_dome';o.scale.z=.7;o.data.materials.append(bpy.data.materials['01_REACTOR_material'])
bpy.ops.object.light_add(type='AREA',location=(-70,-70,170));bpy.context.object.data.energy=180000;bpy.context.object.data.shape='DISK';bpy.context.object.data.size=140
bpy.ops.object.camera_add(location=(180,-240,220));cam=bpy.context.object;cam.rotation_euler=(Vector((0,0,6))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=280;s.camera=cam
bpy.ops.wm.save_as_mainfile(filepath=str(R/'Blockout/site_graybox.blend'))
s.render.filepath=str(R/'Blockout/site_graybox_overview.png');bpy.ops.render.render(write_still=True)
cam.location=(0,0,300);cam.rotation_euler=(0,0,0);cam.data.ortho_scale=240;s.render.resolution_x=1400;s.render.resolution_y=1200;s.render.filepath=str(R/'Blockout/site_graybox_top.png');bpy.ops.render.render(write_still=True)
print('GRAYBOX_COMPLETE')
