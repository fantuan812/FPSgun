"""Cold, isolated desktop exports with resource parity checks; no signing credentials.

Build output must be a new directory outside the source project. Only Python's
standard library and the pinned Godot editor/templates are required. Windows is
inspected as an artifact; this script never claims Windows runtime acceptance.
"""
from pathlib import Path
import argparse
import hashlib
import json
import os
import shutil
import struct
import subprocess


def sha256(path):
    with path.open('rb') as file:
        return hashlib.file_digest(file, 'sha256').hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--project', type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument('--templates', type=Path, required=True, help='Verified directory containing version.txt and desktop templates')
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--godot', default='godot')
    args = parser.parse_args()
    source, templates, output = args.project.resolve(), args.templates.resolve(), args.output.resolve()
    if output == source or source in output.parents:
        parser.error('Output must be outside the source project')
    if output.exists():
        parser.error('Output already exists; choose a new directory (no automatic deletion/overwrite)')
    manifest = json.loads((source / 'tools/godot_templates.json').read_text())
    for item in manifest['files']:
        path = templates / item['name']
        if not path.is_file() or path.stat().st_size != item['bytes'] or sha256(path) != item['sha256']:
            parser.error('Template missing or checksum mismatch: ' + item['name'])
    if (templates / 'version.txt').read_text().strip() != manifest['version']:
        parser.error('Template version mismatch')
    output.mkdir(parents=True)
    env = dict(os.environ)
    for name in list(env):
        if name == 'GODOT_SCRIPT_ENCRYPTION_KEY' or name.startswith('GODOT_WINDOWS_CODESIGN_'):
            env.pop(name)
    for key, directory in {'HOME': 'home', 'XDG_CONFIG_HOME': 'config', 'XDG_DATA_HOME': 'data', 'XDG_CACHE_HOME': 'cache'}.items():
        path = output / directory
        path.mkdir()
        env[key] = str(path)
    template_target = output / 'data/godot/export_templates' / manifest['version']
    template_target.mkdir(parents=True)
    for item in manifest['files']:
        shutil.copy2(templates / item['name'], template_target / item['name'])
    stage = output / 'project'
    shutil.copytree(source, stage, ignore=shutil.ignore_patterns('.godot', '.git', '__pycache__', '.env', '.env.*'))
    logs = output / 'logs'; logs.mkdir()
    records = []

    def run(label, command, cwd=output, timeout=240):
        result = subprocess.run(command, cwd=cwd, env=env, capture_output=True, text=True, timeout=timeout)
        log = result.stdout + result.stderr
        (logs / (label + '.log')).write_text(log)
        record = {'step': label, 'exit': result.returncode, 'engine_error': 'ERROR:' in log, 'pass': result.returncode == 0 and 'ERROR:' not in log}
        records.append(record)
        (output / 'steps.json').write_text(json.dumps(records, indent=2) + '\n')
        print(json.dumps(record), flush=True)
        if not record['pass']:
            raise RuntimeError('Build verification failed: ' + label)
        return log

    version = run('engine-version', [args.godot, '--headless', '--version'])
    if not version.strip().startswith(manifest['version'] + '.'):
        raise RuntimeError('Editor version must match pinned templates')
    run('cold-import', [args.godot, '--headless', '--path', str(stage), '--editor', '--import', '--quit'])
    binaries = {}
    for platform, preset, filename in [('linux', 'Linux x86_64', 'MossCircuit.x86_64'), ('windows', 'Windows x86_64', 'MossCircuit.exe')]:
        folder = output / platform; folder.mkdir()
        binary = folder / filename; binaries[platform] = binary
        run(platform + '-export', [args.godot, '--headless', '--path', str(stage), '--export-release', preset, str(binary)])
    linux = binaries['linux'].read_bytes(); windows = binaries['windows'].read_bytes()
    if linux[:4] != b'\x7fELF' or linux[4] != 2 or struct.unpack_from('<H', linux, 18)[0] != 62:
        raise RuntimeError('Expected Linux x86_64 ELF')
    pe = struct.unpack_from('<I', windows, 0x3c)[0]
    if windows[:2] != b'MZ' or windows[pe:pe + 4] != b'PE\0\0' or struct.unpack_from('<H', windows, pe + 4)[0] != 0x8664:
        raise RuntimeError('Expected Windows x86_64 PE')
    for platform, template_name in [('linux', 'linux_release.x86_64'), ('windows', 'windows_release_x86_64.exe')]:
        expected_binary = next(x for x in manifest['files'] if x['name'] == template_name)
        if sha256(binaries[platform]) != expected_binary['sha256']:
            raise RuntimeError('Unsigned external-PCK executable differs from verified template')
    pack = output / 'linux/MossCircuit.pck'
    if sha256(pack) != sha256(output / 'windows/MossCircuit.pck'):
        raise RuntimeError('Cross-platform game resource packs differ')
    exact, images = {}, {}
    for folder in ('scripts', 'ui', 'data', 'assets'):
        for path in (stage / folder).rglob('*'):
            if not path.is_file(): continue
            relative = str(path.relative_to(stage))
            if relative == 'ui/test_ui.gd': continue
            if path.suffix in ('.gd', '.json'): exact[relative] = sha256(path)
            if path.suffix == '.png': images[relative] = {}
    exact['art_source/alpha_bounds.json'] = sha256(stage / 'art_source/alpha_bounds.json')
    expected = output / 'expected-resources.json'
    expected.write_text(json.dumps({'exact_files': exact, 'images': images}, indent=2) + '\n')
    fingerprint = output / 'source-imported-fingerprints.json'
    run('source-fingerprint', [args.godot, '--headless', '--path', str(stage), '--script', 'res://tools/export_source_fingerprint.gd', '--', str(expected), str(fingerprint)])
    reader = output / 'empty-reader-directory'; reader.mkdir()
    run('packed-resources', [args.godot, '--headless', '--main-pack', str(pack), '--script', str(stage / 'tools/verify_export_pack.gd'), '--', str(fingerprint), str(output / 'packed-resource-report.json')], cwd=reader)
    run('native-linux-startup', [str(binaries['linux']), '--headless', '--quit-after', '30'], cwd=binaries['linux'].parent)
    licenses = output / 'licenses'; licenses.mkdir()
    run('licenses', [args.godot, '--headless', '--path', str(stage), '--script', 'res://tools/export_licenses.gd', '--', str(licenses)])
    for platform in ('linux', 'windows'):
        for file in licenses.iterdir(): shutil.copy2(file, output / platform / file.name)
        (output / platform / 'README.txt').write_text('MOSS CIRCUIT — unsigned desktop prototype\n\nExtract all files together. Keep MossCircuit.pck beside the executable.\nLinux: run ./MossCircuit.x86_64 (restore its executable bit if your extractor removed it).\nWindows: run MossCircuit.exe; this build was artifact-inspected, NOT Windows-runtime tested.\n\nMove: WASD/arrows. Dash: Space. Pause: Esc. Build: I.\nEngine and third-party license notices accompany this package.\nNo installer, signing certificate, telemetry setup or system settings changes are included.\n')
    files = []
    for platform in ('linux', 'windows'):
        for path in sorted((output / platform).iterdir()):
            files.append({'path': str(path.relative_to(output)), 'bytes': path.stat().st_size, 'sha256': sha256(path), 'mode': oct(path.stat().st_mode & 0o777)})
    result = {'version': manifest['version'], 'template_archive_sha256': manifest['archive_sha256'], 'cold_import': True, 'steps': records, 'files': files, 'windows_runtime_tested': False, 'native_gui_tested': False, 'scope': 'Cold exports, exact dynamic-data/imported-pixel parity and native Linux headless startup; GUI and Windows runtime are separate acceptance gates.'}
    (output / 'BUILD_REPORT.json').write_text(json.dumps(result, indent=2) + '\n')
    print('PASS: desktop exports and packed-resource checks; GUI acceptance remains separate', flush=True)


if __name__ == '__main__':
    main()
