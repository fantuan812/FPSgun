from pathlib import Path
import json,hashlib,subprocess,time
q=Path(__file__).parent;p=q/'PLAN.json';h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();ph=h(p);plan=json.loads(p.read_text());root=Path(plan['source']);expected=json.loads(Path(plan['input_map']).read_text());out=Path(plan['output'])
def snap(r):return {str(f.relative_to(r)):h(f) for f in sorted(r.rglob('*')) if f.is_file() and '.godot' not in f.relative_to(r).parts}
def pins():return h(p)==ph and all(Path(f).is_file() and h(Path(f))==v for f,v in plan['pins'].items())
assert pins() and snap(root)==expected and not out.exists();start=time.monotonic();rc=125;errors=[];report={};steps=[]
try:
 with (q/'builder.stdout').open('wb') as a,(q/'builder.stderr').open('wb') as b:
  z=subprocess.run(plan['command'],stdout=a,stderr=b);rc=z.returncode
except Exception as e:errors.append(repr(e))
finally:
 (q/'builder.exit').write_text(str(rc)+'\n')
 try:
  report=json.loads((out/'BUILD_REPORT.json').read_text());steps=json.loads((out/'STEPS.json').read_text())
  if not isinstance(report,dict) or not isinstance(steps,list) or not all(isinstance(x,dict) for x in steps):raise TypeError('wrong builder report schema')
 except (ValueError,TypeError,OSError) as e:errors.append(repr(e));report={};steps=[]
 logs=list((out/'logs').glob('*.log'));bad=[x.name for x in logs if any(s in x.read_text(errors='replace') for s in ['SCRIPT ERROR','Parse Error','ERROR:','instances leaked','resources still in use'])]
 post=snap(root);(q/'POST_INPUTS.json').write_text(json.dumps(post,indent=2,sort_keys=True)+'\n')
 pair=out/'linux/MossCircuit.pck';other=out/'windows/MossCircuit.pck';elf=out/'linux/MossCircuit.x86_64';pack_equal=pair.is_file() and other.is_file() and h(pair)==h(other);elf_same=elf.is_file() and h(elf)==plan['elf_sha256']
 result={'pass_gate':rc==0 and not errors and report.get('pass') is True and [x.get('step') for x in steps]==plan['expected_steps'] and all(x.get('pass') is True and x.get('exit')==0 and 0<=x.get('seconds',9999)<=240 for x in steps) and len(logs)==7 and not bad and pack_equal and elf_same and post==expected and pins(),'native_exit':rc,'seconds':time.monotonic()-start,'errors':errors,'strict_bad_logs':bad,'pack_equal':pack_equal,'elf_same':elf_same,'source_unchanged':post==expected,'pins_unchanged':pins(),'files':report.get('files',{}),'scope':'Original resource-only builder7 steps, no --check or full rerun. Actual packed specialist/privacy/native/ordinary gates remain separate; not Windows execution.'}
 (q/'RESULT.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result),flush=True)
raise SystemExit(0 if result['pass_gate'] else 1)
