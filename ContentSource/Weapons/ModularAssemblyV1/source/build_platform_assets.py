"""Visual assets and scene assembly only. Gameplay validation is owned by AetherEquipment.
All dimensions are fictional game-scene coordinates, not real manufacturing data.
"""
import sys,math,json,hashlib
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
from mesh_helpers import *
from mathutils import Matrix,Quaternion
R=ROOT
prototypes={}; pivots={}; sockets={}
def begin(id,pivot=(0,0,0)):
 start(id);pivots[id]=pivot

def finish(id):
 obs=modules[id];bpy.ops.object.select_all(action='DESELECT')
 for o in obs:o.select_set(True)
 bpy.context.view_layer.objects.active=obs[0];bpy.ops.object.join();o=bpy.context.object;o.name='VIS_'+id.replace('.','_')
 bpy.ops.object.transform_apply(location=False,rotation=True,scale=True);scene.cursor.location=pivots[id];bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
 # Geometry authored in platform coordinates becomes pivot-local module geometry.
 o.location=(0,0,0);bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.uv.smart_project(island_margin=.018);bpy.ops.object.mode_set(mode='OBJECT');o.data.uv_layers.active.name='UV0_Surface'
 o['module_id']=id;o['visual_only']=True;prototypes[id]=o;return o

def recess(o,x,y,z,w,h,d):
 bpy.ops.mesh.primitive_cube_add(size=1,location=(x,y,z));c=bpy.context.object;c.dimensions=(w,d,h);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);bevel(c,.004,3)
 bpy.context.view_layer.objects.active=o;m=o.modifiers.new('Exterior recessed cosmetic panel','BOOLEAN');m.operation='DIFFERENCE';m.object=c;bpy.ops.object.modifier_apply(modifier=m.name);bpy.data.objects.remove(c,do_unlink=True)

def slot(owner,id,pos,kind,occupancy=None,quat=(0,0,0,1)):
 sockets.setdefault(owner,{})[id]={'translation_m':pos,'rotation_xyzw':quat,'scale':[1,1,1],'mount_type':kind,'occupancy_group':occupancy or id}

# Original compact WISP platform: distinct proportions and solid cosmetic exteriors.
begin('wisp02.core')
profile('Wisp receiver',[(-.12,.025),(-.12,.092),(-.08,.12),(.102,.12),(.13,.094),(.13,.004),(.053,-.022),(-.03,-.012)],.049,dark,.004)
for s in [-1,1]:
 profile('Wisp flank armor',[(-.104,.047),(-.084,.093),(.07,.102),(.10,.078),(.035,.042)],.003,sand,.002,y=s*.027)
 box('Wisp teal id',(0,s*.030,.078),(.065,.002,.009),teal,.001)
 for x in [-.08,.075]:cyl('Visual cap',(x,s*.031,.054),.004,.002,rubber,'Y',12)
box('Wisp spine',(.003,0,.126),(.238,.025,.008),steel)
for i in range(14):box('Wisp rail',(-.103+i*.016,0,.134),(.008,.036,.008),dark,.001)
beam('Wisp guard front',(.012,0,-.007),(.012,0,-.063),.008,.018,dark)
beam('Wisp guard bottom',(.012,0,-.063),(-.045,0,-.063),.008,.018,dark)
finish('wisp02.core')
begin('wisp02.handguard.standard',(.13,0,.063))
hg=profile('Wisp handguard',[(.13,.103),(.305,.103),(.319,.083),(.313,.021),(.14,.008),(.13,.025)],.055,sand,.004)
for s in [-1,1]:
 for x in [.178,.264]:recess(hg,x,s*.027,.069,.047,.017,.01)
 box('Wisp side dark panel',(.219,s*.026,.026),(.10,.002,.007),rubber,.001)
