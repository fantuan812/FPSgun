"""Batch02 architecture. Blender 4.3.2; source geometry library is an isolated copy.
Run: blender -b -t 6 -P Scripts/build_architecture.py [-- --asset Door]
Batch01 files are never written by this script.
"""
import bpy,json,pathlib,math,sys
from mathutils import Vector,Matrix
R=pathlib.Path(__file__).resolve().parents[1];sys.path.insert(0,str(R/'Scripts'));import base_geometry as base
ARGS=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [];FILTER=ARGS[ARGS.index('--asset')+1] if '--asset' in ARGS else ''

def add_material(key,color,metal=0,rough=.65,transmission=0):
 m=bpy.data.materials.new('M_NPP_'+key);m.use_nodes=True;m.diffuse_color=(*color,1);p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=rough
 if transmission:p.inputs['Transmission Weight'].default_value=transmission;p.inputs['IOR'].default_value=1.45
 base.MATS[key]=m

def setup():
 s=base.scene_setup();add_material('ConcreteCore',(.28,.32,.34));add_material('ConcretePanel',(.48,.53,.54));add_material('ConcretePanelB',(.42,.47,.48));add_material('RoofMembrane',(.10,.14,.17),0,.82);add_material('GlassTeal',(.20,.44,.48),0,.10,.65);return s

