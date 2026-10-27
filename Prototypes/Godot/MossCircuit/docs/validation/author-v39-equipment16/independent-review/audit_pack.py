from pathlib import Path
import json,hashlib,re,struct
R=Path('evidence-workspace/moss-equipment16-integration-review');O=Path(__file__).parent;T=Path('evidence-workspace/moss-equipment16-integration-candidate');B=Path('evidence-workspace/moss-v39-final-r2');H=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();J=lambda p:json.loads(p.read_text())
expected=J(R/'POST_IMPORT_888_PINS.json');assert len(expected)==888
raw=[]
for phase_dir,plan_name in [('pack-gate','pack-prep'),('pack-gate-r2','pack-prep-r2')]:
 d=R/phase_dir;p=J(R/plan_name/'PLAN.json');result=J(d/'RESULT.json');assert all(H(Path(k))==v for k,v in p['pins'].items())
 if phase_dir=='pack-gate':assert result['pass'] is False and result['completed']==5 and [x['pass'] for x in result['phases']]==[True,True,True,True,False]
 else:assert result['pass'] is True and result['completed']==4
 for i,row in enumerate(result['phases']):
  name=row['phase'];log=d/(name+'.log');text=log.read_text();rc=int((d/(name+'.exit')).read_text());assert rc==row['exit'];assert row['command']==p['phases'][i]['command'];assert J(d/(name+'-source-before.json'))==expected==J(d/(name+'-source-after.json'));assert row['source_888_unchanged'] and row['base_869_unchanged'] and row['test_pins_unchanged'] and row['plan_unchanged'];assert not row['timeout'] and row['launch_error'] is None and row['guards_error']==[]
  if phase_dir=='pack-gate' and i==4:assert rc==1 and 'source bytes differ assets/items/equipment_atlas_editable.png.import' in text
  else:assert rc==0 and not re.search(r'ERROR|WARNING|SCRIPT ERROR|Parse Error|leaked|Orphan',text,re.I)
  if phase_dir=='pack-gate-r2' and name!='actual_UI21_packed_identity':assert row['resource_group_elapsed_seconds']<=180
  if name=='python-safety':assert re.search(r'^Ran 3 tests in [0-9.]+s$',text,re.M) and re.search(r'^OK$',text,re.M)
  raw.append({'run':phase_dir,'phase':name,'native_exit':rc,'sha256':H(log)})
left=R/'pack-gate/linux/MossCircuit.pck';right=R/'pack-gate/windows/MossCircuit.pck';pack=left.read_bytes();assert pack==right.read_bytes() and hashlib.sha256(pack).hexdigest()=='fac259f0e5406c8b3ab56f21c4b7bf5113ae58d50fdc02344fbc09b8b273f23d';base,index=struct.unpack_from('<QQ',pack,24);count=struct.unpack_from('<I',pack,index)[0];cursor=index+4;files={};payloads={}
for _ in range(count):
 length=struct.unpack_from('<I',pack,cursor)[0];cursor+=4;name=pack[cursor:cursor+length].rstrip(b'\0').decode();cursor+=length;off,size=struct.unpack_from('<QQ',pack,cursor);cursor+=16;md5=pack[cursor:cursor+16];cursor+=16;flags=struct.unpack_from('<I',pack,cursor)[0];cursor+=4;assert flags==0 and name not in files and all(z not in ['', '.', '..'] for z in name.split('/'));data=pack[base+off:base+off+size];assert len(data)==size and hashlib.md5(data).digest()==md5;files[name]={'bytes':size,'sha256':hashlib.sha256(data).hexdigest(),'flags':flags};payloads[name]=data
inv=J(R/'pack-gate-r2/PCK_INVENTORY.json');assert count==254 and files==inv['files'] and inv['pass'] and inv['errors']==[]
for marker in inv['wholebytes_privacy_markers']:assert marker.encode() not in pack
assert b'equipment_atlas_v2' not in pack and b'uid://chrklnkaqwl6m' not in pack
for name,v in files.items():
 assert not any(z in name for z in ['equipment_atlas_v2','equipment_atlas_editable.svg','art_source/icons/','reference_only/','validation_inputs/']);assert v['sha256'] not in inv['old_reference_payload_hashes_forbidden']
key='assets/items/equipment_atlas_editable.png.import';source=(T/key).read_bytes();assert payloads[key]==source.split(b'[deps]')[0].rstrip(b'\n')+b'\n\0'
resources=J(R/'pack-prep-r2/expected-resources.json');assert len(resources['exact_files'])==78 and len(resources['images'])==69
for name,h in resources['exact_files'].items():assert H(T/name)==h==files[name]['sha256']
fingerprint=J(R/'pack-gate-r2/source-imported-fingerprints.json');assert len(fingerprint['exact_files'])==78 and len(fingerprint['images'])==69 and len(fingerprint['actions'])==28
report=J(R/'pack-gate-r2/packed-resource-report.json');assert report['checks']==968 and report['failures']==[] and report['action_frames']==308
sourceUI=J(R/'cold-gate/identity.json');packedUI=J(R/'pack-gate-r2/identity.json');assert packedUI['checks']==240 and packedUI['failures']==[] and packedUI['observations']==sourceUI['observations'] and len(packedUI['observations'])==21
lines=[json.loads(x) for x in (R/'pack-gate-r2/actual_UI21_packed_identity.log').read_text().splitlines() if x.startswith('{')];assert lines==[packedUI]
def snap(root):return {str(p.relative_to(root)):H(p) for p in sorted(root.rglob('*')) if p.is_file() and '.godot' not in p.relative_to(root).parts}
assert snap(T)==expected and snap(B)==J(R/'BASE_PINS.json')
r={'pass':True,'scope':'Independent raw/readback audit; combined original resource export4PASS+original auditFAIL retained+new corrected audit and previously unrun3 routesPASS. Not original8routeallPASS, no independent engine rerun/nativeGUI/Windows runtime','pck_sha256':H(left),'pck_bytes':len(pack),'both_preset_packs_exact':True,'records':count,'all_MD5_valid':True,'wholebytes_privacy_markers_absent':True,'oldPNG_import_ctex_UID_and_reference_payloads_absent':True,'specific_import_normalization_only':key,'source888_base869_unchanged':True,'generic_checks':968,'exact_files':78,'images':69,'actions':28,'frames':308,'UI_checks':240,'UI_unique_icons':21,'packed_UI_raw_source_imported_exact':True,'source_PNG_raw_equality_not_claimed':True,'original_fail_retained':True,'raw':raw,'remaining':'Separate native UI/visual acceptance and final source/release documentation freeze; not yet authorized publication'};(O/'PACK_RAW_REVIEW.json').write_text(json.dumps(r,indent=2)+'\n');print(json.dumps({'pass':True,'sha256':H(O/'PACK_RAW_REVIEW.json'),'pck_bytes':len(pack),'records':count}))
