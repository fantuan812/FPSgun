"""Exact independent source copy, first finite four routes. No acceptance retries."""
from pathlib import Path
import sys,json,hashlib,subprocess,os,time,shutil,datetime
q=Path(__file__).resolve().parent
src=Path('<WORKSPACE>/moss-v37-work')
map_path=Path(sys.argv[1]); expected_map_sha=sys.argv[2]
h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
assert h(map_path)==expected_map_sha
pins=json.loads(map_path.read_text())
assert all(h(src/p)==s for p,s in pins.items())
frozen={}
for name in ['ORACLE_FREEZE.json','SUPPLEMENTAL_FREEZE.json']:
    frozen.update(json.loads((q/name).read_text())['files'])
v=json.loads((q/'VIEWS_FREEZE.json').read_text());frozen['checks/independent_forecast_views.gd']=v['sha256']
assert all(h(q/p)==s for p,s in frozen.items())
out=q/'first';project=q/'source-first';assert not out.exists() and not project.exists();out.mkdir();project.mkdir()
for p in pins:
    dst=project/p;dst.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(src/p,dst)
assert all(h(project/p)==s for p,s in pins.items())
env=os.environ.copy()
for k,p in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_DATA_HOME','data'),('XDG_CACHE_HOME','cache')]:
    (out/p).mkdir();env[k]=str(out/p)
cases=[('cold-import',['--editor','--import','--quit'],False),('authority',['--script',str(q/'checks/independent_forecast_authority.gd')],False),('legacy',['--script',str(q/'checks/independent_forecast_legacy.gd')],False),('controller',['--script',str(q/'checks/independent_forecast_controller.gd')],True),('views',['--script',str(q/'checks/independent_forecast_views.gd')],True)]
plan={'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'source_map':str(map_path),'source_map_sha256':expected_map_sha,'inputs':len(pins),'scripts':frozen,'runner_sha256':h(Path(__file__)),'cases':cases,'timeout_per_case_seconds':180,'stop_on_first_failure':True,'independent_source_copy':str(project),'no_prior_result_reclassified':True}
(out/'PLAN.json').write_text(json.dumps(plan,indent=2)+'\n')
rows=[]
for name,args,helper in cases:
    start=time.monotonic();timeout=False
    try:
        p=subprocess.run(['godot','--headless','--audio-driver','Dummy','--path',str(project),*args],env=env,capture_output=True,timeout=180)
        stdout,stderr,code=p.stdout,p.stderr,p.returncode
    except subprocess.TimeoutExpired as e:
        stdout,stderr,code=e.stdout or b'',e.stderr or b'',124;timeout=True
    (out/(name+'.stdout')).write_bytes(stdout);(out/(name+'.stderr')).write_bytes(stderr)
    text=(stdout+stderr).decode(errors='replace'); reports=[];teardowns=[]
    for line in stdout.decode(errors='replace').splitlines():
        if line.startswith('TEST_AUDIO_TEARDOWN '):teardowns.append(json.loads(line.removeprefix('TEST_AUDIO_TEARDOWN ')))
        elif line.startswith('{'):
            try: reports.append(json.loads(line))
            except json.JSONDecodeError:pass
    clean=not any(marker in text for marker in ['ERROR:','instances leaked','resources still in use'])
    semantic=name=='cold-import' or bool(reports and reports[-1].get('failures')==[] and reports[-1].get('checks',0)>0)
    helper_ok=not helper or bool(teardowns and all(t.get('complete') and t.get('capture_removed') and t.get('requested_owner_count',0)>0 and not t.get('prepare_errors') for t in teardowns))
    row={'case':name,'native_exit':code,'timeout':timeout,'seconds':round(time.monotonic()-start,3),'clean':clean,'semantic':semantic,'helper_ok':helper_ok,'reports':reports,'teardowns':teardowns,'pass':code==0 and clean and semantic and helper_ok}
    rows.append(row);(out/'STEPS.json').write_text(json.dumps(rows,indent=2)+'\n');print(json.dumps({k:v for k,v in row.items() if k not in ['reports','teardowns']}),flush=True)
    if not row['pass']:break
changes={label:[p for p,s in pins.items() if not (root/p).exists() or h(root/p)!=s] for label,root in [('author_source',src),('qa_copy',project)]}
script_changes=[p for p,s in frozen.items() if h(q/p)!=s]
result={'pass':len(rows)==len(cases) and all(x['pass'] for x in rows) and not any(changes.values()) and not script_changes,'completed':len(rows),'planned':len(cases),'source_changes':changes,'script_changes':script_changes}
(out/'RESULT.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result),flush=True);sys.exit(0 if result['pass'] else 1)
