from pathlib import Path
import hashlib,json,shutil,re,difflib
r=Path('workspace/shared');src=r/'moss-v35-final';dst=r/'moss-v35-r4';out=r/'moss-v35-teardown-plan';sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
assert not dst.exists();shutil.copytree(src,dst,ignore=shutil.ignore_patterns('.godot','__pycache__'))
(dst/'tests/support').mkdir(exist_ok=True);shutil.copy2(out/'audio_teardown.gd',dst/'tests/support/audio_teardown.gd');shutil.copy2(out/'test_audio_teardown_predicate.gd',dst/'tests/test_audio_teardown_predicate.gd')
paths=sorted((src/'tests').glob('*.gd'))+[src/'ui/test_ui.gd']+sorted((src/'docs/art').glob('check*.gd'));rows=[];changed=[]
exempt={'independent_feedback_mixer.gd':'Dedicated independent mixer already observes real node/stream weakref release plus new silent frames and capture removal after final disposal.','test_feedback_mixer.gd':'Dedicated mixer observes completed voices and fresh drained/resumed silence before owner disposal; preserve its capture semantics.','test_feedback_teardown.gd':'Dedicated real disposal test already asserts node/stream/playback weakref release and new silent frames.'}
definite={'independent_annulus_runtime.gd','independent_brood_parity.gd','independent_weapon_rig.gd','test_core_summon.gd','independent_charger_lifecycle.gd','test_game.gd','test_warden_charge.gd','independent_feedback_authority.gd','independent_feedback_mixer.gd','test_player_feedback.gd','test_feedback_mixer.gd','test_feedback_teardown.gd','test_resolution_validation.gd','independent_settlement_types.gd'}
for p in paths:
 old=p.read_text()
 if not old.lstrip().startswith('extends SceneTree'):continue
 rel=str(p.relative_to(src));row={'fixture':rel,'source_sha256':sha(p),'audio_class':'none','evidence':[],'action':'unchanged'}
 if not ('main.tscn' in old or 'feedback_audio.gd' in old):
  row['evidence']=['Reviewed creation/import boundary: data/geometry/visual/UI-only fixture, no main scene or audio controller construction; support modules provide no audio playback.'];rows.append(row);continue
 row['audio_class']='definite' if p.name in definite else 'possible_indirect'
 row['evidence']=[f'{i+1}:{l.strip()}' for i,l in enumerate(old.splitlines()) if any(t in l for t in ['._hurt(', '._simulate(', 'Runtime.step(', 'feedback_audio.request(', 'queue_free()', 'quit('])]
 if p.name in exempt:row['action']='existing_dedicated_cleanup';row['reason']=exempt[p.name];rows.append(row);continue
 lines=old.splitlines(True);free_indices=[i for i,l in enumerate(lines) if 'queue_free()' in l];assert free_indices,p.name;idx=free_indices[-1];line=lines[idx];indent=re.match(r'\s*',line).group();owners=re.findall(r'\b([a-zA-Z_]\w*)\.queue_free\(\)',line);assert owners,p.name
 # Only the final main-owner disposal group; internal sprite frees and earlier lifecycle tests stay exact.
 assert all(x in ['g','game','a','b','layer'] for x in owners),(p.name,owners)
 before=f'{indent}var audio_teardown = preload("res://tests/support/audio_teardown.gd").new()\n{indent}audio_teardown.prepare([{", ".join(owners)}])\n'
 line=line.replace(';await create_timer(.25).timeout','')
 # Inline quit must follow the added final-disposal observation, never precede it.
 tail='';q=line.find(';quit(')
 if q>=0:tail=indent+line[q+1:];line=line[:q]+';await process_frame\n'
 end=idx+1
 if 'await process_frame' not in line:
  assert end<len(lines) and lines[end].strip()=='await process_frame',(p.name,lines[end]);line+=lines[end];end+=1
 if end<len(lines) and 'await create_timer(.25).timeout' in lines[end]:end+=1
 insert=before+line+f'{indent}await audio_teardown.finish(self)\n'+tail
 new=''.join(lines[:idx])+insert+''.join(lines[end:]);(dst/rel).write_text(new)
 row.update({'action':'shared_final_disposal_observer','original_final_line':idx+1,'owners':owners,'candidate_sha256':sha(dst/rel),'removed_original_lines':[x.rstrip() for x in lines[idx:end]],'new_block':insert.rstrip(),'earlier_disposal_sites_unchanged':len(free_indices)-1,'early_failure_exits':p.name in ['test_core_summon.gd','test_warden_charge.gd']})
 # Mechanical reverse-map proves every other original byte is unchanged.
 assert new.replace(insert,''.join(lines[idx:end]),1)==old,p.name
 changed.append(rel);rows.append(row)
 (out/'diffs').mkdir(exist_ok=True);(out/'diffs'/(p.name+'.patch')).write_text(''.join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile='frozen-final/'+rel,tofile='r4/'+rel)))
prod=json.load(open(r/'moss-v35-final-prep/PRODUCTION_FINAL.json'));assert all(sha(dst/k)==v for k,v in prod.items())
report={'status':'PREPARED_NOT_IMPORTED_OR_EXECUTED','original_command_count':len(rows)+1,'import_row':'no runtime scene/gameplay playback; retained unchanged','fixtures':rows,'counts':{k:sum(x['audio_class']==k for x in rows) for k in ['definite','possible_indirect','none']},'changed_fixtures':changed,'production128_exact':True,'per_case_budget180_unchanged':True,'runner_unchanged':sha(dst/'tests/run_regression.py')==sha(src/'tests/run_regression.py'),'scope':'Final disposal only; prior failed119 remains immutable. Special missingasset failure exits unchanged and alreadyfail, not acceptance paths. This inventory is conservative about indirect routes.'};(out/'COVERAGE_AND_DIFF_AUDIT.json').write_text(json.dumps(report,indent=2)+'\n');print('fixtures',len(rows),'changed',len(changed),'classes',report['counts'])
