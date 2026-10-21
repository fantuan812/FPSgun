import bpy,pathlib,sys,json
R=pathlib.Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(R/'core_hall.blend'))
s=bpy.context.scene
names=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else ['core_eye_front']
CFG=json.loads((R/'core_config.json').read_text())['render'];s.render.engine=CFG['engine'];s.eevee.taa_render_samples=CFG['samples'];s.render.resolution_x=CFG['width'];s.render.resolution_y=CFG['height'];s.render.resolution_percentage=100;s.eevee.shadow_pool_size='1024'
for n in names:
 for o in bpy.data.collections['01_Hall_Architecture'].objects:
  if ('End wall panel' in o.name and o.location.y<0) or ('Side concrete panel' in o.name and o.location.x>0):o.hide_render=False
 s.camera=bpy.data.objects[n];s.render.filepath=str(R/'renders'/f'{n}.png')
 bpy.data.collections['02_Roof_Toggle'].hide_render=n=='core_cutaway'
 if n=='core_cutaway':
  for o in bpy.data.collections['01_Hall_Architecture'].objects:
   if ('End wall panel' in o.name and o.location.y<0) or ('Side concrete panel' in o.name and o.location.x>0):o.hide_render=True
 bpy.ops.render.render(write_still=True)
