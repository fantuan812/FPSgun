"""Five process assets for Batch03. Blender 4.3.2. All dimensional ports are spec-driven."""
import bpy,bmesh,json,pathlib,sys,math
from mathutils import Vector,Matrix
R=pathlib.Path(__file__).resolve().parents[1];sys.path.insert(0,str(R/'Scripts'));import base_geometry as base
ARGS=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [];FILTER=ARGS[ARGS.index('--asset')+1] if '--asset' in ARGS else '';RENDER='--no-render' not in ARGS

def material(name,col,metal,rough):
 m=bpy.data.materials.new('M_NPP_'+name);m.use_nodes=True;m.diffuse_color=(*col,1);p=m.node_tree.nodes['Principled BSDF'];p.inputs['Base Color'].default_value=(*col,1);p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=rough;base.MATS[name]=m

def setup():
 s=base.scene_setup();material('ProcessTeal',(.045,.26,.29),.55,.38);return s

def transform(b,start,T):
 for i in range(start,len(b.v)):b.v[i]=tuple(T@Vector(b.v[i]))
def tube(b,c,length,ro,ri,axis='X',n=32,tag='closed annular pipe'):
 vs=[];fs=[]
 for q in [-length/2,length/2]:
  for radius in [ro,ri]:
   for j in range(n):
    a=j*2*math.pi/n;u=radius*math.cos(a);v=radius*math.sin(a);d=(q,u,v) if axis=='X' else ((u,q,v) if axis=='Y' else (u,v,q));vs.append(tuple(c[k]+d[k] for k in range(3)))
 for j in range(n):
  k=(j+1)%n;fs += [(j,k,2*n+k,2*n+j),(n+j,3*n+j,3*n+k,n+k),(j,n+j,n+k,k),(2*n+j,2*n+k,3*n+k,3*n+j)]
 b.part(vs,fs,tag)
def elbow(b,ro,ri,n=32,steps=24):
 vs=[];fs=[]
 for i in range(steps+1):
  a=-math.pi/2+.10+(math.pi/2-.20)*i/steps;c=Vector((math.cos(a),1+math.sin(a),0));N=Vector((math.cos(a),math.sin(a),0))
  for radius in [ro,ri]:
   for j in range(n):
    t=j*2*math.pi/n;vs.append(tuple(c+N*(radius*math.cos(t))+Vector((0,0,radius*math.sin(t)))))
 for i in range(steps):
  a=i*2*n;d=(i+1)*2*n
  for j in range(n):
   k=(j+1)%n;fs += [(a+j,a+k,d+k,d+j),(a+n+j,d+n+j,d+n+k,a+n+k)]
 for i in [0,steps]:
  a=i*2*n
  for j in range(n):k=(j+1)%n;fs.append((a+j,a+n+j,a+n+k,a+k))
 b.part(vs,fs,'curved hollow barrel, ends seated inside flanges')
def boolean_body(builder,outer_specs,inner_specs):
 def primitive(v):
  c,r,h,axis=v;bpy.ops.mesh.primitive_cylinder_add(vertices=40,radius=r,depth=h,location=c);o=bpy.context.object
  if axis=='X':o.rotation_euler[1]=math.pi/2
  elif axis=='Y':o.rotation_euler=(Matrix.Rotation(math.pi/2,4,'X')@Matrix.Rotation(math.pi/40,4,'Z')).to_euler()
  bpy.ops.object.transform_apply(location=False,rotation=True,scale=True);return o
 o=primitive(outer_specs[0])
 for op,parts in [('UNION',outer_specs[1:]),('DIFFERENCE',inner_specs)]:
  for item in parts:
   cut=primitive(item);bpy.context.view_layer.objects.active=o;mod=o.modifiers.new('Actual open junction','BOOLEAN');mod.operation=op;mod.solver='EXACT';mod.object=cut;bpy.ops.object.modifier_apply(modifier=mod.name);bpy.data.objects.remove(cut,do_unlink=True)
 bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=1e-6);bmesh.ops.dissolve_degenerate(bm,edges=list(bm.edges),dist=1e-6);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(o.data);bm.free()
 builder.part([tuple(o.matrix_world@v.co) for v in o.data.vertices],[tuple(p.vertices) for p in o.data.polygons],'boolean hollow communicating body');bpy.data.objects.remove(o,do_unlink=True)
