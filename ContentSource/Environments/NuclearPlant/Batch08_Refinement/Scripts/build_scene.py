"""Build additive Batch08 strictly from its frozen pre-model numeric design."""
import bpy,sys,json,pathlib,math,hashlib,datetime,random
import numpy as np
from mathutils import Vector
R=pathlib.Path(__file__).resolve().parent.parent;sys.path.insert(0,str(R/'Scripts'))
from analytic_geometry import meshpart
F1=json.loads((R/'QA/reference_freeze.json').read_text())
for fn,h in F1['inputs'].items():
 assert hashlib.sha256((R/fn).read_bytes()).hexdigest()==h,'Frozen v01 design changed: '+fn
F=F1;active_design='Config/design.json';reference_prefix='References/'
for revision in ['v02','v03','v04']:
 fp=R/f'QA/reference_freeze_{revision}.json'
 if fp.exists():
  F=json.loads(fp.read_text());active_design=f'Config/design_{revision}.json';reference_prefix=f'References/{revision}/'
  for fn,h in F['inputs'].items():
   assert hashlib.sha256((R/fn).read_bytes()).hexdigest()==h,'Frozen '+revision+' design changed: '+fn
C=json.loads((R/active_design).read_text())
source=(R/C['source']).resolve();assert hashlib.sha256(source.read_bytes()).hexdigest()==F['source_sha256'];started=datetime.datetime.now(datetime.timezone.utc).isoformat();random.seed(C['seed'])
bpy.ops.wm.open_mainfile(filepath=str(source));s=bpy.context.scene;s.unit_settings.system='METRIC';s.unit_settings.scale_length=1

def sig(o):
 h=hashlib.sha256();h.update(o.type.encode());h.update(np.array(o.matrix_world,dtype=np.float64).tobytes())
 if o.type=='MESH':h.update(np.array([v.co[:] for v in o.data.vertices],dtype=np.float32).tobytes());h.update(str([tuple(p.vertices) for p in o.data.polygons]).encode())
 elif o.type=='FONT':h.update(o.data.body.encode())
 return h.hexdigest()
baseline={o.name:sig(o) for o in s.objects if o.type not in {'CAMERA','LIGHT'}}
M={}
def linear(x):return x/12.92 if x<=.04045 else ((x+.055)/1.055)**2.4
for k,hx in C['material_palette'].items():
 rgb=tuple(linear(int(hx[i:i+2],16)/255) for i in [1,3,5]);m=bpy.data.materials.new('B08 '+k);m.use_nodes=True;m.diffuse_color=(*rgb,1);n=m.node_tree.nodes;l=m.node_tree.links;pr=n.get('Principled BSDF');pr.inputs['Base Color'].default_value=(*rgb,1);pr.inputs['Metallic'].default_value=.65 if k in ['steel','zinc'] else 0;pr.inputs['Roughness'].default_value={'steel':.47,'zinc':.36,'tarp':.91,'hem':.85,'wood':.79,'concrete':.83,'rubber':.76}.get(k,.62)
 if k in ['concrete','steel','zinc','tarp','hem','wood','timber_edge','rubber','rope']:
  co=n.new('ShaderNodeTexCoord');noise=n.new('ShaderNodeTexNoise');noise.inputs['Scale'].default_value=3.5 if k=='concrete' else 6;noise.inputs['Detail'].default_value=3;l.new(co.outputs['Object'],noise.inputs['Vector']);ramp=n.new('ShaderNodeValToRGB');ramp.color_ramp.elements[0].position=.15;ramp.color_ramp.elements[1].position=.85;ramp.color_ramp.elements[0].color=(*[v*.83 for v in rgb],1);ramp.color_ramp.elements[1].color=(*[v*1.08 for v in rgb],1);l.new(noise.outputs['Fac'],ramp.inputs['Fac']);l.new(ramp.outputs['Color'],pr.inputs['Base Color'])
  bump=n.new('ShaderNodeBump');bump.inputs['Strength'].default_value=.20;bump.inputs['Distance'].default_value=.002 if k not in ['concrete','wood'] else .005
  fine=n.new('ShaderNodeTexNoise');fine.inputs['Scale'].default_value=160 if k in ['tarp','hem'] else 65;fine.inputs['Detail'].default_value=2;l.new(co.outputs['Object'],fine.inputs['Vector']);l.new(fine.outputs['Fac'],bump.inputs['Height']);l.new(bump.outputs['Normal'],pr.inputs['Normal'])
  if k in ['tarp','hem']:
   wave=n.new('ShaderNodeTexWave');wave.wave_type='BANDS';wave.bands_direction='DIAGONAL';wave.inputs['Scale'].default_value=180;wave.inputs['Distortion'].default_value=.4;l.new(co.outputs['Object'],wave.inputs['Vector']);micro=n.new('ShaderNodeBump');micro.inputs['Strength'].default_value=.11;micro.inputs['Distance'].default_value=.001;l.new(wave.outputs['Color'],micro.inputs['Height']);l.new(bump.outputs['Normal'],micro.inputs['Normal']);l.new(micro.outputs['Normal'],pr.inputs['Normal'])
 M[k]=m
