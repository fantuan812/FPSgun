import bpy, json, math, pathlib
from mathutils import Vector
D=bpy.context.evaluated_depsgraph_get(); S=bpy.context.scene
out={'file':bpy.data.filepath,'objects':len(S.objects),'dependencies':[], 'path_samples':{},'limits':'Static upward clearance samples in Blender, not swept capsule, navigation, physics or UE gameplay validation.'}
for lib in bpy.data.libraries:out['dependencies'].append({'type':'library','path':lib.filepath,'exists':pathlib.Path(bpy.path.abspath(lib.filepath)).exists()})
for im in bpy.data.images:
 if im.source=='FILE' and not im.packed_file:out['dependencies'].append({'type':'image','path':im.filepath,'exists':pathlib.Path(bpy.path.abspath(im.filepath)).exists()})
def check(name,points):
 hits=[];supports=[]
 for i,p in enumerate(points):
  hit,loc,n,face,obj,mat=S.ray_cast(D,Vector(p)+Vector((0,0,.055)),Vector((0,0,1)),distance=1.8)
  if hit:hits.append({'sample':i,'point':p,'height':round(loc.z-p[2],3),'object':obj.name})
  hit,loc,n,face,obj,mat=S.ray_cast(D,Vector(p)+Vector((0,0,.06)),Vector((0,0,-1)),distance=.25)
  if not hit:supports.append({'sample':i,'point':p})
 out['path_samples'][name]={'count':len(points),'overhead_hits_below_1p8m':hits,'no_floor_within_0p25m':supports}
for r in [5.5,6,6.5]:check('main_ring_radius_'+str(r),[(r*math.cos(a*math.pi/180),r*math.sin(a*math.pi/180),4.512) for a in range(0,360,3)])
check('main_ring_r6p4_width0p6',[(r*math.cos(a*math.pi/180),r*math.sin(a*math.pi/180),4.512) for a in range(0,360,3) for r in [6.1,6.4,6.7]])
for sign in [-1,1]:
 check('bridge_'+str(sign),[(sign*(7+i*.2),off,4.5) for i in range(43) for off in [-.3,0,.3]])
 check('stairs_'+str(sign),[(sign*17+off,-15+(i+.5)*.28,(i+1)*.18) for i in range(25) for off in [-.3,0,.3]])
check('ground_ring_r9',[(9*math.cos(a*math.pi/180),9*math.sin(a*math.pi/180),0) for a in range(0,360,3)])
check('front_entry',[(off,-30+i*.25,0) for i in range(81) for off in [-.3,0,.3]])
check('rear_exit',[(2+off,9+i*.25,0) for i in range(69) for off in [-.3,0,.3]])
check('external_loop',[(x,26,0) for x in range(2,35)]+[(34,y,0) for y in range(-30,27)]+[(x,-30,0) for x in range(0,35)])
P=pathlib.Path(__file__).resolve().parent; P.mkdir(exist_ok=True);(P/'clearance_report.json').write_text(json.dumps(out,indent=2))
print(json.dumps({'file':out['file'],'objects':out['objects'],'dependencies':out['dependencies'],'paths':{n:{'count':v['count'],'blocked':len(v['overhead_hits_below_1p8m']),'unsupported':len(v['no_floor_within_0p25m'])} for n,v in out['path_samples'].items()}}))
