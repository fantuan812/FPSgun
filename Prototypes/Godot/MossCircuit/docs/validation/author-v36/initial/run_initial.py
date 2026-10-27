from pathlib import Path
import os,subprocess,time,json,hashlib,re
r=Path('workspace/shared');src=r/'moss-v36-work';out=r/'moss-v36-prep/initial';assert not out.exists();out.mkdir();env=os.environ.copy()
for k,v in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_DATA_HOME','data'),('XDG_CACHE_HOME','cache')]: (out/v).mkdir();env[k]=str(out/v)
rows=[];h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();before=json.loads((r/'moss-v36-prep/PREIMPORT_INPUTS.json').read_text());assert all(h(src/n)==s for n,s in before.items());assert not (src/'.godot').exists()
commands=[('cold-import',['--editor','--import','--quit'],False),('scavenger-author',['--script','res://tests/test_scavenger_reel.gd'],True),('legacy-ui',['--script','res://ui/test_ui.gd'],True),('legacy-game',['--script','res://tests/test_game.gd'],True),('legacy-effects',['--script','res://tests/test_effects.gd'],True)]
(out/'PLAN.json').write_text(json.dumps({'source_map_sha256':h(r/'moss-v36-prep/PREIMPORT_INPUTS.json'),'commands':commands,'timeout_per_command':180,'stop_on_first_rejection':True},indent=2)+'\n')
for name,args,marker in commands:
 t=time.monotonic()
 try:
  p=subprocess.run(['godot','--headless','--audio-driver','Dummy','--path',str(src),*args],env=env,capture_output=True,text=True,timeout=180);stdout=p.stdout;stderr=p.stderr;code=p.returncode
 except subprocess.TimeoutExpired as e:
  stdout=e.stdout or b'';stderr=e.stderr or b'';stdout=stdout.decode(errors='replace') if isinstance(stdout,bytes) else stdout;stderr=stderr.decode(errors='replace') if isinstance(stderr,bytes) else stderr;stderr+='\nTIMEOUT180s';code=124
 (out/(name+'.stdout')).write_text(stdout);(out/(name+'.stderr')).write_text(stderr);log=stdout+stderr
 success=not marker or bool(re.search(r'"failures"\s*:\s*\[\s*\]|failures=\[\]|\b0 failed\b|\b0 failures\b|^PASS:|UI_STRUCTURE_AND_INTENTS_PASS',log,re.M));row={'case':name,'exit':code,'seconds':round(time.monotonic()-t,3),'semantic_marker':success,'error':'ERROR:' in log,'resource_warning':'instances leaked' in log or 'resources still in use' in log};row['pass']=code==0 and success and not row['error'] and not row['resource_warning'];rows.append(row);(out/'STEPS.json').write_text(json.dumps(rows,indent=2)+'\n');print(row,flush=True)
 if not row['pass']:break
changed=[n for n,s in before.items() if h(src/n)!=s];additions=sorted(str(p.relative_to(src)) for p in src.rglob('*') if p.is_file() and '.godot' not in p.parts and str(p.relative_to(src)) not in before)
report={'pass':len(rows)==len(commands) and all(x['pass'] for x in rows) and not changed,'commands_executed':len(rows),'changed_original_inputs':changed,'import_generated_inputs':additions};(out/'RESULT.json').write_text(json.dumps(report,indent=2)+'\n');print(report,flush=True);raise SystemExit(0 if report['pass'] else 1)
