"""Two local commands only: stage exact PCK then ten unchanged delivery controls."""
from pathlib import Path
import json,hashlib,subprocess,os,signal,time,traceback,argparse,sys
q=Path(__file__).resolve().parent;ap=argparse.ArgumentParser();ap.add_argument('--plan-sha256',required=True);approved=ap.parse_args().plan_sha256
pp=q/'PLAN.json';raw=q/'raw-first';h=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
assert not raw.exists(),'REFUSE OVERWRITE';raw.mkdir();plan={};rows=[];errors=[];before={};after={};expected={}
def inventory(root):
 root=Path(root);d={}
 for f in root.rglob('*'):
  rel=f.relative_to(root)
  if '.godot' in rel.parts:continue
  assert not f.is_symlink(),str(f)
  if f.is_file():d[str(rel)]=h(f)
 return d
def guard():
 assert h(pp)==approved
 for p,v in plan['pins'].items():assert h(p)==v,p
 assert inventory(plan['source'])==expected

def run(route):
 out=raw/route['name'];out.mkdir();rc=None;timeout=False;stdout=stderr=b'';exception=None;reports=[];t=time.monotonic();accepted=False
 try:
  (out/'COMMAND.json').write_text(json.dumps(route['command'],indent=2)+'\n')
  proc=subprocess.Popen(route['command'],cwd=q,stdout=subprocess.PIPE,stderr=subprocess.PIPE,start_new_session=True)
  try:stdout,stderr=proc.communicate(timeout=180)
  except subprocess.TimeoutExpired:
   timeout=True
   try:os.killpg(proc.pid,signal.SIGKILL)
   except ProcessLookupError:pass
   stdout,stderr=proc.communicate()
  rc=proc.returncode
  assert not stderr
  for line in stdout.decode('utf-8',errors='strict').splitlines():
   assert line.startswith('{'),'unexpected output';value=json.loads(line);assert isinstance(value,dict);reports.append(value)
  assert len(reports)==1
  if route['name']=='stage':
   r=json.loads(Path(plan['stage_receipt']).read_text());assert r==reports[0]
   assert r['staging_valid'] is True and r['old_local_records_exact']==82 and r['new_records']==2 and r['total_records']==84 and r['chunks']==14 and r['new_delivery_paths']==17 and r['runtime_size']==39268876 and r['runtime_sha256']==plan['new_pck_sha256'] and r['runtime_chunks_reassembly_equal'] is True and r['external_actions']==[]
  else:
   r=json.loads(Path(plan['check_receipt']).read_text());assert r['status']=='PASS' and r['old_catalog_rows_exact']==82 and r['new_total_rows']==84 and r['planned_payloads_verified']==17
   steps=r['steps'];assert isinstance(steps,list) and len(steps)==10 and [s['name'] for s in steps]==plan['control_names']
   for i,s in enumerate(steps):assert s['expected_success'] is (i<2) and s['pass'] is True and ((s['exit']==0) if i<2 else (type(s['exit']) is int and s['exit']!=0))
   rb=r['manual_rollback'];assert rb['baseline_pack_sha256']==plan['old_pck_sha256'] and rb['new_pack_sha256']==plan['new_pck_sha256'] and rb['unchanged_elf_sha256']==plan['elf_sha256'] and rb['baseline_and_elf_rehashed_after'] is True and rb['unique_backup_exact'] is True
   assert reports==[{'status':'PASS','steps':10,'pack_sha256':plan['new_pck_sha256']}]
  accepted=True
 except Exception:exception=traceback.format_exc()
 finally:
  (out/'stdout.raw').write_bytes(stdout);(out/'stderr.raw').write_bytes(stderr);(out/'native.exit').write_text(str(rc)+'\n' if rc is not None else 'NOT_COMPLETED\n');row={'name':route['name'],'native_exit':rc,'timeout':timeout,'seconds':time.monotonic()-t,'exception':exception,'semantic_accepted':accepted,'pass':rc==0 and not timeout and accepted and exception is None};(out/'RESULT.json').write_text(json.dumps(row,indent=2)+'\n');rows.append(row);(raw/'STEPS.json').write_text(json.dumps(rows,indent=2)+'\n');print(json.dumps(row),flush=True)
 if not row['pass']:raise RuntimeError('first FAIL '+route['name'])
try:
 assert h(pp)==approved;plan=json.loads(pp.read_text());assert plan['status']=='FROZEN_READY';expected=json.loads(Path(plan['source_map']).read_text());assert len(expected)==935;guard();before=inventory(plan['source']);(raw/'SOURCE_BEFORE.json').write_text(json.dumps(before,indent=2)+'\n')
 for p in plan['must_not_exist']:assert not Path(p).exists(),p
 for item in plan['preconditions']:
  d=json.loads(Path(item['path']).read_text());assert isinstance(d,dict) and item['required_true'] and all(d.get(k) is True for k in item['required_true'])
 assert len(plan['routes'])==2
 for route in plan['routes']:run(route)
except Exception:errors.append(traceback.format_exc())
finally:
 try:guard();after=inventory(plan['source'])
 except Exception:errors.append('AFTERGUARD '+traceback.format_exc())
 (raw/'SOURCE_AFTER.json').write_text(json.dumps(after,indent=2)+'\n');r={'pass':not errors and len(rows)==2 and all(x['pass'] for x in rows),'completed':len(rows),'errors':errors,'plan_sha256':approved,'scope':'Local exact v40-held8 resource staging + original two positive/eight negative restoration controls and real old6743-to-new8a74-to-old6743 file rollback. Each command180 seconds, firstFAILstop; no engine/runtime/Git publication acceptance.'};(raw/'RESULT.json').write_text(json.dumps(r,indent=2)+'\n');print(json.dumps(r),flush=True)
sys.exit(0 if r['pass'] else 1)
