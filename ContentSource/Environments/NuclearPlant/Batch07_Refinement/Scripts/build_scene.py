"""Deterministic Blender build from frozen pre-model spec. No reference renders generated here."""
import bpy,sys,json,hashlib,math,pathlib,datetime,random
import numpy as np
from mathutils import Vector
R=pathlib.Path(__file__).resolve().parent.parent;sys.path.insert(0,str(R/'Scripts'))
from analytic_geometry import meshpart
C=json.loads((R/'Config'/'design.json').read_text());F=json.loads((R/'QA'/'reference_freeze.json').read_text())
for fn,sha in F['inputs'].items():
 if hashlib.sha256((R/fn).read_bytes()).hexdigest()!=sha:raise RuntimeError('Frozen pre-model input changed: '+fn)
V2=None
if (R/'QA/reference_freeze_v02.json').exists():
 V2=json.loads((R/'QA/reference_freeze_v02.json').read_text())
 for fn,sha in V2['inputs'].items():
  if hashlib.sha256((R/fn).read_bytes()).hexdigest()!=sha:raise RuntimeError('Frozen v02 input changed: '+fn)
 C=json.loads((R/'Config/design_v02.json').read_text())
V3=None
if (R/'QA/reference_freeze_v03.json').exists():
 V3=json.loads((R/'QA/reference_freeze_v03.json').read_text())
 for fn,sha in V3['inputs'].items():
  if hashlib.sha256((R/fn).read_bytes()).hexdigest()!=sha:raise RuntimeError('Frozen v03 input changed: '+fn)
 C=json.loads((R/'Config/design_v03.json').read_text())
V4=None
if (R/'QA/reference_freeze_v04.json').exists():
 V4=json.loads((R/'QA/reference_freeze_v04.json').read_text())
 for fn,sha in V4['inputs'].items():
  if hashlib.sha256((R/fn).read_bytes()).hexdigest()!=sha:raise RuntimeError('Frozen v04 input changed: '+fn)
 C=json.loads((R/'Config/design_v04.json').read_text())
active_hash=hashlib.sha256((R/'Config'/('design_v04.json' if V4 else ('design_v03.json' if V3 else ('design_v02.json' if V2 else 'design.json')))).read_bytes()).hexdigest()
render_camera_hash=None
if (R/'Config/render_cameras.json').exists():
 cp=R/'Config/render_cameras.json';C['cameras'].update(json.loads(cp.read_text())['cameras']);render_camera_hash=hashlib.sha256(cp.read_bytes()).hexdigest()

source=(R/C['source']).resolve();assert hashlib.sha256(source.read_bytes()).hexdigest()==F['source_sha256']
started=datetime.datetime.now(datetime.timezone.utc).isoformat();random.seed(C['seed'])
bpy.ops.wm.open_mainfile(filepath=str(source));s=bpy.context.scene
s.unit_settings.system='METRIC';s.unit_settings.scale_length=1
# Capture every baseline object's geometry/transform to distinguish protected vs intentionally removed elements.
def geom_sig(o):
 h=hashlib.sha256();h.update(str(o.type).encode());h.update(str([round(x,7) for row in o.matrix_world for x in row]).encode())
 if o.type=='MESH':
  h.update(np.array([v.co[:] for v in o.data.vertices],dtype=np.float32).tobytes());h.update(str([tuple(p.vertices) for p in o.data.polygons]).encode())
 return h.hexdigest()
baseline={o.name:geom_sig(o) for o in s.objects if o.type not in {'CAMERA','LIGHT'}}
MATS={}
def srgb(x):return x/12.92 if x<=.04045 else ((x+.055)/1.055)**2.4
for key,hx in C['material_palette'].items():
 rgb=tuple(srgb(int(hx[i:i+2],16)/255) for i in [1,3,5]);m=bpy.data.materials.new('B07 '+key);m.use_nodes=True;m.diffuse_color=(*rgb,1);n=m.node_tree.nodes;l=m.node_tree.links;p=n.get('Principled BSDF');p.inputs['Base Color'].default_value=(*rgb,1);p.inputs['Roughness'].default_value={'steel':.48,'zinc':.39,'tarp':.87,'wood':.78,'concrete':.83,'asphalt':.91}.get(key,.64);p.inputs['Metallic'].default_value=.7 if key in ['steel','zinc'] else .05
 if key in ['concrete','asphalt','wood','tarp','zinc','steel']:
  tex=n.new('ShaderNodeTexNoise');tex.inputs['Scale'].default_value={'concrete':2.3,'asphalt':5,'wood':5,'tarp':9,'zinc':8,'steel':3}[key];tex.inputs['Detail'].default_value=3.2;tex.inputs['Roughness'].default_value=.65
  co=n.new('ShaderNodeTexCoord');l.new(co.outputs['Object'],tex.inputs['Vector']);ramp=n.new('ShaderNodeValToRGB');ramp.color_ramp.elements[0].position=.20;ramp.color_ramp.elements[1].position=.8
  ramp.color_ramp.elements[0].color=(*[v*.78 for v in rgb],1);ramp.color_ramp.elements[1].color=(*[min(v*1.10,.9) for v in rgb],1);l.new(tex.outputs['Fac'],ramp.inputs['Fac']);l.new(ramp.outputs['Color'],p.inputs['Base Color'])
  noise=n.new('ShaderNodeTexNoise');noise.inputs['Scale'].default_value=110 if key!='tarp' else 65;noise.inputs['Detail'].default_value=2;l.new(co.outputs['Object'],noise.inputs['Vector']);bump=n.new('ShaderNodeBump');bump.inputs['Strength'].default_value=.22;bump.inputs['Distance'].default_value=.018 if key in ['concrete','asphalt'] else .006;l.new(noise.outputs['Fac'],bump.inputs['Height']);l.new(bump.outputs['Normal'],p.inputs['Normal'])
 MATS[key]=m