def build(sp):
 id=sp['asset_id'];kind=sp['builder'];geo=base.collection('01_RENDER_GEOMETRY');cc=base.collection('02_COLLISION_UCX');sc=base.collection('03_CONNECTION_SOCKETS');rig=base.collection('04_VALIDATION_RIG');B={k:base.Builder(id+'__'+k,k) for k in ['ProcessTeal','SteelGraphite','Galvanized','SafetyYellow','BoltSteel']};C=[];ro=sp['pipe_outer_radius_m'];ri=sp['pipe_inner_radius_m'];rf=sp['flange_radius_m'];fd=sp['flange_depth_m']
 def box(k,c,d,tag='fabrication part',T=None):
  b=B[k];start=len(b.v);b.box(c,d,tag)
  if T is not None:transform(b,start,T)
 def col(c,d):
  b=base.Builder('UCX_'+id+'_'+str(len(C)).zfill(2),None);b.box(c,d,'convex gameplay proxy');C.append(b)
 def flange(port):
  p=Vector(port['position_m']);out=Vector(port['outward_normal']);T=out.to_track_quat('X','Z').to_matrix().to_4x4();T.translation=p
  # Real drilled annular flange with eight recessed hex heads, all behind the mating plane.
  ring=base.Builder('TEMP_flange',None);tube(ring,(-fd/2,0,0),fd,rf,ri,'X');a=ring.object(bpy.context.scene.collection)
  holes=base.Builder('TEMP_holes',None)
  for j in range(8):
   angle=j*math.pi/4;holes.cyl((-fd/2,.315*math.cos(angle),.315*math.sin(angle)),.029,fd+.10,axis='X',n=12)
  cut=holes.object(bpy.context.scene.collection);bpy.context.view_layer.objects.active=a;mod=a.modifiers.new('Eight true fastener holes','BOOLEAN');mod.operation='DIFFERENCE';mod.solver='EXACT';mod.object=cut;bpy.ops.object.modifier_apply(modifier=mod.name);bpy.data.objects.remove(cut,do_unlink=True)
  bm=bmesh.new();bm.from_mesh(a.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=1e-6);bmesh.ops.dissolve_degenerate(bm,edges=list(bm.edges),dist=1e-6);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(a.data);bm.free()
  B['Galvanized'].part([tuple(T@v.co) for v in a.data.vertices],[tuple(f.vertices) for f in a.data.polygons],'drilled flange');bpy.data.objects.remove(a,do_unlink=True)
  b=B['BoltSteel'];st=len(b.v)
  for j in range(8):
   angle=j*math.pi/4;b.cyl((-.025,.315*math.cos(angle),.315*math.sin(angle)),.025,.022,axis='X',n=6,tag='recessed visible flange bolt')
  transform(b,st,T)
 for port in sp['connection_sockets']:flange(port)
 if kind=='pipe':
  tube(B['ProcessTeal'],(2,0,0),4-2*fd,ro,ri);col((2,0,0),(4,.75,.75))
  for x in [1,3]:tube(B['SteelGraphite'],(x,0,0),.06,ro+.008,ro-.002)
 elif kind=='elbow':
  elbow(B['ProcessTeal'],ro,ri);col((.5,0,0),(1,.75,.75));col((1,.5,0),(.75,1,.75))
 elif kind=='pipe_tee':
  boolean_body(B['ProcessTeal'],[((1,0,0),ro,2-2*fd,'X'),((1,.44,0),ro,.88,'Y')],[((1,0,0),ri,2.4,'X'),((1,.6,0),ri,1.2,'Y')]);col((1,0,0),(2,.75,.75));col((1,.5,0),(.75,1,.75))
 elif kind=='valve':
  tube(B['ProcessTeal'],(.5,0,0),1-2*fd,.32,ri)
  B['ProcessTeal'].cyl((.5,0,.40),.22,.4,n=32,tag='valve bonnet');B['SteelGraphite'].cyl((.5,0,.62),.28,.08,n=32,tag='bonnet flange')
  for j in range(8):a=j*math.pi/4;B['BoltSteel'].cyl((.5+.23*math.cos(a),.23*math.sin(a),.68),.018,.04,n=6)
  B['BoltSteel'].cyl((.5,0,.88),.028,.4,n=16,tag='spindle')
  for x in [.28,.72]:box('SteelGraphite',(x,0,.84),(.035,.06,.36),'yoke')
  box('SteelGraphite',(.5,0,1.02),(.48,.06,.04),'yoke crossbeam');tube(B['SafetyYellow'],(.5,0,1.1),.05,.4,.345,'Z',40,'handwheel rim')
  for a in [0,math.pi/2]:box('SafetyYellow',(.5,0,1.1),(.7,.035,.04),'handwheel spoke',Matrix.Translation((.5,0,1.1))@Matrix.Rotation(a,4,'Z')@Matrix.Translation((-.5,0,-1.1)))
  col((.5,0,.375),(1,.8,1.5))
 elif kind=='pump':
  for y in [-.92,.92]:box('SteelGraphite',(2,y,.125),(4,.16,.25),'skid longitudinal I-beam')
  for x in [.2,1.3,2.7,3.8]:box('SteelGraphite',(x,0,.125),(.24,1.68,.25),'skid crossmember')
  for x in [.25,3.75]:
   for y in [-.75,.75]:box('Galvanized',(x,y,.275),(.36,.36,.05),'anchor plate');B['BoltSteel'].cyl((x,y,.33),.035,.06,n=6)
  for x in [1.3,3.2]:
   for y in [-.3,.3]:box('SteelGraphite',(x,y,.48),(.32,.18,.46),'machine foot')
  boolean_body(B['ProcessTeal'],[((1.45,0,1),.60,.9,'X'),((.61,0,1),ro,.98,'X'),((1.5,.44,1),ro,.88,'Y')],[((.75,0,1),ri,1.7,'X'),((1.45,0,1),.42,.60,'X'),((1.5,.5,1),ri,1.4,'Y')])
  B['SteelGraphite'].cyl((2.4,0,1),.12,1.1,axis='X',n=24,tag='coupled shaft')
  for j in range(12):
   a=j*2*math.pi/12;box('SafetyYellow',(2.3,.28*math.cos(a),1+.28*math.sin(a)),(.5,.035,.035),'open coupling guard slat')
  for x in [2.05,2.55]:tube(B['SafetyYellow'],(x,0,1),.035,.30,.265,'X',32,'guard end ring')
  B['SteelGraphite'].cyl((3.2,0,1),.45,1.2,axis='X',n=40,tag='motor casing');B['SteelGraphite'].cyl((3.86,0,1),.41,.12,axis='X',n=40,tag='motor fan cover')
  for j in range(16):
   a=j*2*math.pi/16;T=Matrix.Translation((0,0,1))@Matrix.Rotation(a,4,'X')@Matrix.Translation((0,0,-1));box('SteelGraphite',(3.2,.475,1),(1.08,.09,.025),'motor cooling fin',T)
  box('ProcessTeal',(3.15,-.58,1.1),(.55,.28,.42),'terminal box');box('Galvanized',(3.15,-.728,1.1),(.48,.016,.35),'terminal lid')
  box('SteelGraphite',(3.2,0,1.53),(.18,.18,.25),'lifting lug boss');tube(B['Galvanized'],(3.2,0,1.8),.08,.2,.12,'X',32,'lifting eye')
  col((2,0,.125),(4,2,.25));col((1.5,0,1), (1.2,1.25,1.25));col((3.1,0,1.1),(1.8,1.5,1.8));col((.5,0,1),(1,.75,.75));col((1.5,.5,1),(.75,1,.75))
 objects=[]
 for k,b in B.items():
  if b.v:
   o=b.object(geo,0 if k=='ProcessTeal' and kind in ['pipe_tee','pump'] else (.001 if k in ['ProcessTeal','Galvanized'] else .0007));base.uv_atlas(o)
   for face in o.data.polygons:face.use_smooth=True
   o.data.set_sharp_from_angle(angle=math.radians(30));objects.append(o)
 cols=[]
 for b in C:
  o=b.object(cc);o.hide_render=True;o.display_type='WIRE';o['collision_proxy']=True;cols.append(o)
 sockets=[]
 for i,p in enumerate(sp['connection_sockets']):
  o=bpy.data.objects.new('SOCKET_'+id+'_'+str(i).zfill(2),None);sc.objects.link(o);o.location=p['position_m'];o.rotation_euler=Vector(p['outward_normal']).to_track_quat('X','Z').to_euler();o['socket_id']=p['id'];o['bore_radius_m']=ri;o.empty_display_type='ARROWS';o.empty_display_size=.3;sockets.append(o)
 return objects,cols,sockets,rig

