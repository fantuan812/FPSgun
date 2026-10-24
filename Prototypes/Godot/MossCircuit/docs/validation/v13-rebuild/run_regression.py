import pathlib,subprocess,json,time,os,sys
import argparse
args=argparse.ArgumentParser(description='Run every standalone project check; writes logs outside project.')
args.add_argument('--project',type=pathlib.Path,default=pathlib.Path(__file__).resolve().parents[3])
args.add_argument('--output',type=pathlib.Path,required=True)
a=args.parse_args();p=a.project.resolve();q=a.output.resolve()
if q==p or p in q.parents:raise SystemExit('Output must be outside the project')
q.mkdir(parents=True,exist_ok=True);env={**os.environ}
for k,v in {'HOME':'home','XDG_DATA_HOME':'data','XDG_CONFIG_HOME':'config','XDG_CACHE_HOME':'cache'}.items():
 d=q/v;d.mkdir(exist_ok=True);env[k]=str(d)
r=subprocess.run(['godot','--headless','--path',str(p),'--editor','--import','--quit'],capture_output=True,text=True,env=env,timeout=180);(q/'import.log').write_text(r.stdout+r.stderr);out=[{'test':'import','exit':r.returncode,'error':'ERROR:' in r.stdout+r.stderr}]
for t in sorted((p/'tests').glob('*.gd'))+[p/'ui/test_ui.gd',p/'docs/art/check_icons.gd',p/'docs/art/check_mechanism_icons.gd',p/'docs/art/check_build_expansion_icons.gd']:
 if t.name.endswith('_fixture.gd'):continue
 start=time.time()
 try:r=subprocess.run(['godot','--headless','--path',str(p),'--script','res://'+str(t.relative_to(p))],capture_output=True,text=True,timeout=120,env=env);log=r.stdout+r.stderr;rc=r.returncode
 except subprocess.TimeoutExpired as e:log=str(e);rc=124
 (q/(t.name+'.log')).write_text(log);out.append({'test':t.name,'exit':rc,'error':'SCRIPT ERROR:' in log or 'ERROR:' in log,'seconds':round(time.time()-start,2)});print(out[-1],flush=True)
 (q/'summary.json').write_text(json.dumps(out,indent=2))
