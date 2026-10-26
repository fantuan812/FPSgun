"""Reconcile a completed provisional runner using exact shipped success-marker function.
No game rerun and no raw log/result overwrite. Explicitly retains the rejected parser verdict.
"""
import argparse,ast,hashlib,json,re
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--project',required=True,type=Path);p.add_argument('--results',required=True,type=Path);a=p.parse_args()
root=a.project.resolve();out=a.results.resolve();raw=json.loads((out/'SUMMARY.json').read_text());records=json.loads((out/'results.json').read_text())
shipped=root/'tests/run_regression.py';b=shipped.read_bytes();module=ast.parse(b);fn=next(n for n in module.body if isinstance(n,ast.FunctionDef) and n.name=='success_marker')
ns={'re':re};exec(compile(ast.Module(body=[fn],type_ignores=[]),'<exact shipped success_marker>','exec'),ns)
fixed=[]
for old in records:
 log=out/(old['entry'].replace('/','__')+'.log');txt=log.read_text();marker=None if old['entry']=='import_reused_cache' else ns['success_marker'](txt)
 new=dict(old);new.update(success_marker=marker,pass_reconciled=old['exit']==0 and not old['timeout'] and not old['engine_error'] and (marker if marker is not None else True),log_sha256=hashlib.sha256(log.read_bytes()).hexdigest())
 fixed.append(new)
report={'schema':1,'reason':'Provisional independent runner omitted existing N passed; 0 failed / 0 failures formats. Exact shipped success_marker function applied after all processes ended. No source/test rerun or raw-result overwrite.','shipped_runner_sha256':hashlib.sha256(b).hexdigest(),'raw_summary_sha256':hashlib.sha256((out/'SUMMARY.json').read_bytes()).hexdigest(),'entries':len(fixed),'expected_standalone':raw['standalone_expected'],'passed':sum(x['pass_reconciled'] for x in fixed),'input_changes':raw['input_changes'],'marker_only_corrections':[x['entry'] for x in fixed if x['pass_reconciled']!=x['pass']],'results':fixed}
report['all_pass']=len(fixed)==raw['standalone_expected']+1 and not report['input_changes'] and all(x['pass_reconciled'] for x in fixed)
(out/'RECONCILED_SUMMARY.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps({k:v for k,v in report.items() if k!='results'}));raise SystemExit(0 if report['all_pass'] else 1)
