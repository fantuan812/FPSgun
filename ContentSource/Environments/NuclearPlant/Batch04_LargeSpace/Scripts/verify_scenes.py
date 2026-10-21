import bpy,json,pathlib,math
from mathutils import Vector
R=pathlib.Path(__file__).resolve().parents[1];reports=[]
# Centerline samples in actual scene. This proves neither a swept capsule nor UE runtime movement.
upper=[(.25,-6,4),(16.25,-6,4),(19.25,-6,4),(19.25,-15,4),(26.25,-15,4),(29.25,-15,4),(29.25,-18,4),(29.25,-22,6),(29.25,-26,8),(29.25,-50,8),(29.25,-54,6),(29.25,-58,4),(29.25,-61,4),(6.25,-61,4),(4,-61,4),(4,-68,4),(2.25,-68,4),(-1.75,-68,2),(-5.75,-68,0)]
ground=[(22,-25,0),(22,-39,0),(22,-40,.07),(22,-48,.07),(22,-49,0),(22,-51,0),(10,-51,0),(10,-53,0),(4,-53,0)]
def sampleline(points):
 out=[]
 for i,(a,b) in enumerate(zip(points,points[1:])):
  a=Vector(a);b=Vector(b);n=max(1,math.ceil((b-a).length/.5))
  out.extend([tuple(a.lerp(b,j/n)) for j in range(n)])
 return out+[tuple(points[-1])]
