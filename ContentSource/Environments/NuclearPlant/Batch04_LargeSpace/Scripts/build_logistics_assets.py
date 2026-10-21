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
 if kind=='bay_wall':
  wallrect(0,.875,0,4);wallrect(7.125,8,0,4);wallrect(.875,7.125,3.125,4)
  for x in [.9375,7.0625]:
   box('SafetyYellow',(x,0,.5),(.125,.28,1),'protected lower jamb')
   box('SteelGraphite',(x,0,1.999),(.125,.28,2.002),'door guide rail with 2 mm jamb overlap')
   collision((x,0,1.5),(.125,.30,3))
   for sign in [-1,1]:
    for z in [.25,.75,1.5,2.5]:bolt(x,sign*.145,z,depth=.01)
  box('SteelGraphite',(4,0,3.0625),(6.25,.28,.125),'opening head rail');collision((4,0,3.0625),(6.25,.30,.125))
  # Contained low-profile raised shutter, no geometry within the clear 6 x 3 m aperture.
  for y in [-.14,.14]:
   for z in [3.22,3.31,3.40,3.49,3.58,3.67,3.76,3.85]:box('Galvanized',(4,y,z),(5.9,.012,.075),'raised shutter slat indication')
  for x in [1.2,6.8]:box('SteelGraphite',(x,-.14,3.54),(.07,.014,.72),'cassette end strap')
 elif kind=='rack':
  for x in [.08,3.92]:
   for y in [-.42,.42]:
    box('SteelGraphite',(x,y,1.515),(.08,.08,2.97),'square rack upright')
    box('Galvanized',(x,y,.015),(.16,.16,.03),'anchor foot plate')
    for z in [.25,1.5,2.75]:
     for sign in [-1,1]:bolt(x,y+sign*.043,z,depth=.012,r=.012)
  for z in [.25,1.5,2.75]:
   box('Galvanized',(2,0,z-.03),(3.76,.76,.06),'actual steel shelf deck')
   for y in [-.42,.42]:box('SafetyYellow',(2,y,z-.09),(3.76,.08,.12),'shelf bearer')
   for x in [.15,1.35,2.65,3.85]:box('SteelGraphite',(x,0,z-.08),(.08,.76,.08),'cross bearer')
  for a,bb in [((.16,.47,.2),(3.84,.47,2.92)),((3.84,.47,.2),(.16,.47,2.92))]:
   p=Vector(a);q=Vector(bb);T=Matrix.Translation((p+q)/2)@(q-p).to_track_quat('Z','Y').to_matrix().to_4x4();box('SteelGraphite',(0,0,0),(.035,.035,(q-p).length),'rear diagonal brace',T)
  # Storage racks are static obstacles in gameplay; intentional conservative hull.
  collision((2,0,1.5),(4,1,3))
 elif kind=='roof_truss':
  for y in [-.1875,.1875]:
   for z in [.0625,1.9375]:box('SteelGraphite',(16,y,z),(32,.125,.125),'continuous truss chord')
  for x in [.0625,31.9375]:box('SteelGraphite',(x,0,1),(.125,.5,1.75),'end bearing frame')
  for i in range(1,8):box('SteelGraphite',(i*4,0,1),(.1,.4,1.75),'panel vertical')
  for i in range(8):
   for y in [-.15,.15]:
    a=Vector((i*4+.15,y,.15 if i%2==0 else 1.85));b=Vector(((i+1)*4-.15,y,1.85 if i%2==0 else .15));T=Matrix.Translation((a+b)/2)@(b-a).to_track_quat('Z','Y').to_matrix().to_4x4();box('SteelGraphite',(0,0,0),(.1,.1,(b-a).length),'diagonal lattice',T)
  for x in [.125,4,8,12,16,20,24,28,31.875]:
   for z in [.13,1.87]:
    for y in [-.242,.242]:box('Galvanized',(x,y,z),(.24,.016,.24),'node gusset plate')
  collision((16,0,1),(32,.5,2))
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
