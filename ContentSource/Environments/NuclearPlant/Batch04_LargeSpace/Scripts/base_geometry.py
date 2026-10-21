"""Parametric NPP first-batch assets. Run: blender -b -t 6 -P build_kit.py
Optional: -- --asset <id substring> --no-render. Specs and AI references must exist first.
All dimensions in meters. Coordinates are local to the shared asset pivot.
"""
import bpy, bmesh, json, math, pathlib, sys, hashlib
from mathutils import Vector, Matrix
R=pathlib.Path(__file__).resolve().parents[1]
ARGS=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
FILTER=ARGS[ARGS.index('--asset')+1] if '--asset' in ARGS else ''
RENDER='--no-render' not in ARGS
MATS={}

def make_mats():
 global MATS
 for name,col,metal,rough in [('SteelGraphite',(.075,.105,.12),.72,.43),('Galvanized',(.45,.52,.54),.82,.38),('SafetyYellow',(.93,.48,.035),.32,.39),('BoltSteel',(.26,.30,.32),.9,.29)]:
  m=bpy.data.materials.new('M_NPP_'+name);m.use_nodes=True;m.diffuse_color=(*col,1)
  p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*col,1);p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=rough
  MATS[name]=m

class Builder:
 def __init__(self,name,mat):self.name=name;self.mat=mat;self.v=[];self.f=[];self.parts=[]
 def part(self,verts,faces,tag):
  n=len(self.v);self.v.extend(verts);self.f.extend([tuple(n+i for i in f) for f in faces]);self.parts.append({'tag':tag,'vertex_start':n,'vertex_count':len(verts),'face_count':len(faces)})
 def box(self,c,d,tag='box'):
  x,y,z=c;a,b,h=[k/2 for k in d]
  v=[(x-a,y-b,z-h),(x+a,y-b,z-h),(x+a,y+b,z-h),(x-a,y+b,z-h),(x-a,y-b,z+h),(x+a,y-b,z+h),(x+a,y+b,z+h),(x-a,y+b,z+h)]
  self.part(v,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],tag)
 def slope(self,x0,x1,y0,y1,z0,z1,thick,tag='sloped prism'):
  v=[(x0,y0,z0-thick),(x1,y0,z1-thick),(x1,y1,z1-thick),(x0,y1,z0-thick),(x0,y0,z0),(x1,y0,z1),(x1,y1,z1),(x0,y1,z0)]
  self.part(v,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],tag)
 def cyl(self,c,r,h,axis='Z',n=8,tag='bolt'):
  v=[]
  for q in [-h/2,h/2]:
   for i in range(n):
    a=2*math.pi*i/n;u=r*math.cos(a);w=r*math.sin(a)
    d=(u,w,q) if axis=='Z' else ((u,q,w) if axis=='Y' else (q,u,w));v.append(tuple(c[j]+d[j] for j in range(3)))
  faces=[tuple(reversed(range(n))),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
  self.part(v,faces,tag)
 def arc(self,cx,cz,rout,rin,depth,n=20):
  # Extruded lower-half annular saddle; actual curved 3D solid, open upward.
  v=[]
  for y in [-depth/2,depth/2]:
   for r in [rout,rin]:
    for i in range(n+1):
     a=math.pi+math.pi*i/n;v.append((cx+r*math.cos(a),y,cz+r*math.sin(a)))
  k=n+1;f=[]
  for i in range(n):
   f += [(i,i+1,2*k+i+1,2*k+i),(k+i,3*k+i,3*k+i+1,k+i+1),(i,k+i,k+i+1,i+1),(2*k+i,2*k+i+1,3*k+i+1,3*k+i)]
  f += [(0,2*k,3*k,k),(n,k+n,3*k+n,2*k+n)]
  self.part(v,f,'pipe saddle')
 def object(self,coll,bevel=0):
  mesh=bpy.data.meshes.new(self.name+'_Mesh');mesh.from_pydata(self.v,[],self.f);mesh.update()
  bm=bmesh.new();bm.from_mesh(mesh);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(mesh);bm.free()
  o=bpy.data.objects.new(self.name,mesh);coll.objects.link(o)
  if self.mat:mesh.materials.append(MATS[self.mat])
  o['fabrication_parts']=json.dumps(self.parts);o['generated_by']='Scripts/build_kit.py'
  uv=mesh.uv_layers.new(name='UV0_TileMeters')
  for p in mesh.polygons:
   axis=max(range(3),key=lambda a:abs(p.normal[a]));axes=[a for a in range(3) if a!=axis]
   for li in p.loop_indices:
    co=mesh.vertices[mesh.loops[li].vertex_index].co;uv.data[li].uv=(co[axes[0]],co[axes[1]])
  if bevel:
   mod=o.modifiers.new('Fabrication edge bevel','BEVEL');mod.width=bevel;mod.segments=2;mod.limit_method='ANGLE';mod.harden_normals=True
  return o

def collection(name):
 c=bpy.data.collections.new(name);bpy.context.scene.collection.children.link(c);return c

def uv_atlas(o):
 # Give EVERY evaluated face its own nonoverlapping atlas cell; stable and deterministic.
 me=o.data;n=math.ceil(math.sqrt(len(me.polygons)));uv=me.uv_layers.get('UV1_Lightmap') or me.uv_layers.new(name='UV1_Lightmap')
 for i,p in enumerate(me.polygons):
  axis=max(range(3),key=lambda a:abs(p.normal[a]));axes=[a for a in range(3) if a!=axis]
  coords=[(me.vertices[me.loops[li].vertex_index].co[axes[0]],me.vertices[me.loops[li].vertex_index].co[axes[1]]) for li in p.loop_indices]
  xmin=min(x for x,y in coords);ymin=min(y for x,y in coords);w=max(x for x,y in coords)-xmin;h=max(y for x,y in coords)-ymin;span=max(w,h,1e-9)
  for li,(x,y) in zip(p.loop_indices,coords):uv.data[li].uv=((i%n+.1+.8*(x-xmin)/span)/n,(i//n+.1+.8*(y-ymin)/span)/n)
 o['UV1_atlas_note']='Non-overlap per-face atlas. Repack and raise lightmap resolution for static baked production lighting.'

def scene_setup():
 bpy.ops.wm.read_factory_settings(use_empty=True);make_mats();s=bpy.context.scene
 s.unit_settings.system='METRIC';s.unit_settings.scale_length=1
 s.render.engine='CYCLES';s.cycles.samples=32;s.cycles.use_denoising=False;s.cycles.max_bounces=4
 s.render.resolution_x=1024;s.render.resolution_y=1024;s.render.resolution_percentage=100
 s.render.image_settings.file_format='PNG';s.render.image_settings.color_mode='RGBA';s.render.film_transparent=True
 s.world=bpy.data.worlds.new('NPP neutral studio');s.world.use_nodes=True;s.world.node_tree.nodes['Background'].inputs[0].default_value=(.6,.67,.72,1);s.world.node_tree.nodes['Background'].inputs[1].default_value=.7
 s.view_settings.view_transform='AgX'
 return s

def build_asset(spec):
 id=spec['asset_id'];kind=spec['builder'];geo=collection('01_RENDER_GEOMETRY');cols=collection('02_COLLISION_UCX');socks=collection('03_CONNECTION_SOCKETS');rig=collection('04_VALIDATION_RIG')
 B={k:Builder(id+'__'+k,m) for k,m in [('Frame','SteelGraphite'),('Grating','Galvanized'),('Rails','SafetyYellow'),('Fasteners','BoltSteel')]};F,G,Y,H=[B[k] for k in ['Frame','Grating','Rails','Fasteners']];C=[]
 def colbox(c,d):
  b=Builder('UCX_'+id+'_'+str(len(C)).zfill(2),None);b.box(c,d);C.append(b)
 def colslope(x0,x1,y0,y1,z0,z1,t):
  b=Builder('UCX_'+id+'_'+str(len(C)).zfill(2),None);b.slope(x0,x1,y0,y1,z0,z1,t);C.append(b)
 def bolts(cx,cy,z,dx=.04,dy=.04):
  for x in [cx-dx,cx+dx]:
   for y in [cy-dy,cy+dy]:H.cyl((x,y,z),.009,.014,n=6)
 def rail(a,b,z=0,infill=False,depth=.10):
  x0,y0=a;x1,y1=b;length=math.hypot(x1-x0,y1-y0);alongx=abs(x1-x0)>abs(y1-y0)
  axis=(1,0) if alongx else (0,1)
  def bar(mid,height,width,zmid,mat=Y):
   sz=(width,depth,height) if alongx else (depth,width,height);mat.box((mid[0],mid[1],zmid),sz)
  mid=((x0+x1)/2,(y0+y1)/2)
  bar(mid,.06,length,z+1.07);bar(mid,.045,length,z+.57);bar(mid,.1,length,z+.07)
  count=max(2,math.ceil(length/1.4)+1)
  for i in range(count):
   inset=.16 if kind in ['corner','tee'] else .10;t=inset+(length-2*inset)*i/(count-1);frac=t/length;x=x0+(x1-x0)*frac;y=y0+(y1-y0)*frac
   Y.box((x,y,z+.52),(.06,.06,1.04));Y.box((x,y,z+.0125),(.125,.125,.025));bolts(x,y,z+.033)
  if infill:
   for i in range(1,int(length/.125)):
    t=i*.125;frac=t/length;F.box((x0+(x1-x0)*frac,y0+(y1-y0)*frac,z+.60),(.025,.025,.86))
  colbox((mid[0],mid[1],z+.55),(length,.10,1.1) if alongx else (.10,length,1.1))
 def deck(rects):
  # Nonoverlapping occupied rectangles. Real, open grating with two welded bar levels.
  for xmin,xmax,ymin,ymax in rects:
   w=xmax-xmin;d=ymax-ymin
   for j in range(round(d/.05)):
    G.box(((xmin+xmax)/2,ymin+.025+j*.05,-.018),(w,.012,.036),'grating bearer')
   for i in range(round(w/.10)):
    G.box((xmin+.05+i*.10,(ymin+ymax)/2,-.042),(.008,d,.024),'grating cross tie')
   for x in [xmin+.04,xmax-.04]:F.box((x,(ymin+ymax)/2,-.11),(.08,d,.18),'edge frame')
   for y in [ymin+.04,ymax-.04]:F.box(((xmin+xmax)/2,y,-.11),(w-.16,.08,.18),'edge frame')
   for i in range(1,round(w)):
    F.box((xmin+i,(ymin+ymax)/2,-.15),(.05,d-.16,.10),'crossbeam')
   colbox(((xmin+xmax)/2,(ymin+ymax)/2,-.1),(w,d,.2))
 if kind in ['straight','corner','tee']:
  deck(spec['footprint_rects'])
  edges={'straight':[((0,-.9375),(4,-.9375)),((0,.9375),(4,.9375))],
         'corner':[((0,-.9375),(3.8875,-.9375)),((3.9375,-.9875),(3.9375,3)),((0,.9375),(2.1125,.9375)),((2.0625,.9875),(2.0625,3))],
         'tee':[((0,-.9375),(4,-.9375)),((0,.9375),(1.1125,.9375)),((2.8875,.9375),(4,.9375)),((1.0625,.9875),(1.0625,3)),((2.9375,.9875),(2.9375,3))]}[kind]
  for a,b in edges:rail(a,b)
  for xmin,xmax,ymin,ymax in spec['footprint_rects']:
   for x in [xmin+.12,xmax-.12]:
    for y in [ymin+.12,ymax-.12]:H.cyl((x,y,-.008),.025,.016,n=6,tag='deck fastener')
 elif kind=='stairs':
  for i in range(spec['steps']):
   x=i*.4;z=(i+1)*.2
   for j in range(16):G.box((x+.20,-.9375+j*.125,z-.018),(.4,.018,.036),'tread grating')
   for dx in [.025,.375]:G.box((x+dx,0,z-.04),(.05,1.88,.08),'tread edge')
   Y.box((x+.015,0,z-.012),(.03,1.8,.024),'safety nosing')
  for y in [-.94,.94]:
   F.slope(0,4,y-.06,y+.06,0,2,.2,'stair stringer')
   F.box((.01,y,-.1),(.02,.11,.2),'lower stringer end cap')
   Y.box((3.99,y,3.07),(.02,.07,.06),'upper handrail end cap')
   Y.slope(0,4,y-.03,y+.03,1.1,3.1,.06,'sloped handrail');Y.slope(0,4,y-.025,y+.025,.57,2.57,.05,'sloped midrail')
   for x in [.125,.875,1.625,2.375,3.125,3.875]:
    bottom=math.ceil(x/.4)*.2;top=1.04+.5*x;Y.box((x,y,(bottom+top)/2),(.06,.06,top-bottom),'stair rail post');H.cyl((x,y-.035,bottom+.075),.02,.014,axis='Y',n=6)
   colslope(0,4,y-.05,y+.05,1.1,3.1,1.1)
  colslope(0,4,-1,1,0,2,.2)
 elif kind in ['rail_open','rail_infill']:
  L=spec['dimensions'][0];rail((0,0),(L,0),infill=kind=='rail_infill',depth=.0625)
 elif kind=='column':
  for z in [.04,3.96]:F.box((0,0,z),(.5,.5,.08),'anchor plate')
  for x in [-.135,.135]:F.box((x,0,2),(.03,.3,3.84),'H flange')
  F.box((0,0,2),(.24,.035,3.84),'H web')
  for x in [-.135,.135]:Y.box((x,0,.65),(.031,.301,.22),'painted collar')
  for z in [.098,3.902]:
   for x in [-.19,.19]:
    for y in [-.19,.19]:H.cyl((x,y,z),.028,.036,n=6,tag='anchor bolt')
  colbox((0,0,2),(.5,.5,4))
 elif kind=='pipe_support':
  for x in [-.875,.875]:
   F.box((x,0,.04),(.25,.5,.08),'baseplate');F.box((x,0,.76),(.125,.16,1.36),'portal upright');bolts(x,0,.09,.08,.17)
  F.box((0,0,1.54),(1.875,.18,.2),'support header')
  for x in [-.5,.5]:
   Y.box((x,0,1.665),(.5,.28,.05),'saddle base');Y.arc(x,2,.31,.265,.24)
   for dx in [-.2,.2]:H.cyl((x+dx,0,1.705),.022,.03,n=6)
  for x in [-.875,.875]:colbox((x,0,.8),(.25,.5,1.6))
  colbox((0,0,1.54),(1.5,.18,.2))
  # Separate convex blocks approximate saddles; intentionally conservative simplified collision.
  for x in [-.5,.5]:colbox((x,0,1.82),(.62,.28,.36))
 objects=[]
 for k,b in B.items():
  if b.v:
   o=b.object(geo,{'Frame':.004,'Grating':.0007,'Rails':.003,'Fasteners':.0007}[k]);uv_atlas(o);objects.append(o)
 collisions=[]
 for b in C:
  o=b.object(cols);o.hide_render=True;o.display_type='WIRE';o.color=(.1,1,.1,1);o['collision_proxy']=True;collisions.append(o)
 empties=[]
 for i,sc in enumerate(spec['connection_sockets']):
  o=bpy.data.objects.new('SOCKET_'+id+'_'+str(i).zfill(2),None);socks.objects.link(o);o.location=sc['position_m'];o.empty_display_type='ARROWS';o.empty_display_size=.35;o.rotation_euler=Vector(sc['outward_normal']).to_track_quat('X','Z').to_euler();o['socket_id']=sc['id'];o['outward_normal']=sc['outward_normal'];empties.append(o)
 return objects,collisions,empties,rig

def evaluated_join(objects,id):
 deps=bpy.context.evaluated_depsgraph_get();copies=[]
 for o in objects:
  mesh=bpy.data.meshes.new_from_object(o.evaluated_get(deps),depsgraph=deps);ob=bpy.data.objects.new('ExportPart',mesh);bpy.context.scene.collection.objects.link(ob);copies.append(ob)
 bpy.ops.object.select_all(action='DESELECT')
 for o in copies:o.select_set(True)
 bpy.context.view_layer.objects.active=copies[0];bpy.ops.object.join();o=copies[0];o.name=id
 uv_atlas(o)
 tri=o.modifiers.new('Export triangulation','TRIANGULATE');bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=tri.name)
 return o

def metrics(o):
 me=o.data;bm=bmesh.new();bm.from_mesh(me)
 nonman=sum(not e.is_manifold for e in bm.edges);zero=sum(f.calc_area()<1e-12 for f in bm.faces)
 duplicates=0;seen=set()
 for p in me.polygons:
  key=tuple(sorted(tuple(round(v,7) for v in me.vertices[i].co) for i in p.vertices))
  if key in seen:duplicates+=1
  seen.add(key)
 mn=[min(v.co[a] for v in me.vertices) for a in range(3)];mx=[max(v.co[a] for v in me.vertices) for a in range(3)]
 # Verify each disconnected closed component has positive signed volume.
 remaining=set(bm.verts);volumes=[]
 while remaining:
  stack=[remaining.pop()];verts=set(stack)
  while stack:
   v=stack.pop()
   for e in v.link_edges:
    w=e.other_vert(v)
    if w in remaining:remaining.remove(w);verts.add(w);stack.append(w)
  faces={f for v in verts for f in v.link_faces};vol=0
  for f in faces:
   vs=[v.co for v in f.verts]
   for i in range(1,len(vs)-1):vol+=vs[0].dot(vs[i].cross(vs[i+1]))/6
  volumes.append(vol)
 bm.free()
 return {'bounds_min_m':mn,'bounds_max_m':mx,'dimensions_m':[mx[a]-mn[a] for a in range(3)],'vertices':len(me.vertices),'triangles':len(me.polygons),'nonmanifold_edges':nonman,'degenerate_faces':zero,'exact_duplicate_faces':duplicates,'watertight_components':len(volumes),'nonpositive_volume_components':sum(v<=1e-12 for v in volumes),'uv_layers':[x.name for x in me.uv_layers],'material_slots':len(me.materials)}

def render_rig(spec,rig,path):
 s=bpy.context.scene;center=Vector([(a+b)/2 for a,b in zip(spec['bounds_min'],spec['bounds_max'])]);cams={}
 for name,offset,rot in [('front',(0,-20,0),(math.pi/2,0,0)),('right',(20,0,0),(math.pi/2,0,math.pi/2)),('top',(0,0,20),(0,0,0))]:
  data=bpy.data.cameras.new('ORTHO_'+name.upper());data.type='ORTHO';data.ortho_scale=spec.get('ortho_scale_m',10.24);data.lens=50;data.clip_start=.1;data.clip_end=100
  cam=bpy.data.objects.new(data.name,data);rig.objects.link(cam);cam.location=center+Vector(offset);cam.rotation_euler=rot;cams[name]=cam
 for name,loc,energy,size in [('key',(-3,-6,8),1100,7),('fill',(6,3,5),900,6)]:
  data=bpy.data.lights.new(name,'AREA');data.energy=energy;data.shape='DISK';data.size=size;o=bpy.data.objects.new(name,data);rig.objects.link(o);o.location=loc;o.rotation_euler=(center-o.location).to_track_quat('-Z','Y').to_euler()
 if RENDER:
  for name,cam in cams.items():s.camera=cam;s.render.filepath=str(path/(name+'.png'));bpy.ops.render.render(write_still=True)
 s.camera=cams['front']
 return {'projection':'ORTHO','resolution_px':[1024,1024],'ortho_scale_m':spec.get('ortho_scale_m',10.24),'pixels_per_meter':1024/spec.get('ortho_scale_m',10.24),'front_camera_axis':'-Y','right_camera_axis':'+X','top_camera_axis':'+Z','camera_rotations_radians':{n:list(c.rotation_euler) for n,c in cams.items()}}

def main():
 manifest=json.loads((R/'manifest.json').read_text());reports=[]
 for entry in manifest['assets']:
  id=entry['asset_id']
  if FILTER and FILTER not in id:continue
  path=R/entry['path'];spec=json.loads((path/'spec.json').read_text())
  assert (path/'reference_sheet.png').is_file(),f'Missing reference for {id}'
  print('START_ASSET',id,flush=True);scene_setup();objects,collisions,sockets,rig=build_asset(spec)
  export=evaluated_join(objects,id);m=metrics(export);errors=[]
  for a in range(3):
   if abs(m['bounds_min_m'][a]-spec['bounds_min'][a])>1e-5 or abs(m['bounds_max_m'][a]-spec['bounds_max'][a])>1e-5:errors.append('bbox axis '+str(a))
  for k in ['nonmanifold_edges','degenerate_faces','exact_duplicate_faces','nonpositive_volume_components']:
   if m[k]:errors.append(k)
  bpy.ops.object.select_all(action='DESELECT');export.select_set(True)
  for o in collisions+sockets:o.select_set(True)
  bpy.context.view_layer.objects.active=export
  bpy.ops.export_scene.fbx(filepath=str(path/'export.fbx'),use_selection=True,object_types={'MESH','EMPTY'},axis_forward='-Y',axis_up='Z',apply_unit_scale=True,bake_space_transform=False,use_mesh_modifiers=True,mesh_smooth_type='FACE',add_leaf_bones=False)
  for o in collisions:o.select_set(False)
  bpy.ops.export_scene.gltf(filepath=str(path/'export.glb'),export_format='GLB',use_selection=True,export_yup=True,export_apply=True,export_texcoords=True,export_normals=True,export_materials='EXPORT',export_extras=True)
  # Keep evaluated triangle mesh in source for inspection, hidden while editable geometry renders.
  export.hide_render=True;export.hide_set(True);export['role']='Frozen triangulated export snapshot'
  cameras=render_rig(spec,rig,path)
  bpy.ops.object.select_all(action='DESELECT')
  for o in objects:o.select_set(True)
  bpy.context.view_layer.objects.active=objects[0]
  bpy.ops.wm.save_as_mainfile(filepath=str(path/'model.blend'))
  report={'asset_id':id,'status':'PASS' if not errors else 'FAIL','errors':errors,'spec_dimensions_m':spec['dimensions'],'geometry':m,'collision_hulls':len(collisions),'socket_count':len(sockets),'socket_positions_m':{o['socket_id']:list(o.location) for o in sockets},'pivot_m':[0,0,0],'scale':[1,1,1],'rotation_radians':[0,0,0],'orthographic_validation':cameras,'reference_review':'AI sheet is appearance reference only. Projection / proportions are not accepted as geometry authority. See StyleGuide/reference_review.md.','intentional_intersections':['welded steel frame joints','crossed grating members','rail-post welds','bolt seating'], 'limits':['No UE editor import/play test performed yet.','Cross-component fabrication contacts intentionally intersect; no exhaustive arbitrary triangle self-intersection certification.','UV1 uses many small per-face islands; production lightmap repacking is recommended.'],'export_files':['export.fbx','export.glb']}
  (path/'validation.json').write_text(json.dumps(report,indent=2));reports.append(report);print('ASSET_COMPLETE',id,report['status'],m['triangles'],flush=True)
 (R/'Validation'/('build_report_'+(FILTER or 'all')+'.json')).write_text(json.dumps(reports,indent=2))
if __name__=='__main__':main()
