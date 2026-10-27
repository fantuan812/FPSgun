from pathlib import Path
import json,hashlib,subprocess,os,time
p=Path(__file__).parent;planpath=p/'PACKED_ASSET_PLAN.json';h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();plan=json.loads(planpath.read_text());ph=h(planpath);pins=plan['pins'];src=Path(plan['source']);source=json.loads(Path(plan['source_map']).read_text());out=p/'packed-assets-first';assert not out.exists();out.mkdir()
def guard():return all(h(Path(n))==v for n,v in pins.items()) and all(h(src/n)==v for n,v in source.items()) and h(planpath)==ph
assert guard();env=dict(os.environ)
for k,n in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_DATA_HOME','data'),('XDG_CACHE_HOME','cache')]:
 (out/n).mkdir();env[k]=str(out/n)
(out/'empty').mkdir();t=time.monotonic();timed=False
cmd=['godot','--headless','--audio-driver','Dummy','--main-pack',plan['pck'],'--script',plan['script'],'--','--expected-imported',plan['baseline']]
try:r=subprocess.run(cmd,cwd=out/'empty',env=env,capture_output=True,timeout=180);a,b,rc=r.stdout,r.stderr,r.returncode
except subprocess.TimeoutExpired as e:a,b,rc=e.stdout or b'',e.stderr or b'',124;timed=True
(out/'stdout.raw').write_bytes(a);(out/'stderr.raw').write_bytes(b);(out/'native.exit').write_text(str(rc)+'\n');reports=[];errors=[]
for line in a.decode(errors='replace').splitlines():
 if line.startswith('{'):
  try:reports.append(json.loads(line))
  except ValueError as e:errors.append(str(e))
clean=not errors and not any(x in a+b for x in [b'SCRIPT ERROR',b'ERROR:',b'instances leaked',b'resources still in use']);semantic=len(reports)==1 and reports[0].get('pass') is True and reports[0].get('checks')==121 and reports[0].get('failures')==[];unchanged=guard();result={'pass':rc==0 and not timed and clean and semantic and unchanged,'native_exit':rc,'timeout':timed,'seconds':time.monotonic()-t,'reports':reports,'parse_errors':errors,'pins_and_source_unchanged':unchanged,'scope':plan['scope']};(out/'RESULT.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result));raise SystemExit(0 if result['pass'] else 1)
