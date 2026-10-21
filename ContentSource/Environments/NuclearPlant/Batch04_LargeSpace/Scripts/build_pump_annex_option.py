"""Optional double-height pump annex; preserves every delivered Batch03 file."""
import bpy,pathlib,json,math
from mathutils import Vector,Matrix
R=pathlib.Path(__file__).resolve().parents[1];F=R.parent;RENDER='--no-render' not in __import__('sys').argv
bpy.ops.wm.open_mainfile(filepath=str(F/'Batch03/Region/pump_zone.blend'));s=bpy.context.scene;s.cycles.use_denoising=False;s.cycles.samples=32;s.cycles.max_bounces=4;s.cycles.diffuse_bounces=2;s.render.resolution_x=1280;s.render.resolution_y=960;s.render.resolution_percentage=100;zone=bpy.data.collections['04_PUMP_REALIZED']
# Same 1.8 m mannequin in both comparisons, copied as geometry from the scale collection.
with bpy.data.libraries.load(str(R/'Region/pump_service_connected.blend'),link=False) as (a,b):b.collections=['SCALE_REFERENCES_TOGGLE']
refs=b.collections[0];s.collection.children.link(refs)
for o in list(refs.objects):
 if 'HUMAN_0_' not in o.name:bpy.data.objects.remove(o,do_unlink=True)
 else:o.location+=Vector((13,36,0))
inside=[]
for y in [-23,-15,-7]:
 bpy.ops.object.light_add(type='AREA',location=(-4,y,3.45));o=bpy.context.object;o.name='ANNEX_INTERIOR_LIGHT_'+str(y);o.data.energy=450;o.data.size=3;inside.append(o)
bpy.ops.object.camera_add(location=(-4,-25,1.65));cam=bpy.context.object;cam.name='Annex_Eye_1p65m';cam.data.type='PERSP';cam.data.lens=24;cam.data.clip_start=.05;cam.rotation_euler=(Vector((-4,-8,2.2))-cam.location).to_track_quat('-Z','Y').to_euler();s.camera=cam
if RENDER:s.render.filepath=str(R/'Previews/pump_annex_before_eye.png');bpy.ops.render.render(write_still=True)
removed=[]
for o in list(zone.objects):
 if (o.name.startswith('UpperFloor_') and o.name!='UpperFloor_-3.75_-8') or o.name.startswith(('BuildingColumn_','BuildingHead_')):removed.append(o.name);bpy.data.objects.remove(o,do_unlink=True)
# One small safe upper entrance landing remains attached to the original external walkway.
mp={}
for e in json.loads((R/'Geometry/asset_mesh_map.json').read_text()):mp[e['asset_id']]=e
meshmap={}
for lib in sorted(set(e['library'] for e in mp.values())):
 es=[e for e in mp.values() if e['library']==lib];p=(R/'Region'/lib[2:]).resolve()
 with bpy.data.libraries.load(str(p),link=True) as (a,b):b.meshes=[e['mesh'] for e in es]
 for e,m in zip(es,b.meshes):meshmap[e['asset_id']]=m
for o in zone.objects:
 if o.get('asset_id') in meshmap:o.data=meshmap[o['asset_id']]
def inst(n,id,xyz,deg=0):
 o=bpy.data.objects.new(n,meshmap[id]);zone.objects.link(o);o.location=xyz;o.rotation_euler[2]=math.radians(deg);o['asset_id']=id;return o
for i,x in enumerate([-2.75,-.75]):inst('OPTION_LandingColumn_'+str(i),'SM_NPP_Column_4m_A',(x,-6,-.5));inst('OPTION_LandingHead_'+str(i),'SM_NPP_ColumnHead_075m_A',(x,-6,3.5))
# Guard the two exposed landing edges; east/north are backed by building walls and the existing door.
inst('OPTION_LandingRailWest','SM_NPP_Railing_Open_4m_A',(-3.75,-8,4),90);inst('OPTION_LandingRailSouth','SM_NPP_Railing_Open_4m_A',(-3.75,-8,4))
steel=next(m for m in bpy.data.materials if 'SteelGraphite' in m.name)
def box(n,c,d):
 bpy.ops.mesh.primitive_cube_add(size=1,location=c);o=bpy.context.object;o.name=n;o.dimensions=d;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(steel)
 for cc in list(o.users_collection):cc.objects.unlink(o)
 zone.objects.link(o)
for y in [-26,-18,-10]:
 for z in [7.52,7.72]:box('OPTION_RoofBeamFlange_'+str(y)+'_'+str(z),(-3.75,y,z),(8,.20,.05))
 box('OPTION_RoofBeamWeb_'+str(y),(-3.75,y,7.62),(8,.06,.15))
for o in inside:o.location.z=7.2;o.data.energy=700
for lib in bpy.data.libraries:lib.filepath=bpy.path.relpath(lib.filepath,start=str(R/'Region'))
bpy.data.orphans_purge(do_local_ids=True,do_linked_ids=True,do_recursive=True)
for lib in bpy.data.libraries:lib.filepath='//../Geometry/'+pathlib.Path(lib.filepath).name
bpy.ops.wm.save_as_mainfile(filepath=str(R/'Region/pump_annex_double_height_option.blend'),compress=False,relative_remap=False)
if RENDER:s.render.filepath=str(R/'Previews/pump_annex_after_eye.png');bpy.ops.render.render(write_still=True)
report={'status':'BUILT_PENDING_GEOMETRY_REVIEW','source':'Batch03/Region/pump_zone.blend (read only)','optional':True,'removed':removed,'preserved_upper_landing_m':[4,4],'prior_overall_interior_m':[7.7,23.2,3.75],'new_double_height_main_clear_m':[7.7,19.5,7.495],'north_landing_zone_note':'A 4 x 4 m upper entrance landing remains at the north-east corner; the full 23.2 m length is not uniformly double-height.','human_m':1.8,'eye_height_m':1.65,'lens_mm':24,'limits':['Equipment annex, not the large production hall.','No UE runtime test.']}
(R/'Validation/pump_annex_option.json').write_text(json.dumps(report,indent=2));print('PUMP_ANNEX_OPTION_COMPLETE',len(removed),flush=True)
