from pathlib import Path
import os,subprocess,json,hashlib,time,sys,argparse,shutil
ap=argparse.ArgumentParser();ap.add_argument('--qa-root',type=Path,default=Path(__file__).parent);ap.add_argument('--pack-root',type=Path,required=True);a=ap.parse_args()
q=a.qa_root.resolve();r=q/'project';out=q/'final-gate';out.mkdir(exist_ok=False);packroot=a.pack_root.resolve();h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
inputs=json.loads((q/'FINAL_INPUTS.json').read_text());assert all(h(r/p)==v for p,v in inputs.items())
env=os.environ.copy();env['GODOT_SILENCE_ROOT_WARNING']='1'
for key,name in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_CACHE_HOME','cache'),('XDG_DATA_HOME','data')]:env[key]=str(q/'private-profile'/name)
steps=[]
def run(name,cmd,cwd=q,timeout=1200):
 start=time.monotonic();p=subprocess.run(cmd,cwd=cwd,env=env,capture_output=True,text=True,timeout=timeout);log=p.stdout+p.stderr;(out/(name+'.log')).write_text(log);row={'step':name,'exit':p.returncode,'seconds':round(time.monotonic()-start,3),'engine_error':'ERROR:' in log,'resource_warning':('leaked at exit' in log or 'resources still in use' in log),'pass':p.returncode==0 and 'ERROR:' not in log and 'leaked at exit' not in log and 'resources still in use' not in log};steps.append(row);(out/'STEPS.json').write_text(json.dumps(steps,indent=2)+'\n');print(json.dumps(row),flush=True);assert row['pass'],log[-3000:];return log
# Explicit verification scope: independent audit of author complete aggregate, not a duplicate full execution.
author_audit=json.loads((q/'receipts/R4_FULL_AGGREGATE_REVIEW.json').read_text())
assert author_audit['status']=='PASS_INDEPENDENT_REVIEW_OF_AUTHOR_120'
assert author_audit['source_map_sha256']==h(q/'FINAL_INPUTS.json')
exact={};images={}
for folder in ['scripts','ui','data','assets']:
 for p in (r/folder).rglob('*'):
  if not p.is_file():continue
  rel=p.relative_to(r).as_posix()
  if rel=='ui/test_ui.gd':continue
  if p.suffix in ['.gd','.json']:exact[rel]=h(p)
  if p.suffix=='.png':images[rel]={}
exact['art_source/alpha_bounds.json']=h(r/'art_source/alpha_bounds.json');expected=out/'expected-resources.json';expected.write_text(json.dumps({'exact_files':exact,'images':images},indent=2)+'\n');oracle=out/'source-imported-fingerprints.json'
run('independent-source-oracle',['godot','--headless','--path',str(r),'--script','res://tools/export_source_fingerprint.gd','--',str(expected),str(oracle)])
assert json.loads(oracle.read_text())==json.loads((packroot/'source-imported-fingerprints.json').read_text())
reader=out/'empty-reader';reader.mkdir();pack=packroot/'linux/MossCircuit.pck';assert h(pack)==h(packroot/'windows/MossCircuit.pck')
run('packed-resources',['godot','--headless','--main-pack',str(pack),'--script',str(r/'tools/verify_export_pack.gd'),'--',str(oracle),str(out/'packed-resource-report.json')],reader)
harness=out/'packed-harness';harness.mkdir();helper=harness/'audio_teardown.gd';shutil.copy2(r/'tests/support/audio_teardown.gd',helper);harness_rows=[]
for name in ['authority','mixer','views','settlement-types']:
 filename='independent_settlement_types.gd' if name=='settlement-types' else f'independent_feedback_{name}.gd'
 source_script=r/'tests'/filename
 # Runtime export intentionally excludes tests; bind only the test-owned support file externally.
 old=source_script.read_text(); needle='res://tests/support/audio_teardown.gd'
 new=old.replace(needle,str(helper))
 script=harness/filename;script.write_text(new)
 assert new.replace(str(helper),needle)==old
 harness_rows.append({'script':filename,'source_sha256':h(source_script),'external_sha256':h(script),'helper_sha256':h(helper),'replacement_count':old.count(needle),'only_change':'test support preload rebound to exact external helper; production pack unchanged'})
 (out/'PACKED_HARNESS_BINDINGS.json').write_text(json.dumps(harness_rows,indent=2)+'\n')
 command=['godot','--headless','--audio-driver','Dummy','--main-pack',str(pack),'--script',str(script),'--',str(out/(name+'.json'))]
 if name=='mixer':command.append(str(out/'packed-mixer-raw'))
 run('packed-'+name,command,reader,timeout=180)
 result=json.loads((out/(name+'.json')).read_text());assert result.get('failures')==[]
run('independent-pcm',['python',str(q/'checks/independent_feedback_pcm.py'),str(r),str(out/'pcm.json')])
run('python-safety',['python',str(r/'tests/test_export_tools.py')])
changes=[p for p,v in inputs.items() if h(r/p)!=v];assert not changes
report={'status':'PASS','steps':steps,'source_inputs':len(inputs),'input_changes':changes,'source_execution_scope':'Author full120 aggregate independently raw-audited; QA selected source fingerprint and exact packed routes. No independent full120 replay.','source_oracle_exact':True,'both_preset_packs_equal':True,'pck':{'bytes':pack.stat().st_size,'sha256':h(pack)},'elf':{'bytes':(pack.parent/'MossCircuit.x86_64').stat().st_size,'sha256':h(pack.parent/'MossCircuit.x86_64')},'ordinary_gui_pending':True,'physical_audibility_verified':False,'source_and_packed_internal_dummy_capture_only':True,'windows_executed':False}
(out/'SUMMARY.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report),flush=True)
