from pathlib import Path
import subprocess,json,hashlib,os,time
q=Path(__file__).parent;p=q/'COLD_PLAN.json';h=lambda f:hashlib.sha256(f.read_bytes()).hexdigest();ph=h(p);plan=json.loads(p.read_text());root=Path(plan['source']);old=Path(plan['r3_source']);expected=json.loads(Path(plan['input_map']).read_text());oldmap=json.loads(Path(plan['r3_map']).read_text())
def snap(r):return {str(f.relative_to(r)):h(f) for f in sorted(r.rglob('*')) if f.is_file() and '.godot' not in f.relative_to(r).parts}
def pins():return h(p)==ph and all(Path(f).is_file() and h(Path(f))==v for f,v in plan['pins'].items())
assert plan['status']=='FROZEN_FOR_QA_WINDOW' and pins() and snap(root)==expected and snap(old)==oldmap and not(root/'.godot').exists()
out=q/'cold-first';assert not out.exists();out.mkdir();env=dict(os.environ)
for k,n in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_DATA_HOME','data'),('XDG_CACHE_HOME','cache')]:
 (out/n).mkdir();env[k]=str(out/n)
t=time.monotonic();rc=125;timed=False;a=b=b'';error=None
try:
 try:
  z=subprocess.run(plan['command'],capture_output=True,env=env,timeout=180);a,b,rc=z.stdout,z.stderr,z.returncode
 except subprocess.TimeoutExpired as e:a,b,rc=e.stdout or b'',e.stderr or b'',124;timed=True
except Exception as e:error=repr(e)
finally:
 (out/'cold.stdout').write_bytes(a);(out/'cold.stderr').write_bytes(b);(out/'cold.exit').write_text(str(rc)+'\n');post=snap(root);(out/'POST_INPUTS.json').write_text(json.dumps(post,indent=2,sort_keys=True)+'\n')
 changed=[k for k,v in expected.items() if post.get(k)!=v];added=sorted(post.keys()-expected.keys());clean=not any(s in (a+b).decode(errors='replace') for s in ['SCRIPT ERROR','Parse Error','ERROR:','instances leaked','resources still in use'])
 result={'pass_gate':rc==0 and not timed and error is None and clean and not changed and added==sorted(plan['exact_uid_additions']) and len(post)==869 and pins() and snap(old)==oldmap,'native_exit':rc,'timeout':timed,'seconds':time.monotonic()-t,'error':error,'clean':clean,'changed':changed,'added':added,'post_count':len(post),'all_pins_unchanged':pins(),'original_r3_unchanged':snap(old)==oldmap}
 (out/'RESULT.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result),flush=True)
raise SystemExit(0 if result['pass_gate'] else 1)
