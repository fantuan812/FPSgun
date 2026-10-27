from pathlib import Path
import hashlib,json,subprocess,time,os
from PIL import Image
R=Path('evidence-workspace/moss-equipment-atlas-svg-candidate');O=Path(__file__).resolve().parent
plan_bytes=(O/'FRESH_PLAN.json').read_bytes();plan_hash=hashlib.sha256(plan_bytes).hexdigest();freeze=json.loads(plan_bytes);out=O/'fresh-first';assert not out.exists();out.mkdir()
def h(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def guard():
 assert h(O/'FRESH_PLAN.json')==plan_hash
 actual={str(p.relative_to(R)):h(p) for p in R.rglob('*') if p.is_file() and '__pycache__' not in p.parts}
 assert actual==freeze['candidate_inputs']
 for p,s in freeze['execution_inputs'].items():assert h(Path(p))==s
start=time.time();error=None;native=None
try:
 guard();env=os.environ.copy();env['INKSCAPE_PROFILE_DIR']=str(out/'isolated-profile')
 c=subprocess.run(['inkscape',str(R/'art_source/equipment_atlas_editable.svg'),'--export-type=png','--export-png-antialias=0','--export-filename='+str(out/'atlas.png')],stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=180,env=env)
 native=c.returncode;(out/'stdout.raw').write_bytes(c.stdout);(out/'stderr.raw').write_bytes(c.stderr);(out/'native.exit').write_text(str(native)+'\n');assert native==0
 assert not any(x in c.stderr.lower() for x in [b'error',b'critical',b'failed'])
 assert (out/'atlas.png').read_bytes()==(R/'assets/items/equipment_atlas_editable.png').read_bytes()
 im=Image.open(out/'atlas.png').convert('RGBA');assert im.size==(256,256)
 layout=json.loads((R/'layout.json').read_text());cells=[]
 for r in layout['icons']:
  x,y,w,hh=r['rect'];a=im.crop((x,y,x+w,y+hh));b=Image.open(R/r['reference_runtime_png']).convert('RGBA');assert a.size==b.size and a.tobytes()==b.tobytes();cells.append(r['id'])
 assert len(cells)==16
except subprocess.TimeoutExpired as e:
 error=repr(e);(out/"stdout.raw").write_bytes(e.stdout or b"");(out/"stderr.raw").write_bytes(e.stderr or b"");(out/"timeout.json").write_text(json.dumps({"timeout_seconds":180,"native_exit":None})+"\n")
except BaseException as e:error=repr(e)
after=None
try:guard()
except BaseException as e:after=repr(e)
res={'pass':error is None and after is None,'native_exit':native,'error':error,'after_guard_error':after,'seconds':time.time()-start,'scope':'One independently rendered atlas; all16 cell identities, not runtime/native acceptance'}
(out/'RESULT.json').write_text(json.dumps(res,indent=2)+'\n');print(json.dumps(res));raise SystemExit(0 if res['pass'] else 1)