box('Wisp lower rail',(.235,0,.005),(.13,.028,.008),dark,.001)
finish('wisp02.handguard.standard')
begin('wisp02.stock.standard',(-.12,0,.074))
beam('Wisp upper stock',(-.135,0,.084),(-.282,0,.073),.032,.034,sand)
beam('Wisp lower stock',(-.145,0,.052),(-.279,0,-.024),.021,.03,sand)
box('Wisp shoulder pad',(-.302,0,.025),(.026,.043,.122),rubber,.005)
box('Wisp cheek',(-.228,0,.098),(.11,.038,.023),dark,.004)
finish('wisp02.stock.standard')
begin('wisp02.grip',(-.077,0,-.008))
profile('Wisp grip',[(-.098,.009),(-.051,-.009),(-.083,-.121),(-.12,-.113)],.034,rubber,.006)
for s in [-1,1]:
 profile('Wisp grip inlay',[(-.085,-.028),(-.063,-.038),(-.087,-.102),(-.107,-.10)],.002,steel,.002,y=s*.018)
finish('wisp02.grip')
begin('wisp02.magazine',(.071,0,-.015))
profile('Wisp narrow magazine',[(.054,-.008),(.089,-.008),(.078,-.198),(.041,-.198)],.033,dark,.003)
box('Wisp magazine shoe',(.059,0,-.202),(.049,.040,.014),sand)
for s in [-1,1]:box('Magazine teal line',(.064,s*.018,-.12),(.004,.001,.12),teal,.0005,rot=.058)
finish('wisp02.magazine')
begin('wisp02.muzzle',(.315,0,.064));cyl('Wisp sealed cap',(.335,0,.064),.019,.04,dark);cyl('Wisp dark front',(.356,0,.064),.012,.001,rubber);finish('wisp02.muzzle')
begin('wisp02.charging_handle',(-.06,-.028,.073));box('Wisp tab',(-.06,-.036,.073),(.035,.024,.011),steel);finish('wisp02.charging_handle')
begin('wisp02.trigger',(-.025,0,-.019));profile('Wisp trigger',[(-.028,-.018),(-.020,-.018),(-.02,-.038),(-.03,-.05),(-.037,-.045)],.008,steel,.001);finish('wisp02.trigger')
# MOTE platform: shorter pistol silhouette, separate animated cosmetic slide and magazine.
begin('mote03.core')
profile('Mote frame',[(-.083,.015),(-.076,.060),(.147,.060),(.157,.036),(.154,.006),(.069,.005),(.065,-.047),(.009,-.05),(-.024,-.132),(-.076,-.112),(-.045,-.001)],.035,dark,.004)
# open guard formed independently rather than filling its hand-space
# Remove visual center of guard via actual cosmetic recess, preserving frame boundary.
frame=modules['mote03.core'][0];recess(frame,.037,0,-.021,.049,.035,.065)
for s in [-1,1]:
 profile('Mote grip pad',[(-.049,-.026),(-.014,-.037),(-.035,-.113),(-.061,-.10)],.003,rubber,.002,y=s*.019)
 for i in range(7):box('Mote grip rib',(-.040-i*.0025,s*.022,-.044-i*.008),(.019,.002,.003),steel,.0006,rot=-.30)
 box('Mote teal strip',(-.026,s*.021,.029),(.086,.002,.006),teal,.001)
box('Mote utility base',(.104,0,.000),(.067,.026,.008),dark,.001)
finish('mote03.core')
begin('mote03.slide',(-.07,0,.057))
profile('Mote slide',[(-.084,.056),(-.086,.091),(-.072,.105),(.149,.105),(.162,.092),(.162,.057)],.042,sand,.003)
for s in [-1,1]:
 for i in range(6):box('Mote rear serration',(-.071+i*.009,s*.022,.08),(.003,.002,.033),dark,.0006,rot=-.22)
 profile('Mote slide panel',[(.063,.074),(.080,.092),(.117,.092),(.098,.074)],.002,steel,.001,y=s*.023)
