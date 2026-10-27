from pathlib import Path
import json,hashlib,datetime
r=Path('<WORKSPACE>');q=r/'moss-v36-qa';s=r/'moss-v36-r2';p=r/'moss-v36-r2-prep';h=lambda x:hashlib.sha256(x.read_bytes()).hexdigest()
a=json.loads((r/'moss-v36-catalog-plan/PREIMPORT_INPUTS.json').read_text());b=json.loads((p/'R2_INPUTS.json').read_text())
assert len(b)==717 and [n for n in a if a[n]!=b[n]]==['MANIFEST.json']
assert set(b)-set(a)=={'tests/support/v36_catalog_projection.gd.uid'} and all(h(s/n)==v for n,v in b.items())
prod=json.loads((p/'PRODUCTION_FINAL.json').read_text());assert len(prod)==131 and all(h(s/n)==v for n,v in prod.items())
paths=sorted((s/'tests').glob('*.gd'))+[s/'ui/test_ui.gd']+sorted((s/'docs/art').glob('check*.gd'))
tests=[str(x.relative_to(s)) for x in paths if x.read_text().lstrip().startswith('extends SceneTree')]
assert tests==json.loads((q/'FINAL_FREEZE_REVIEW.json').read_text())['standalone_discovery'] and len(tests)==124
row=json.loads((p/'FOCUSED_STEPS.json').read_text())[0];assert row['pass'] and row['exit']==0
raw=''.join((p/'focused'/('cold-import.'+x)).read_text() for x in ['stdout','stderr']);assert not any(x in raw for x in ['ERROR:','instances leaked','resources still in use'])
d={'status':'PASS_R2_717_PREFULL_FREEZE_REVIEW','utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'source_map_sha256':h(p/'R2_INPUTS.json'),'manifest_sha256':h(s/'MANIFEST.json'),'source_inputs':717,'only_preimport_change':'MANIFEST.json regenerated','only_generated_additions':['tests/support/v36_catalog_projection.gd.uid'],'production131_exact_focused':True,'cold_import_native0_clean':True,'standalone_discovery':tests,'author_commands':125,'original_714_full':'REJECTED 117/125 unchanged; not accepted by this freeze review','focused_status':'running, not accepted yet','review_correction':'First unexecuted-review discovery assertion omitted original extends SceneTree filter, counted two nonstandalone policy fixtures126. Corrected review only; source and runner unchanged, actual discovery124.'}
(q/'R2_FREEZE_REVIEW.json').write_text(json.dumps(d,indent=2)+'\n');print({k:v for k,v in d.items() if k!='standalone_discovery'})
