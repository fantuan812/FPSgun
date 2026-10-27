from pathlib import Path
import os,subprocess,time,json,hashlib
r=Path('workspace/shared');root=r/'moss-v37-parity';out=root/'results';assert not out.exists();out.mkdir();plan=json.loads((root/'EXECUTION_PLAN.json').read_text());h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();env=os.environ.copy();maps={Path(x['project']):json.loads(Path(x['map']).read_text()) for x in plan['source_maps']}
for x in plan['source_maps']:assert h(Path(x['map']))==x['sha256']
for p,m in maps.items():assert all(h(p/n)==s for n,s in m.items())
for row in plan['routes']:
 assert h(Path(row['fixture']))==row['fixture_sha256']
 if row['retained_trace']:assert h(Path(row['retained_trace']))==row['retained_trace_sha256']
assert h(r/'moss-v35-r4/data/catalog.json')==plan['old_catalog_sha256']
assert h(r/'moss-v36-r2/data/catalog.json')==h(r/'moss-v37-work/data/catalog.json')==plan['current_catalog_sha256']
for k,v in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_DATA_HOME','data'),('XDG_CACHE_HOME','cache')]: (out/v).mkdir();env[k]=str(out/v)
records=[]
for row in plan['routes']:
 name=row['name'];target=out/(name+'.json');start=time.monotonic()
 try:
  proc=subprocess.run(['godot','--headless','--audio-driver','Dummy','--path',row['project'],'--script',row['fixture'],'--',str(target)],env=env,capture_output=True,text=True,timeout=180);stdout=proc.stdout;stderr=proc.stderr;code=proc.returncode
 except subprocess.TimeoutExpired as e:
  stdout=e.stdout or b'';stderr=e.stderr or b'';stdout=stdout.decode(errors='replace') if isinstance(stdout,bytes) else stdout;stderr=stderr.decode(errors='replace') if isinstance(stderr,bytes) else stderr;stderr+='\nTIMEOUT180s';code=124
 (out/(name+'.stdout')).write_text(stdout);(out/(name+'.stderr')).write_text(stderr);log=stdout+stderr;semantic=json.loads(target.read_text()) if target.exists() else {};helpers=[json.loads(l.split('TEST_AUDIO_TEARDOWN ',1)[1]) for l in log.splitlines() if l.startswith('TEST_AUDIO_TEARDOWN ')];clean=len(helpers)==1
 for d in helpers:
  z=d['observations'][-1];clean=clean and d['complete'] and d['capture_removed'] and not d['prepare_errors'] and d['requested_owner_count']==d['tracked_owner_count']>0 and d['game_owner_count']>0 and d['tracked_stream_count']>0 and z['owners_released'] and z['streams_released'] and z['new_pushed']>=z['required_frames']>0 and z['silent_frames']>=z['required_frames'] and 150000<=z['elapsed_us']<=1000000 and all(x['invalid']==x['discarded']==0 for x in d['observations'])
 reference=Path(row['retained_trace']) if row['retained_trace'] else (out/'current-transactions-baseline.json' if name=='current-transactions-candidate' else None)
 equal=target.is_file() and (reference is None or target.read_bytes()==reference.read_bytes());count=6 if 'transactions' in name else 24;ok=code==0 and semantic.get('failures')==[] and len(semantic.get('cases',[]))==count and clean and equal and not any(x in log for x in ['ERROR:','instances leaked','resources still in use'])
 record={'name':name,'exit':code,'seconds':round(time.monotonic()-start,3),'pass':ok,'case_count':len(semantic.get('cases',[])),'reference_bytes_equal':equal if reference else None,'trace_sha256':h(target) if target.exists() else None,'helper_clean':clean};records.append(record);(out/'STEPS.json').write_text(json.dumps(records,indent=2)+'\n');print(record,flush=True)
 if not ok:raise SystemExit(1)
assert all(h(p/n)==s for p,m in maps.items() for n,s in m.items())
result={'pass':True,'steps':records,'source_maps_unchanged':True,'scope':plan['scope']};(out/'RESULT.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result))
