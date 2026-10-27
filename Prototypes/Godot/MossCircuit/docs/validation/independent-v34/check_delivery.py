from pathlib import Path
import argparse,copy,hashlib,json,os,shutil,subprocess,sys
p=argparse.ArgumentParser();p.add_argument('--delivery',required=True);p.add_argument('--baseline-pack',required=True);p.add_argument('--elf',required=True);a=p.parse_args()
q=Path(__file__).parent;root=Path(a.delivery);stage=root/'staging';out=q/'delivery';out.mkdir(exist_ok=False)
h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
helper=stage/'Deliveries/MossCircuit/restore_deliveries.py';catalog=stage/'Deliveries/MossCircuit/CATALOG.json'
assert h(helper)=='3228782b92e9ec6573b7ba9842d950b3cb6c4dbe928fb3bdcb9a2b4f930b55ad'
d=json.loads(catalog.read_text());base=json.loads((root/'BASE_LOCAL_CATALOG.json').read_text());assert len(base['files'])==66 and d['files'][:-2]==base['files'] and d['reassembled_archives']==base['reassembled_archives'];records=[r for r in d['files'] if r['version']=='v34'];assert len(records)==2
pack_record=next(r for r in records if r['name']=='MossCircuit.pck');rows=[]
def run(name,args,expected):
 proc=subprocess.run([sys.executable,str(helper),'--version','v34',*args],cwd=stage,capture_output=True,text=True);(out/(name+'.log')).write_text(proc.stdout+proc.stderr);row={'name':name,'exit':proc.returncode,'expected_success':expected,'pass':(proc.returncode==0)==expected};rows.append(row);assert row['pass'],(name,proc.stdout,proc.stderr)
run('literal-verify',['--verify-only'],True);restored=out/'restored-v34';run('literal-restore',['--output',str(restored)],True)
pack=restored/'MossCircuit.pck';assert h(pack)==pack_record['sha256'] and pack.stat().st_size==pack_record['size'];before={p.name:h(p) for p in restored.iterdir()}
run('no-overwrite',['--output',str(restored)],False);assert before=={p.name:h(p) for p in restored.iterdir()}
cases=[('wrong-chunk-sha',lambda r:r['storage']['chunks'][0].update(sha256='0'*64)),('wrong-whole-sha',lambda r:r.update(sha256='0'*64)),('wrong-git-object',lambda r:r['storage']['chunks'][0].update(git_blob_sha='0'*40)),('noncontiguous-offset',lambda r:r['storage']['chunks'][1].update(offset=0)),('unsafe-name',lambda r:r.update(name='../escaped.pck')),('unsafe-source',lambda r:r['storage']['chunks'][0].update(path='../escaped.bin'))]
for name,mutate in cases:
 record=copy.deepcopy(pack_record);mutate(record);c=out/(name+'.json');c.write_text(json.dumps({'files':[record]}));target=out/(name+'-output');run(name,['--catalog',str(c),'--output',str(target)],False);assert not target.exists() or not list(target.iterdir())
link=out/'symlink-output';link.symlink_to(restored,target_is_directory=True);run('symlink-output',['--output',str(link)],False);assert before=={p.name:h(p) for p in restored.iterdir()}
plan_name='UPLOAD_PLAN.json' if (root/'UPLOAD_PLAN.json').exists() else 'UPLOAD_PLAN_DRAFT.json';plan=json.loads((root/plan_name).read_text());assert len(plan)==17
for entry in plan:
 b=Path(entry['local_path']).read_bytes();assert len(b)==entry['size'] and hashlib.sha256(b).hexdigest()==entry['sha256'] and hashlib.sha1(b'blob '+str(len(b)).encode()+b'\0'+b).hexdigest()==entry['git_blob_sha']
old=Path(a.baseline_pack);elf=Path(a.elf)
assert h(old)=='8ec850cc2fd8b5490ee1f945d56cdb674fa38460191c3eb75be0fdb419ee9aba'
assert h(elf)=='2c78919325d7f29fa7607287c7c1eeac367ea4c94e7b8b6f5f4c6b20492f73d0'
install=out/'manual-file-simulation';install.mkdir();os.link(elf,install/'MossCircuit.x86_64');shutil.copy2(old,install/'MossCircuit.pck')
initial={p.name:{'sha256':h(p),'mode':oct(p.stat().st_mode&0o777)} for p in install.iterdir()};backup=install/'MossCircuit-v33-r2-manual-backup.pck';assert not backup.exists();shutil.copy2(install/'MossCircuit.pck',backup)
shutil.copy2(pack,install/'MossCircuit.pck');assert h(backup)==h(old) and h(install/'MossCircuit.pck')==h(pack) and h(install/'MossCircuit.x86_64')==h(elf)
shutil.copy2(backup,install/'MossCircuit.pck');assert {n:{'sha256':h(install/n),'mode':oct((install/n).stat().st_mode&0o777)} for n in initial}==initial
receipt={'status':'PASS','helper_sha256':h(helper),'catalog_sha256':h(catalog),'old_catalog_rows_exact':66,'new_total_rows':68,'planned_payloads_verified':len(plan),'steps':rows,'restored_files':before,'manual_rollback':{'scope':'Actual local v33 R2->v34->v33 R2 core-file backup/replacement/rollback only; no runtime execution, Windows test or Git download claim','baseline_pack_sha256':h(old),'new_pack_sha256':h(pack),'unchanged_elf_sha256':h(elf),'baseline_and_elf_rehashed_after':True,'unique_backup_exact':True,'restored_initial_map':initial},'scope':'Unchanged public restoration helper on local staged repository; per-file atomicity/no automatic install/extract/execute. Catalog/helper and all17 payload bytes verified; no remote publication claim.'}
(out/'DELIVERY_VERIFICATION.json').write_text(json.dumps(receipt,indent=2)+'\n');print(json.dumps({'status':'PASS','steps':len(rows),'pack_sha256':h(pack)}))
