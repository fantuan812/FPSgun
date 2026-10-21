import bpy,json,pathlib
from mathutils import Vector
R=pathlib.Path(__file__).resolve().parents[1];out=[]
def bounds(o):
 v=[o.matrix_world@Vector(c) for c in o.bound_box];return [min(p[i] for p in v) for i in range(3)],[max(p[i] for p in v) for i in range(3)]
for label,name in [('before','service_compact_comparison_only.blend'),('after','pump_service_connected.blend')]:
 bpy.ops.wm.open_mainfile(filepath=str(R/'Region'/name));s=bpy.context.scene;cols=[o for o in s.objects if o.name.startswith('HallColumn')];floors=[o for o in s.objects if o.name.startswith('MezzFloor_')];roof=[o for o in s.objects if o.name.startswith('ServiceRoof_')];trusses=[o for o in s.objects if o.name.startswith('HallRoofTruss_')]
 xs=sorted(set(round(o.location.x,4) for o in cols));ys=sorted(set(round(o.location.y,4) for o in cols));out.append({'label':label,'source':name,'roof_top_z_m':max(bounds(o)[1][2] for o in roof),'roof_tile_bottom_z_m':min(bounds(o)[0][2] for o in roof),'internal_hall_column_x_axes_m':xs,'internal_hall_column_y_axes_m':ys,'mezzanine_floor_tile_count':len(floors),'mezzanine_width_m':max(bounds(o)[1][0] for o in floors)-min(bounds(o)[0][0] for o in floors),'mezzanine_underside_z_m':min(bounds(o)[0][2] for o in floors),'truss_count':len(trusses),'truss_bottom_z_m':min([bounds(o)[0][2] for o in trusses],default=None)})
(R/'Validation/space_before_after_measured.json').write_text(json.dumps(out,indent=2));print(json.dumps(out,indent=2))
