"""Unique independent combined926 packed22. Requires actual immutable export and separate review."""
from pathlib import Path
import argparse,json,hashlib,subprocess,os,time,shutil,sys,math,struct,re,signal,traceback,importlib.util
q=Path(__file__).parent;R=q.parent;ap=argparse.ArgumentParser();ap.add_argument('--plan-sha256',required=True);approved=ap.parse_args().plan_sha256
pp=q/'PACKED_COMBINED_PLAN.json';out=q/'packed-combined-first';project=q/'packed-combined-project';h=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
if out.exists() or project.exists():raise SystemExit('REFUSE OVERWRITE')
out.mkdir();plan={};pins={};rows=[];errors=[];source=None;before={};after={};frozen={}
def inventory(root):
 result={}
 for f in root.rglob('*'):
  rel=f.relative_to(root)
  if '.godot' in rel.parts:continue
  assert not f.is_symlink(),str(f)
  if f.is_file():result[str(rel)]=h(f)
 return result
def guard():
 assert h(pp)==approved
 for p,v in plan['pins'].items():assert h(p)==v,p
 assert inventory(source)==pins
 if project.exists():assert inventory(project)==pins

def helper_ok(d,owners):
 if not isinstance(d,dict):return False
 rate=d.get('mix_rate');obs=d.get('observations')
 if type(rate) not in (int,float) or not math.isfinite(rate) or rate<=0 or not isinstance(obs,list) or not obs or not all(isinstance(o,dict) for o in obs):return False
 required=math.ceil(rate*.15);last=obs[-1]
 return (d.get('driver')=='Dummy' and d.get('complete') is True and d.get('capture_removed') is True and d.get('prepare_errors')==[] and d.get('requested_owner_count')==d.get('tracked_owner_count')==d.get('game_owner_count')==owners and type(d.get('tracked_stream_count')) is int and d['tracked_stream_count']>0 and all(o.get('invalid')==o.get('discarded')==o.get('prepare_errors')==0 and o.get('owner_count')==o.get('game_owner_count')==owners and o.get('required_frames')==required for o in obs) and last.get('owners_released') is True and last.get('streams_released') is True and last.get('new_pushed',-1)>=required and last.get('silent_frames',-1)>=required and 150000<=last.get('elapsed_us',-1)<=1000000)

def parse_stdout(raw,cold=False):
 text=raw.decode('utf-8',errors='strict');reports=[];helpers=[];offset=0;consumed=0;decoder=json.JSONDecoder()
 for line in text.splitlines(keepends=True):
  start=offset;offset+=len(line)
  if start<consumed:continue
  stripped=line.lstrip()
  if line.startswith('TEST_AUDIO_TEARDOWN '):helpers.append(json.loads(line.split(' ',1)[1]));continue
  if stripped.startswith('{'):
   pos=start+len(line)-len(stripped);value,end=decoder.raw_decode(text[pos:]);assert isinstance(value,dict);reports.append(value);consumed=pos+end;line_end=text.find('\n',consumed);line_end=len(text) if line_end<0 else line_end;assert text[consumed:line_end].strip()=='';continue
  if '{' in line or 'TEST_AUDIO_TEARDOWN' in line:raise ValueError('malformed/prefixed report')
  clean=re.sub(r'\x1b\[[0-9;]*m','',line)
  if cold and re.match(r'^\[\s*(?:(?:100|[1-9]?[0-9])%|DONE)\s*\]',clean):continue
  if 'checks' in line or 'failures' in line or stripped.startswith(('"','[',']','}')):raise ValueError('apparent malformed report')
 return reports,helpers

