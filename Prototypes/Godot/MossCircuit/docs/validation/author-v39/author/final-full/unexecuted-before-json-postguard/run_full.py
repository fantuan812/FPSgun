from pathlib import Path
import subprocess,json,hashlib,time
q=Path(__file__).parent;p=q/'FULL_PLAN.json';h=lambda f:hashlib.sha256(f.read_bytes()).hexdigest();ph=h(p);plan=json.loads(p.read_text());root=Path(plan['source']);old=Path(plan['r3_source']);expected=json.loads(Path(plan['input_map']).read_text());oldmap=json.loads(Path(plan['r3_map']).read_text())
def snap(r):return {str(f.relative_to(r)):h(f) for f in sorted(r.rglob('*')) if f.is_file() and '.godot' not in f.relative_to(r).parts}
def pins():return h(p)==ph and all(Path(f).is_file() and h(Path(f))==v for f,v in plan['pins'].items())
assert plan['status']=='FROZEN_AFTER_COLD_REVIEW' and len(expected)==869 and pins() and snap(root)==expected and snap(old)==oldmap
out=q/'full-first';assert not out.exists();out.mkdir();target=out/'aggregate';start=time.monotonic();rc=125;error=None
try:
 with (out/'runner.stdout').open('wb') as a,(out/'runner.stderr').open('wb') as b:
  z=subprocess.run(plan['command'],stdout=a,stderr=b);rc=z.returncode
except Exception as e:error=repr(e)
finally:
 (out/'native.exit').write_text(str(rc)+'\n');post=snap(root);(out/'POST_INPUTS.json').write_text(json.dumps(post,indent=2,sort_keys=True)+'\n');summary={};rows=[]
 if (target/'result.json').exists():summary=json.loads((target/'result.json').read_text())
 if (target/'summary.json').exists():rows=json.loads((target/'summary.json').read_text())
 expected_names=['import']+[Path(s).name for s in plan['discovery_scripts']]
 raw_bad=[f.name for f in target.glob('*.log') if any(s in f.read_text(errors='replace') for s in ['SCRIPT ERROR','Parse Error','ERROR:','instances leaked','resources still in use'])]
 result={'pass_gate':rc==0 and error is None and summary.get('all_pass') is True and summary.get('entries')==150 and summary.get('passed')==151 and [x['test'] for x in rows]==expected_names and not raw_bad and post==expected and pins() and snap(old)==oldmap,'native_exit':rc,'seconds':time.monotonic()-start,'error':error,'summary':summary,'actual_rows':len(rows),'exact_discovery_order':[x['test'] for x in rows]==expected_names,'strict_bad_logs':raw_bad,'full_source_unchanged':post==expected,'all_pins_unchanged':pins(),'original_r3_unchanged':snap(old)==oldmap,'scope':'One author-coordinated original generic full suite. Per-case180/error/Rooms dispatch unchanged. Separate independent raw/helper/count audit required; not native/PCK acceptance.'}
 (out/'RESULT.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result),flush=True)
raise SystemExit(0 if result['pass_gate'] else 1)
