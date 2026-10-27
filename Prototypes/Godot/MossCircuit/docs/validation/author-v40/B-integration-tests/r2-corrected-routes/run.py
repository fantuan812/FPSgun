from pathlib import Path
import argparse,hashlib,json,subprocess,os,time,traceback,sys,math
q=Path(__file__).resolve().parent;p=q/'PLAN.json';out=q/'raw-first';project=Path('evidence-workspace/moss-v39-B-r2')
a=argparse.ArgumentParser();a.add_argument('--plan-sha256',required=True);approved=a.parse_args().plan_sha256
h=lambda f:hashlib.sha256(f.read_bytes()).hexdigest()
def inventory():
 result={}
 for f in project.rglob('*'):
  rel=f.relative_to(project)
  if '.godot' in rel.parts:continue
  if f.is_symlink():raise ValueError('symlink '+str(rel))
  if f.is_file():result[str(rel)]=h(f)
 return result

def helper_valid(report, owners):
 try:
  obs=report['observations'];last=obs[-1]
  integer_keys=['requested_owner_count','tracked_owner_count','game_owner_count','tracked_stream_count','pre_window_drained']
  if any(type(report[k]) is not int for k in integer_keys):return False
  if not (report['complete'] is True and report['capture_removed'] is True and report['prepare_errors']==[] and report['driver']=='Dummy' and report['requested_owner_count']==report['tracked_owner_count']==report['game_owner_count']==owners and report['tracked_stream_count']>0 and report['pre_window_drained']>=0):return False
  rate=report['mix_rate']
  if type(rate) not in (int,float) or not math.isfinite(rate) or rate<=0:return False
  for item in obs:
   if any(type(item[k]) is not int for k in ['owner_count','game_owner_count','prepare_errors','invalid','discarded','required_frames','new_pushed','silent_frames','elapsed_us']):return False
   if item['invalid']!=0 or item['discarded']!=0 or item['prepare_errors']!=0:return False
  return last['owner_count']==last['game_owner_count']==owners and last['prepare_errors']==0 and last['owners_released'] is True and last['streams_released'] is True and last['required_frames']==math.ceil(rate*.15) and last['new_pushed']>=last['required_frames']>0 and last['silent_frames']>=last['required_frames'] and 150000<=last['elapsed_us']<=1000000
 except (KeyError,TypeError,IndexError,ValueError,OverflowError):return False

if out.exists():raise SystemExit('REFUSE OVERWRITE')
out.mkdir();plan={};rows=[];issues=[];error=None;before={};after={}
def guard():
 if h(p)!=approved:raise ValueError('approved plan changed')
 for name,sha in plan['pins'].items():
  if h(Path(name))!=sha:raise ValueError('changed pin '+name)
 state=inventory()
 if state!=plan['inputs']:raise ValueError('R2 exact894 source set changed')
 return state
try:
 if h(p)!=approved:raise ValueError('caller plan mismatch')
 plan=json.loads(p.read_text());before=guard();(out/'BEFORE.json').write_text(json.dumps(before,indent=2)+'\n')
 cold=json.loads(Path(plan['cold_result']).read_text())
 if not (cold.get('pass') is True and cold.get('native_exit')==0 and cold.get('stderr_bytes')==0 and cold.get('after_issues')==[] and cold.get('generated')=={}):raise ValueError('R2 cold strict prerequisite absent')
 validation=json.loads(Path(plan['validator63_result']).read_text())
 if not (validation.get('pass') is True and validation.get('native_exit')==0 and validation.get('stderr_bytes')==0 and len(validation.get('records',[]))==1 and validation['records'][0].get('B_rules_configuration_checks')==63 and validation['records'][0].get('failures')==[]):raise ValueError('retained validator63 strict prerequisite absent')
 for route in plan['routes']:
  folder=out/route['name'];folder.mkdir();stdout=stderr=b'';rc=None;timed=False;exception=None;records=[];helpers=[];marker_errors=[];start=time.monotonic();env=dict(os.environ)
  for key,leaf in [('HOME','home'),('XDG_DATA_HOME','data'),('XDG_CONFIG_HOME','config'),('XDG_CACHE_HOME','cache')]:
   target=folder/leaf;target.mkdir();env[key]=str(target)
  try:
   guard()
   try:
    result=subprocess.run(['/usr/local/bin/godot','--headless','--audio-driver','Dummy','--path',str(project),'--script',route['script']],capture_output=True,env=env,timeout=180);stdout,stderr,rc=result.stdout,result.stderr,result.returncode
   except subprocess.TimeoutExpired as e:stdout,stderr=e.stdout or b'',e.stderr or b'';timed=True
   for line in stdout.decode(errors='replace').splitlines():
    if line.startswith('TEST_AUDIO_TEARDOWN '):
     try:
      value=json.loads(line[len('TEST_AUDIO_TEARDOWN '):])
      if not isinstance(value,dict):raise ValueError('helper must be object')
      helpers.append(value)
     except Exception:marker_errors.append(traceback.format_exc())
    elif line.lstrip().startswith('{') or route['marker'] in line or 'TEST_AUDIO_TEARDOWN' in line:
     try:
      value=json.loads(line)
      if not isinstance(value,dict) or route['marker'] not in value:raise ValueError('unexpected marker schema')
      records.append(value)
     except Exception:marker_errors.append(traceback.format_exc())
   guard()
  except Exception:exception=traceback.format_exc()
  (folder/'stdout.raw').write_bytes(stdout);(folder/'stderr.raw').write_bytes(stderr);(folder/'native.exit').write_text(str(rc)+'\n' if rc is not None else ('TIMEOUT\n' if timed else 'NO_NATIVE_EXIT\n'))
  text=(stdout+stderr).decode(errors='replace');tags=[tag for tag in ['SCRIPT ERROR','ERROR:','Parse Error','WARNING:','ObjectDB instances leaked','resources still in use'] if tag in text]
  helper_ok=len(helpers)==route['helpers'] and all(helper_valid(x,route['owners']) for x in helpers)
  good=helper_ok and rc==0 and not timed and exception is None and not stderr and not tags and not marker_errors and len(records)==1 and type(records[0].get(route['marker'])) is int and records[0][route['marker']]==route['checks'] and records[0].get('failures')==[]
  row={'name':route['name'],'pass':good,'native_exit':rc,'timed_out':timed,'seconds':time.monotonic()-start,'stderr_bytes':len(stderr),'strict_tags':tags,'exception':exception,'records':records,'helpers':helpers,'helper_ok':helper_ok,'marker_errors':marker_errors};rows.append(row);(folder/'RESULT.json').write_text(json.dumps(row,indent=2)+'\n');print(json.dumps(row),flush=True)
  if not good:break
except Exception:error=traceback.format_exc()
finally:
 try:after=guard()
 except Exception:issues.append(traceback.format_exc())
 (out/'AFTER.json').write_text(json.dumps(after,indent=2)+'\n')
 result={'pass':error is None and not issues and len(rows)==2 and all(row['pass'] for row in rows),'scope':'fixture-ID-corrected actual-chain56 and pure UI20; prior validator63 retained, not repeated; not independent/native/full acceptance','completed':len(rows),'exception':error,'after_issues':issues,'rows':rows,'approved_plan':approved};(out/'RESULT.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result),flush=True)
sys.exit(0 if result['pass'] else 1)