def coll(name):c=bpy.data.collections.new(name);s.collection.children.link(c);return c
regions={k:coll('B07_'+k) for k in C['regions']};env=coll('B07_SurfaceDetail');cams=coll('B07_Cameras')
keys=list(MATS)
def partsmesh(name,parts):
 vv=[];ff=[];mi=[];smooth=[]
 for p in parts:
  v,f=meshpart(p);base=len(vv);vv.extend(v.tolist());ff.extend([[base+i for i in face] for face in f]);mi.extend([keys.index(p['mat'])]*len(f));smooth.extend([p['type']=='tube' or (p['type']=='cylinder' and i>=2) for i in range(len(f))])
 me=bpy.data.meshes.new(name);me.from_pydata(vv,[],ff);me.update()
 for k in keys:me.materials.append(MATS[k])
 for p,i,sm in zip(me.polygons,mi,smooth):p.material_index=i;p.use_smooth=sm
 return me
meshes={mid:partsmesh(mid,m['parts']) for mid,m in C['modules'].items()}
def object_mesh(n,me,col,pos=(0,0,0),rz=0,bevel=.012):
 ob=bpy.data.objects.new(n,me);col.objects.link(ob);ob.location=pos;ob.rotation_euler.z=math.radians(rz)
 if bevel:
  mod=ob.modifiers.new('Manufactured edge radius','BEVEL');mod.width=bevel;mod.segments=2;mod.limit_method='ANGLE';mod.angle_limit=math.radians(40)
  mod=ob.modifiers.new('Weighted metal / panel normals','WEIGHTED_NORMAL');mod.keep_sharp=True;mod.weight=40
 return ob
# Remove only twelve specifically designated B06 infill units in this new scene copy.
removed=[]
for o in list(s.objects):
 if not (o.name.startswith('B06_UTILITY_SHELTER') or o.name.startswith('B06_SERVICE_BANK') or o.name.startswith('Service compound ID')):continue
 x,y=o.location.x,o.location.y
 for cx,cy in C['replace_shelter_centers']:
  if abs(x-cx)<7.05 and abs(y-cy)<4.2:
   removed.append(o.name);bpy.data.objects.remove(o,do_unlink=True);break
placements=[]
for rn,r in C['regions'].items():
 for i,p in enumerate(r['placements']):
  ob=object_mesh(f'{p["module"]} / {rn} / {i:02d}',meshes[p['module']],regions[rn],p['position'],p['rz'],C['modules'][p['module']].get('bevel_m',.012));ob.scale=p.get('scale',[1,1,1]);ob['module_id']=p['module'];ob['design_hash']=active_hash;ob['region']=rn;placements.append({'object':ob.name,**p})
 # One independently tagged mesh per analytic custom part for optional cutaway and focused QA.
 for i,p in enumerate(r['custom_parts']):
  ob=object_mesh('B07 '+rn+' / '+p['name']+f' / {i}',partsmesh('B07 part '+rn+str(i),[p]),regions[rn],bevel=.006 if p['d'][2]>.05 and not p['name'].startswith('retained cover') else 0);ob['region']=rn
# Surface-only refinement in the copy; protect all baseline geometry. No thick decals on route bands.
for ob in s.objects:
 if ob.type!='MESH' or ob.name.startswith('B07'):continue
 replacement=None
 if ob.name.startswith(('B06 road','East road','West road','South road','North road','Protected pedestrian hardstand')):replacement=MATS['asphalt']
 elif ob.name.startswith('Service compound hardstand'):replacement=MATS['concrete']
 elif ob.name.startswith(('End wall panel','Side concrete panel')) and ob.location.z>3.5:replacement=MATS['concrete']
 if replacement:
  # Shared mesh copies prevent accidental indoor/other-object material mutation.
  ob.data=ob.data.copy();ob.data.materials.clear();ob.data.materials.append(replacement)
  for poly in ob.data.polygons:poly.material_index=0
# Graphic labels are explicitly non-collision curves; no unrelated noisy prop scatter.
def label(name,body,pos,size=.65,rot=(math.pi/2,0,0),mat='white'):
 d=bpy.data.curves.new(name,'FONT');d.body=body;d.size=size;d.align_x='CENTER';d.extrude=.001;d.materials.append(MATS[mat]);o=bpy.data.objects.new(name,d);env.objects.link(o);o.location=pos;o.rotation_euler=rot;return o
