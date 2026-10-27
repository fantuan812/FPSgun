from pathlib import Path
import json,hashlib,math,ast,importlib.util,struct
R=Path('workspace/shared');q=R/'moss-v39-items/B-full-evidence';new=q/'source-continue';old=q/'source';h=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest();j=lambda p:json.loads(p.read_text())
plan=j(new/'PLAN.json');assert h(new/'PLAN.json')=='576025a1b6191fa315f5a6e1aa4ac7c09d6c5f3ce0764aeab069e324ba87feeb'
# Load only pure helpers; never import an execution runner.
ns={'math':math};tree=ast.parse((new/'run_remaining.py').read_text());f=next(x for x in tree.body if isinstance(x,ast.FunctionDef) and x.name=='helper_check');exec(compile(ast.Module(body=[f],type_ignores=[]),'pure_helper','exec'),ns)
def load(name,path):
 s=importlib.util.spec_from_file_location(name,path);m=importlib.util.module_from_spec(s);s.loader.exec_module(m);return m
policy=load('reportpolicy',new/'report_policy.py');warning=load('warningpolicy',new/'warning_policy.py');rows=[]
original=j(old/'PLAN.json');assert [r['name'] for r in plan['routes']]==[r['name'] for r in original['routes'][36:]]
assert j(old/'raw-first/RESULT.json')['pass'] is False
prior=j(R/'moss-v39-B-qa/B_SOURCE_STOP36_FULL435_REVIEW.json');assert prior['review_pass'] and prior['actual_435_semantic_pass']
for source,routes in [(old,original['routes'][:35]),(new,plan['routes'])]:
 for route in routes:
  d=source/'raw-first'/route['name'];result=j(d/'RESULT.json');stdout=(d/'stdout.raw').read_text();stderr=(d/'stderr.raw').read_bytes();assert (d/'native.exit').read_text().strip()=='0';assert result['pass'] and result['native_exit']==0 and not result['timeout'] and result['seconds']<180 and not result['exception'] and not result['parse_errors'] and not result['tags']
  hs=[];reports=[]
  for line in stdout.splitlines():
   if line.startswith('TEST_AUDIO_TEARDOWN '):hs.append(json.loads(line.split(' ',1)[1]))
   elif '{' in line and not line.startswith('Godot Engine'):reports.append((line[:line.index('{')],json.loads(line[line.index('{'):])))
  assert len(hs)==len(route['helper_schemas']) and all(ns['helper_check'](v,s) for v,s in zip(hs,route['helper_schemas']))
  assert hs==result['helpers'];assert warning.classify(stderr,route.get('stderr_policy'))['accepted']
  marker=route['marker'];report=None
  if marker['kind']=='json':
   assert len(reports)==1;prefix,report=reports[0];assert prefix==marker['prefix'] and report['failures']==[];assert all(type(report.get(k)) is int and report[k]==v for k,v in marker['counts'].items())
   assert result['reports']==[report]
  else:assert not reports and stdout.splitlines().count(marker['text'])==1
  if route.get('write_report'):
   full=j(d/'report.json')
   if source==new:assert policy.classify(report,full,route['report_policy'])['accepted']
   else:assert full==report
   if route.get('mixer_pcm'):
    windows=full['windows'];assert len(windows)==51;files=list((d/'pcm').glob('*.f32le'));assert len(files)==7
    for p in files:
     w=next(w for w in windows if w.get('raw_file')==p.name);data=p.read_bytes();assert h(p)==w['pcm_f32le_stereo_sha256'] and len(data)==w['frames']*8
     samples=struct.unpack('<'+'f'*(len(data)//4),data);assert all(math.isfinite(x) for x in samples);assert abs(max(map(abs,samples))-w['peak'])<1e-6 and abs(math.sqrt(sum(x*x for x in samples)/len(samples))-w['rms'])<1e-6
  rows.append({'name':route['name'],'execution':source.name,'native_exit':0,'checks':marker.get('counts'),'helpers':len(hs),'stderr_bytes':len(stderr),'result_sha256':h(d/'RESULT.json')})
terminal=j(new/'raw-first/RESULT.json');assert terminal['pass'] and terminal['completed']==129 and terminal['after_issues']==[]
assert j(new/'raw-first/BEFORE.json')==j(new/'raw-first/AFTER.json')==plan['inputs']
actual={str(p.relative_to(Path(plan['project']))):h(p) for p in Path(plan['project']).rglob('*') if p.is_file() and '.godot' not in p.relative_to(Path(plan['project'])).parts};assert actual==plan['inputs'] and len(actual)==907
for p,v in plan['pins'].items():assert h(p)==v,p
out={'review_pass':True,'source_combination_pass':True,'scope':'35 original strict routes + separately independently reviewed original435 + remaining129; original36-stop FAIL retained, not a new single165 process. Cold separate; excludes packed/native/ordinary.','original_aggregate_pass':False,'original_first35':35,'original435_independent_review_sha256':h(R/'moss-v39-B-qa/B_SOURCE_STOP36_FULL435_REVIEW.json'),'remaining129':129,'total_distinct_source_routes':165,'live_source_files':907,'live_pins':len(plan['pins']),'original_failure_preserved':True,'rows':rows};dest=R/'moss-v39-B-qa/B_SOURCE_COMBINATION_RAW_REVIEW.json';dest.write_text(json.dumps(out,indent=2)+'\n');print(json.dumps({k:v for k,v in out.items() if k!='rows'}));print('sha256',h(dest))
