"""Local-only v40-held8 staging. Runtime evidence is complete within its recorded boundaries; delivery verification and publication remain separate."""
from pathlib import Path
import hashlib,json,copy,collections
root=Path(__file__).parent;stage=root/'staging';assert not stage.exists(),'Never overwrite an existing staging tree';dest=stage/'Deliveries/MossCircuit';version=dest/'v40-held8';version.mkdir(parents=True)
sha=lambda b:hashlib.sha256(b).hexdigest();git=lambda b:hashlib.sha1(b'blob '+str(len(b)).encode()+b'\0'+b).hexdigest()
base=Path('evidence-workspace/moss-v40-delivery-prep');old=json.loads((base/'staging/Deliveries/MossCircuit/CATALOG.json').read_text());assert len(old['files'])==82
(root/'BASE_LOCAL_CATALOG.json').write_text(json.dumps(old,ensure_ascii=False,indent=2)+'\n')
helper=(base/'staging/Deliveries/MossCircuit/restore_deliveries.py').read_bytes();assert sha(helper)=='3228782b92e9ec6573b7ba9842d950b3cb6c4dbe928fb3bdcb9a2b4f930b55ad';(dest/'restore_deliveries.py').write_bytes(helper)
pack=Path('evidence-workspace/moss-held8-integration-review/pack-gate-first/linux/MossCircuit.pck').read_bytes();assert len(pack)==39268876 and sha(pack)=='8a74dd872a22da4c2b15e1799207e885a9c604bbf58adc1f2fdb37196a23bffa'
text=(root/'READ_ME_FINAL.txt').read_bytes();(version/'READ_ME_v40-held8.txt').write_bytes(text);parts=[]
for i,off in enumerate(range(0,len(pack),3000000),1):
 b=pack[off:off+3000000];rel=f'Deliveries/MossCircuit/v40-held8/chunks/MossCircuit.pck/chunk-{i:03}.bin';p=stage/rel;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(b);parts.append({'path':rel,'offset':off,'size':len(b),'sha256':sha(b),'git_blob_sha':git(b)})
assert len(parts)==14 and b''.join((stage/x['path']).read_bytes() for x in parts)==pack
cat=copy.deepcopy(old);cat['files']+=[{'version':'v40-held8','name':'MossCircuit.pck','size':len(pack),'sha256':sha(pack),'original_git_blob_sha':git(pack),'delivery_kind':'github_native_runtime_resource_pack','storage':{'kind':'chunks','chunks':parts},'delivery_identity_basis':'Locally staged complete v40-held8 PCK; final independent gates separate; not published, attached or a new executable.'},{'version':'v40-held8','name':'READ_ME_v40-held8.txt','size':len(text),'sha256':sha(text),'original_git_blob_sha':git(text),'delivery_kind':'github_native_runtime_instructions','storage':{'kind':'direct','path':'Deliveries/MossCircuit/v40-held8/READ_ME_v40-held8.txt','git_blob_sha':git(text)},'delivery_identity_basis':'Local instructions record finite verification limits; helper result is separately recorded; not publication.'}]
assert cat['files'][:82]==old['files'];cat['scope']='Preserves 82 historical catalog records exactly; appends 2 LOCAL v40-held8 files. Versions32–40 and v39-equipment16 have separately verified historical publication; v40-held8 publication is not yet claimed.';cat['publication_status']['v40-held8']='local held8 asset-only source23090/fire1089; original pack ninth strictFAIL retained and separate fixture-only source/packed1089 repair; native239/36 images; delivery and publication remain separate, no new ordinary/full claim';cat['storage_counts']=dict(collections.Counter(x['storage']['kind'] for x in cat['files']));cat['original_bytes']=sum(x['size'] for x in cat['files']);cat['reassembly_note']=cat['reassembly_note'].replace('v26-v40','v26-v40-held8')
for p in [root/'CATALOG_DRAFT.json',dest/'CATALOG.json']:p.write_text(json.dumps(cat,ensure_ascii=False,indent=2)+'\n')
head="""## v40-held8 — editable held weapons

Eight existing held weapon sprites now use semantic editable SVG masters and derived PNGs. Geometry/calibration and v40 gameplay remain unchanged; the accepted equipment16 migration remains present. No UI R2 is included. See [restoration and exact evidence boundaries](v40-held8/READ_ME_v40-held8.txt). The accepted v40 delivery README below remains verbatim history; this pack has a different identity. Actual source publication is recorded separately in SOURCE_VERSIONS only after a reachable commit.

"""
readme=head+(base/'staging/Deliveries/MossCircuit/README.md').read_text();(dest/'README.md').write_text(readme);(root/'README_DRAFT.md').write_text(readme)
plan=[]
for rel in [x['path'] for x in parts]+['Deliveries/MossCircuit/v40-held8/READ_ME_v40-held8.txt','Deliveries/MossCircuit/CATALOG.json','Deliveries/MossCircuit/README.md']:
 b=(stage/rel).read_bytes();plan.append({'path':rel,'local_path':str(stage/rel),'size':len(b),'sha256':sha(b),'git_blob_sha':git(b),'mode':'100644'})
(root/'UPLOAD_PLAN_DRAFT.json').write_text(json.dumps(plan,indent=2)+'\n')
r={'staging_valid':True,'final_qa_pending':True,'pending_scope':'delivery verification and actual publication only; bounded native/ordinary evidence separately recorded','old_local_records_exact':82,'new_records':2,'total_records':84,'chunks':14,'runtime_size':len(pack),'runtime_sha256':sha(pack),'runtime_chunks_reassembly_equal':True,'helper_sha256':sha(helper),'new_delivery_paths':17,'staged_only_not_published':True,'no_history_or_platform_zip_copy':True,'external_actions':[]};(root/'STAGE_IDENTITY_DRAFT.json').write_text(json.dumps(r,indent=2)+'\n');print(json.dumps(r))