def build(sp):
 id=sp['asset_id'];kind=sp['builder'];geo=base.collection('01_RENDER_GEOMETRY');col=base.collection('02_COLLISION_UCX');socketcoll=base.collection('03_CONNECTION_SOCKETS');rig=base.collection('04_VALIDATION_RIG')
 keys=['ConcreteCore','ConcretePanel','ConcretePanelB','SteelGraphite','Galvanized','SafetyYellow','BoltSteel','RoofMembrane','GlassTeal'];B={k:base.Builder(id+'__'+k,k) for k in keys};C=[]
 def transform_part(builder,start,T):
  for i in range(start,len(builder.v)):builder.v[i]=tuple(T@Vector(builder.v[i]))
 def box(k,c,d,tag='fabricated part',T=None):
  start=len(B[k].v);B[k].box(c,d,tag)
  if T is not None:transform_part(B[k],start,T)
 def bolt(x,y,z,T=None,depth=.018,r=.012):
  b=B['BoltSteel'];start=len(b.v);b.cyl((x,y,z),r,depth,axis='Y',n=8,tag='face anchor')
  if T is not None:transform_part(b,start,T)
 def collision(c,d,T=None):
  b=base.Builder('UCX_'+id+'_'+str(len(C)).zfill(2),None);b.box(c,d,'convex collision')
  if T is not None:transform_part(b,0,T)
  C.append(b)
 def wallrect(x0,x1,z0,z1,T=None,do_collision=True):
  w=x1-x0;h=z1-z0;box('ConcreteCore',((x0+x1)/2,0,(z0+z1)/2),(w,.24,h),'solid wall backing',T)
  nx=max(1,math.ceil(w/2));nz=max(1,math.ceil(h/2))
  for a in range(nx):
   for b in range(nz):
    lo=x0+w*a/nx+.012;hi=x0+w*(a+1)/nx-.012;bot=z0+h*b/nz+.012;top=z0+h*(b+1)/nz-.012
    for sign in [-1,1]:
     mat='ConcretePanel' if (a+b)%2==0 else 'ConcretePanelB';box(mat,((lo+hi)/2,sign*.125,(bot+top)/2),(hi-lo,.014,top-bot),'bonded face panel',T)
     # Face anchors are contained in the .30 m envelope.
     for x in [lo+.06,hi-.06]:
      for z in [bot+.06,top-.06]:bolt(x,sign*.141,z,T)
  if z0==0:
   for sign in [-1,1]:box('SteelGraphite',((x0+x1)/2,sign*.128,.125),(w-.06,.01,.22),'recessed kick strip',T)
  if do_collision:collision(((x0+x1)/2,0,(z0+z1)/2),(w,.30,h),T)
 if kind=='solid_wall':wallrect(0,4,0,4)
 elif kind=='door_wall':
  wallrect(0,.875,0,4);wallrect(3.125,4,0,4);wallrect(.875,3.125,3.125,4)
  for x in [.9375,3.0625]:
   box('SafetyYellow',(x,0,.375),(.125,.28,.75),'lower door jamb')
   box('SteelGraphite',(x,0,1.875),(.125,.278,2.25),'upper door jamb')
   for sign in [-1,1]:
    for z in [.25,.65,1.25,2.5,2.9]:bolt(x,sign*.145,z,depth=.01)
   collision((x,0,1.5),(.125,.30,3))
  box('SteelGraphite',(2,0,3.0625),(2.25,.28,.125),'door lintel frame');collision((2,0,3.0625),(2.25,.30,.125))
 elif kind=='window_wall':
  for a,b,c,d in [(0,.75,0,4),(3.25,4,0,4),(.75,3.25,0,1),(.75,3.25,3,4)]:wallrect(a,b,c,d)
  for x in [.8125,3.1875]:box('SteelGraphite',(x,0,2),(.125,.28,2),'window jamb')
  for z in [1.0625,2.9375]:box('SteelGraphite',(2,0,z),(2.25,.28,.125),'window frame crosspiece')
  box('Galvanized',(2,0,2),(.075,.12,1.75),'window mullion')
  for x0,x1 in [(.875,1.9625),(2.0375,3.125)]:box('GlassTeal',((x0+x1)/2,0,2),(x1-x0,.025,1.75),'closed glass pane')
  collision((2,0,2),(2.5,.30,2))
 elif kind=='corner_wall':
  wallrect(0,3.5,0,4,Matrix.Translation((0,.25,0)))
  T=Matrix.Translation((3.75,.5,0))@Matrix.Rotation(math.pi/2,4,'Z');wallrect(0,3.5,0,4,T)
  box('ConcreteCore',(3.75,.25,2),(.5,.5,4),'solid corner pilaster');collision((3.75,.25,2),(.5,.5,4))
  # Subtle inset corner marker, kept entirely inside the pilaster envelope.
 elif kind in ['floor','roof']:
  floor=kind=='floor';low=-.25 if floor else 0;coretop=-.025 if floor else .20;top=0 if floor else .25
  box('ConcreteCore',(2,2,(low+coretop)/2),(4,4,coretop-low),'structural slab')
  for i in range(2):
   for j in range(2):
    x0=.08+i*1.92+.008;x1=.08+(i+1)*1.92-.008;y0=.08+j*1.92+.008;y1=.08+(j+1)*1.92-.008
    high=0 if floor else .24;mat=('ConcretePanel' if (i+j)%2==0 else 'ConcretePanelB') if floor else 'RoofMembrane'
    box(mat,((x0+x1)/2,(y0+y1)/2,(coretop+high)/2),(x1-x0,y1-y0,high-coretop),'surface tile')
  mat='SteelGraphite' if floor else 'Galvanized';h=top-coretop
  for y in [.04,3.96]:box(mat,(2,y,(coretop+top)/2),(4,.08,h),'perimeter trim')
  for x in [.04,3.96]:box(mat,(x,2,(coretop+top)/2),(.08,3.84,h),'perimeter trim')
  collision((2,2,(low+top)/2),(4,4,top-low))
 elif kind=='column_head':
  box('SteelGraphite',(0,0,.025),(.5,.5,.05),'column mating plate')
  box('SteelGraphite',(0,0,.22),(.75,.75,.06),'slab bearing plate')
  for x in [-.18,.18]:box('SteelGraphite',(x,0,.12),(.04,.5,.14),'long stiffener web')
  for y in [-.18,.18]:box('SteelGraphite',(0,y,.12),(.32,.04,.14),'short stiffener web')
  for x in [-.22,.22]:
   for y in [-.22,.22]:B['BoltSteel'].cyl((x,y,.068),.016,.036,n=6,tag='base fastener')
  collision((0,0,.125),(.75,.75,.25))
 objects=[]
 for k,b in B.items():
  if b.v:
   bevel=.004 if k in ['ConcreteCore','ConcretePanel','ConcretePanelB'] else (.0008 if k in ['BoltSteel','GlassTeal'] else .002)
   o=b.object(geo,bevel);base.uv_atlas(o);objects.append(o)
 collisions=[]
 for b in C:
  o=b.object(col);o.hide_render=True;o.display_type='WIRE';o['collision_proxy']=True;collisions.append(o)
 sockets=[]
 for i,sc in enumerate(sp['connection_sockets']):
  o=bpy.data.objects.new('SOCKET_'+id+'_'+str(i).zfill(2),None);socketcoll.objects.link(o);o.location=sc['position_m'];o.rotation_euler=Vector(sc['outward_normal']).to_track_quat('X','Z').to_euler();o.empty_display_type='ARROWS';o.empty_display_size=.25;o['socket_id']=sc['id'];o['role']=sc['role'];sockets.append(o)
 return objects,collisions,sockets,rig

