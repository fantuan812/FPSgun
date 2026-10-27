from pathlib import Path
import os,subprocess,time,json,hashlib,re
r=Path('workspace/shared');root=r/'moss-v36-parity';out=root/'results';assert not out.exists();out.mkdir();plan=json.loads((root/'PLAN.json').read_text());h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();env=os.environ.copy();maps={r/'moss-v35-r4':json.loads((r/'moss-v35-r4-prep/R4_INPUTS.json').read_text()),r/'moss-v36-work':json.loads((r/'moss-v36-prep/POSTIMPORT_INPUTS.json').read_text())}
for p,m in maps.items():assert all(h(p/n)==s for n,s in m.items())
assert h(Path(plan['old_catalog']))==plan['old_catalog_sha256']
for row in plan['fixtures']:assert h(Path(row['external_fixture']))==row['external_sha256'] and h(Path(row['historical_trace']))==row['historical_trace_sha256']
for k,v in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_DATA_HOME','data'),('XDG_CACHE_HOME','cache')]: (out/v).mkdir();env[k]=str(out/v)
records=[]
for label,project in [('baseline',r/'moss-v35-r4'),('candidate',r/'moss-v36-work')]:
 for row in plan['fixtures']:
  name=label+'-'+row['name'];target=out/(name+'.json');start=time.monotonic()
  try:
   p=subprocess.run(['godot','--headless','--audio-driver','Dummy','--path',str(project),'--script',row['external_fixture'],'--',str(target)],env=env,capture_output=True,text=True,timeout=180);stdout=p.stdout;stderr=p.stderr;code=p.returncode
  except subprocess.TimeoutExpired as e:
   stdout=e.stdout or b'';stderr=e.stderr or b'';stdout=stdout.decode(errors='replace') if isinstance(stdout,bytes) else stdout;stderr=stderr.decode(errors='replace') if isinstance(stderr,bytes) else stderr;stderr+='\nTIMEOUT180s';code=124
  (out/(name+'.stdout')).write_text(stdout);(out/(name+'.stderr')).write_text(stderr);log=stdout+stderr
  marker=bool(re.search(r'"failures"\s*:\s*\[\s*\]',log));equal=target.is_file() and target.read_bytes()==Path(row['historical_trace']).read_bytes();record={'name':name,'exit':code,'seconds':round(time.monotonic()-start,3),'error':'ERROR:' in log,'resource_warning':'instances leaked' in log or 'resources still in use' in log,'success_marker':marker,'historical_bytes_equal':equal,'trace_sha256':h(target) if target.exists() else None};record['pass']=code==0 and marker and equal and not record['error'] and not record['resource_warning'];records.append(record);(out/'STEPS.json').write_text(json.dumps(records,indent=2)+'\n');print(record,flush=True)
  if not record['pass']:raise SystemExit(1)
changes={str(p):[n for n,s in m.items() if h(p/n)!=s] for p,m in maps.items()};assert not any(changes.values());assert all((out/('baseline-'+row['name']+'.json')).read_bytes()==(out/('candidate-'+row['name']+'.json')).read_bytes() for row in plan['fixtures'])
result={'pass':True,'steps':records,'unchanged_input_counts':[len(m) for m in maps.values()],'source_changes':changes,'scope':plan['scope']};(out/'RESULT.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result))
