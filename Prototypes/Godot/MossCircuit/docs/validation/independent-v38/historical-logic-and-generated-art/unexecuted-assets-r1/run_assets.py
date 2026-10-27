from pathlib import Path
import json,hashlib,subprocess,time,os
q=Path(__file__).resolve().parent;s=q/'source-first';author=Path('<WORKSPACE>/moss-v38-work');m=Path('<WORKSPACE>/moss-v38-prep/CORRECTED_INPUTS.json');h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();freeze=q/'ASSET_ORACLE_FREEZE.json';f=json.loads(freeze.read_text());assert h(m)==f['source_map_sha256'];source=json.loads(m.read_text());pins={str(q/n):v for n,v in f['files'].items()};pins.update({str(freeze):h(freeze),str(m):h(m),str(Path(__file__)):h(Path(__file__))})
assert all(h(Path(p))==v for p,v in pins.items());assert all(h(root/n)==v for root in [s,author] for n,v in source.items())
out=q/'source-assets';assert not out.exists();out.mkdir();(out/'PINS_BEFORE.json').write_text(json.dumps(pins,indent=2)+'\n');env=os.environ.copy()
for k,n in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_DATA_HOME','data'),('XDG_CACHE_HOME','cache')]:
 (out/n).mkdir();env[k]=str(out/n)
t=time.monotonic();timeout=False
try:
 p=subprocess.run(['godot','--headless','--audio-driver','Dummy','--path',str(s),'--script',str(q/'checks/independent_support_assets.gd')],capture_output=True,env=env,timeout=180);stdout,stderr,code=p.stdout,p.stderr,p.returncode
except subprocess.TimeoutExpired as e:stdout,stderr,code=e.stdout or b'',e.stderr or b'',124;timeout=True
(out/'stdout').write_bytes(stdout);(out/'stderr').write_bytes(stderr);text=(stdout+stderr).decode(errors='replace');reports=[];errors=[]
for line in stdout.decode(errors='replace').splitlines():
 if line.startswith('{'):
  try:reports.append(json.loads(line))
  except ValueError as e:errors.append(str(e))
clean=not errors and not any(z in text for z in ['ERROR:','instances leaked','resources still in use']);semantic=len(reports)==1 and reports[0].get('pass') is True and reports[0].get('failures')==[] and reports[0].get('checks',0)>0
changed={str(root):[n for n,v in source.items() if not (root/n).is_file() or h(root/n)!=v] for root in [s,author]};pinchanges=[p for p,v in pins.items() if not Path(p).is_file() or h(Path(p))!=v];(out/'PINS_AFTER.json').write_text(json.dumps({p:h(Path(p)) if Path(p).is_file() else None for p in pins},indent=2)+'\n')
x={'pass':code==0 and clean and semantic and not any(changed.values()) and not pinchanges,'native_exit':code,'seconds':round(time.monotonic()-t,3),'timeout':timeout,'clean':clean,'semantic':semantic,'reports':reports,'parse_errors':errors,'source_changes':changed,'pinchanges':pinchanges};(out/'RESULT.json').write_text(json.dumps(x,indent=2)+'\n');print(json.dumps(x),flush=True);raise SystemExit(0 if x['pass'] else 1)