for e in json.loads((R/'manifest.json').read_text())['assets']:
 if FILTER and FILTER not in e['asset_id']:continue
 p=R/e['path'];sp=json.loads((p/'spec.json').read_text());assert (p/'reference_sheet.png').is_file();print('START_ASSET',sp['asset_id'],flush=True)
 s=setup();objects,cols,sockets,rig=build(sp);export=base.evaluated_join(objects,sp['asset_id']);metrics=base.metrics(export);errors=[]
 for a in range(3):
  if abs(metrics['bounds_min_m'][a]-sp['bounds_min'][a])>1e-5 or abs(metrics['bounds_max_m'][a]-sp['bounds_max'][a])>1e-5:errors.append('bbox axis '+str(a))
 for k in ['nonmanifold_edges','degenerate_faces','exact_duplicate_faces','nonpositive_volume_components']:
  if metrics[k]:errors.append(k)
 bpy.ops.object.select_all(action='DESELECT');export.select_set(True)
 for o in cols+sockets:o.select_set(True)
 bpy.context.view_layer.objects.active=export
 bpy.ops.export_scene.fbx(filepath=str(p/'export.fbx'),use_selection=True,object_types={'MESH','EMPTY'},axis_forward='-Y',axis_up='Z',apply_unit_scale=True,bake_space_transform=False,use_mesh_modifiers=True,mesh_smooth_type='FACE',add_leaf_bones=False)
 for o in cols:o.select_set(False)
 bpy.ops.export_scene.gltf(filepath=str(p/'export.glb'),export_format='GLB',use_selection=True,export_yup=True,export_apply=True,export_texcoords=True,export_normals=True,export_materials='EXPORT',export_extras=True)
 export.hide_render=True;export.hide_set(True);export['role']='Frozen triangulated export snapshot'
 cameras=base.render_rig(sp,rig,p)
 bpy.ops.object.select_all(action='DESELECT')
 for o in objects:o.select_set(True)
 bpy.context.view_layer.objects.active=objects[0];bpy.ops.wm.save_as_mainfile(filepath=str(p/'model.blend'))
 center=Vector([(a+b)/2 for a,b in zip(sp['bounds_min'],sp['bounds_max'])]);bpy.ops.object.camera_add(location=center+Vector((9,-12,8)));cam=bpy.context.object;cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=max(sp['dimensions'])*1.65;s.camera=cam;s.render.resolution_x=900;s.render.resolution_y=900;s.cycles.samples=64;s.render.filepath=str(p/'beauty.png');bpy.ops.render.render(write_still=True)
 report={'asset_id':sp['asset_id'],'status':'PASS' if not errors else 'FAIL','errors':errors,'geometry':metrics,'collision_hulls':len(cols),'socket_count':len(sockets),'orthographic_validation':cameras,'pivot_m':[0,0,0],'rotation_radians':[0,0,0],'scale':[1,1,1],'intentional_contacts':['bonded wall skin overlap','metal frame seating','glass in frame','plate to stiffener welded joints'],'limits':['Basic PBR only; no final weathering or environment art polish.','No UE editor import, runtime collision or player traversal test.','UV1 per-face atlas needs production lightmap repack.','No exhaustive arbitrary mesh intersection certification.']}
 (p/'validation.json').write_text(json.dumps(report,indent=2));print('ASSET_COMPLETE',sp['asset_id'],report['status'],metrics['triangles'],flush=True)
