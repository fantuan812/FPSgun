from pathlib import Path
import hashlib,json,subprocess,os,zipfile,types,copy,io
import argparse
p=argparse.ArgumentParser();p.add_argument('--output',type=Path,required=True);p.add_argument('--prep',type=Path,required=True);p.add_argument('--old-runtime',type=Path,required=True);p.add_argument('--base-archive',type=Path,required=True);a=p.parse_args()
q=a.output.resolve();q.mkdir(parents=True,exist_ok=True);prep=a.prep.resolve();stage=prep/'staging';local=stage/'Deliveries/MossCircuit';output=q/'restored-v31';install=q/'manual-install'
h=lambda b:hashlib.sha256(b).hexdigest()
g=lambda b:hashlib.sha1(b'blob '+str(len(b)).encode()+b'\0'+b).hexdigest()
base=json.loads((prep/'BASE_CATALOG.json').read_text()); cat=json.loads((prep/'CATALOG_DRAFT.json').read_text()); assert cat['files'][:60]==base['files'] and len(cat['files'])==62
assert cat['reassembled_archives']==base['reassembled_archives']
helper=local/'restore_deliveries.py';assert h(helper.read_bytes())=='3228782b92e9ec6573b7ba9842d950b3cb6c4dbe928fb3bdcb9a2b4f930b55ad';assert helper.read_bytes()==(prep/'BASE_restore_deliveries.py').read_bytes()
assert (local/'CATALOG.json').read_bytes()==(prep/'CATALOG_DRAFT.json').read_bytes()
records=[r for r in cat['files'] if r['version']=='v31'];assert len(records)==2
for r in records:
 assert r['name'] in ['MossCircuit.pck','READ_ME_v31.txt']
run=[]
for args in [['--verify-only'],['--output',str(output)],['--output',str(output)]]:
 p=subprocess.run(['python','Deliveries/MossCircuit/restore_deliveries.py','--version','v31']+args,cwd=stage,capture_output=True,text=True)
 run.append({'action':'verify-only' if args[0]=='--verify-only' else ('restore' if len(run)==1 else 'reject existing output'),'exit':p.returncode,'stdout_sha256':h(p.stdout.encode()),'expected_failure':'Invalid or existing output file' in p.stderr})
 (q/f'helper-{len(run)}.private.log').write_text(p.stdout+p.stderr)
assert [x['exit'] for x in run]==[0,0,1]
restored={}
for r in records:
 b=(output/r['name']).read_bytes();assert len(b)==r['size'] and h(b)==r['sha256'] and g(b)==r['original_git_blob_sha'];restored[r['name']]={'bytes':len(b),'sha256':h(b),'git_blob_sha':g(b)}
assert not list(output.glob('.moss-restore-*'))
# Exercise unchanged helper's fail-closed branches without touching staged/canonical bytes.
m=types.ModuleType('verified_restore');exec(compile(helper.read_text(),'restore_deliveries.py','exec'),m.__dict__)
r=next(x for x in records if x['name']=='MossCircuit.pck');neg=[]
for name,mutate in [('reordered chunks',lambda d:d['storage']['chunks'].reverse()),('wrong chunk SHA256',lambda d:d['storage']['chunks'][0].update(sha256='0'*64)),('wrong whole SHA256',lambda d:d.update(sha256='0'*64)),('unsafe source path',lambda d:d['storage']['chunks'][0].update(path='../escape'))]:
 d=copy.deepcopy(r);mutate(d)
 try:m.stream_verified(stage,d);raise AssertionError('unsafe accepted')
 except ValueError as e:neg.append({'case':name,'rejected':True,'reason':str(e)})
# Actual isolated backup/install/rollback. Hardlink unchanged ELF/old PCK, never edit their inodes.
install.mkdir(exist_ok=False)
old=a.old_runtime.resolve(); new=output/'MossCircuit.pck'
os.link(old/'MossCircuit.x86_64',install/'MossCircuit.x86_64');os.link(old/'MossCircuit.pck',install/'MossCircuit.pck')
archive=a.base_archive.resolve()
assert h(archive.read_bytes())=='edb66b67ef3b039cf8a5161d25b229345903ca931b5ea5c6873aeaf6222e607d'
with zipfile.ZipFile(archive) as z:
 for info in z.infolist():
  if info.is_dir():continue
  rel=Path(info.filename).relative_to('MossCircuit-v19-Linux-x86_64') if info.filename.startswith('MossCircuit-v19-Linux-x86_64/') else Path(*Path(info.filename).parts[1:])
  if rel.name in ['MossCircuit.pck','MossCircuit.x86_64']:continue
  p=install/rel;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(z.read(info));p.chmod((info.external_attr>>16)&0o777)
def mapping():return {p.relative_to(install).as_posix():{'sha256':h(p.read_bytes()),'bytes':p.stat().st_size,'mode':oct(p.stat().st_mode&0o777)} for p in sorted(install.rglob('*')) if p.is_file()}
before=mapping(); assert before['MossCircuit.pck']['sha256']=='c7485c5a423312fac0c064e5a5a2815cc36284f6018a020c9c54e64b6dcec894';assert len(before)==9
backup=install/'MossCircuit.pck.before-v31';assert not backup.exists();(install/'MossCircuit.pck').rename(backup);os.link(new,install/'MossCircuit.pck');after=mapping();assert after['MossCircuit.pck']['sha256']==r['sha256'];assert after[backup.name]==before['MossCircuit.pck'];assert all(after[k]==v for k,v in before.items() if k!='MossCircuit.pck')
(install/'MossCircuit.pck').rename(install/'MossCircuit.pck.accepted-v31');backup.rename(install/'MossCircuit.pck');rollback=mapping();assert all(rollback[k]==v for k,v in before.items());assert h((old/'MossCircuit.pck').read_bytes())==before['MossCircuit.pck']['sha256']
result={'verdict':'PASS','helper_sha256':h(helper.read_bytes()),'catalog_sha256':h((prep/'CATALOG_DRAFT.json').read_bytes()),'readme_sha256':h((prep/'READ_ME_DRAFT.txt').read_bytes()),'general_readme_sha256':h((prep/'README_DRAFT.md').read_bytes()),'old_catalog_records_preserved':60,'new_records':2,'chunks':len(r['storage']['chunks']),'restored':restored,'literal_helper_runs':run,'negative_cases':neg,'manual_update':{'scope':'Isolated file operation simulation; hardlinked unchanged ELF and old PCK, original v19 license/readme/checksum bytes. No executable launched and no canonical inode edited. Old package checksum manifest deliberately remains historical as instructions disclose.','before':before,'after':after,'rollback':rollback,'non_pck_files_unchanged':True,'canonical_old_pck_unchanged':True},'limits':['Linux helper executed; Windows/NTFS not executed','per-original atomic restoration, not batch rollback','manual replacement/rollback only; no automatic installation or full platform extraction','native exact runtime already tested separately; no recampaign']}
(q/'DELIVERY_VERIFICATION.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps({k:v for k,v in result.items() if k!='manual_update'},indent=2))
