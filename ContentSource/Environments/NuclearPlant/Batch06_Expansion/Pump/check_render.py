import bpy,json,pathlib,math
from mathutils import Vector
R=pathlib.Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(R.parent/'Regions/pumps.blend'));s=bpy.context.scene;dg=bpy.context.evaluated_depsgraph_get()
fail=[];samples=[]
for i in range(25):
 x=42.5+i
 for y in [6.5,8,9.5]:
  hit,p,n,idx,obj,m=s.ray_cast(dg,Vector((x,y,2.5)),Vector((0,0,-1)),distance=3)
  if not hit or abs(p.z)>.15:fail.append({'x':x,'y':y,'kind':'floor','object':obj.name if obj else None})
  else:
   hh,pp,*_=s.ray_cast(dg,Vector((x,y,.05)),Vector((0,0,1)),distance=2.4)
   if hh:fail.append({'x':x,'y':y,'kind':'head_clearance','height':pp.z})
  samples.append([x,y])
# Hall approach: center corridor from main aisle into 6m opening.
for x in [57,57.5,58]:
 for y in [10,11,12,13,14,15,16,17,18,19,20,21]:
  hit,p,*_=s.ray_cast(dg,Vector((x,y,2.5)),Vector((0,0,-1)),distance=3)
  if not hit or abs(p.z)>.15:fail.append({'x':x,'y':y,'kind':'hall_approach_floor'})
  samples.append([x,y])
# Conservative 2.1m high / .5m radius proxy envelope, sampled not UE collision.
route=[(56,8),(57.5,9),(57.5,18.5),(56,20)]
for a,b in zip(route,route[1:]):
 steps=math.ceil(math.dist(a,b)/.2)
 for i in range(steps+1):
  x=a[0]+(b[0]-a[0])*i/steps;y=a[1]+(b[1]-a[1])*i/steps
  for angle in range(0,360,45):
   xx=x+.5*math.cos(math.radians(angle));yy=y+.5*math.sin(math.radians(angle))
   hit,p,*_=s.ray_cast(dg,Vector((xx,yy,2.1)),Vector((0,0,-1)),distance=2.3)
   if not hit or abs(p.z)>.15:fail.append({'x':xx,'y':yy,'kind':'proxy_route','surface_z':p.z if hit else None})
   samples.append([xx,yy])
bbox=[]
for o in s.objects:
 if o.type in ['MESH','CURVE','FONT']:
  ob=o.evaluated_get(dg)
  mesh=ob.to_mesh();bbox.extend([ob.matrix_world@v.co for v in mesh.vertices]);ob.to_mesh_clear()
mn=[min(p[i] for p in bbox) for i in range(3)];mx=[max(p[i] for p in bbox) for i in range(3)]
r={'samples':len(samples),'failures':fail,'bounds':[mn,mx],'libraries':[l.filepath for l in bpy.data.libraries],'main_aisle':'4m wide declared; 3 sampled lines','hall_route':route,'proxy':{'height':2.1,'radius':.5,'method':'ring floor-rays at .2m route spacing, not full physics sweep'},'limitations':'static vertical rays only, not capsule or UE tests'}
(R/'check_report.json').write_text(json.dumps(r,indent=2));print(r)
s.render.engine='BLENDER_WORKBENCH';s.display.shading.light='STUDIO';s.display.shading.color_type='MATERIAL';s.display.shading.show_shadows=True;s.display.shading.show_cavity=True;s.display.shading.cavity_type='BOTH';s.display.shading.background_type='WORLD';s.world=bpy.data.worlds.new('QA World');s.world.color=(.10,.10,.10)
s.render.resolution_x=1200;s.render.resolution_y=900;s.render.resolution_percentage=100
cam=bpy.data.cameras.new('QA_Camera');o=bpy.data.objects.new('QA_Camera',cam);s.collection.objects.link(o);o.location=(24,-25,30);o.rotation_euler=(Vector((55,8,3))-o.location).to_track_quat('-Z','Y').to_euler();cam.type='ORTHO';cam.ortho_scale=48;s.camera=o;s.render.filepath=str(R/'overview.png');bpy.ops.render.render(write_still=True)
