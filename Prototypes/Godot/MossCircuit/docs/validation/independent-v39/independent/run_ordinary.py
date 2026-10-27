from pathlib import Path
import json,hashlib,subprocess,os,time,sys
q=Path(__file__).parent;plan=json.loads((q/'ORDINARY_FREEZE.json').read_text());h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();ph=h(q/'ORDINARY_FREEZE.json');name=sys.argv[1];assert name in ['arena','rooms'];out=q/('ordinary-'+name);assert not(out/'sidecar-runtime.log').exists();root=Path(plan['source']);expected=json.loads(Path(plan['source_map']).read_text())
def snap():return {str(p.relative_to(root)):h(p) for p in root.rglob('*') if p.is_file() and '.godot' not in p.relative_to(root).parts}
def guards():return h(q/'ORDINARY_FREEZE.json')==ph and all(h(Path(p))==v for p,v in plan['pins'].items()) and snap()==expected
assert guards();assert json.loads(Path(plan['native_mechanics_result']).read_text())['pass_gate'] is True;assert json.loads(Path(plan['native_ui_review']).read_text())['pass'] is True;assert json.loads(Path(plan['native_mechanics_review']).read_text())['pass'] is True
assert os.environ.get('DISPLAY') or os.environ.get('WAYLAND_DISPLAY');reader=out/'empty-reader';reader.mkdir();env=dict(os.environ)
for k,n in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_DATA_HOME','data'),('XDG_CACHE_HOME','cache')]:
 p=out/'profile'/n;p.mkdir(parents=True);env[k]=str(p)
cmd=[plan['elf'],'--audio-driver','Dummy','--resolution','960x540','--position','0,60'];(out/'COMMAND.json').write_text(json.dumps({'cmd':cmd,'scope':plan['runs'][name],'no_gameplay_injection':True},indent=2)+'\n');start=time.monotonic();rc=125;error=None
try:
 with (out/'sidecar-runtime.log').open('wb') as log:z=subprocess.run(cmd,cwd=reader,env=env,stdout=log,stderr=subprocess.STDOUT);rc=z.returncode
except Exception as e:error=repr(e)
finally:
 (out/'sidecar-runtime.exit').write_text(str(rc)+'\n');after=False
 try:after=guards()
 except Exception as e:error=repr(e)
 raw=(out/'sidecar-runtime.log').read_text(errors='replace') if (out/'sidecar-runtime.log').exists() else '';bad=[x for x in ['SCRIPT ERROR','Parse Error','ERROR:','instances leaked','resources still in use'] if x in raw];result={'native_exit':rc,'seconds':time.monotonic()-start,'error':error,'strict_bad_tags':bad,'pins_and_source_unchanged':after,'process_gate_pass':rc==0 and error is None and not bad and after,'scope':'Normal release ELF adjacent exactPCK only. User-visible gameplay stop/acquisition/action evidence reviewed separately; process exit alone does not establish ordinary objective.'};(out/'PROCESS_RESULT.json').write_text(json.dumps(result,indent=2)+'\n')
raise SystemExit(0 if result['process_gate_pass'] else 1)
