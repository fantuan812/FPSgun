"""Wrapper of unchanged approved original7-step resource-only builder,240s existing per-step cap."""
from pathlib import Path
import argparse,json,hashlib,subprocess,time,traceback,sys,os,signal
q=Path(__file__).resolve().parent;ap=argparse.ArgumentParser();ap.add_argument('--plan-sha256',required=True);approved=ap.parse_args().plan_sha256
p=q/'PLAN.json';raw=q/'raw-first';h=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
if raw.exists():raise SystemExit('REFUSE OVERWRITE')
raw.mkdir();plan={};expected={};rc=None;timed_out=False;exception=None;errors=[];report={};steps=[];before={};after={};start=time.monotonic()
def inventory(root):
 d={}
 for f in root.rglob('*'):
  rel=f.relative_to(root)
  if '.godot' in rel.parts:continue
  if f.is_symlink():raise ValueError('symlink '+str(f))
  if f.is_file():d[str(rel)]=h(f)
 return d
def guard():
 assert h(p)==approved
 for name,value in plan['pins'].items():assert h(name)==value,name
 for name,value in plan['original_sources'].items():assert inventory(Path(name))==value,name
try:
 assert h(p)==approved;plan=json.loads(p.read_text());guard();root=Path(plan['source']);out=Path(plan['output']);expected=plan['inputs'];before=inventory(root)
 assert before==expected and len(before)==926 and not out.exists()
 for item in plan['preconditions']:
  d=json.loads(Path(item['path']).read_text())
  for key in item['required_true']:assert d.get(key) is True
 (raw/'BEFORE.json').write_text(json.dumps(before,indent=2)+'\n');(raw/'COMMAND.json').write_text(json.dumps(plan['command'],indent=2)+'\n')
 with (raw/'builder.stdout').open('wb') as stdout,(raw/'builder.stderr').open('wb') as stderr:
  proc=subprocess.Popen(plan['command'],stdout=stdout,stderr=stderr,cwd=raw,start_new_session=True)
  try:rc=proc.wait(timeout=240)
  except subprocess.TimeoutExpired:
   timed_out=True;exception=traceback.format_exc()
   try:os.killpg(proc.pid,signal.SIGKILL)
   except ProcessLookupError:pass
   rc=proc.wait()  # Actual terminal status after killing only this builder's own process group.
except Exception:exception=traceback.format_exc()
finally:
 (raw/'builder.native.exit').write_text('NOT_STARTED\n' if rc is None else str(rc)+'\n')
 try:
  out=Path(plan['output']);report=json.loads((out/'BUILD_REPORT.json').read_text());steps=json.loads((out/'STEPS.json').read_text())
  assert isinstance(report,dict) and isinstance(steps,list) and len(steps)==7 and all(isinstance(x,dict) for x in steps)
  assert [x.get('step') for x in steps]==plan['expected_steps']
  assert all(x.get('pass') is True and type(x.get('exit')) is int and x['exit']==0 and x.get('engine_error') is False and type(x.get('seconds')) in (int,float) and 0<=x['seconds']<=240 for x in steps)
  assert report.get('pass') is True and report.get('source_inputs')==926 and report.get('source_inputs_unchanged') is True and report.get('resource_only') is True and report.get('windows_runtime_tested') is False and report.get('native_gui_tested') is False
  assert report.get('external_actions')==[]
  logs=sorted((out/'logs').glob('*.log'));assert len(logs)==7
  forbidden=['SCRIPT ERROR','Parse Error','ERROR:','WARNING:','instances leaked','resources still in use']
  bad={f.name:[token for token in forbidden if token in f.read_text(errors='replace')] for f in logs};assert not any(bad.values()),bad
  resource=json.loads((out/'packed-resource-report.json').read_text())
  assert resource['checks']==998 and resource['failures']==[] and resource['exact_files']==84 and resource['images']==72 and resource['actions']==28 and resource['action_frames']==308
  pair=out/'linux/MossCircuit.pck';other=out/'windows/MossCircuit.pck';elf=out/'linux/MossCircuit.x86_64'
  assert pair.is_file() and other.is_file() and h(pair)==h(other)
  assert h(elf)==plan['elf_sha256']
  for rel,meta in report['files'].items():assert h(out/rel)==meta['sha256'] and (out/rel).stat().st_size==meta['bytes']
 except Exception:errors.append(traceback.format_exc())
 try:
  guard();after=inventory(Path(plan['source']));assert after==expected
 except Exception:errors.append(traceback.format_exc())
 (raw/'AFTER.json').write_text(json.dumps(after,indent=2)+'\n')
 result={'pass_gate':rc==0 and not timed_out and exception is None and not errors,'native_exit':rc,'termination':'TIMEOUT_KILLED_OWN_GROUP' if timed_out else 'NATIVE_TERMINAL','timed_out':timed_out,'outer_timeout_seconds':240,'seconds':time.monotonic()-start,'exception':exception,'errors':errors,'files':report.get('files',{}) if isinstance(report,dict) else {},'approved_plan':approved,'scope':'Original7-step resource-only builder internal240-per-step unchanged, wrapper240 total builder wall budget; new combined926 source. Generic998/84files72PNG28actions308frames and identical PCKpair/unchangedELF. No specialist22/native/ordinary or Windows execution acceptance.'}
 (raw/'RESULT.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result),flush=True)
sys.exit(0 if result['pass_gate'] else 1)