box('Mote rear sight',(-.064,0,.11),(.019,.035,.01),dark)
box('Mote front sight',(.137,0,.11),(.012,.009,.011),dark,.001)
cyl('Mote nonfunctional sealed face',(.163,0,.081),.012,.001,rubber)
finish('mote03.slide')
begin('mote03.magazine',(-.047,0,-.083))
profile('Mote magazine insert',[(-.044,-.055),(-.02,-.058),(-.034,-.128),(-.061,-.116)],.025,steel,.002)
profile('Mote floorplate',[(-.073,-.11),(-.022,-.125),(-.024,-.139),(-.078,-.121)],.044,sand,.002)
finish('mote03.magazine')
begin('mote03.trigger',(.029,0,-.005));profile('Mote trigger',[(.02,-.001),(.03,-.001),(.031,-.021),(.022,-.031),(.016,-.027)],.007,teal,.001);finish('mote03.trigger')
# Shared modules all authored about common fictional attachment entrance origin.
begin('shared.optic.reflex')
box('Reflex mount',(0,0,.006),(.078,.042,.012),dark)
profile('Reflex hood',[(-.028,.012),(-.024,.059),(-.008,.071),(.018,.067),(.029,.016)],.032,dark,.002)
box('Reflex lens',(.023,0,.043),(.002,.023,.035),glass,.001,rot=-.3)
for s in [-1,1]:box('Reflex sand flank',(-.009,s*.019,.02),(.035,.004,.011),sand,.001)
finish('shared.optic.reflex')
begin('shared.optic.micro')
box('Micro foot',(0,0,.004),(.041,.029,.008),dark)
profile('Micro housing',[(-.016,.009),(-.014,.033),(.005,.038),(.018,.011)],.025,dark,.002)
box('Micro lens',(.014,0,.023),(.002,.019,.02),glass,.001,rot=-.35)
finish('shared.optic.micro')
begin('shared.adapter.universal_micro')
box('Adapter base',(0,0,.006),(.058,.033,.012),sand)
box('Adapter top',(0,0,.017),(.045,.029,.010),dark)
for s in [-1,1]:cyl('Adapter visual cap',(-.009,s*.018,.008),.003,.003,steel,'Y',12)
finish('shared.adapter.universal_micro')
begin('shared.light.compact')
box('Light mount',(0,0,-.006),(.042,.027,.012),dark)
box('Light body',(.018,0,-.025),(.066,.029,.03),sand,.004)
cyl('Light front lens',(.052,0,-.025),.010,.006,glass)
box('Light teal id',(.02,-.016,-.024),(.03,.001,.006),teal,.001)
finish('shared.light.compact')
begin('shared.grip.stub')
box('Stub top',(0,0,-.005),(.05,.027,.01),dark)
profile('Stub grip',[(-.018,-.009),(.018,-.009),(.012,-.060),(-.022,-.060)],.029,rubber,.004)
finish('shared.grip.stub')
# Bring only exact prior game meshes in; no old source is edited.
old=R/'inputs/KITE01_Source.blend'
oldmap={'Receiver':'core','Handguard_Sand':'handguard.standard','Stock_Skeleton':'stock.standard','Grip_Angled':'grip','Magazine_Box':'magazine','Muzzle_Short':'muzzle','ChargingHandle':'charging_handle','Trigger':'trigger'}
with bpy.data.libraries.load(str(old),link=False) as (src,dst):dst.objects=['SM_KITE01_'+n for n in oldmap]
for o in dst.objects:
 if not o:continue
 scene.collection.objects.link(o);n=o.name.replace('SM_KITE01_','').split('.00')[0];id='kite01.'+oldmap[n];pivots[id]=tuple(o.location);o.parent=None;o.animation_data_clear();o.location=(0,0,0);o.name='VIS_'+id.replace('.','_');o['module_id']=id
 for sl in o.material_slots:
  if sl.material:
   base=bpy.data.materials.get(sl.material.name.split('.')[0]);sl.material=base or sl.material
 prototypes[id]=o
# Transform metadata always refers to the parent module's local pivot.
for platform in ['kite01','wisp02']:
 core=platform+'.core'
 for part in ['handguard.standard','stock.standard','grip','magazine','muzzle','charging_handle','trigger']:
  slot(core,part,pivots[platform+'.'+part],platform+'.'+part)
 slot(core,'optic',(-.028,0,.145) if platform=='kite01' else (0,0,.139),'universal_optic')
 hg=platform+'.handguard.standard';base=Vector(pivots[hg]);at=Vector((.31,0,.0) if platform=='kite01' else (.235,0,-.003))
 slot(hg,'under_light',list(at-base),'utility','under_shared');slot(hg,'under_grip',list(at-base),'under_grip','under_shared')
