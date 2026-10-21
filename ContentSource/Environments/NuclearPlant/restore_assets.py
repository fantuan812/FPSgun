"""Restore independent ZIP assets locally and verify exact original SHA-256; no downloads."""
from pathlib import Path
import hashlib,json,zipfile
R=Path(__file__).resolve().parent
def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()
for x in json.loads((R/'RESTORE_ASSETS.json').read_text())['assets']:
    p=R/x['restored_path']
    if p.is_file() and digest(p)==x['restored_sha256']:
        print('Verified existing',x['restored_path']);continue
    archive=R/x['archive']
    if digest(archive)!=x['archive_sha256']:raise RuntimeError('Archive hash mismatch: '+str(archive))
    with zipfile.ZipFile(archive) as z:
        if z.namelist()!=[x['zip_member']]:raise RuntimeError('Unexpected archive members: '+str(archive))
        data=z.read(x['zip_member'])
    if len(data)!=x['restored_bytes'] or hashlib.sha256(data).hexdigest()!=x['restored_sha256']:
        raise RuntimeError('Restored asset hash mismatch: '+str(p))
    p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(data);print('Restored',x['restored_path'])
print('All archived native scenes, exports and source drawings verified. Run python verify_delivery.py for the current complete delivery.')