for i,(x,y) in enumerate(C['replace_shelter_centers']):
 body=('LOGISTICS / '+str(i+1).zfill(2)) if x<0 else ('PROCESS / '+str(i-5).zfill(2))
 label('B07 functional pad stencil',body,(x,y-4.3,.029),.55,(0,0,0))
for rn,r in C['regions'].items():
 for i,p in enumerate(r['placements']):
  if p['module']=='B07_TRANSFORMER_BAY':
   x,y,z=p['position'];label('B07 transformer identifier','T / '+str(i+1).zfill(2),(x,y-2.215,3.82),.36)
# Existing external daylight / interior lighting unchanged: material/geometry improvement can be compared honestly.
for name,v in C['cameras'].items():
 old=bpy.data.objects.get(name)
 if old and old.type=='CAMERA':bpy.data.objects.remove(old,do_unlink=True)
 d=bpy.data.cameras.new(name);o=bpy.data.objects.new(name,d);cams.objects.link(o);o.location=v['position'];o.rotation_euler=(Vector(v['target'])-o.location).to_track_quat('-Z','Y').to_euler();d.lens=v['lens'];d.clip_end=500
s.camera=bpy.data.objects['site_overview'];s.render.engine='BLENDER_EEVEE_NEXT';s.eevee.taa_render_samples=48;s.eevee.shadow_pool_size='1024';s.render.resolution_x=C['render']['width'];s.render.resolution_y=C['render']['height'];s.render.resolution_percentage=100
# Module scene .blend libraries have real scenes so they open with visible objects, not empty orphan collections.
asset_manifest=[]
for mid,m in C['modules'].items():
 sc=bpy.data.scenes.new(mid);sc.unit_settings.system='METRIC';sc.unit_settings.scale_length=1;ac=bpy.data.collections.new(mid+' asset');sc.collection.children.link(ac)
 ob=object_mesh(mid,meshes[mid],ac,bevel=m.get('bevel_m',.012));ob['module_id']=mid;ob['reference_sha256']=(V2['inputs']['References/v02/'+mid+'.svg'] if V2 else F['inputs']['References/'+mid+'.svg']);ob['part_count']=len(m['parts'])
 bpy.data.libraries.write(str(R/'Assets'/f'{mid}.blend'),{sc},fake_user=True,compress=True)
 verts=np.concatenate([meshpart(p)[0] for p in m['parts']]);asset_manifest.append({'module_id':mid,'title':m['title'],'blend':'Assets/'+mid+'.blend','parts':len(m['parts']),'bounds_min':verts.min(0).tolist(),'bounds_max':verts.max(0).tolist(),'vertices':len(meshes[mid].vertices),'faces':len(meshes[mid].polygons),'reference':('References/v02/' if V2 else 'References/')+mid+'.svg'})
 bpy.data.scenes.remove(sc);bpy.data.objects.remove(ob,do_unlink=True);bpy.data.collections.remove(ac)
for rn,c in regions.items():
 sc=bpy.data.scenes.new('B07 '+rn);sc.collection.children.link(c);bpy.data.libraries.write(str(R/'Regions'/f'{rn}.blend'),{sc},fake_user=True,compress=True);bpy.data.scenes.remove(sc)
changed=[name for name,h in baseline.items() if name not in removed and (name not in bpy.data.objects or geom_sig(bpy.data.objects[name])!=h)]
if changed:raise RuntimeError('Protected baseline geometry changed: '+str(changed[:20]))
s['batch07_design_sha256']=active_hash;s['batch07_reference_freeze_utc']=F['utc'];s['batch07_not_ue_validated']=True;s['batch07_proxy_is_official_Manny']=False
s.render.filepath='//renders/site_overview.png';bpy.ops.wm.save_as_mainfile(filepath=str(R/'site_refined.blend'),compress=True)
(R/'ALL_MODULES.json').write_text(json.dumps(asset_manifest,indent=2))
(R/'QA'/'build_record.json').write_text(json.dumps({'stage':'MODEL_AFTER_REFERENCE','started_utc':started,'finished_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'reference_freeze_utc':F['utc'],'design_sha256':active_hash,'v02_reference_freeze_utc':None if V2 is None else V2['utc'],'v02_inputs_verified':V2 is not None,'v03_reference_freeze_utc':None if V3 is None else V3['utc'],'v03_inputs_verified':V3 is not None,'v04_reference_freeze_utc':None if V4 is None else V4['utc'],'v04_inputs_verified':V4 is not None,'render_camera_sha256':render_camera_hash,'reference_hashes_verified':True,'baseline_sha256':F['source_sha256'],'baseline_unchanged':hashlib.sha256(source.read_bytes()).hexdigest()==F['source_sha256'],'preserved_objects':len(baseline)-len(removed),'protected_geometry_changes':changed,'intentional_removed_objects':removed,'placements':placements,'total_objects':len(s.objects),'unique_new_modules':len(meshes),'ue_runtime_tested':False,'official_manny_tested':False},indent=2))
print('BATCH07_BUILD_OK',len(placements),len(removed))