slot('mote03.core','slide',pivots['mote03.slide'],'mote03.slide');slot('mote03.core','magazine',pivots['mote03.magazine'],'mote03.magazine');slot('mote03.core','trigger',pivots['mote03.trigger'],'mote03.trigger')
slot('mote03.core','under_light',(.105,0,-.004),'utility','under_shared')
slot('mote03.slide','optic',(.027,0,.054),'micro_optic')
slot('shared.adapter.universal_micro','micro',(0,0,.022),'micro_optic')
# Native library has prototypes at stable local origins, hidden to prevent overlap.
lib=bpy.data.collections.new('MODULE_LIBRARY_hidden');scene.collection.children.link(lib)
for id,o in prototypes.items():
 for c in list(o.users_collection):c.objects.unlink(o)
 lib.objects.link(o);o.hide_render=True
# Six visual presets: nest through authored slots; validation authority remains runtime/data rules.
def core_children(p):
 names=['handguard.standard','stock.standard','grip','magazine','muzzle','charging_handle','trigger'] if p!='mote03' else ['slide','magazine','trigger']
 return [{'instance_id':n,'module_id':p+'.'+n,'parent_id':'root','slot_id':n} for n in names]
presets=[]
for p in ['kite01','wisp02','mote03']:
 for variant in ['standard','compact_optic']:
  nodes=[{'instance_id':'root','module_id':p+'.core','parent_id':None,'slot_id':None}]+core_children(p)
  if p=='mote03':
   if variant=='compact_optic':nodes.append({'instance_id':'sight','module_id':'shared.optic.micro','parent_id':'slide','slot_id':'optic'})
   nodes.append({'instance_id':'light','module_id':'shared.light.compact','parent_id':'root','slot_id':'under_light'})
  elif variant=='standard':
   nodes += [{'instance_id':'sight','module_id':'shared.optic.reflex','parent_id':'root','slot_id':'optic'},{'instance_id':'grip_addon','module_id':'shared.grip.stub','parent_id':'handguard.standard','slot_id':'under_grip'}]
  else:
   nodes += [{'instance_id':'adapter','module_id':'shared.adapter.universal_micro','parent_id':'root','slot_id':'optic'},{'instance_id':'sight','module_id':'shared.optic.micro','parent_id':'adapter','slot_id':'micro'},{'instance_id':'light','module_id':'shared.light.compact','parent_id':'handguard.standard','slot_id':'under_light'}]
  presets.append({'id':p+'.'+variant,'platform_id':p,'nodes':nodes})
def tr(s):return Matrix.Translation(Vector(s['translation_m']))@Quaternion((s['rotation_xyzw'][3],*s['rotation_xyzw'][:3])).to_matrix().to_4x4()
manifest={'schema':'aetherlab.visual-modules.v1','units':'meters','forward':'+X','up':'+Z','source_kite01_sha256':hashlib.sha256(old.read_bytes()).hexdigest(),'modules':{},'presets':presets,'runtime_status':'Visual fixture metadata; UE definitions/import and runtime validation owned by AetherEquipment; no uasset import claimed'}
for id,o in prototypes.items():
 o.data.calc_loop_triangles();manifest['modules'][id]={'object':o.name,'mesh_glb':'modules/'+id+'.glb','platform_id':id.split('.')[0] if not id.startswith('shared.') else None,'mount_type':id if not id.startswith('shared.') else {'shared.optic.reflex':'universal_optic','shared.optic.micro':'micro_optic','shared.adapter.universal_micro':'universal_optic','shared.light.compact':'utility','shared.grip.stub':'under_grip'}[id],'slots':sockets.get(id,{}),'triangle_count':len(o.data.loop_triangles),'pivot_local':[0,0,0],'role':'visual_module','engine_soft_reference':None}
