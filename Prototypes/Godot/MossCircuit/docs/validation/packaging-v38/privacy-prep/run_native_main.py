from pathlib import Path
import hashlib,json,os,subprocess,time
p=Path(__file__).parent;planpath=p/'NATIVE_MAIN_PLAN.json';plan=json.loads(planpath.read_text());h=lambda x:hashlib.sha256(Path(x).read_bytes()).hexdigest();ph=h(planpath);out=p/'native-main-first';assert not out.exists();assert os.environ.get('DISPLAY') or os.environ.get('WAYLAND_DISPLAY'),'native display required';out.mkdir()
source=json.loads(Path(plan['source_map']).read_text());src=Path(plan['source'])
def guard():return h(planpath)==ph and all(h(n)==v for n,v in plan['pins'].items()) and all(h(src/n)==v for n,v in source.items())
assert guard() and json.loads((p/'packed-assets-first/RESULT.json').read_text())['pass'];env=dict(os.environ)
for k,n in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_DATA_HOME','data'),('XDG_CACHE_HOME','cache')]:
 (out/n).mkdir();env[k]=str(out/n)
(out/'empty').mkdir();t=time.monotonic();timed=False
try:r=subprocess.run(plan['command'],cwd=out/'empty',env=env,capture_output=True,timeout=180);a,b,rc=r.stdout,r.stderr,r.returncode
except subprocess.TimeoutExpired as e:a,b,rc=e.stdout or b'',e.stderr or b'',124;timed=True
(out/'stdout.raw').write_bytes(a);(out/'stderr.raw').write_bytes(b);(out/'native.exit').write_text(str(rc)+'\n');clean=not any(x in a+b for x in [b'SCRIPT ERROR',b'ERROR:',b'instances leaked',b'resources still in use']);unchanged=guard();res={'pass':rc==0 and not timed and clean and unchanged,'native_exit':rc,'timeout':timed,'seconds':time.monotonic()-t,'clean':clean,'pins_and_787_unchanged':unchanged,'scope':plan['scope'],'display_present':bool(os.environ.get('DISPLAY') or os.environ.get('WAYLAND_DISPLAY'))};(out/'RESULT.json').write_text(json.dumps(res,indent=2)+'\n');print(json.dumps(res));raise SystemExit(0 if res['pass'] else 1)
