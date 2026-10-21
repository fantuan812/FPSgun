from pathlib import Path
import hashlib,json,sys
R=Path(__file__).resolve().parent
m=json.loads((R/'CUMULATIVE_MANIFEST.json').read_text());bad=[]
for x in m['files']:
 p=R/x['path']
 if not p.is_file() or hashlib.sha256(p.read_bytes()).hexdigest()!=x['sha256']:bad.append(x['path'])
print(json.dumps({'pass':not bad,'checked':len(m['files']),'failures':bad},indent=2))
sys.exit(bool(bad))
