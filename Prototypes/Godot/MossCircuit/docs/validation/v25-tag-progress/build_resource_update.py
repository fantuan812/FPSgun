"""Private bounded v25 pack-only orchestration; reuse held source, no template or executable copies."""
from pathlib import Path
import argparse,hashlib,json,os,subprocess
p=argparse.ArgumentParser();p.add_argument('--source',type=Path,required=True);p.add_argument('--output',type=Path,required=True);p.add_argument('--accepted-linux',type=Path,required=True);p.add_argument('--accepted-windows',type=Path,required=True);a=p.parse_args()
src=a.source.resolve();out=a.output.resolve();assert src.is_dir() and not out.exists() and src not in out.parents
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
expected_exe={'linux':'2c78919325d7f29fa7607287c7c1eeac367ea4c94e7b8b6f5f4c6b20492f73d0','windows':'91724f15024a3a545e28ccd83134403d31ce2323a38e51c95e4dfa282f732ab6'}
exe={'linux':a.accepted_linux.resolve(),'windows':a.accepted_windows.resolve()};assert all(sha(f)==expected_exe[k] for k,f in exe.items())
def source_map():return {str(f.relative_to(src)):sha(f) for f in sorted(src.rglob('*')) if f.is_file() and not {'.godot','__pycache__','.git'}&set(f.relative_to(src).parts)}
before=source_map();out.mkdir();env=dict(os.environ)
for key,folder in {'HOME':'home','XDG_DATA_HOME':'data','XDG_CONFIG_HOME':'config','XDG_CACHE_HOME':'cache'}.items():
 d=out/folder;d.mkdir();env[key]=str(d)
for key in list(env):
 if key=='GODOT_SCRIPT_ENCRYPTION_KEY' or key.startswith('GODOT_WINDOWS_CODESIGN_'):env.pop(key)
logs=out/'logs';logs.mkdir();records=[]
def run(label,args,cwd=out):
 r=subprocess.run(args,env=env,cwd=cwd,capture_output=True,text=True,timeout=240);log=r.stdout+r.stderr;(logs/(label+'.log')).write_text(log)
 item={'step':label,'exit':r.returncode,'engine_error':'ERROR:' in log,'pass':r.returncode==0 and 'ERROR:' not in log};records.append(item);(out/'steps.json').write_text(json.dumps(records,indent=2)+'\n');print(json.dumps(item),flush=True);assert item['pass'],label;return log
version=run('engine-version',['godot','--headless','--version']).strip();assert version.startswith('4.6.3.stable.')
# Reuse the author's imported project. Independent final QA owns a separate cold import.
assert (src/'.godot').is_dir();folder=out/'runtime';folder.mkdir();pack=folder/'MossCircuit.pck';preset_results=[]
for label,preset in [('linux','Linux x86_64'),('windows','Windows x86_64')]:
 run(label+'-resource-pack',['godot','--headless','--path',str(src),'--export-pack',preset,str(pack)])
 preset_results.append({'preset':preset,'bytes':pack.stat().st_size,'sha256':sha(pack)})
assert preset_results[0]['sha256']==preset_results[1]['sha256'] and preset_results[0]['bytes']==preset_results[1]['bytes']
exact={};images={}
for folder_name in ['scripts','ui','data','assets']:
 for f in (src/folder_name).rglob('*'):
  if not f.is_file():continue
  rel=str(f.relative_to(src))
  if rel=='ui/test_ui.gd':continue
  if f.suffix in ['.gd','.json']:exact[rel]=sha(f)
  if f.suffix=='.png':images[rel]={}
exact['art_source/alpha_bounds.json']=sha(src/'art_source/alpha_bounds.json')
expected=out/'expected-resources.json';expected.write_text(json.dumps({'exact_files':exact,'images':images},indent=2)+'\n');fingerprint=out/'source-imported-fingerprints.json'
run('source-fingerprint',['godot','--headless','--path',str(src),'--script','res://tools/export_source_fingerprint.gd','--',str(expected),str(fingerprint)])
reader=out/'empty-reader-directory';reader.mkdir()
run('packed-resources',['godot','--headless','--main-pack',str(pack),'--script',str(src/'tools/verify_export_pack.gd'),'--',str(fingerprint),str(out/'packed-resource-report.json')],reader)
linked=out/'runtime/MossCircuit.x86_64';os.link(exe['linux'],linked);assert linked.stat().st_ino==exe['linux'].stat().st_ino and sha(linked)==expected_exe['linux']
run('accepted-linux-adjacent-pack-headless',[str(linked),'--headless','--quit-after','30'],linked.parent)
assert before==source_map(),'Non-cache source changed during export'
assert all(sha(f)==expected_exe[k] for k,f in exe.items())
prod={}
for folder_name in ['scripts','data','ui','scenes','assets']:
 for f in (src/folder_name).rglob('*'):
  if f.is_file() and f.suffix not in ['.uid','.import'] and str(f.relative_to(src))!='ui/test_ui.gd':prod[str(f.relative_to(src))]=sha(f)
for n in ['project.godot','export_presets.cfg','art_source/alpha_bounds.json']:prod[n]=sha(src/n)
report={'scope':'Resource-only update using held accepted source cache. Both existing presets sequentially exported to the same unaccepted output path; size and SHA256 equality required before freezing. No duplicate pack, template or executable payload. Existing accepted executable identities unchanged. Windows not run; native GUI acceptance separate.','engine_version':version,'author_cache_reused':True,'cold_import_in_this_build':False,'independent_cold_import_required':True,'source_fingerprint':dict(sorted(prod.items())),'non_cache_source_inputs_unchanged':len(before),'steps':records,'preset_results':preset_results,'pck':{'bytes':pack.stat().st_size,'sha256':sha(pack)},'accepted_executables':{k:{'name':f.name,'bytes':f.stat().st_size,'sha256':sha(f)} for k,f in exe.items()},'new_executables_generated':False,'windows_runtime_tested':False,'native_gui_tested':False,'byte_reproducibility_claim':False}
(out/'BUILD_REPORT.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps({'pass':True,'pck':report['pck'],'production_paths':len(prod)}),flush=True)
