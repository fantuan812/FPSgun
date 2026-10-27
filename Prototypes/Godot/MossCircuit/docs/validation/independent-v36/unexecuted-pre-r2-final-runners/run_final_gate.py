from pathlib import Path
import os,subprocess,json,hashlib,time,sys,argparse,shutil
ap=argparse.ArgumentParser();ap.add_argument('--pack-root',type=Path,required=True);a=ap.parse_args();q=Path(__file__).parent;project=q/'project';packroot=a.pack_root;out=q/'final-gate';assert not out.exists();out.mkdir();h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();inputs=json.loads((q/'FINAL_INPUTS.json').read_text());assert all(h(project/p)==s for p,s in inputs.items())
audit=json.loads((q/'AUTHOR_FULL_RAW_REVIEW.json').read_text());assert audit['status']=='PASS_INDEPENDENT_RAW_REVIEW_AUTHOR_FULL' and audit['source_map_sha256']==h(q/'FINAL_INPUTS.json')
env=os.environ.copy();env['GODOT_SILENCE_ROOT_WARNING']='1'
for key,n in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_CACHE_HOME','cache'),('XDG_DATA_HOME','data')]:p=out/'private-profile'/n;p.mkdir(parents=True);env[key]=str(p)
steps=[]
def run(name,args,cwd=q):
 start=time.monotonic();code=None;timeout=False
 try:p=subprocess.run(args,env=env,cwd=cwd,capture_output=True,timeout=180);stdout=p.stdout;stderr=p.stderr;code=p.returncode
 except subprocess.TimeoutExpired as e:stdout=e.stdout or b'';stderr=e.stderr or b'';timeout=True
 (out/(name+'.stdout')).write_bytes(stdout);(out/(name+'.stderr')).write_bytes(stderr);text=(stdout+stderr).decode(errors='replace');error=any(x in text for x in ['ERROR:','SCRIPT ERROR:','instances leaked','resources still in use']);row={'step':name,'native_exit':code,'timeout':timeout,'elapsed':round(time.monotonic()-start,3),'error_or_resource_warning':error,'pass':code==0 and not timeout and not error};steps.append(row);(out/'STEPS.json').write_text(json.dumps(steps,indent=2)+'\n');print(json.dumps(row),flush=True)
 if not row['pass']:raise RuntimeError('Rejected '+name+'; raw retained')
 return text
exact={};images={}
for folder in ['scripts','ui','data','assets']:
 for p in (project/folder).rglob('*'):
  if not p.is_file():continue
  rel=p.relative_to(project).as_posix()
  if rel=='ui/test_ui.gd':continue
  if p.suffix in ['.gd','.json']:exact[rel]=h(p)
  if p.suffix=='.png':images[rel]={}
exact['art_source/alpha_bounds.json']=h(project/'art_source/alpha_bounds.json');expected=out/'expected-resources.json';expected.write_text(json.dumps({'exact_files':exact,'images':images},indent=2)+'\n');oracle=out/'source-imported-fingerprints.json'
run('source-resource-fingerprint',['godot','--headless','--audio-driver','Dummy','--path',str(project),'--script','res://tools/export_source_fingerprint.gd','--',str(expected),str(oracle)])
assert json.loads(oracle.read_text())==json.loads((packroot/'source-imported-fingerprints.json').read_text())
reader=out/'empty-reader';reader.mkdir();pack=packroot/'linux/MossCircuit.pck';assert h(pack)==h(packroot/'windows/MossCircuit.pck');packhash=h(pack)
run('packed-resources',['godot','--headless','--audio-driver','Dummy','--main-pack',str(pack),'--script',str(project/'tools/verify_export_pack.gd'),'--',str(oracle),str(out/'packed-resource-report.json')],reader)
harness=out/'packed-harness';harness.mkdir();helper=harness/'audio_teardown.gd';shutil.copy2(project/'tests/support/audio_teardown.gd',helper);bindings=[]
for name,filename in [(x,'independent_scavenger_'+x+'.gd') for x in ['authority','events','views','settlement']]+[('audio-'+x,'independent_feedback_'+x+'.gd') for x in ['authority','mixer','views']]:
 source=project/'tests'/filename;old=source.read_text();needle='res://tests/support/audio_teardown.gd';new=old.replace(needle,str(helper));assert new.replace(str(helper),needle)==old;script=harness/filename;script.write_text(new);bindings.append({'script':filename,'source_sha256':h(source),'external_sha256':h(script),'helper_sha256':h(helper),'only_change':'external exact test-only preload path','replacement_count':old.count(needle)});(out/'PACKED_HARNESS_BINDINGS.json').write_text(json.dumps(bindings,indent=2)+'\n')
 cmd=['godot','--headless','--audio-driver','Dummy','--main-pack',str(pack),'--script',str(script),'--',str(out/(name+'.json'))]
 if name=='audio-mixer':cmd.append(str(out/'audio-mixer-raw'))
 run('packed-'+name,cmd,reader);d=json.loads((out/(name+'.json')).read_text());assert d.get('failures')==[] and d.get('checks')=={'authority':178,'events':46,'views':132,'settlement':30,'audio-authority':773,'audio-mixer':236,'audio-views':168}[name]
icon=q/'checks/independent_scavenger_icon.gd';icon_oracle=q/'source-icon-corrected/source-icon-oracle.json';assert h(icon_oracle)=='cc61e79859ec3b87ebefa558cd676bfb9350081d5f05b35ee2503edb2e63a475';assert h(icon)==json.loads((q/'ICON_NUMERIC_ORACLE_CORRECTION.json').read_text())['new_script_sha256'];shutil.copy2(icon,harness/icon.name);(out/'SVG_BINDING.json').write_text(json.dumps({'fixture_sha256':h(icon),'oracle_sha256':h(icon_oracle),'source_production_map':h(q.parent/'moss-v36-final-prep/PRODUCTION_FINAL.json'),'scope':'Source oracle on same131 production bytes, retained rejected first numeric-layer fixture separate'},indent=2)+'\n')
log=run('packed-svg-icon',['godot','--headless','--audio-driver','Dummy','--main-pack',str(pack),'--script',str(harness/icon.name),'--','verify',str(icon_oracle)],reader);reports=[]
for line in log.splitlines():
 try:d=json.loads(line)
 except:continue
 if isinstance(d,dict) and 'failures' in d:reports.append(d)
assert len(reports)==1 and reports[0]['failures']==[] and reports[0]['status']=='PASS'
run('python-pcm',['python',str(q/'checks/independent_feedback_pcm.py'),str(project),str(out/'pcm.json')]);run('python-export-safety',['python',str(project/'tests/test_export_tools.py')])
changed=[p for p,s in inputs.items() if h(project/p)!=s];assert not changed and h(pack)==packhash
result={'status':'PASS_FINAL_SELECTED_EXACT_PACK','steps':steps,'source_inputs':len(inputs),'source_changes':changed,'pck_sha256':packhash,'pck_bytes':pack.stat().st_size,'elf_sha256':h(pack.parent/'MossCircuit.x86_64'),'two_preset_packs_identical':True,'generic_png_resource_identity_exact':True,'dedicated_svg_identity_exact':True,'author_full_raw_audit_reference':h(q/'AUTHOR_FULL_RAW_REVIEW.json'),'scope':'Author whole suite independently raw-reviewed; independent selected exact PCK resource/newfeature/reward/lifecycle/SVG and prior audio routes. No repeated independent fullsuite. Source resource fingerprint reuses independent imported cache.','native_ordinary_pending':True,'physical_audio_windows_verified':False};(out/'SUMMARY.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result),flush=True)
