"""One ordinary manual Rooms/Rivet attempt. No input, seed, or script injection."""
from pathlib import Path
import argparse,json,hashlib,subprocess,os,time,sys,traceback
q=Path(__file__).resolve().parent;ap=argparse.ArgumentParser();ap.add_argument('--plan-sha256',required=True);approved=ap.parse_args().plan_sha256
pp=q/'PLAN.json';h=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
assert h(pp)==approved
plan=json.loads(pp.read_text());assert plan['status']=='FROZEN_READY'
assert isinstance(plan['preconditions'],list) and len(plan['preconditions'])==2 and all(isinstance(x,dict) for x in plan['preconditions'])
out=Path(plan['output']);assert not out.exists(),'REFUSE any previous attempt artifacts'
root=Path(plan['source']);expected=json.loads(Path(plan['source_map']).read_text());assert len(expected)==926
elf=Path(plan['elf']);pack=elf.with_name('MossCircuit.pck');assert str(pack)==plan['pck']
def snap():
 result={}
 for p in root.rglob('*'):
  rel=p.relative_to(root)
  if '.godot' in rel.parts:continue
  assert not p.is_symlink(),str(p)
  if p.is_file():result[str(rel)]=h(p)
 return result
def guard():
 assert h(pp)==approved
 for p,v in plan['pins'].items():assert h(p)==v,p
 assert h(pack)==plan['pck_sha256'] and pack.stat().st_size==42300876
 assert snap()==expected
 for item in plan['preconditions']:
  assert isinstance(item['path'],str) and item['path'] in plan['pins']
  data=json.loads(Path(item['path']).read_text());assert isinstance(data,dict)
  assert item['required_true'] and all(data.get(key) is True for key in item['required_true'])
guard();assert os.environ.get('DISPLAY') or os.environ.get('WAYLAND_DISPLAY')
out.mkdir();reader=out/'empty-reader';reader.mkdir();env=dict(os.environ)
for k,n in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_DATA_HOME','data'),('XDG_CACHE_HOME','cache')]:
 p=out/'profile'/n;p.mkdir(parents=True);env[k]=str(p)
cmd=[str(elf),'--audio-driver','Dummy','--resolution','960x540','--position','0,60'];(out/'COMMAND.json').write_text(json.dumps({'cmd':cmd,'scope':plan['attempt'],'no_gameplay_injection':True},indent=2)+'\n')
start=time.monotonic();rc=None;errors=[];after=False
try:
 with (out/'sidecar-runtime.log').open('xb') as log:
  proc=subprocess.run(cmd,cwd=reader,env=env,stdout=log,stderr=subprocess.STDOUT);rc=proc.returncode
except Exception:errors.append(traceback.format_exc())
finally:
 (out/'sidecar-runtime.exit').write_text(str(rc)+'\n' if rc is not None else 'NOT_COMPLETED\n')
 try:guard();after=True
 except Exception:errors.append(traceback.format_exc())
 raw=(out/'sidecar-runtime.log').read_text(errors='replace') if (out/'sidecar-runtime.log').exists() else ''
 bad=[x for x in ['SCRIPT ERROR','Parse Error','ERROR:','WARNING:','instances leaked','resources still in use'] if x in raw]
 result={'native_exit':rc,'seconds':time.monotonic()-start,'errors':errors,'strict_bad_tags':bad,'pins_and_source_unchanged':after,'process_gate_pass':rc==0 and not errors and not bad and after,'scope':'Real original ELF adjacent exact combined6743 PCK, one manual default-seed Rooms/Rivet attempt. No injection/restart/refresh. Goal/acquisition/mechanic observation separately reviewed; process exit alone proves no gameplay objective.'}
 (out/'PROCESS_RESULT.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result),flush=True)
sys.exit(0 if result['process_gate_pass'] else 1)
