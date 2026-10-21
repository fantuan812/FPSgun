"""Verify current restored delivery hashes, or exact retained Batch01–06 historical bytes."""
from pathlib import Path
import argparse,hashlib,json,sys
R=Path(__file__).resolve().parent
p=argparse.ArgumentParser(description=__doc__);p.add_argument('--baseline',action='store_true');a=p.parse_args()
snap=R/'RepositoryVerification/Batch01-06_RootSnapshot'
manifest=(snap if a.baseline else R)/'CUMULATIVE_MANIFEST.json'
m=json.loads(manifest.read_text());bad=[]
for x in m['files']:
    path=R/x['path']
    if a.baseline and (snap/x['path']).is_file():path=snap/x['path']
    if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest()!=x['sha256']:bad.append(x['path'])
print(json.dumps({'pass':not bad,'checked':len(m['files']),'scope':'historical baseline bytes with retained root snapshots; NOT rerun geometric acceptance' if a.baseline else 'current complete restored delivery bytes; NOT engine acceptance','failures':bad},indent=2))
sys.exit(bool(bad))
