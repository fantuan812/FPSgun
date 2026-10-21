import bpy,math,os,json
from mathutils import Vector
R=os.path.dirname(os.path.abspath(__file__))
bpy.ops.wm.open_mainfile(filepath=os.path.join(R,'reactor.blend'))
s=bpy.context.scene;s.render.engine='BLENDER_WORKBENCH';s.render.resolution_x=1000;s.render.resolution_y=1000;s.render.resolution_percentage=100;s.render.image_settings.file_format='PNG';s.render.film_transparent=False
s.display.shading.light='STUDIO';s.display.shading.studiolight_rotate_z=.4;s.display.shading.color_type='MATERIAL';s.display.shading.show_shadows=True;s.display.shading.show_cavity=True;s.display.shading.cavity_type='BOTH';s.display.shading.curvature_ridge_factor=1.5;s.display.shading.curvature_valley_factor=1.0;s.display.shading.background_type='WORLD';s.world.color=(.13,.15,.18)
if not s.camera:
    cd=bpy.data.cameras.new('Ortho_verify');cam=bpy.data.objects.new('Ortho_verify',cd);s.collection.objects.link(cam);s.camera=cam
cam=s.camera;cam.data.type='ORTHO';cam.data.ortho_scale=17
views=[('front',(0,-30,7),(0,0,7)),('side',(30,0,7),(0,0,7)),('top',(0,0,35),(0,0,0)),('beauty',(22,-28,20),(0,0,7))]
for name,loc,target in views:
    cam.location=loc;cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler();s.render.filepath=os.path.join(R,'reactor_'+name+'.png');bpy.ops.render.render(write_still=True)
info={'projection':'ORTHO','ortho_scale_m':17,'resolution_px':[1000,1000],'views':[x[0] for x in views],'camera_coordinates':views,'scene_file':'reactor.blend','all_views_actual_blender_renders':True}
with open(os.path.join(R,'orthographic_manifest.json'),'w') as f:json.dump(info,f,indent=2)