def main():
 for e in json.loads((R/'manifest.json').read_text())['assets']:
  if FILTER and FILTER not in e['asset_id']:continue
  p=R/e['path'];sp=json.loads((p/'spec.json').read_text());assert (p/'reference_sheet.png').is_file();s=setup();obs,cols,sockets,rig=build(sp);export=base.evaluated_join(obs,sp['asset_id']);m=base.metrics(export);errors=[]
  for a in range(3):
   if abs(m['bounds_min_m'][a]-sp['bounds_min'][a])>1e-5 or abs(m['bounds_max_m'][a]-sp['bounds_max'][a])>1e-5:errors.append('bbox axis '+str(a))
  for k in ['nonmanifold_edges','degenerate_faces','exact_duplicate_faces','nonpositive_volume_components']:
   if m[k]:errors.append(k)
  bpy.ops.object.select_all(action='DESELECT');export.select_set(True)
  for o in cols+sockets:o.select_set(True)
  bpy.context.view_layer.objects.active=export;bpy.ops.export_scene.fbx(filepath=str(p/'export.fbx'),use_selection=True,object_types={'MESH','EMPTY'},axis_forward='-Y',axis_up='Z',apply_unit_scale=True,bake_space_transform=False,mesh_smooth_type='FACE',add_leaf_bones=False)
  for o in cols:o.select_set(False)
  bpy.ops.export_scene.gltf(filepath=str(p/'export.glb'),export_format='GLB',use_selection=True,export_yup=True,export_apply=True,export_texcoords=True,export_normals=True,export_materials='EXPORT',export_extras=True)
  export.hide_render=True;export.hide_set(True);export['role']='Frozen triangulated export snapshot';cameras=base.render_rig(sp,rig,p) if RENDER else {};bpy.ops.wm.save_as_mainfile(filepath=str(p/'model.blend'))
  if RENDER:
   c=Vector([(a+b)/2 for a,b in zip(sp['bounds_min'],sp['bounds_max'])]);bpy.ops.object.camera_add(location=c+Vector((9,-12,8)));cam=bpy.context.object;cam.rotation_euler=(c-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=max(sp['dimensions'])*1.65;s.camera=cam;s.render.resolution_x=900;s.render.resolution_y=900;s.cycles.samples=64;s.render.filepath=str(p/'beauty.png');bpy.ops.render.render(write_still=True)
  report={'asset_id':sp['asset_id'],'status':'PASS' if not errors else 'FAIL','errors':errors,'geometry':m,'collision_hulls':len(cols),'socket_count':len(sockets),'orthographic_validation':cameras,'pivot_m':[0,0,0],'rotation_radians':[0,0,0],'scale':[1,1,1],'intentional_contacts':['flange/barrel seating','bolted joints','skid welds','motor feet','coupler guards'],'limits':['Basic PBR only.','Convex collision blocks pipe bores intentionally.','No hydraulic/structural certification or simulated pump internals.','No exhaustive arbitrary-intersection proof.','UE actual import and traversal not run.']};(p/'validation.json').write_text(json.dumps(report,indent=2));print('ASSET_COMPLETE',sp['asset_id'],report['status'],m['triangles'],errors,flush=True)
if __name__=='__main__':main()
