#!/usr/bin/env python3
import hashlib,json,pathlib,subprocess,time,sys,os
ROOT=pathlib.Path(__file__).parent
HARNESS=ROOT/'B-harness'
DEST=ROOT/'B-evidence'/'author-r1'
if DEST.exists():raise SystemExit('Refusing overwrite/retry of retained run')
DEST.mkdir()
def snapshot():
 return {str(p.relative_to(HARNESS)):hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(HARNESS.rglob('*')) if p.is_file() and '.godot' not in p.parts and p.suffix in ['.gd','.godot','.json']}
generated_before={str(p.relative_to(HARNESS)):hashlib.sha256(p.read_bytes()).hexdigest() for p in HARNESS.rglob('*.uid')}
(DEST/'runner-pin.json').write_text(json.dumps({'sha256':hashlib.sha256(pathlib.Path(__file__).read_bytes()).hexdigest()},indent=2)+'\n')
before=snapshot();(DEST/'inputs-before.json').write_text(json.dumps(before,indent=2)+'\n')
cmd=['/usr/local/bin/godot','--headless','--path',str(HARNESS),'--script','res://tests/test_build_items_runtime.gd']
env=os.environ.copy()
for key,folder in [('HOME','home'),('XDG_DATA_HOME','data'),('XDG_CACHE_HOME','cache'),('XDG_CONFIG_HOME','config')]:
 path=ROOT/'B-engine-user'/folder;path.mkdir(parents=True,exist_ok=True);env[key]=str(path)
(DEST/'environment.json').write_text(json.dumps({key:env[key] for key in ['HOME','XDG_DATA_HOME','XDG_CACHE_HOME','XDG_CONFIG_HOME']},indent=2)+'\n')
start=time.monotonic();timeout=False
try:
 p=subprocess.run(cmd,stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=180,env=env)
 code=p.returncode;out=p.stdout;err=p.stderr
except subprocess.TimeoutExpired as e:
 code=None;timeout=True;out=e.stdout or b'';err=e.stderr or b''
(DEST/'stdout.raw').write_bytes(out);(DEST/'stderr.raw').write_bytes(err)
generated_after={str(p.relative_to(HARNESS)):hashlib.sha256(p.read_bytes()).hexdigest() for p in HARNESS.rglob('*.uid')}
(DEST/'generated-uids.json').write_text(json.dumps({'before':generated_before,'after':generated_after,'new':{k:v for k,v in generated_after.items() if k not in generated_before}},indent=2)+'\n')
after=snapshot();(DEST/'inputs-after.json').write_text(json.dumps(after,indent=2)+'\n')
text=(out+err).decode(errors='replace');records=[]
for line in out.decode(errors='replace').splitlines():
 try:r=json.loads(line)
 except ValueError:continue
 if isinstance(r,dict) and 'B_author_checks' in r:records.append(r)
errors=[tag for tag in ['SCRIPT ERROR','ERROR:','Parse Error','WARNING:','ObjectDB instances leaked','resources still in use'] if tag in text]
passed=code==0 and not err and not timeout and before==after and not errors and len(records)==1 and records[0].get('B_author_checks',0)>0 and records[0].get('failures')==[]
result={'status':'PASS' if passed else 'FAIL','command':cmd,'timeout_seconds':180,'timed_out':timeout,'exit':code,'elapsed':time.monotonic()-start,'input_identical':before==after,'strict_error_tags':errors,'records':records}
(DEST/'result.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result));sys.exit(0 if passed else 1)
