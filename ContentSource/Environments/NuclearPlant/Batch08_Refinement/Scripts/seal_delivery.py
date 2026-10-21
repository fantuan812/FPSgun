"""Seal final author files after independent report has been copied; no Blender use."""
from pathlib import Path
import json,hashlib,datetime,argparse
R=Path(__file__).resolve().parent.parent
p=argparse.ArgumentParser();p.add_argument('--independent-report',required=True);args=p.parse_args()
assert (R/args.independent_report).is_file()
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
b=json.loads((R/'QA/build_record.json').read_text()); assert b['active_revision']=='v04'
assert sha(R/'site_refined.blend')==b['full_scene_sha256']
freeze_checks=[]
for name in ['reference_freeze.json','reference_freeze_v02.json','reference_freeze_v03.json','reference_freeze_v04.json']:
 f=json.loads((R/'QA'/name).read_text());assert not f['models_present_at_freeze'] and f['model_absence_verified']
 for fn,h in f['inputs'].items():assert sha(R/fn)==h,fn
 freeze_checks.append({'file':'QA/'+name,'sha256':sha(R/'QA'/name),'utc':f['utc'],'verified_inputs':len(f['inputs'])})
e=json.loads((R/'Exports/manifest.json').read_text());assert len(e)==4
for v in e:assert sha(R/v['file'])==v['sha256']
r=json.loads((R/'QA/rebuild_verification.json').read_text());assert r['geometry_signature_equal'] and all(x['byte_identical'] for x in r['module_glb_comparison'])
prov=json.loads((R/'QA/render_provenance.json').read_text());after=['site_overview','site_cutaway','pump_connection_eye','receiving_connection_eye','cargo_detail_eye','module_gallery'];pairs=['pump_connection_eye','receiving_connection_eye','cargo_detail_eye']
for key in after+['before_'+v for v in pairs]:
 v=prov[key];assert sha(R/'renders'/f'{key}.png')==v['image_sha256'];assert v['samples']==48 and v['resolution']==[1600,1000]
 assert v['source_scene_sha256']==(b['source_sha256'] if key.startswith('before_') else b['full_scene_sha256'])
 assert v['render_script_sha256']==sha(R/v.get('render_script','Scripts/render_scene.py')) and v['render_camera_config_sha256']==sha(R/'Config/render_cameras.json')
for v in pairs:
 a,z=prov['before_'+v],prov[v]
 for key in ['camera_position','camera_rotation','camera_lens','renderer','samples','resolution','baseline_lights']:assert a[key]==z[key],(v,key)
comp=json.loads((R/'QA/comparison_manifest.json').read_text());assert len(comp)==3
for v in comp:assert sha(R/'renders'/v['comparison'])==v['sha256']
summary={'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'active_design':b['active_design'],'source_scene_sha256':b['full_scene_sha256'],'baseline_scene_sha256':b['source_sha256'],'old_objects_preserved':b['old_objects_preserved'],'old_geometry_changes':b['old_geometry_changes'],'family_count':3,'asset_count_including_variant':4,'region_count':2,'placements':len(b['new_placements']),'reference_freezes':freeze_checks,'final_render_count':len(after),'same_camera_comparison_count':len(pairs),'render_provenance_verified':True,'geometry_rebuild_equal':True,'glb_rebuild_byte_equal':True,'independent_report':args.independent_report,'ue_runtime_tested':False,'official_manny_tested':False,'limitations':['Inherited six route-edge contacts remain; no whole-map capsule/navmesh acceptance.','New grates, conduit and low service edges are not credited as ballistic cover.','GLB shaders use base PBR; procedural textile/noise is not baked.','No game LOD, collision bake, performance budget or AAA acceptance.']}
(R/'QA/delivery_summary.json').write_text(json.dumps(summary,indent=2))
files=[]
for p in sorted(R.rglob('*')):
 if not p.is_file() or p.name in {'DELIVERY_MANIFEST.json','RELEASE.json'} or '__pycache__' in p.parts or p.suffix in {'.pyc','.blend1'}:continue
 files.append({'path':str(p.relative_to(R)),'bytes':p.stat().st_size,'sha256':sha(p)})
manifest={'format':'Batch08 author file manifest v1','utc':summary['utc'],'excluded':['DELIVERY_MANIFEST.json (self)','RELEASE.json (binds manifest hash)','__pycache__/*.pyc and Blender backup files (not delivery content)'],'files':files,'file_count':len(files),'total_bytes':sum(x['bytes'] for x in files)}
(R/'DELIVERY_MANIFEST.json').write_text(json.dumps(manifest,indent=2))
release={'status':'AUTHOR_RELEASE_FOR_INDEPENDENT_PACKAGING','utc':summary['utc'],'manifest':'DELIVERY_MANIFEST.json','manifest_sha256':sha(R/'DELIVERY_MANIFEST.json'),'scene':'site_refined.blend','scene_sha256':b['full_scene_sha256'],'active_config':'Config/design_v04.json','active_config_sha256':sha(R/'Config/design_v04.json'),'reference_freeze':'QA/reference_freeze_v04.json','reference_freeze_sha256':sha(R/'QA/reference_freeze_v04.json'),'independent_report':args.independent_report,'rebuild_command':'python3 rebuild_all.py','rebuild_with_renders':'python3 rebuild_all.py --render','verification_command':'python3 Scripts/check_rebuild.py','source_dependency':'../Batch07_Refinement/site_refined.blend','source_dependency_sha256':b['source_sha256'],'publishing_authority':'Parent and cumulative packager; this author script does not publish.'}
(R/'RELEASE.json').write_text(json.dumps(release,indent=2));print('SEALED',len(files),manifest['total_bytes'],release['manifest_sha256'])
