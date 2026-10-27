from pathlib import Path
import argparse,hashlib,json,os,subprocess,time
p=argparse.ArgumentParser();p.add_argument('--candidate',required=True);p.add_argument('--inputs',required=True);p.add_argument('--pack-root',required=True);a=p.parse_args()
q=Path(__file__).parent;r=q/'project';candidate=Path(a.candidate);packroot=Path(a.pack_root);out=q/'r2-gate';out.mkdir(exist_ok=False)
h=lambda x:hashlib.sha256(x.read_bytes()).hexdigest()
old=json.loads((q/'FINAL_INPUTS.json').read_text());new=json.loads(Path(a.inputs).read_text())
assert all(h(r/n)==v for n,v in old.items())
assert all(h(candidate/n)==v for n,v in new.items())
removed=sorted(set(old)-set(new));assert not removed
delta={n:{'old':old.get(n),'new':v} for n,v in new.items() if old.get(n)!=v}
old_main=(r/'scripts/main.gd').read_text();new_main=(candidate/'scripts/main.gd').read_text()
old_branch='\telif build.get("weapons") is Array and build.weapons.size() == 1: reason = "Requires another STANDARD copy of this weapon."'
start=new_main.index('\telif build.get("weapons") is Array and build.weapons.size() == 1:\n',new_main.index('func _weapon_temper_view'))
end=new_main.index('\n\telse: reason = WeaponOrder.loadout_error',start)
assert new_main[:start]+old_branch+new_main[end:]==old_main
runtime_changed=[n for n in delta if n.startswith(('scripts/','ui/','data/','assets/','art_source/'))]
assert runtime_changed==['scripts/main.gd'],runtime_changed
for n,v in delta.items():
 target=r/n;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes((candidate/n).read_bytes())
assert all(h(r/n)==v for n,v in new.items())
(out/'SYNC_AND_DIFF.json').write_text(json.dumps({'old_inputs':len(old),'new_inputs':len(new),'delta':delta,'removed':removed,'runtime_changed':runtime_changed,'main_outside_reason_branch_exact':True},indent=2)+'\n')
(out/'FINAL_INPUTS.json').write_text(json.dumps(new,indent=2)+'\n')
env=os.environ.copy();env['GODOT_SILENCE_ROOT_WARNING']='1'
for k,n in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_CACHE_HOME','cache'),('XDG_DATA_HOME','data')]:env[k]=str(q/'private-r2-profile'/n)
steps=[]
def run(name,cmd,cwd=q,timeout=300):
 t=time.monotonic();proc=subprocess.run(cmd,cwd=cwd,env=env,capture_output=True,text=True,timeout=timeout);log=proc.stdout+proc.stderr;(out/(name+'.log')).write_text(log)
 row={'name':name,'exit':proc.returncode,'seconds':round(time.monotonic()-t,3),'engine_error':'ERROR:' in log};row['pass']=row['exit']==0 and not row['engine_error'];steps.append(row);(out/'STEPS.json').write_text(json.dumps(steps,indent=2)+'\n');print(json.dumps(row),flush=True);assert row['pass'],log[-3000:]
run('reused-cache-import',['godot','--headless','--editor','--path',str(r),'--import','--quit'])
for name in ['authority','combat','views','hint']:
 script=q/f'checks/independent_tempering_{name}.gd';assert h(script)==h(r/f'tests/independent_tempering_{name}.gd')
 run('source-'+name,['godot','--headless','--path',str(r),'--script',str(script),'--',str(out/('source-'+name+'.json'))])
run('old-six-transactions',['godot','--headless','--path',str(r),'--script',str(q/'checks/no_temper_transactions.gd'),'--',str(out/'transactions.json')])
assert (out/'transactions.json').read_bytes()==(q/'baseline/no-temper-transactions.json').read_bytes()
expected=json.loads((q/'final-gate/expected-resources.json').read_text())
for n in expected['exact_files']:expected['exact_files'][n]=h(r/n)
(out/'expected-resources.json').write_text(json.dumps(expected,indent=2)+'\n')
oracle=out/'source-imported-fingerprints.json'
run('source-oracle',['godot','--headless','--path',str(r),'--script','res://tools/export_source_fingerprint.gd','--',str(out/'expected-resources.json'),str(oracle)])
assert json.loads(oracle.read_text())==json.loads((packroot/'source-imported-fingerprints.json').read_text())
reader=out/'empty-reader';reader.mkdir();pack=packroot/'linux/MossCircuit.pck';assert h(pack)==h(packroot/'windows/MossCircuit.pck')
run('packed-resources',['godot','--headless','--main-pack',str(pack),'--script',str(r/'tools/verify_export_pack.gd'),'--',str(oracle),str(out/'packed-resource-report.json')],reader)
for name in ['authority','combat','views','hint']:
 run('packed-'+name,['godot','--headless','--main-pack',str(pack),'--script',str(q/f'checks/independent_tempering_{name}.gd'),'--',str(out/('packed-'+name+'.json'))],reader)
changes=[n for n,v in new.items() if h(r/n)!=v];assert not changes
summary={'status':'PASS','steps':steps,'source_inputs':len(new),'input_changes':changes,'source_oracle_exact':True,'both_preset_packs_equal':True,'runtime_changed':runtime_changed,'main_outside_reason_branch_exact':True,'import':'Reused-cache revalidation, not fresh cold import','r1_full_suite':'Separate completed104+import105 carried only across inspected copy-only delta; not a fresh R2 aggregate','pck':{'bytes':pack.stat().st_size,'sha256':h(pack)},'elf_sha256':h(pack.parent/'MossCircuit.x86_64'),'native_corrected_hint_pending':True,'ordinary_route':'Separate R1 artifact only; no R2 ordinary acquisition claim','windows_executed':False}
(out/'SUMMARY.json').write_text(json.dumps(summary,indent=2)+'\n');print(json.dumps(summary),flush=True)
