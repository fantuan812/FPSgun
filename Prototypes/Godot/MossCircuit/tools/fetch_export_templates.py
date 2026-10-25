"""Download the pinned official archive and extract only desktop x86_64 templates.

Uses Python's standard library. Never installs globally or changes user settings.
The archive SHA256 and size are verified before extraction; existing mismatches
are not overwritten. The upstream URL/checksum are pinned in godot_templates.json.
"""
from pathlib import Path
from urllib.request import Request, urlopen
import argparse
import hashlib
import json
import shutil
import zipfile


def sha256(path):
    with path.open('rb') as file:
        return hashlib.file_digest(file, 'sha256').hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    manifest = json.loads(Path(__file__).with_name('godot_templates.json').read_text())
    output = args.output.resolve()
    project = Path(__file__).resolve().parents[1]
    if output == project or project in output.parents:
        parser.error('Template storage must be outside the project')
    output.mkdir(parents=True, exist_ok=True)
    archive = output / manifest['archive_name']
    if not archive.exists():
        partial = archive.with_suffix('.tpz.part')
        if partial.exists():
            parser.error('An incomplete download already exists; inspect it or choose a new output directory')
        if shutil.disk_usage(output).free < manifest['archive_size'] + 500_000_000:
            parser.error('Insufficient free space for the archive and selected desktop templates')
        with urlopen(Request(manifest['download_url'], headers={'User-Agent': 'MossCircuit-template-verifier'}), timeout=90) as response, partial.open('xb') as destination:
            if response.status != 200:
                raise RuntimeError('Unexpected download response')
            shutil.copyfileobj(response, destination, length=1024 * 1024)
        if partial.stat().st_size != manifest['archive_size'] or sha256(partial) != manifest['archive_sha256']:
            raise RuntimeError('Official archive checksum/size mismatch; file retained without extraction')
        partial.rename(archive)
    if archive.stat().st_size != manifest['archive_size'] or sha256(archive) != manifest['archive_sha256']:
        raise RuntimeError('Existing archive does not match pinned official release')
    templates = output / manifest['version']
    templates.mkdir(exist_ok=True)
    with zipfile.ZipFile(archive) as bundle:
        for item in manifest['files']:
            name = item['name']
            if Path(name).name != name:
                raise RuntimeError('Invalid manifest filename')
            data = bundle.read('templates/' + name)
            if len(data) != item['bytes'] or hashlib.sha256(data).hexdigest() != item['sha256']:
                raise RuntimeError('Selected template checksum mismatch: ' + name)
            target = templates / name
            if target.exists() and target.read_bytes() != data:
                raise RuntimeError('Refusing to overwrite a different template: ' + name)
            if not target.exists():
                target.write_bytes(data)
            if name.startswith('linux_'):
                target.chmod(0o755)
    print('PASS: pinned archive and selected desktop templates verified; version', manifest['version'])


if __name__ == '__main__':
    main()
