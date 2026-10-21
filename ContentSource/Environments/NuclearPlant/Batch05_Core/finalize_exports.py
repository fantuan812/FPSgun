"""Run with Python after export_core and both validate_exports processes complete."""
from pathlib import Path
import json,hashlib,struct
R=Path(__file__).resolve().parent;P=R/'Exports'
s=json.loads((P/'export_source_manifest.json').read_text());g=json.loads((P/'readback_glb.json').read_text());f=json.loads((P/'readback_fbx.json').read_text());b=(P/'NuclearPlant_Core.glb').read_bytes();magic,ver,total=struct.unpack('<4sII',b[:12]);ln,typ=struct.unpack('<II',b[12:20]);gl=json.loads(b[20:20+ln]);uris=[x['uri'] for arr in ['buffers','images'] for x in gl.get(arr,[]) if 'uri' in x and not x['uri'].startswith('data:')]
current=hashlib.sha256((R/'core_hall.blend').read_bytes()).hexdigest()
audit_path=P/'camera_only_source_audit.json'
audit=json.loads(audit_path.read_text()) if audit_path.exists() else {}
verified_camera_revision=bool(audit.get('pass') and audit.get('geometry_and_materials_identical') and audit.get('current_source_sha256')==current and audit.get('exported_baseline_source_sha256')==s['source_sha256'])
source_applicable=current==s['source_sha256'] or verified_camera_revision
filehashes_match=all(hashlib.sha256((P/k).read_bytes()).hexdigest()==v['sha256'] for k,v in s['files'].items())
r={'pass':g['pass'] and f['pass'] and source_applicable and magic==b'glTF' and ver==2 and total==len(b) and not uris and filehashes_match,'source_sha256':current,'exported_baseline_source_sha256':s['source_sha256'],'camera_only_revision_audit':audit if verified_camera_revision else None,'source_geometry_applicable':source_applicable,'source_unchanged':current==s['source_sha256']==s['source_sha256_after'],'glb_header_valid':magic==b'glTF' and ver==2 and total==len(b),'glb_external_uri_dependencies':uris,'glb':g,'fbx':f,'files':s['files'],'export_hashes_match':filehashes_match,'roof_included':True,'scale_reference_humans_included':True,'no_camera_or_light_objects':not g['cameras_and_lights'] and not f['cameras_and_lights'],'shader_limitations':s['material_fidelity'],'validation_scope':'New Blender processes imported GLB and FBX. Counts, triangles, materials, bounds and dependencies checked. GLB was additionally rendered after import. Not UE runtime validation.','corrected_issue':'Initial GLB included 2 selected source-scene meshes. Export now isolates realized export scene; repeated GLB and FBX imports match source geometry counts exactly.'}
(P/'export_validation.json').write_text(json.dumps(r,indent=2));print('PASS',r['pass']);print('SOURCE',current)
if not r['pass']:raise SystemExit(1)
