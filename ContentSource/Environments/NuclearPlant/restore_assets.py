from pathlib import Path
import hashlib,json,zipfile
R=Path(__file__).resolve().parent
for x in json.loads((R/'RESTORE_ASSETS.json').read_text())['assets']:
 p=R/x['restored_path']
 if p.is_file() and hashlib.sha256(p.read_bytes()).hexdigest()==x['restored_sha256']:
  print('Verified existing',x['restored_path']);continue
 a=R/x['archive']
 assert hashlib.sha256(a.read_bytes()).hexdigest()==x['archive_sha256'], 'Archive hash mismatch: '+str(a)
 with zipfile.ZipFile(a) as z:
  assert z.namelist()==[x['zip_member']], 'Unexpected archive members'
  data=z.read(x['zip_member'])
 assert len(data)==x['restored_bytes'] and hashlib.sha256(data).hexdigest()==x['restored_sha256'], 'Asset hash mismatch'
 p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(data);print('Restored',x['restored_path'])
print('All archived native scenes and interchange exports verified. Run python verify_delivery.py to verify the original full delivery.')
