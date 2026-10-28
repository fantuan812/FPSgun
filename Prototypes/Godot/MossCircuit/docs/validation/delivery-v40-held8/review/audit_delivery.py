"""Independent read-only delivery evidence audit; no rerun or external action."""
from pathlib import Path
import json, hashlib
R=Path('workspace/shared'); P=Path(__file__).parent
H=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
J=lambda p:json.loads(Path(p).read_text())
q=R/'moss-held8-delivery-gate'; d=R/'moss-held8-delivery-qa/delivery'; s=R/'moss-held8-delivery-prep'
checks=[]
def check(value,name):
    assert value,name
    checks.append(name)
plan=J(q/'PLAN.json'); result=J(q/'raw-first/RESULT.json'); report=J(d/'DELIVERY_VERIFICATION.json')
check(result['pass'] is True and result['completed']==2 and not result['errors'],'terminal exact2')
check((q/'wrapper.exit').read_text()=='0\n' and not (q/'wrapper.stderr').read_bytes(),'wrapper0 clean')
check(H(q/'PLAN.json')==result['plan_sha256'],'plan identity')
for path,sha in plan['pins'].items():check(H(path)==sha,'pin '+path)
for name in ['stage','delivery10']:
    rr=J(q/'raw-first'/name/'RESULT.json');check(rr['pass'] is True and rr['native_exit']==0 and rr['timeout'] is False and rr['exception'] is None,'native '+name)
    check((q/'raw-first'/name/'native.exit').read_text()=='0\n' and not (q/'raw-first'/name/'stderr.raw').read_bytes(),'raw clean '+name)
expected={
    'no-overwrite':'ValueError: Invalid or existing output file',
    'wrong-chunk-sha':'ValueError: Chunk identity mismatch: Deliveries/MossCircuit/v40-held8/chunks/MossCircuit.pck/chunk-001.bin',
    'wrong-whole-sha':'ValueError: Original identity mismatch: MossCircuit.pck',
    'wrong-git-object':'ValueError: Chunk identity mismatch: Deliveries/MossCircuit/v40-held8/chunks/MossCircuit.pck/chunk-001.bin',
    'noncontiguous-offset':'ValueError: Non-contiguous or reordered chunks',
    'unsafe-name':'ValueError: Unsafe relative path',
    'unsafe-source':'ValueError: Unsafe relative path',
    'symlink-output':'ValueError: Output symlinks are not accepted'}
check([x['name'] for x in report['steps']]==plan['control_names'],'exact10 ordered names')
for row in report['steps']:
    name=row['name'];txt=(d/(name+'.log')).read_text()
    check(row['pass'] is True and row['expected_success'] is (name not in expected),'step semantics '+name)
    if name in expected:
        check(type(row['exit']) is int and row['exit']!=0,'negative native '+name)
        check(txt.rstrip().endswith(expected[name]),'exact rejection '+name)
        if name not in ['no-overwrite','symlink-output']:
            target=d/(name+'-output');check(not target.exists() or not list(target.iterdir()),'no partial output '+name)
    else:
        check(row['exit']==0 and 'All selected originals match their recorded SHA-256 and Git blob IDs.' in txt,'positive native '+name)
check((d/'symlink-output').is_symlink() and (d/'symlink-output').resolve()==(d/'restored-v40-held8').resolve(),'negative symlink target exact')
for name,sha in report['restored_files'].items():check(H(d/'restored-v40-held8'/name)==sha,'restored '+name)
check(H(d/'restored-v40-held8/MossCircuit.pck')==plan['new_pck_sha256'],'new pack actual identity')
for name,row in report['manual_rollback']['restored_initial_map'].items():
    f=d/'manual-file-simulation'/name
    check(H(f)==row['sha256'] and oct(f.stat().st_mode&0o777)==row['mode'],'rollback bytes+mode '+name)
check(H(d/'manual-file-simulation/MossCircuit-v40-manual-backup.pck')==plan['old_pck_sha256'],'unique old backup exact')
check(H(d/'manual-file-simulation/MossCircuit.pck')==plan['old_pck_sha256'],'actual restored old PCK')
check(H(d/'manual-file-simulation/MossCircuit.x86_64')==plan['elf_sha256'],'actual unchanged ELF')
old=J(R/'moss-v40-delivery-prep/staging/Deliveries/MossCircuit/CATALOG.json'); new=J(s/'staging/Deliveries/MossCircuit/CATALOG.json')
check(len(old['files'])==82 and len(new['files'])==84 and new['files'][:82]==old['files'],'82old exact84total')
check(new['reassembled_archives']==old['reassembled_archives'],'archive history unchanged')
check((s/'staging/Deliveries/MossCircuit/README.md').read_bytes().endswith((R/'moss-v40-delivery-prep/staging/Deliveries/MossCircuit/README.md').read_bytes()),'delivery history suffix exact')
upload=J(s/'UPLOAD_PLAN_DRAFT.json');check(len(upload)==17 and len({x['path'] for x in upload})==17,'17unique paths')
for row in upload:
    b=Path(row['local_path']).read_bytes();check(len(b)==row['size'] and hashlib.sha256(b).hexdigest()==row['sha256'] and hashlib.sha1(b'blob '+str(len(b)).encode()+b'\0'+b).hexdigest()==row['git_blob_sha'],'payload triple '+row['path'])
source=J(plan['source_map']);check(len(source)==935,'source935 count')
check(J(q/'raw-first/SOURCE_BEFORE.json')==source==J(q/'raw-first/SOURCE_AFTER.json'),'935 exact beforeafter')
for rel,sha in source.items():check(H(Path(plan['source'])/rel)==sha,'source '+rel)
first=J(q/'launcher-bad-cli-pin/raw-first/RESULT.json');check(first['pass'] is False and first['completed']==0,'original no-target launcherFAIL retained')
receipt={'review_pass':True,'checks':len(checks),'result_sha256':H(q/'raw-first/RESULT.json'),'report_sha256':H(d/'DELIVERY_VERIFICATION.json'),'source935_unchanged':True,'negative_reasons':expected,'scope':'Independent complete local delivery byte/mode/history and exact8 rejection reason audit.10 controls, actual v40-to-held8-to-v40 file rollback. No rerun, engine, Windows, remote download or Git publication claim. Original pre-target CLI typo retained; target commands executed once.','checks_detail':checks}
(P/'DELIVERY_RAW_REVIEW.json').write_text(json.dumps(receipt,indent=2)+'\n');print(json.dumps({k:v for k,v in receipt.items() if k!='checks_detail'}))
