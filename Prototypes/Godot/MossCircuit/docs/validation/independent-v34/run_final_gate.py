from pathlib import Path
import os,subprocess,json,hashlib,time,sys,argparse
ap=argparse.ArgumentParser();ap.add_argument('--qa-root',type=Path,default=Path(__file__).parent);ap.add_argument('--pack-root',type=Path,required=True);a=ap.parse_args()
q=a.qa_root.resolve();r=q/'project';out=q/'final-gate';out.mkdir(exist_ok=False);packroot=a.pack_root.resolve();h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
inputs=json.loads((q/'FINAL_INPUTS.json').read_text());assert all(h(r/p)==v for p,v in inputs.items())
env=os.environ.copy();env['GODOT_SILENCE_ROOT_WARNING']='1'
for key,name in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_CACHE_HOME','cache'),('XDG_DATA_HOME','data')]:env[key]=str(q/'private-profile'/name)
steps=[]
def run(name,cmd,cwd=q,timeout=1200):
 start=time.monotonic();p=subprocess.run(cmd,cwd=cwd,env=env,capture_output=True,text=True,timeout=timeout);log=p.stdout+p.stderr;(out/(name+'.log')).write_text(log);row={'step':name,'exit':p.returncode,'seconds':round(time.monotonic()-start,3),'engine_error':'ERROR:' in log,'pass':p.returncode==0 and 'ERROR:' not in log};steps.append(row);(out/'STEPS.json').write_text(json.dumps(steps,indent=2)+'\n');print(json.dumps(row),flush=True);assert row['pass'],log[-3000:];return log
run('full-reused-cache-suite',['python',str(r/'tests/run_regression.py'),'--project',str(r),'--output',str(out/'full-suite')],timeout=2400)
assert json.loads((out/'full-suite/result.json').read_text())['all_pass']
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
for name in ['authority','combat','views']:
 script=r/f'tests/independent_focus_{name}.gd'
 assert h(script)==h(q/f'checks/independent_focus_{name}.gd')
 run('packed-'+name,['godot','--headless','--main-pack',str(pack),'--script',str(script),'--',str(out/(name+'.json'))],reader)
run('python-safety',['python',str(r/'tests/test_export_tools.py')])
changes=[p for p,v in inputs.items() if h(r/p)!=v];assert not changes
report={'status':'PASS','steps':steps,'source_inputs':len(inputs),'input_changes':changes,'final_import':'Reused-cache revalidation; R1 had independently executed true cold import.','source_oracle_exact':True,'both_preset_packs_equal':True,'pck':{'bytes':pack.stat().st_size,'sha256':h(pack)},'elf':{'bytes':(pack.parent/'MossCircuit.x86_64').stat().st_size,'sha256':h(pack.parent/'MossCircuit.x86_64')},'ordinary_gui_pending':True,'windows_executed':False}
(out/'SUMMARY.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report),flush=True)
