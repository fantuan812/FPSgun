from pathlib import Path
import shutil
q=Path('<WORKSPACE>/moss-v39-qa');old=Path('<WORKSPACE>/moss-v38-qa');s=(old/'run_packed.py').read_text();s=s.replace("src=r/'moss-v38-final-r2';project=q/'project';out=q/'packed-first';packroot=r/'moss-v38-pack'","src=r/'moss-v39-final-r2';project=q/'packed-project';out=q/'packed-first';packroot=r/'moss-v39-pack'")
s=s.replace("q/'AGGREGATE_SEPARATE_REVIEW.json'","q/'FINAL_R2_RAW_REVIEW.json'")
s=s.replace("elif line.startswith('{'):\n    try:reports.append(json.loads(line))\n    except json.JSONDecodeError:pass","elif line.startswith('{'):reports.append(json.loads(line))")
s=s.replace("except (ValueError,OSError) as e:","except (ValueError,OSError,TypeError) as e:")
s=s.replace("'ERROR:','SCRIPT ERROR:','instances leaked'","'ERROR:','SCRIPT ERROR','Parse Error','instances leaked'")
s=s.replace("semantic=bool(reports and reports[-1].get('checks')==expected_checks and reports[-1].get('failures')==[])","semantic=bool(reports and all(isinstance(v,dict) and v.get('checks')==expected_checks and v.get('failures')==[] for v in reports) and all(v==reports[0] for v in reports))")
s=s.replace("o['invalid']==o['discarded']==0", "o['invalid']==o['discarded']==o['prepare_errors']==0")
s=s.replace("assert len(exact)==72 and len(images)==62", "assert len(exact)==plan['expected_exact_files'] and len(images)==plan['expected_images']")
s=s.replace("],916,report_file=out/'resources.json')", "],plan['generic_checks'],report_file=out/'resources.json')")
s=s.replace("if name=='support-assets':cmd+=['--','--expected-imported',str(q/'packed-harness/source-support-imported-baseline.json')]", "if name=='A7-assets':\n   result=out/'A7-assets.json';cmd+=['--',str(q/'packed-harness/A7_RAW_SOURCE_ORACLE.json'),str(oracle),str(result)]")
s=s.replace("  run(name,cmd,binding['expected_checks'],binding['helper_required'],result)","  rr=run(name,cmd,binding['expected_checks'],binding['helper_required'],result)\n  if binding.get('observations') is not None:assert len(rr[-1].get('observations',[]))==binding['observations']")
s=s.replace("assert len(rows)==16, len(rows)","assert len(rows)==17, len(rows)")
s=s.replace("6support routes", "six A feature routes plus A7 identities")
# Full source set guard, not only existing-file identity.
s=s.replace("assert all(h(src/n)==s for n,s in pins.items());", "def inventory(root):return {str(f.relative_to(root)):h(f) for f in root.rglob('*') if f.is_file() and '.godot' not in f.relative_to(root).parts}\nassert inventory(src)==pins;")
s=s.replace("summary={'status':", "source_sets_unchanged=inventory(src)==pins and inventory(project)==pins\nsummary={'source_sets_unchanged':source_sets_unchanged,'status':")
s=s.replace("if not failure and not changed else", "if not failure and not changed and source_sets_unchanged else")
s=s.replace("'pass':not failure and not changed", "'pass':not failure and not changed and source_sets_unchanged")
(q/'run_packed.py').write_text(s)
for n in ['independent_feedback_pcm.py','independent_scavenger_icon.gd','svg-oracle.json']:
 shutil.copyfile(old/'packed-harness'/n,q/'packed-harness'/n)
print('static runner drafted, no engine')