keys=list(M)
def meshparts(name,parts):
 vv=[];ff=[];mi=[];sm=[];part_ranges=[]
 for p in parts:
  v,f=meshpart(p);start=len(vv);first=len(ff);vv.extend(v.tolist());ff.extend([[i+start for i in face] for face in f]);mi.extend([keys.index(p['mat'])]*len(f));sm.extend([p.get('smooth',False) or p['type']=='tube' or (p['type']=='cylinder' and i>=2) for i in range(len(f))]);part_ranges.append({'name':p['name'],'vertices':[start,len(vv)],'polygons':[first,len(ff)]})
 me=bpy.data.meshes.new(name);me.from_pydata(vv,[],ff);me.update()
 for k in keys:me.materials.append(M[k])
 for p,i,v in zip(me.polygons,mi,sm):p.material_index=i;p.use_smooth=v
 return me,part_ranges
meshes={};ranges={}
for mid,m in C['modules'].items():meshes[mid],ranges[mid]=meshparts(mid,m['parts'])
def collection(name):c=bpy.data.collections.new(name);s.collection.children.link(c);return c
regions={k:collection('B08_'+k) for k in C['regions']};labels=collection('B08_Labels');cameras=collection('B08_Cameras')
def obmesh(name,me,col,mid=None,pos=(0,0,0),rz=0,scale=(1,1,1),bevel=0):
 ob=bpy.data.objects.new(name,me);col.objects.link(ob);ob.location=pos;ob.rotation_euler.z=math.radians(rz);ob.scale=scale
 if mid:ob['module_id']=mid;ob['batch08_design_sha256']=F['inputs'][active_design];ob['not_credit_as_ballistic_cover']=True
 if bevel:
  mo=ob.modifiers.new('Small manufactured edge radius','BEVEL');mo.width=bevel;mo.segments=2;mo.limit_method='ANGLE';mo.angle_limit=math.radians(40)
  mo=ob.modifiers.new('Weighted hard-surface normals','WEIGHTED_NORMAL');mo.keep_sharp=True
 return ob

def textobj(body,name,p,size,col=labels,rot=(math.pi/2,0,0),mat='dark',align='CENTER'):
 d=bpy.data.curves.new(name,'FONT');d.body=body;d.align_x=align;d.size=size;d.extrude=.0005;d.materials.append(M[mat]);o=bpy.data.objects.new(name,d);col.objects.link(o);o.location=p;o.rotation_euler=rot;return o
placements=[]
for rn,r in C['regions'].items():
 for i,p in enumerate(r['placements']):
  mid=p['module'];ob=obmesh(f'{mid} / {rn} / {i:02d}',meshes[mid],regions[rn],mid,p['position'],p['rz'],p.get('scale',[1,1,1]),C['modules'][mid]['bevel']);ob['region']=rn;ob['placement_tag']=p.get('tag','');placements.append({'object':ob.name,**p})
  for j,lab in enumerate(C['modules'][mid].get('labels',[])):
   a=math.radians(p['rz']);v=Vector(lab['position']);v=Vector((math.cos(a)*v.x-math.sin(a)*v.y,math.sin(a)*v.x+math.cos(a)*v.y,v.z))+Vector(p['position']);tx=textobj(lab['body'],f'B08 module stencil {rn} {i} {j}',v,lab['size'],regions[rn],(math.pi/2,0,a),lab.get('material','dark'));tx['non_collision_annotation']=True
 for i,p in enumerate(r['custom_parts']):
  me,_=meshparts('B08 custom '+rn+str(i),[p]);ob=obmesh('B08 '+rn+' / '+p['name']+f' / {i}',me,regions[rn]);ob['region']=rn;ob['not_credit_as_ballistic_cover']=True
for v in C['ground_labels']:textobj(v['body'],'B08 service pavement stencil',v['p'],v['size'],rot=(0,0,math.radians(v['rz'])),mat='white')
for name,v in C['cameras'].items():
 old=bpy.data.objects.get(name)
 if old and old.type=='CAMERA':bpy.data.objects.remove(old,do_unlink=True)
 d=bpy.data.cameras.new(name);o=bpy.data.objects.new(name,d);cameras.objects.link(o);o.location=v['position'];o.rotation_euler=(Vector(v['target'])-o.location).to_track_quat('-Z','Y').to_euler();d.lens=v['lens'];d.clip_end=500
