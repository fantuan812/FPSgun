import argparse,hashlib,json
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('delivery',type=Path);p.add_argument('qa',type=Path);a=p.parse_args();r=a.delivery;q=a.qa;H=lambda b:hashlib.sha256(b).hexdigest();G=lambda b:hashlib.sha1(b'blob '+str(len(b)).encode()+b'\0'+b).hexdigest()
c=json.loads((r/'COPY_PRECISION_CORRECTION.json').read_text());old=(r/'READ_ME_FINAL.txt.before-precision').read_bytes();new=(r/'READ_ME_FINAL.txt').read_bytes();expected=old
for before,after in c['replacements']: assert expected.count(before.encode())==1;expected=expected.replace(before.encode(),after.encode())
assert expected==new
oldcat=json.loads((r/'CATALOG_DRAFT.json.before-precision').read_text());cat=json.loads((r/'CATALOG_DRAFT.json').read_text())
assert oldcat.keys()==cat.keys(); changes=[]
for k in cat:
 if k!='files':assert cat[k]==oldcat[k]
assert len(cat['files'])==68
for i,(x,y) in enumerate(zip(oldcat['files'],cat['files'])):
 if x!=y:changes.append(i);assert x['version']==y['version']=='v34' and x['name']==y['name']=='READ_ME_v34.txt'
assert len(changes)==1
oldplan=json.loads((r/'UPLOAD_PLAN_DRAFT.json.before-precision').read_text());plan=json.loads((r/'UPLOAD_PLAN_DRAFT.json').read_text());op={x['path']:x for x in oldplan};np={x['path']:x for x in plan};assert op.keys()==np.keys();changed=[]
for path,x in np.items():
 b=Path(x['local_path']).read_bytes();assert len(b)==x['size'] and H(b)==x['sha256'] and G(b)==x['git_blob_sha']
 if any(x[k]!=op[path][k] for k in ['size','sha256','git_blob_sha']):changed.append(path)
assert sorted(changed)==sorted(c['changed_paths'])
base=json.loads((r/'BASE_LOCAL_CATALOG.json').read_text());assert cat['files'][:-2]==base['files'] and len(base['files'])==66
helper=r/'staging/Deliveries/MossCircuit/restore_deliveries.py';assert H(helper.read_bytes())=='3228782b92e9ec6573b7ba9842d950b3cb6c4dbe928fb3bdcb9a2b4f930b55ad'
receipt={'status':'PASS','prior_helper_receipt_sha256':H((q/'delivery/DELIVERY_VERIFICATION.json').read_bytes()),'old_instruction_sha256':H(old),'final_instruction_sha256':H(new),'old_catalog_sha256':H((r/'CATALOG_DRAFT.json.before-precision').read_bytes()),'final_catalog_sha256':H((r/'CATALOG_DRAFT.json').read_bytes()),'only_changed_payloads':changed,'all17_final_payloads_verified':True,'old66_catalog_rows_exact':True,'helper_and_all14_runtime_chunks_unchanged':True,'exact_copy_replacements':c['replacements'],'scope':'Carry forward actual helper10 and v33R2-v34-v33R2 file-only proof across two reviewed instruction-only phrase replacements and dependent catalog metadata; no helper rerun or new gameplay claim.'}
(q/'delivery/FINAL_METADATA_CARRY.json').write_text(json.dumps(receipt,indent=2,ensure_ascii=False)+'\n');print(json.dumps(receipt))
