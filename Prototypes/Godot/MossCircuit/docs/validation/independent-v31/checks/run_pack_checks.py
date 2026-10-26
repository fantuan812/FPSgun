"""Independent imported-source oracle regeneration and packed reader checks; no export/rebuild."""
import argparse,hashlib,json,os,subprocess,time
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--project',type=Path,required=True);p.add_argument('--runtime',type=Path,required=True);p.add_argument('--output',type=Path,required=True);p.add_argument('--checks',type=Path,required=True);p.add_argument('--expected-pck',required=True);a=p.parse_args()
root=a.project.resolve();runtime=a.runtime.resolve();out=a.output.resolve();out.mkdir(parents=True,exist_ok=True);reader=out/'empty-reader';reader.mkdir(exist_ok=True)
env=dict(os.environ)
for key,d in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_DATA_HOME','data'),('XDG_CACHE_HOME','cache')]:
 path=out/'private-profile'/d;path.mkdir(parents=True,exist_ok=True);env[key]=str(path)
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
expected={'exact_files':{},'images':{}}
for folder in ('scripts','ui','data','assets'):
 for f in sorted((root/folder).rglob('*')):
  if not f.is_file() or f.relative_to(root).as_posix()=='ui/test_ui.gd':continue
  n=f.relative_to(root).as_posix()
  if f.suffix in ('.gd','.json'):expected['exact_files'][n]=sha(f)
  if f.suffix=='.png':expected['images'][n]={}
expected['exact_files']['art_source/alpha_bounds.json']=sha(root/'art_source/alpha_bounds.json')
(out/'expected-resources.json').write_text(json.dumps(expected,indent=2)+'\n');rows=[]
def run(name,cmd,cwd=root):
 t=time.monotonic();r=subprocess.run(cmd,cwd=cwd,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=180);txt=r.stdout.decode('utf8',errors='replace');(out/(name+'.log')).write_bytes(r.stdout)
 row={'name':name,'exit':r.returncode,'error':'ERROR:' in txt,'seconds':round(time.monotonic()-t,3),'pass':r.returncode==0 and 'ERROR:' not in txt};rows.append(row);print(json.dumps(row),flush=True);(out/'steps.json').write_text(json.dumps(rows,indent=2)+'\n');assert row['pass'],name
run('python_safety',['python','tests/test_export_tools.py'])
run('independent_source_imported',['godot','--headless','--path',str(root),'--script','res://tools/export_source_fingerprint.gd','--',str(out/'expected-resources.json'),str(out/'source-imported-fingerprints.json')])
fp=json.loads((out/'source-imported-fingerprints.json').read_text());author=json.loads((runtime.parent/'source-imported-fingerprints.json').read_text());assert fp==author
run('packed_resources',['godot','--headless','--main-pack',str(runtime/'MossCircuit.pck'),'--script',str(root/'tools/verify_export_pack.gd'),'--',str(out/'source-imported-fingerprints.json'),str(out/'packed-resource-report.json')],reader)
run('packed_independent_loadouts',['godot','--headless','--main-pack',str(runtime/'MossCircuit.pck'),'--script',str(a.checks.resolve()/'independent_starting_loadouts.gd'),'--',str(out/'packed-loadouts.json')],reader)
run('packed_independent_views',['godot','--headless','--main-pack',str(runtime/'MossCircuit.pck'),'--script',str(a.checks.resolve()/'independent_starting_loadout_views.gd'),'--',str(out/'packed-views.json')],reader)
files={n:{'bytes':(runtime/n).stat().st_size,'sha256':sha(runtime/n)} for n in ['MossCircuit.pck','MossCircuit.x86_64']};assert files['MossCircuit.pck']['sha256']==sha(runtime.parent/'windows/MossCircuit.pck')
assert files['MossCircuit.pck']['sha256']==a.expected_pck
assert files['MossCircuit.x86_64']['sha256']=='2c78919325d7f29fa7607287c7c1eeac367ea4c94e7b8b6f5f4c6b20492f73d0'
result={'pass':True,'exact_file_count':len(expected['exact_files']),'images':len(expected['images']),'source_imported_fingerprint_equal_to_author':True,'independently_regenerated':True,'preset_packs_equal':True,'artifacts':files,'steps':rows,'scope':'Editor packed-resource reader from empty cwd, not exported GUI or Windows execution.'};(out/'SUMMARY.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result),flush=True)