(R/'config/Visual_Module_Manifest.json').write_text(json.dumps(manifest,indent=2))
# Export each independently for persistent asset identity, no implicit mesh path fabrication.
(R/'exports/modules').mkdir(exist_ok=True)
for id,o in prototypes.items():
 bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o
 bpy.ops.export_scene.gltf(filepath=str(R/'exports/modules'/f'{id}.glb'),export_format='GLB',use_selection=True,export_animations=False,export_extras=True)
# Build transform-composed fixtures in separate collections and export each assembly.
fixtures={}
for preset in presets:
 col=bpy.data.collections.new('ASSEMBLY_'+preset['id']);scene.collection.children.link(col);world={};mods={};obs=[]
 for n in preset['nodes']:
  if n['parent_id'] is None:mat=Matrix.Identity(4)
  else:mat=world[n['parent_id']]@tr(sockets[mods[n['parent_id']]][n['slot_id']])
  world[n['instance_id']]=mat;mods[n['instance_id']]=n['module_id'];o=prototypes[n['module_id']].copy();o.data=prototypes[n['module_id']].data;o.name=preset['id']+'__'+n['instance_id'];o.matrix_world=mat;o.hide_render=True;col.objects.link(o);obs.append(o)
 bpy.ops.object.select_all(action='DESELECT')
 for o in obs:o.select_set(True)
 bpy.ops.export_scene.gltf(filepath=str(R/'exports'/f'{preset["id"]}.glb'),export_format='GLB',use_selection=True,export_animations=False,export_extras=True)
 fixtures[preset['id']]=obs
bpy.ops.wm.save_as_mainfile(filepath=str(R/'AetherLab_ThreePlatform_Modular.blend'),compress=True)
# Studio, shared relative camera with per-platform framing.
scene.cycles.samples=56;scene.cycles.use_denoising=False;scene.render.resolution_x=1500;scene.render.resolution_y=1000
for name,loc,power,size in [('Key',(.2,-.7,1.3),170,1.1),('Fill',(-.4,.5,.7),100,1),('Rim',(.5,.6,.4),80,.5)]:
 data=bpy.data.lights.new(name,'AREA');data.energy=power;data.shape='DISK';data.size=size;o=bpy.data.objects.new(name,data);scene.collection.objects.link(o);o.location=loc;o.rotation_euler=(Vector((.03,0,.0))-o.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add(location=(.8,-1.3,.6));cam=bpy.context.object;cam.name='Review_Camera';cam.data.type='ORTHO';scene.camera=cam
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.23));floor=bpy.context.object;floor.name='Studio_Floor';floor.data.materials.append(material('M_Studio',(.12,.15,.17),0,.90))
for id,obs in fixtures.items():
 for o in obs:o.hide_render=False
 platform=id.split('.')[0];center=Vector((.04,0,.0));cam.location=center+Vector((.7,-1.3,.65));cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale={'kite01':1.13,'wisp02':.81,'mote03':.50}[platform]
 floor.location.z=-.23 if platform!='mote03' else -.15
 scene.render.filepath=str(R/'renders'/f'{id}.png');bpy.ops.render.render(write_still=True)
 for o in obs:o.hide_render=True
# Leave one main preview assembled, prototypes/other combinations hidden.
for o in fixtures['wisp02.compact_optic']:o.hide_render=False
lib.hide_viewport=True
for c in bpy.data.collections:
 if c.name.startswith('ASSEMBLY_') and c.name!='ASSEMBLY_wisp02.compact_optic':c.hide_viewport=True
cam.location=Vector((.04,0,0))+Vector((.7,-1.3,.65));cam.rotation_euler=(Vector((.04,0,0))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=.81;floor.location.z=-.23
for im in bpy.data.images:
 if im.source=='FILE' and not im.packed_file:im.pack()
bpy.data.orphans_purge(do_recursive=True)
bpy.ops.wm.save_as_mainfile(filepath=str(R/'AetherLab_ThreePlatform_Modular.blend'),compress=True)
print('THREE_PLATFORM_BUILD_COMPLETE',len(prototypes),len(presets))
