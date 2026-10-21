import bpy,json,os,math
r=os.path.dirname(os.path.abspath(__file__));bpy.ops.wm.open_mainfile(filepath=os.path.join(r,'reactor.blend'));dg=bpy.context.evaluated_depsgraph_get();p=[]
for o in bpy.data.collections['Reactor_Core'].objects:
 if o.name.startswith(('RC_main_coolant_trunk','RC_coolant_coupling','RC_pipe_anchor')):
  e=o.evaluated_get(dg);me=e.to_mesh()
  for v in me.vertices:
   q=e.matrix_world@v.co
   if 4.5<=q.z<=7:p.append((math.hypot(q.x,q.y),o.name))
  e.to_mesh_clear()
rmax,name=max(p)
f=os.path.join(r,'main_route_clearance.json');d=json.load(open(f));d.update({'actual_evaluated_vertex_max_radius_in_main_walk_height_4_5_to_7_m':rmax,'limiting_object':name,'measured_outer_route_clearance_m':6.885-rmax,'measured_clearance_at_least_1_2m':6.885-rmax>=1.2});json.dump(d,open(f,'w'),indent=2);print(d)
