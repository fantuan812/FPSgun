import bpy,pathlib,json
R=pathlib.Path(__file__).resolve().parent;bpy.ops.wm.open_mainfile(filepath=str(R/'core_hall.blend'))
CFG=json.loads((R/'core_config.json').read_text());s=bpy.context.scene
# Foundation must sit BELOW the separate finish panels (panels top -0.005m).
bpy.data.objects['Foundation'].location.z=-.365
bpy.data.objects['Foundation'].data.materials.clear();bpy.data.objects['Foundation'].data.materials.append(bpy.data.materials['Graphite structure'])
# Keep display header below platform diagonal braces; brackets still enter the shell.
for o in s.objects:
 if o.name.startswith(('Diagnostic panel housing','Diagnostic active display','Display shell mount','Display grid','Telemetry bar','Diagnostic label')):o.location.z-=.5;o.location.y-=.2
s.render.engine=CFG['render']['engine'];s.eevee.shadow_pool_size='1024';s.eevee.taa_render_samples=CFG['render']['samples'];s.render.resolution_x=CFG['render']['width'];s.render.resolution_y=CFG['render']['height'];s.render.resolution_percentage=100
bpy.ops.wm.save_as_mainfile(filepath=str(R/'core_hall.blend'),compress=True)
print('FINAL_SCENE_FINISH')
