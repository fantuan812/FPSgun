"""Private bounded PCK-only build orchestration. No executable generation or user installation."""
from pathlib import Path
import argparse,hashlib,json,os,shutil,subprocess
p=argparse.ArgumentParser();p.add_argument('--source',type=Path,required=True);p.add_argument('--output',type=Path,required=True);p.add_argument('--accepted-linux',type=Path,required=True);p.add_argument('--accepted-windows',type=Path,required=True);a=p.parse_args()
src=a.source.resolve();out=a.output.resolve();assert src.is_dir() and not out.exists() and src not in out.parents
sha=lambda f:hashlib.sha256(f.read_bytes()).hexdigest()
expected_exe={'linux':'2c78919325d7f29fa7607287c7c1eeac367ea4c94e7b8b6f5f4c6b20492f73d0','windows':'91724f15024a3a545e28ccd83134403d31ce2323a38e51c95e4dfa282f732ab6'}
executables={'linux':a.accepted_linux.resolve(),'windows':a.accepted_windows.resolve()}
assert all(f.is_file() and sha(f)==expected_exe[k] for k,f in executables.items())
out.mkdir();env=dict(os.environ)
for key,folder in {'HOME':'home','XDG_DATA_HOME':'data','XDG_CONFIG_HOME':'config','XDG_CACHE_HOME':'cache'}.items():
 d=out/folder;d.mkdir();env[key]=str(d)
for k in list(env):
 if k=='GODOT_SCRIPT_ENCRYPTION_KEY' or k.startswith('GODOT_WINDOWS_CODESIGN_'):env.pop(k)
logs=out/'logs';logs.mkdir();records=[]
def run(label,args,cwd=out):
 result=subprocess.run(args,env=env,cwd=cwd,capture_output=True,text=True,timeout=240)
 log=result.stdout+result.stderr;(logs/(label+'.log')).write_text(log)
 record={'step':label,'exit':result.returncode,'engine_error':'ERROR:' in log,'pass':result.returncode==0 and 'ERROR:' not in log};records.append(record);(out/'steps.json').write_text(json.dumps(records,indent=2)+'\n');print(json.dumps(record),flush=True)
 assert record['pass'],label
 return log
version=run('engine-version',['godot','--headless','--version']).strip();assert version.startswith('4.6.3.stable.')
stage=out/'project';shutil.copytree(src,stage,ignore=shutil.ignore_patterns('.godot','.git','__pycache__'))
run('cold-import',['godot','--headless','--path',str(stage),'--editor','--import','--quit'])
for platform,preset in [('linux','Linux x86_64'),('windows','Windows x86_64')]:
 folder=out/platform;folder.mkdir()
 run(platform+'-resource-pack',['godot','--headless','--path',str(stage),'--export-pack',preset,str(folder/'MossCircuit.pck')])
pack=out/'linux/MossCircuit.pck';assert sha(pack)==sha(out/'windows/MossCircuit.pck')
exact={};images={}
for folder in ['scripts','ui','data','assets']:
 for f in (stage/folder).rglob('*'):
  if not f.is_file():continue
  rel=str(f.relative_to(stage))
  if rel=='ui/test_ui.gd':continue
  if f.suffix in ['.gd','.json']:exact[rel]=sha(f)
  if f.suffix=='.png':images[rel]={}
exact['art_source/alpha_bounds.json']=sha(stage/'art_source/alpha_bounds.json')
expected=out/'expected-resources.json';expected.write_text(json.dumps({'exact_files':exact,'images':images},indent=2)+'\n')
fingerprint=out/'source-imported-fingerprints.json'
run('source-fingerprint',['godot','--headless','--path',str(stage),'--script','res://tools/export_source_fingerprint.gd','--',str(expected),str(fingerprint)])
reader=out/'empty-reader-directory';reader.mkdir()
run('packed-resources',['godot','--headless','--main-pack',str(pack),'--script',str(stage/'tools/verify_export_pack.gd'),'--',str(fingerprint),str(out/'packed-resource-report.json')],reader)
run('accepted-linux-new-pack-headless',[str(executables['linux']),'--main-pack',str(pack),'--headless','--quit-after','30'],reader)
assert all(sha(f)==expected_exe[k] for k,f in executables.items())
prod={}
for folder in ['scripts','data','ui','scenes','assets']:
 for f in (stage/folder).rglob('*'):
  if f.is_file() and f.suffix not in ['.uid','.import'] and str(f.relative_to(stage))!='ui/test_ui.gd':prod[str(f.relative_to(stage))]=sha(f)
for name in ['project.godot','export_presets.cfg','art_source/alpha_bounds.json']:prod[name]=sha(stage/name)
report={'scope':'Resource-only update. Two existing presets export identical PCK; accepted v23 executables reused unchanged, not rebuilt. Windows not executed; native GUI gate remains separate.','engine_version':version,'cold_import':True,'source_fingerprint':dict(sorted(prod.items())),'steps':records,'pck':{'bytes':pack.stat().st_size,'sha256':sha(pack)},'accepted_base_executables':{k:{'name':f.name,'bytes':f.stat().st_size,'sha256':sha(f)} for k,f in executables.items()},'new_executables_generated':False,'windows_runtime_tested':False,'native_gui_tested':False,'byte_reproducibility_claim':False}
(out/'BUILD_REPORT.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps({'pass':True,'pck':report['pck'],'production_paths':len(prod)}),flush=True)
