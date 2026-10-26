"""Offline staged-delivery checks; explicit local roots, no network or game launch."""
from pathlib import Path
import argparse, hashlib, json, os, shutil, subprocess, sys, zipfile

p = argparse.ArgumentParser()
for key in ('prep', 'recovery', 'base_pack', 'output'):
    p.add_argument('--' + key.replace('_', '-'), type=Path, required=True)
a = p.parse_args()
out = a.output.resolve(); out.mkdir(exist_ok=False)
helper = a.prep / 'BASE_restore_deliveries.py'
catalog = a.prep / 'CATALOG_DRAFT.json'
stage = a.prep / 'staging'
def sha(path):
    h = hashlib.sha256()
    with path.open('rb') as f:
        for block in iter(lambda: f.read(1048576), b''): h.update(block)
    return h.hexdigest()
assert sha(helper) == '3228782b92e9ec6573b7ba9842d950b3cb6c4dbe928fb3bdcb9a2b4f930b55ad'
c = json.loads(catalog.read_text()); base = json.loads((a.prep / 'BASE_CATALOG.json').read_text())
assert len(base['files']) == 52 and c['files'][:52] == base['files'] and len(c['files']) == 54
new = [r for r in c['files'] if r['version'] == 'v27']
assert {r['name'] for r in new} == {'MossCircuit.pck', 'READ_ME_v27.txt'}
pack_record = next(r for r in new if r['name'] == 'MossCircuit.pck')
cmd = [sys.executable, str(helper), '--version', 'v27', '--repo-root', str(stage), '--catalog', str(catalog)]
cases = []
def run(name, args, success):
    r = subprocess.run(args, capture_output=True, text=True)
    (out / (name + '.log')).write_text(r.stdout + r.stderr)
    assert (r.returncode == 0) == success, (name, r.stdout, r.stderr)
    cases.append({'case': name, 'exit': r.returncode, 'expected_success': success})
run('verify', cmd + ['--verify-only'], True)
restored = out / 'restored-v27'
run('restore', cmd + ['--output', str(restored)], True)
identities = {r['name']: {'size': (restored/r['name']).stat().st_size, 'sha256': sha(restored/r['name'])} for r in new}
assert all(identities[r['name']] == {'size': r['size'], 'sha256': r['sha256']} for r in new)
before = {x.name: sha(x) for x in restored.iterdir()}
run('no-overwrite', cmd + ['--output', str(restored)], False)
assert before == {x.name: sha(x) for x in restored.iterdir()}
for label, edit in [
    ('bad-whole-hash', lambda r: r.update(sha256='0'*64)),
    ('bad-chunk-hash', lambda r: r['storage']['chunks'][0].update(sha256='0'*64)),
    ('reordered-offset', lambda r: r['storage']['chunks'][0].update(offset=1)),
    ('unsafe-name', lambda r: r.update(name='../MossCircuit.pck')),
]:
    bad = json.loads(json.dumps(c)); edit(next(r for r in bad['files'] if r['version']=='v27' and r['name']=='MossCircuit.pck'))
    path = out / (label+'.json'); path.write_text(json.dumps(bad))
    run(label, [sys.executable, str(helper), '--version','v27','--repo-root',str(stage),'--catalog',str(path),'--output',str(out/label)], False)
    assert not list((out/label).rglob('MossCircuit.pck')) and not list((out/label).glob('.moss-restore-*'))
# Same accepted executable/notices, current v26 PCK. Hardlinked non-PCK files are never written.
assert sha(a.base_pack) == '59096e791e270250a7c6a314d741d7295100016863be2ba85455795c88017e33'
install = out/'manual-install'; install.mkdir()
mapping = {}
with zipfile.ZipFile(a.recovery/'accepted-v19-linux.zip') as z:
    assert z.testzip() is None
    for member in z.infolist():
        if member.is_dir(): continue
        name = Path(member.filename).name
        if name == 'MossCircuit.pck': continue
        data = z.read(member); canonical = a.recovery/name
        assert sha(canonical) == hashlib.sha256(data).hexdigest()
        os.link(canonical, install/name)
        mapping[name] = {'sha256': sha(canonical), 'size': len(data), 'mode': canonical.stat().st_mode & 511}
assert len(mapping) == 8
pack = install/'MossCircuit.pck'; shutil.copy2(a.base_pack, pack)
mapping[pack.name] = {'sha256': sha(pack), 'size': pack.stat().st_size, 'mode': pack.stat().st_mode & 511}
backup = install/'MossCircuit.pck.before-v27'; assert not backup.exists(); shutil.copy2(pack, backup)
assert backup.stat().st_ino != pack.stat().st_ino and sha(backup) == mapping[pack.name]['sha256']
shutil.copyfile(restored/'MossCircuit.pck', pack); assert sha(pack) == pack_record['sha256']
assert sha(backup) == mapping[pack.name]['sha256']
for name,r in mapping.items():
    if name != pack.name: assert {'sha256':sha(install/name),'size':(install/name).stat().st_size,'mode':(install/name).stat().st_mode & 511} == r
pack.rename(install/'MossCircuit.pck.retained-v27'); shutil.copy2(backup, pack)
assert all({'sha256':sha(install/n),'size':(install/n).stat().st_size,'mode':(install/n).stat().st_mode & 511} == r for n,r in mapping.items())
assert all(sha(a.recovery/n)==r['sha256'] for n,r in mapping.items() if n!='MossCircuit.pck')
report = {'scope':'Offline exact helper on staged v27 delivery; Linux manual v26 backup/update/rollback. Not remote publication or Windows execution.', 'helper_sha256':sha(helper),'catalog_sha256':sha(catalog),'old_52_rows_exact':True,'new_records':identities,'cases':cases,'original_members':9,'unchanged_non_pack_members':8,'rollback_exact_bytes_and_modes':True,'canonical_files_unchanged':True,'base_pack_sha256':sha(a.base_pack)}
(out/'VERIFICATION.json').write_text(json.dumps(report,indent=2)+'\n'); print(json.dumps(report,indent=2))
