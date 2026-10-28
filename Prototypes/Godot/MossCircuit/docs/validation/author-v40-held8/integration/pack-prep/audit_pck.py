"""Same-path held8 payload replacement audit; retains resource names, forbids stale contents."""
from pathlib import Path
import json,hashlib,re,sys
from parse_pck import parse
Q=Path(__file__).parent;T=Path('evidence-workspace/moss-held8-integration-candidate');old=json.loads((Q/'OLD_PAYLOAD_IDENTITIES.json').read_text());p=Path(sys.argv[1]);out=Path(sys.argv[2]);data=p.read_bytes();result=parse(p);files=result['files'];errors=[];forbidden=set(old['other_reference_payload_hashes_forbidden'])
for marker in old['privacy_markers']:
 if marker.encode()in data:errors.append('wholebytes private marker '+marker)
for record in old['selected8']:
 rel=record['runtime_path_kept'].removeprefix('res://');imp=rel+'.import';raw=(T/imp).read_bytes();assert raw.startswith(b'[remap]\n')and raw.count(b'[deps]')==1
 exact=raw.split(b'[deps]')[0].rstrip(b'\n')+b'\n\0'
 if imp not in files or files[imp]['sha256']!=hashlib.sha256(exact).hexdigest():errors.append('exact new import remap serialization differs '+imp)
 ctex=re.search(rb'path="res://([^"]+)"',raw).group(1).decode()
 if ctex not in files:errors.append('new loaded ctex missing '+ctex)
 if (T/rel).is_file()and hashlib.sha256((T/rel).read_bytes()).hexdigest()!=record['new_raw_PNG_sha256_expected']:errors.append('candidate newPNG altered '+rel)
 forbidden.update([record['old_ctex_payload_sha256_forbidden'],record['old_raw_PNG_sha256_forbidden']])
 for uid in record['old_UID_reference_to_check']:
  if uid.encode()in data:errors.append('old held UID remains '+uid)
for name,record in files.items():
 if record['sha256']in forbidden:errors.append('old/reference payload survives '+name)
 if name.startswith(('art_source/legacy_held_L1_C2/','reference_only/','validation_inputs/')):errors.append('source/reference asset leaked '+name)
 if 'equipment_atlas_v2' in name or 'equipment_atlas_editable.svg' in name or name.startswith('art_source/icons/'):errors.append('accepted equipment exclusion regressed '+name)
for marker in [b'equipment_atlas_v2',b'uid://chrklnkaqwl6m']:
 if marker in data:errors.append('old equipment marker survives '+marker.decode())
expected=json.loads((Q/'expected-resources.json').read_text())
for name,h in expected['exact_files'].items():
 if name not in files or files[name]['sha256']!=h:errors.append('runtime exact bytes differ '+name)
if result['count']!=273:errors.append('expected273 runtime records')
result.update({'pass':not errors,'errors':errors,'scope':'actual PCK full273records, allrecordMD5/privacy, new8 remaps exact serializedformat, old8payloads absent while runtime paths remain; no native visual acceptance','forbidden_payload_hashes':sorted(forbidden),'runtime_exact_files':len(expected['exact_files']),'same_path_policy':'ctex filenames may remain identical; compare payload identity, not filename absence'})
out.write_text(json.dumps(result,indent=2)+'\n');print(('PCK_AUDIT_PASS 'if not errors else'PCK_AUDIT_FAIL ')+json.dumps({'records':len(files),'findings':errors,'pck_sha256':result['pack_sha256']}));raise SystemExit(0 if not errors else 1)
