import bpy,pathlib,json,sys
R=pathlib.Path(__file__).resolve().parent;C=json.loads((R/'layout.json').read_text());bpy.ops.wm.open_mainfile(filepath=str(R/'site_expansion.blend'));s=bpy.context.scene
names=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else ['site_overview']
cut_cols=['02_Roof_Toggle','B06_Control_Roof','B06_Maintenance_Roof']
cut_objects=[o for o in bpy.data.objects if ('End wall panel' in o.name and o.location.y<0) or ('Side concrete panel' in o.name and o.location.x>0) or o.name.startswith('B06_P_hall roof')]
for n in names:
 cut=n=='site_cutaway'
 for cc in bpy.data.collections:
  if cc.name.startswith('B06_Proxy_'):cc.hide_render=n not in ['site_overview','site_cutaway']
 for cn in cut_cols:
  if cn in bpy.data.collections:bpy.data.collections[cn].hide_render=cut
 for o in cut_objects:o.hide_render=cut
 s.camera=bpy.data.objects['site_overview' if cut else n];s.render.filepath=str(R/'renders'/f'{n}.png');bpy.ops.render.render(write_still=True)
