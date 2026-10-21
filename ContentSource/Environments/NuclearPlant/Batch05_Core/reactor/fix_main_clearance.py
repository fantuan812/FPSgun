import bpy,os,importlib.util,json,math
r=os.path.dirname(os.path.abspath(__file__))
bpy.ops.wm.open_mainfile(filepath=os.path.join(r,'reactor.blend'))
spec=importlib.util.spec_from_file_location('reactor_asset',os.path.join(r,'reactor_asset.py'));m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m);m.C=bpy.data.collections['Reactor_Core']
for o in list(m.C.objects):
 if o.name.startswith(('RC_main_coolant_trunk','RC_coolant_coupling','RC_pipe_anchor')):bpy.data.objects.remove(o,do_unlink=True)
steel=bpy.data.materials['RC_dark_forged_steel'];alloy=bpy.data.materials['RC_brushed_alloy']
for side in [-1,1]:
 for xx in [-1.4,1.4]:
  yy=side*5.15
  pts=[(xx,side*3.7,5.0),(xx,side*4.65,5.0),(xx,side*5.00,5.35),(xx,yy,5.8),(xx,yy,11.9),(xx,side*5.00,12.45),(xx,side*4.65,12.9),(xx,side*3.3,12.9)]
  m.pipe('RC_main_coolant_trunk',pts,.20,alloy)
  for z in [6.8,9.2,12.0]:
   m.cyl('RC_coolant_coupling',(xx,yy,z),.29,.17,steel,32)
   m.beam('RC_pipe_anchor',(xx,yy,z),(xx,side*3.8,z),.08,steel)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(r,'reactor.blend'),compress=True)
report={'change':'Main coolant trunks moved inward from y +/-5.85 to +/-5.15 m; lower and upper elbows moved inward too. Upper anchor raised from 11.3 to 12.0 m to avoid low overhead at upper deck.','trunk_center_xy_m':[1.4,5.15],'max_coupling_outer_radius_m':math.hypot(1.4,5.15)+.29,'outer_guard_inner_radius_m':6.93-.045,'conservative_main_outer_route_width_m':6.93-.045-(math.hypot(1.4,5.15)+.29),'upper_deck_outer_radius_m':5.1,'trunk_inner_radius_at_upper_deck_m':math.hypot(1.4,5.15)-.2,'upper_anchor_underside_height_above_deck_m':12-.04-10,'scope':'Analytic radial envelope clearance; no UE runtime or climbing verification.'}
json.dump(report,open(os.path.join(r,'main_route_clearance.json'),'w'),indent=2);print(report)
