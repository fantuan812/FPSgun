from pathlib import Path
import subprocess,json,hashlib,time,os
q=Path(__file__).resolve().parent;s=q/'source-first';m=Path('<WORKSPACE>/moss-v38-prep/CORRECTED_INPUTS.json');h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();f=json.loads((q/'DEATH_DISPOSAL_FREEZE.json').read_text());assert h(m)==f['source_map_sha256'];pins=json.loads(m.read_text());script=q/'checks/independent_support_death_disposal.gd';assert h(script)==f['script_sha256'];assert all(h(s/n)==v for n,v in pins.items());out=q/'death-disposal';assert not out.exists();out.mkdir();env=os.environ.copy()
for k,n in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_DATA_HOME','data'),('XDG_CACHE_HOME','cache')]:
 (out/n).mkdir();env[k]=str(out/n)
recordpins={str(m):h(m),str(script):h(script),str(q/'DEATH_DISPOSAL_FREEZE.json'):h(q/'DEATH_DISPOSAL_FREEZE.json'),str(Path(__file__)):h(Path(__file__))};(out/'PINS_BEFORE.json').write_text(json.dumps(recordpins,indent=2)+'\n');t=time.monotonic();timeout=False
try:
 p=subprocess.run(['godot','--headless','--audio-driver','Dummy','--path',str(s),'--script',str(script)],env=env,capture_output=True,timeout=180);stdout,stderr,code=p.stdout,p.stderr,p.returncode
except subprocess.TimeoutExpired as e:stdout,stderr,code=e.stdout or b'',e.stderr or b'',124;timeout=True
(out/'stdout').write_bytes(stdout);(out/'stderr').write_bytes(stderr);reports=[];helpers=[];errors=[]
for line in stdout.decode(errors='replace').splitlines():
 try:
  if line.startswith('{'):reports.append(json.loads(line))
  elif line.startswith('TEST_AUDIO_TEARDOWN '):helpers.append(json.loads(line.split(' ',1)[1]))
 except ValueError as e:errors.append(str(e))
clean=not errors and not any(z in (stdout+stderr).decode(errors='replace') for z in ['ERROR:','instances leaked','resources still in use']);sem=len(reports)==1 and reports[0].get('pass') is True and reports[0].get('failures')==[];helper=len(helpers)==1 and helpers[0].get('complete') is True and helpers[0].get('capture_removed') is True and not helpers[0].get('prepare_errors');changes=[n for n,v in pins.items() if h(s/n)!=v];pinchanges=[n for n,v in recordpins.items() if h(Path(n))!=v]
x={'pass':code==0 and clean and sem and helper and not changes and not pinchanges,'native_exit':code,'timeout':timeout,'seconds':round(time.monotonic()-t,3),'clean':clean,'semantic':sem,'helper_ok':helper,'reports':reports,'helpers':helpers,'source_changes':changes,'pinchanges':pinchanges};(out/'RESULT.json').write_text(json.dumps(x,indent=2)+'\n');print(json.dumps(x),flush=True);raise SystemExit(0 if x['pass'] else 1)
