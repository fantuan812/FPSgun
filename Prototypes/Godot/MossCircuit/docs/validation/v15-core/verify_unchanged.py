"""Verify reaction-only changes against the immutable published baseline directory."""
import argparse,hashlib,json
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--baseline',required=True,type=Path);p.add_argument('--candidate',required=True,type=Path);p.add_argument('--output',required=True,type=Path);a=p.parse_args();records=[];errors=[]
for folder in ['scripts','ui','scenes','assets','data']:
 for old in sorted((a.baseline/folder).rglob('*')):
  if not old.is_file():continue
  rel=old.relative_to(a.baseline)
  if str(rel)=='data/actor_actions.json':continue
  new=a.candidate/rel
  unchanged=new.exists() and old.read_bytes()==new.read_bytes()
  if not unchanged:errors.append(str(rel))
  records.append({'path':str(rel),'sha256':hashlib.sha256(old.read_bytes()).hexdigest(),'unchanged':unchanged})
old=json.loads((a.baseline/'data/actor_actions.json').read_text());new=json.loads((a.candidate/'data/actor_actions.json').read_text())
expected=json.loads(json.dumps(old));expected['profiles']['boss_core'].update({'hurt':'boss_core_hurt','death':'boss_core_death'});expected['additional_manifests'].append('res://assets/actions/boss_core/action_manifest.json')
if expected!=new:errors.append('unexpected actor_actions configuration change')
result={'passed':not errors,'errors':errors,'checked_unchanged_files':len(records),'exact_allowed_config_delta':expected==new,'files':records};a.output.parent.mkdir(parents=True,exist_ok=True);a.output.write_text(json.dumps(result,indent=2)+'\n');print(json.dumps({k:v for k,v in result.items() if k!='files'}));raise SystemExit(0 if not errors else 1)