def run(name,cmd,checks=None,helper=0,report_file=None,policy=None,observations=None,vector=None,status=None,count_key="checks"):
 d=out/name;d.mkdir();stdout=stderr=b'';native=None;timeout=False;exception=None;reports=[];helpers=[];full=None;t=time.monotonic();semantic=False
 try:
  env=dict(os.environ)
  for key,leaf in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_DATA_HOME','data'),('XDG_CACHE_HOME','cache')]:
   p=d/leaf;p.mkdir();env[key]=str(p)
  (d/'COMMAND.json').write_text(json.dumps(cmd,indent=2)+'\n')
  proc=subprocess.Popen(cmd,cwd=reader,env=env,stdout=subprocess.PIPE,stderr=subprocess.PIPE,start_new_session=True)
  try:stdout,stderr=proc.communicate(timeout=180)
  except subprocess.TimeoutExpired:
   timeout=True
   try:os.killpg(proc.pid,signal.SIGKILL)
   except ProcessLookupError:pass
   stdout,stderr=proc.communicate()
  native=proc.returncode
  reports,helpers=parse_stdout(stdout,name=='source-cold-import')
  assert len(helpers)==(1 if helper else 0) and all(helper_ok(x,helper) for x in helpers)
  text=(stdout+stderr).decode('utf-8',errors='strict');assert not any(x in text for x in ['SCRIPT ERROR','ERROR:','Parse Error','WARNING:','instances leaked','resources still in use'])
  if name=='python-export-safety':
   assert re.fullmatch(r'\.\.\.\n-{70}\nRan 3 tests in [0-9.]+s\n\nOK\n',stderr.decode()) and not reports
  else:assert stderr==b''
  if checks is not None:
   assert len(reports)==1 and type(reports[0].get(count_key)) is int and reports[0][count_key]==checks and reports[0].get('failures')==[]
  elif status is not None:assert len(reports)==1 and reports[0].get('status')==status and reports[0].get('failures')==[]
  else:assert not reports
  full=reports[0] if reports else None
  if report_file is not None:
   full=json.loads(report_file.read_text());assert isinstance(full,dict)
   if policy:assert report_policy.classify(reports[0],full,policies[policy])['accepted']
   else:assert full==reports[0]
  if observations is not None:
   observed=full.get('observations',[]);assert isinstance(observed,list) and len(observed)==observations and all(isinstance(x,dict) for x in observed)
  if vector:
   accepted=json.loads(Path(vector['path']).read_text())
   for key in vector.get('selection',[]):accepted=accepted[key]
   assert full[vector.get('field','observations')]==accepted
  if name=='audio-mixer':
   windows=full['windows'];assert len(windows)==51 and len(full['shapes'])==5
   for w in windows:assert w['discarded_before']==w['discarded_after']==w['nonfinite']==0 and w['fresh_pushed_frames']>=2048 and w['frames']>=2048 and w['pushed_after']-w['pushed_before']==w['fresh_pushed_frames']
   files=list((d/'pcm').glob('*.f32le'));assert len(files)==7
   for f in files:
    ws=[w for w in windows if w.get('raw_file')==f.name];assert len(ws)==1;w=ws[0];data=f.read_bytes();assert h(f)==w['pcm_f32le_stereo_sha256'] and len(data)==w['frames']*8
    samples=struct.unpack('<'+'f'*(len(data)//4),data);assert all(math.isfinite(x) for x in samples);assert abs(max(map(abs,samples))-w['peak'])<1e-6 and abs(math.sqrt(sum(x*x for x in samples)/len(samples))-w['rms'])<1e-6
  semantic=True
 except Exception:exception=traceback.format_exc()
 finally:
  (d/'stdout.raw').write_bytes(stdout);(d/'stderr.raw').write_bytes(stderr);(d/'native.exit').write_text(str(native)+'\n' if native is not None else 'NOT_COMPLETED\n')
  row={'name':name,'native_exit':native,'timeout':timeout,'seconds':time.monotonic()-t,'reports':reports,'helpers':helpers,'full_report':full,'exception':exception,'semantic':semantic,'pass':native==0 and not timeout and semantic and exception is None};(d/'RESULT.json').write_text(json.dumps(row,indent=2)+'\n');rows.append({k:v for k,v in row.items() if k not in ['reports','helpers','full_report']});(out/'STEPS.json').write_text(json.dumps(rows,indent=2)+'\n');print(json.dumps(rows[-1]),flush=True)
 if not row['pass']:raise RuntimeError('first FAIL '+name)
 return full
try:
 assert h(pp)==approved;plan=json.loads(pp.read_text());source=Path(plan['source']);pins=json.loads(Path(plan['source_map']).read_text());assert len(pins)==926;guard()
 for item in plan['preconditions']:
  receipt=json.loads(Path(item['path']).read_text())
  for key in item['required_true']:assert receipt.get(key) is True
 packroot=Path(plan['pack_root']);pack=packroot/'linux/MossCircuit.pck';assert h(pack)==plan['pck_sha256']==h(packroot/'windows/MossCircuit.pck')
 before=inventory(source);project.mkdir()
 for rel in pins:
  p=project/rel;p.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(source/rel,p)
 guard();(out/'SOURCE_BEFORE.json').write_text(json.dumps(before,indent=2)+'\n');reader=out/'empty-reader';reader.mkdir()
 spec=importlib.util.spec_from_file_location('packed_report_policy',q/'packed-report-policy.py');report_policy=importlib.util.module_from_spec(spec);spec.loader.exec_module(report_policy);policies=json.loads((q/'PACKED_REPORT_POLICIES.json').read_text())['policies']
 engine=['/usr/local/bin/godot','--headless','--audio-driver','Dummy']
 run('source-cold-import',engine+['--path',str(project),'--editor','--import','--quit'])
 exact={};images={}
 for folder in ['scripts','ui','data','assets']:
  for p in (project/folder).rglob('*'):
   if not p.is_file():continue
   rel=str(p.relative_to(project))
   if rel=='ui/test_ui.gd':continue
   if p.suffix in ['.gd','.json']:exact[rel]=h(p)
   if p.suffix=='.png':images[rel]={}
 exact['art_source/alpha_bounds.json']=h(project/'art_source/alpha_bounds.json');assert len(exact)==84 and len(images)==72
 expected=out/'expected-resources.json';expected.write_text(json.dumps({'exact_files':exact,'images':images},indent=2)+'\n');oracle=out/'source-imported-fingerprints.json'
 run('source-resource-fingerprint',engine+['--path',str(project),'--script','res://tools/export_source_fingerprint.gd','--',str(expected),str(oracle)])
 assert json.loads(oracle.read_text())==json.loads((packroot/'source-imported-fingerprints.json').read_text())
 rf=out/'packed-resources/report.json';resources=run('packed-resources',engine+['--main-pack',str(pack),'--script',str(project/'tools/verify_export_pack.gd'),'--',str(oracle),str(rf)],998,report_file=rf);assert {k:resources[k] for k in ['exact_files','images','actions','action_frames']}=={'exact_files':84,'images':72,'actions':28,'action_frames':308}
 for b in plan['bindings']:
  name=b['name'];cmd=engine+['--main-pack',str(pack),'--script',b['script']];rf=out/name/'report.json' if b.get('write_report') else None;args=[]
  for arg in b.get('args',[]):args.append(arg.replace('{ORACLE}',str(oracle)).replace('{REPORT}',str(rf)).replace('{PCM}',str(out/name/'pcm')))
  if args:cmd+=['--',*args]
  run(name,cmd,b['checks'],b['helper_owners'],rf,b.get('policy'),b.get('observations'),b.get('vector'),count_key=b.get('count_key','checks'))
 svg=run('packed-svg',engine+['--main-pack',str(pack),'--script',str(q/'packed-harness/independent_scavenger_icon.gd'),'--','verify',str(q/'packed-harness/svg-oracle.json')],status='PASS');assert svg==plan['accepted_svg_report']
 rf=out/'python-pcm/report.json';run('python-pcm',['/usr/bin/python3',str(q/'packed-harness/independent_feedback_pcm.py'),str(project),str(rf)],38,report_file=rf)
 run('python-export-safety',['/usr/bin/python3',str(project/'tests/test_export_tools.py')]);assert len(rows)==22
except Exception:errors.append(traceback.format_exc())
finally:
 try:guard();after=inventory(source);assert inventory(project)==pins
 except Exception:errors.append('AFTERGUARD '+traceback.format_exc())
 (out/'SOURCE_AFTER.json').write_text(json.dumps(after,indent=2)+'\n');summary={'pass':not errors and len(rows)==22 and all(x['pass'] for x in rows),'completed':len(rows),'errors':errors,'source_map_sha256':plan.get('source_map_sha256'),'pck_sha256':plan.get('pck_sha256'),'source_sets_unchanged':not any('AFTERGUARD' in e for e in errors),'scope':'Independent combined926 packed22; Arena435/Rooms338 each180, total360. Original B source35+435+129 remains combined, not single165. Source/PCK specified vectors compared; mixer timing not asserted identical. Native and one ordinary attempt separate.'};(out/'SUMMARY.json').write_text(json.dumps(summary,indent=2)+'\n');print(json.dumps(summary),flush=True)
sys.exit(0 if summary['pass'] else 1)
