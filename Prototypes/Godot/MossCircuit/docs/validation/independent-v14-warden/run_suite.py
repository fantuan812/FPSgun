import os,subprocess,json,pathlib,sys,time
project=pathlib.Path(sys.argv[1]);out=pathlib.Path(sys.argv[2]);out.mkdir(parents=True,exist_ok=True)
env={**os.environ,'HOME':'/tmp/moss-independent-home','XDG_CACHE_HOME':'/tmp/moss-independent-cache','XDG_DATA_HOME':'/tmp/moss-independent-data','XDG_CONFIG_HOME':'/tmp/moss-independent-config'}
results=[]
for file in sorted(list((project/'tests').glob('*.gd'))+list((project/'ui').glob('test*.gd'))):
    if not file.read_text().lstrip().startswith('extends SceneTree'):continue
    start=time.time()
    try:
        p=subprocess.run(['godot','--headless','--path',str(project),'--script','res://'+str(file.relative_to(project))],capture_output=True,text=True,env=env,timeout=120)
        log=p.stdout+p.stderr;code=p.returncode
    except subprocess.TimeoutExpired as e:log=str(e);code=124
    (out/(file.stem+'.log')).write_text(log)
    error=any(s in log for s in ['SCRIPT ERROR:','Parse Error:','ERROR:'])
    row={'test':file.name,'exit':code,'engine_errors':error,'seconds':round(time.time()-start,2),'passed':code==0 and not error}
    results.append(row);print(json.dumps(row),flush=True)
(out/'suite.json').write_text(json.dumps({'passed':all(r['passed'] for r in results),'results':results},indent=2))
sys.exit(not all(r['passed'] for r in results))