for name in ['pump_service_connected','site_with_pump_service']:
 bpy.ops.wm.open_mainfile(filepath=str(R/'Region'/(name+'.blend')));s=bpy.context.scene;dg=bpy.context.evaluated_depsgraph_get();checks=[]
 badlibs=[l.filepath for l in bpy.data.libraries if not pathlib.Path(bpy.path.abspath(l.filepath)).is_file() or not l.filepath.startswith('//')]
 checks.append({'test':'all four relative geometry libraries resolve','library_count':len(bpy.data.libraries),'bad':badlibs,'status':'PASS' if not badlibs and len(bpy.data.libraries)==4 else 'FAIL'})
 for label,path in [('upper continuous route',upper),('ground road-crossing route',ground)]:
  missing=[];blocked=[];sample=sampleline(path)
  for x,y,z in sample:
   # At least one of nine nearby downward rays must find actual tread/grating within the design tread tolerance.
   floors=[]
   for dx,dy in [(0,0),(.025,0),(-.025,0),(0,.025),(0,-.025),(.0625,0),(-.0625,0),(0,.0625),(0,-.0625)]:
    hit,loc,n,face,obj,m=s.ray_cast(dg,Vector((x+dx,y+dy,z+.3)),Vector((0,0,-1)),distance=.56)
    if hit and abs(loc.z-z)<.251:floors.append(loc.z)
   if not floors:missing.append([round(x,3),round(y,3),round(z,3)])
   hit,loc,n,face,obj,m=s.ray_cast(dg,Vector((x,y,z+.3)),Vector((0,0,1)),distance=1.7)
   if hit:blocked.append({'point':[round(x,3),round(y,3),round(z,3)],'object':obj.name,'hit_z':loc.z})
  checks.append({'test':label+' actual floor/headroom rays','sample_count':len(sample),'max_sample_spacing_m':.5,'floor_tolerance_m':.251,'probe_offsets_m':[0,.025,.0625],'headroom_checked_z_range_m':[.3,2.0],'missing_floor':missing,'blocked_headroom':blocked,'status':'PASS' if not missing and not blocked else 'FAIL'})
 # Measure actual large-span inner boundaries and the lowest truss surface.
 west=s.objects['HallPerimeterColumn_0_0_0'];left=max((west.matrix_world@v.co).x for v in west.data.vertices)
 rail=s.objects['MezzRail_0'];right=min((rail.matrix_world@v.co).x for v in rail.data.vertices)
 north=s.objects['NorthWall_-25.75_0'];yn=min((north.matrix_world@v.co).y for v in north.data.vertices)
 south=s.objects['SouthWall_-25.75_0'];ys=max((south.matrix_world@v.co).y for v in south.data.vertices)
 truss=s.objects['HallRoofTruss_0'];height=min((truss.matrix_world@v.co).z for v in truss.data.vertices)
 checks.append({'test':'measured column-free production hall span','x_bounds_m':[left,right],'y_bounds_m':[ys,yn],'clear_span_m':[right-left,yn-ys],'lowest_truss_m':height,'status':'PASS' if right-left>=24 and yn-ys>=16 and height>=8 else 'FAIL'})
 violations=[]
 for o in s.objects:
  if o.type!='MESH' or o.name in s.collection.children['SCALE_REFERENCES_TOGGLE'].objects or any(k in o.name for k in ['Ground','Aisle','Lane','Dash','LocalRoad','Stripe']):continue
  vs=[o.matrix_world@v.co for v in o.data.vertices];lo=[min(v[a] for v in vs) for a in range(3)];hi=[max(v[a] for v in vs) for a in range(3)]
  if hi[0]>-12.00001 and lo[0]<-5.99999 and hi[1]>-67 and lo[1]<-52 and hi[2]>.05 and lo[2]<3:violations.append(o.name)
 checks.append({'test':'6 m main aisle free of equipment, excluding removable scale references','prism_m':[-12,-6,-67,-52,.05,3],'violations':violations,'status':'PASS' if not violations else 'FAIL'})
 # Rack bodies must not overlap the two interior stair AABBs; conservative mesh bounds.
 def bounds(o):
  v=[o.matrix_world@x.co for x in o.data.vertices];return [min(x[a] for x in v) for a in range(3)],[max(x[a] for x in v) for a in range(3)]
 overlaps=[]
 for a in [o for o in s.objects if o.name.startswith('StorageRack_')]:
  lo,hi=bounds(a)
  for b in [s.objects['InteriorStairLower'],s.objects['InteriorStairUpper']]:
   ll,hh=bounds(b)
   if all(min(hi[i],hh[i])-max(lo[i],ll[i])>1e-5 for i in range(3)):overlaps.append([a.name,b.name])
 checks.append({'test':'storage racks do not invade interior stair envelopes','overlaps':overlaps,'status':'PASS' if not overlaps else 'FAIL'})
 if name.startswith('site_'):
  expected=['01_REACTOR','02_TURBINE','03_CONTROL','05_COOLING','06_TRANSFORMER','08_INTAKE'];actual=[n for n in expected if n in s.objects];old=[n for n in ['04_PUMP','07_SERVICE','Label_04_PUMP','Label_07_SERVICE'] if n in s.objects];checks.append({'test':'six placeholders retained and two obsolete placeholders absent','present':actual,'obsolete':old,'status':'PASS' if len(actual)==6 and not old else 'FAIL'})
  g=next(o for o in s.objects if o.name.startswith('SITE_224x192'));results=[]
  for x,y in [(0,-20),(22,-34),(-20,-64),(22,-50)]:
   inv=g.matrix_world.inverted();hit,loc,_,_=g.ray_cast(inv@Vector((x,y,1)),inv.to_3x3()@Vector((0,0,-1)),distance=2);z=(g.matrix_world@loc).z if hit else None;results.append({'xy':[x,y],'z':z,'pass':hit and abs(z+.26)<1e-4})
  checks.append({'test':'copied ground recessed under both districts and approaches','samples':results,'status':'PASS' if all(v['pass'] for v in results) else 'FAIL'})
 report={'scene':name+'.blend','status':'PASS' if all(c['status']=='PASS' for c in checks) else 'FAIL','checks':checks,'limits':['Centerline floor/headroom rays are not swept-capsule, full rail collision or Unreal Engine gameplay tests.','No structural load certification.']};reports.append(report);(R/'Validation/scene_integrity.json').write_text(json.dumps(reports,indent=2));print('SCENE_CHECK',name,report['status'],flush=True)
(R/'Validation/scene_integrity.json').write_text(json.dumps(reports,indent=2))