s.camera=bpy.data.objects['site_overview'];s.render.engine='BLENDER_EEVEE_NEXT';s.eevee.taa_render_samples=48;s.eevee.shadow_pool_size='1024';s.render.resolution_x=C['render']['width'];s.render.resolution_y=C['render']['height'];s.render.resolution_percentage=100
# Independent complete module assets; cargo base retained exactly, no duplicate base in assembled site.
manifest=[]
for mid,m in C['modules'].items():
 sc=bpy.data.scenes.new(mid);sc.unit_settings.system='METRIC';sc.world=s.world;ac=bpy.data.collections.new(mid+' asset');sc.collection.children.link(ac);obs=[]
 ob=obmesh(mid,meshes[mid],ac,mid,bevel=m['bevel']);obs.append(ob)
 if m.get('base_module'):
  base=bpy.data.meshes.get(m['base_module']);assert base is not None;bb=obmesh(mid+' / unchanged B07 base',base,ac);obs.append(bb)
 for lab in m.get('labels',[]):obs.append(textobj(lab['body'],mid+' label',lab['position'],lab['size'],ac,mat=lab.get('material','dark')))
 bpy.data.libraries.write(str(R/'Assets'/f'{mid}.blend'),{sc},fake_user=True,compress=True)
 verts=np.concatenate([meshpart(p)[0] for p in m['parts']+m.get('base_parts',[])]);manifest.append({'module_id':mid,'family':m['family'],'title':m['title'],'blend':f'Assets/{mid}.blend','glb':f'Exports/{mid}.glb','bounds_min':verts.min(0).tolist(),'bounds_max':verts.max(0).tolist(),'new_vertices':len(meshes[mid].vertices),'new_polygons':len(meshes[mid].polygons),'composite_includes_unchanged_base':m.get('base_module'),'reference':m.get('reference',reference_prefix+mid+'.png'),'note':'Cargo asset is complete base plus dressing; site contains dressing only over original unchanged cargo.' if m.get('base_module') else 'Self-contained module'})
 bpy.data.scenes.remove(sc)
 for ob in obs:bpy.data.objects.remove(ob,do_unlink=True)
 bpy.data.collections.remove(ac)
# Regions retain existing local context, not just floating additive details.
region_inventory={}
for rn,col in regions.items():
 sc=bpy.data.scenes.new('B08 '+rn);sc.world=s.world;sc.collection.children.link(col);ctx=bpy.data.collections.new('B08 contextual '+rn);sc.collection.children.link(ctx);b=C['regions'][rn]['bounds'];kept=[]
 for o in list(s.objects):
  if o.name.startswith('B08') or o.type not in {'MESH','FONT','LIGHT'}:continue
  if o.type=='LIGHT':ctx.objects.link(o);kept.append(o.name);continue
  vv=[o.matrix_world@Vector(v) for v in o.bound_box];mn=Vector([min(v[i] for v in vv) for i in range(3)]);mx=Vector([max(v[i] for v in vv) for i in range(3)]);p=(mn+mx)/2
  if b[0]<=p.x<=b[1] and b[2]<=p.y<=b[3] and max(mx.x-mn.x,mx.y-mn.y)<80:ctx.objects.link(o);kept.append(o.name)
 bpy.data.libraries.write(str(R/'Regions'/f'{rn}.blend'),{sc},fake_user=True,compress=True);region_inventory[rn]=kept;bpy.data.scenes.remove(sc);bpy.data.collections.remove(ctx)
changed=[n for n,h in baseline.items() if n not in bpy.data.objects or sig(bpy.data.objects[n])!=h];assert not changed,changed[:10]
s['batch08_reference_freeze_utc']=F['utc'];s['batch08_design_sha256']=F['inputs'][active_design];s['batch08_ue_runtime_tested']=False;s['batch08_official_manny_tested']=False
s.render.filepath='//renders/site_overview.png';bpy.ops.wm.save_as_mainfile(filepath=str(R/'site_refined.blend'),compress=True)
(R/'ALL_MODULES.json').write_text(json.dumps(manifest,indent=2));(R/'QA/part_ranges.json').write_text(json.dumps(ranges,indent=2));(R/'QA/region_inventory.json').write_text(json.dumps(region_inventory,indent=2))
(R/'QA/build_record.json').write_text(json.dumps({'stage':'MODEL_AFTER_REFERENCE','started_utc':started,'finished_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'reference_freeze_utc':F['utc'],'active_design':active_design,'active_revision':C['revision'],'v01_reference_freeze_utc':F1['utc'],'reference_hashes_verified':True,'source_sha256':F['source_sha256'],'source_still_unchanged':hashlib.sha256(source.read_bytes()).hexdigest()==F['source_sha256'],'old_objects_preserved':len(baseline),'old_geometry_changes':changed,'new_placements':placements,'family_count':3,'asset_count_including_variant':4,'full_scene_sha256':hashlib.sha256((R/'site_refined.blend').read_bytes()).hexdigest(),'ue_runtime_tested':False,'official_manny_tested':False},indent=2));print('BATCH08_BUILD_OK',len(placements),'baseline objects preserved',len(baseline))
