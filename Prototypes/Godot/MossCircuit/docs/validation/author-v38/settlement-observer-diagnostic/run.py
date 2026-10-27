from pathlib import Path
import json,hashlib,subprocess,os,time
r=Path('workspace/shared');d=Path(__file__).parent;s=r/'moss-v38-final';h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();plan=json.loads((d/'PLAN.json').read_text());m=r/'moss-v38-final-prep/FINAL_INPUTS.json';assert h(m)==plan['source_map_sha256'];source=json.loads(m.read_text());assert all(h(s/n)==v for n,v in source.items());assert h(d/'instrumented.gd')==plan['instrumented_sha256'];pins={str(z):h(z) for z in [d/'PLAN.json',d/'instrumented.gd',d/'run.py',m]};out=d/'results';assert not out.exists();out.mkdir();env=os.environ.copy()
for k,n in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_DATA_HOME','data'),('XDG_CACHE_HOME','cache')]:
 (out/n).mkdir();env[k]=str(out/n)
(out/'PINS_BEFORE.json').write_text(json.dumps(pins,indent=2)+'\n');t=time.monotonic();timeout=False
try:
 p=subprocess.run(['godot','--headless','--audio-driver','Dummy','--path',str(s),'--script',str(d/'instrumented.gd'),'--',str(out/'original-report.json')],env=env,capture_output=True,timeout=180);stdout,stderr,code=p.stdout,p.stderr,p.returncode
except subprocess.TimeoutExpired as e:stdout,stderr,code=e.stdout or b'',e.stderr or b'',124;timeout=True
(out/'stdout').write_bytes(stdout);(out/'stderr').write_bytes(stderr);reports=[];timings=[];helpers=[];parse=[]
for line in stdout.decode(errors='replace').splitlines():
 try:
  if line.startswith('{'):reports.append(json.loads(line))
  elif line.startswith('SETTLEMENT_TIMING '):timings.append(json.loads(line.split(' ',1)[1]))
  elif line.startswith('TEST_AUDIO_TEARDOWN '):helpers.append(json.loads(line.split(' ',1)[1]))
 except ValueError as e:parse.append(str(e))
changed=[n for n,v in source.items() if h(s/n)!=v];pinchanges=[n for n,v in pins.items() if h(Path(n))!=v];clean=not parse and not any(z in (stdout+stderr).decode(errors='replace') for z in ['ERROR:','instances leaked','resources still in use'])
x={'status':'DIAGNOSTIC_ONLY_NOT_ACCEPTANCE_RETRY','native_exit':code,'seconds':round(time.monotonic()-t,3),'timeout':timeout,'clean':clean,'reports':reports,'timings':timings,'helpers':helpers,'parse_errors':parse,'source_changes':changed,'pinchanges':pinchanges};(out/'RESULT.json').write_text(json.dumps(x,indent=2)+'\n');print(json.dumps({k:v for k,v in x.items() if k not in ['timings','helpers']}),flush=True);raise SystemExit(code)
