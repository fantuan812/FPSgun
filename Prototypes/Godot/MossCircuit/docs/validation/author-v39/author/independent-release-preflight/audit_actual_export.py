from pathlib import Path
import json,hashlib,struct,stat
B=Path('workspace/shared');S=B/'moss-v39-final-r2';P=B/'moss-v39-pack';O=B/'moss-v39-public-prep';j=lambda p:json.loads(p.read_text());h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
inputs=j(B/'moss-v39-prep/final-r2/INPUTS.json');assert len(inputs)==869
for n,v in inputs.items():assert h(S/n)==v,n
plan=j(B/'moss-v39-prep/final-export/PLAN.json')
for p,v in plan['pins'].items():assert h(Path(p))==v,p
assert (B/'moss-v39-prep/final-export/wrapper.exit').read_text().strip()=='0' and (B/'moss-v39-prep/final-export/builder.exit').read_text().strip()=='0'
br=j(P/'BUILD_REPORT.json');steps=j(P/'STEPS.json');assert br['pass'] and br['source_inputs']==869 and br['source_inputs_unchanged'] and br['steps']==steps and [x['step'] for x in steps]==plan['expected_steps']
raw={};warnings=[]
for x in steps:
 p=P/'logs'/(x['step']+'.log');text=p.read_text();raw[str(p)]=h(p);assert x['exit']==0 and x['pass'] and not x['engine_error'] and x['seconds']<=240
 assert not any(v in text for v in ['ERROR:','SCRIPT ERROR','instances leaked','resources still in use']),x['step']
 warnings.extend({'step':x['step'],'line':l} for l in text.splitlines() if 'WARNING' in l)
assert 'Ran 3 tests' in (P/'logs/python-safety.log').read_text() and 'OK' in (P/'logs/python-safety.log').read_text()
expect=j(O/'EXPORT_RESOURCE_STATIC_EXPECTATIONS.json');resource=j(P/'packed-resource-report.json');assert resource['failures']==[] and resource['checks']==expect['expected_checks']==968
for k in ['exact_files','images','actions','action_frames']:assert resource[k]==expect[k],k
finger=j(P/'source-imported-fingerprints.json');assert set(finger['exact_files'])==set(expect['exact_file_paths']);assert set(finger['images'])==set(expect['image_paths']);assert finger['actions']==expect['action_frame_map'];assert set(finger['project_settings'])==set(expect['settings_keys'])
for n,v in finger['exact_files'].items():assert h(S/n)==v,n
for n,v in finger['images'].items():assert h(S/n)==v['raw_png_sha256'] and h(S/(n+'.import'))==v['import_settings_sha256'],n
for n,v in br['files'].items():
 p=P/n;assert p.stat().st_size==v['bytes'] and h(p)==v['sha256'];assert oct(stat.S_IMODE(p.stat().st_mode))==v['mode']
pack=(P/'linux/MossCircuit.pck').read_bytes();assert pack==(P/'windows/MossCircuit.pck').read_bytes();assert len(pack)==43017204 and hashlib.sha256(pack).hexdigest()=='2d9969dedc30f460e0da61eef49fd224ddd5d54bbc6973e1a76ffa6656a12f56'
assert (P/'linux/MossCircuit.x86_64').read_bytes()[:4]==b'\x7fELF' and h(P/'linux/MossCircuit.x86_64')=='2c78919325d7f29fa7607287c7c1eeac367ea4c94e7b8b6f5f4c6b20492f73d0'
assert pack[:4]==b'GDPC' and struct.unpack_from('<I',pack,4)[0]==3
flags,base,index=struct.unpack_from('<IQQ',pack,20);assert flags==2 and index<len(pack);count=struct.unpack_from('<I',pack,index)[0];pos=index+4;records={};payloads={}
for _ in range(count):
 n=struct.unpack_from('<I',pack,pos)[0];pos+=4;assert n>0 and n%4==0;name=pack[pos:pos+n].rstrip(b'\0').decode('utf8');pos+=n;offset,size=struct.unpack_from('<QQ',pack,pos);pos+=16;md5=pack[pos:pos+16];pos+=16;ff=struct.unpack_from('<I',pack,pos)[0];pos+=4
 assert ff==0 and name not in records and base+offset+size<=index and not Path(name).is_absolute() and '..' not in Path(name).parts
 payload=pack[base+offset:base+offset+size];assert hashlib.md5(payload).digest()==md5
 records[name]={'bytes':size,'sha256':hashlib.sha256(payload).hexdigest()};payloads[name]=payload
assert len(records)==count==254
for n in records:
 assert not n.startswith(('docs/','tests/','tools/','art_source/v9-room-candidates/')) and n not in ['MANIFEST.json','README.md','ui/test_ui.gd','art_source/provenance.json']
 assert not any(s in n.lower() for s in ['reference-only','references/','validation_inputs/','engine-user','private']),n
for n in expect['exact_file_paths']:assert n in payloads and payloads[n]==(S/n).read_bytes(),n
markers=[b'/' + b'workspace/',b'/' + b'home/agent/',b'/' + b'tmp/',b'lib' + b'file_',b'file_' + b'000000',b'.codex/' + b'sessions',b'manager' + b':',b'github_' + b'pat_',b'gh' + b'p_'];assert not [m for m in markers if m in pack]
# Actual imported resource payloads cannot contain any of the six historical AI originals by payload identity.
ref_paths=list((B/'moss-v39-art/references').glob('*ai.png'))
prov=j(S/'art_source/stitch_drone/metadata/reference_provenance.json')
for r in prov['sources']:ref_paths.append(B/'moss-v38-work'/r['historical_path'])
refs={h(p) for p in ref_paths};assert len(refs)==6 and not refs.intersection(v['sha256'] for v in records.values())
# Guard all exact source files again after all potentially expensive reads.
for n,v in inputs.items():assert h(S/n)==v,n
result={'pass':True,'scope':'Independent read-only seven raw export routes, all869 source before/after, two actual PCKs and ELF, all254 PCK directory records and MD5 payloads, exact source files/import metadata, full-byte privacy and historical reference identity exclusions. No new engine/native/PCK17 target execution; no Windows runtime claim.','source_inputs':869,'export_routes':7,'resource_checks':968,'resource_counts':{k:resource[k] for k in ['exact_files','images','actions','action_frames']},'pck_bytes':len(pack),'pck_sha256':hashlib.sha256(pack).hexdigest(),'pck_records':count,'actual_all_record_md5_valid':True,'private_marker_hits':[],'reference_original_payload_hashes_excluded':sorted(refs),'warnings':warnings,'raw_sha256':raw,'record_identity':records,'elf_sha256':h(P/'linux/MossCircuit.x86_64'),'source_fingerprint_sha256':h(P/'source-imported-fingerprints.json'),'original_full151_still_failed':True,'independent_packed_native_ordinary':'NOT_ESTABLISHED_BY_THIS_AUDIT'}
(O/'ACTUAL_EXPORT_INDEPENDENT_REVIEW.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps({k:v for k,v in result.items() if k not in ['record_identity','raw_sha256']}))
