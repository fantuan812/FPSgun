from pathlib import Path
import hashlib,json,subprocess,time,os,shutil,sys,argparse,traceback
q=Path(__file__).resolve().parent;p=q/'PLAN.json';h=lambda f:hashlib.sha256(f.read_bytes()).hexdigest();project=q/'project';out=q/'raw-first'
parser=argparse.ArgumentParser();parser.add_argument('--plan-sha256',required=True);args=parser.parse_args();approved=args.plan_sha256
if out.exists():print('REFUSED_OVERWRITE');sys.exit(2)
out.mkdir();plan={};src=None;before={};rows=[];error=None

def inventory(root):
 if not root.exists():raise FileNotFoundError(str(root))
 result={}
 for f in root.rglob('*'):
  if '.godot' in f.relative_to(root).parts:continue
  if f.is_symlink():raise ValueError('symlink '+str(f))
  if f.is_file():result[str(f.relative_to(root))]=h(f)
 return result

def guard():
 result={'issues':[],'source':{},'project':{},'all_pins_unchanged':False}
 try:
  if h(p)!=approved:raise ValueError('approved plan identity changed')
  if not all(h(Path(k))==v for k,v in plan['pins'].items()):raise ValueError('execution pin changed')
  result['all_pins_unchanged']=True;result['source']=inventory(src)
  if {k:v for k,v in result['source'].items() if not k.endswith('.gd.uid')}!=plan['source_files']:raise ValueError('author authored map changed')
  if not all(k[:-4] in plan['source_files'] for k in result['source'] if k.endswith('.gd.uid')):raise ValueError('unexpected author UID')
  if project.exists():
   result['project']=inventory(project);actual=result['project'];extra={k:v for k,v in actual.items() if k not in plan['source_files']}
   if not all(actual.get(k)==v for k,v in plan['source_files'].items()) or not all(k.endswith('.gd.uid') and k[:-4] in plan['source_files'] for k in extra):raise ValueError('independent authored copy or extra paths changed')
 except Exception:result['issues'].append(traceback.format_exc())
 return result
try:
 if h(p)!=approved:raise ValueError('caller-approved PLAN mismatch')
 plan=json.loads(p.read_text());src=Path(plan['author_source'])
 if project.exists():raise ValueError('refuse existing independent project')
 pre=guard();(out/'PREFLIGHT.json').write_text(json.dumps(pre,indent=2)+'\n')
 if pre['issues']:raise ValueError('preflight failed')
 author=json.loads(Path(plan['author_result']).read_text());records=author.get('records',[])
 if not (author.get('status')=='PASS' and author.get('native_exit')==0 and len(records)==1 and records[0].get('B_author_checks')==318 and records[0].get('failures')==[] and author.get('before_issues')==[] and author.get('after_issues')==[]):raise ValueError('author first strict PASS prerequisite absent')
 before=pre['source'];(out/'AUTHOR_INPUTS_BEFORE.json').write_text(json.dumps(before,indent=2)+'\n');project.mkdir()
 for rel in plan['source_files']:
  dest=project/rel;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(src/rel,dest)
 if inventory(project)!=plan['source_files']:raise ValueError('initial exact copy failed')
 for route in plan['routes']:
  dest=out/route['name'];dest.mkdir();env=dict(os.environ)
  for k,n in [('HOME','home'),('XDG_DATA_HOME','data'),('XDG_CONFIG_HOME','config'),('XDG_CACHE_HOME','cache')]:
   (dest/n).mkdir();env[k]=str(dest/n)
  command=['/usr/local/bin/godot','--headless','--path',str(project),'--script',route['script']];start=time.monotonic();a=b=b'';rc=None;timed=False;exception=None;reports=[];parse_errors=[]
  try:
   z=subprocess.run(command,capture_output=True,env=env,timeout=180);a,b,rc=z.stdout,z.stderr,z.returncode
  except subprocess.TimeoutExpired as e:a,b=e.stdout or b'',e.stderr or b'';timed=True
  except Exception as e:exception=repr(e)
  (dest/'stdout.raw').write_bytes(a);(dest/'stderr.raw').write_bytes(b);(dest/'native.exit').write_text('NOT_EXITED_TIMEOUT\n' if timed else ('UNAVAILABLE\n' if rc is None else str(rc)+'\n'))
  for line in a.decode(errors='replace').splitlines():
   if line.lstrip().startswith('{'):
    try:
     report=json.loads(line)
     if not isinstance(report,dict) or 'checks' not in report:raise ValueError('unexpected marker schema')
     reports.append(report)
    except Exception as e:parse_errors.append(repr(e))
  tags=[tag for tag in ['SCRIPT ERROR','ERROR:','Parse Error','WARNING:','instances leaked','resources still in use'] if tag in (a+b).decode(errors='replace')]
  good=rc==0 and not timed and not exception and not b and not tags and not parse_errors and len(reports)==1 and type(reports[0].get('checks')) is int and reports[0]['checks']==route['checks'] and reports[0].get('failures')==[]
  row={'name':route['name'],'pass':good,'native_exit':rc,'timeout':timed,'seconds':time.monotonic()-start,'exception':exception,'stderr_bytes':len(b),'strict_tags':tags,'parse_errors':parse_errors,'reports':reports};rows.append(row);(dest/'RESULT.json').write_text(json.dumps(row,indent=2)+'\n');print(json.dumps(row),flush=True)
  if not good:break
except Exception:error=traceback.format_exc()
finally:
 after=guard();(out/'AFTERGUARD.json').write_text(json.dumps(after,indent=2)+'\n')
 source_same=bool(before) and before==after['source'];copy_exists=project.exists() and bool(after['project'])
 result={'pass':error is None and len(rows)==4 and all(r['pass'] for r in rows) and source_same and copy_exists and not after['issues'],'scope':'Four independent pure-helper fixtures; not main/Effects/loop/native integration','exception':error,'completed':len(rows),'expected_total_checks':647,'actual_total_checks':sum(r['reports'][0]['checks'] for r in rows if len(r['reports'])==1 and type(r['reports'][0].get('checks')) is int),'author_source_unchanged':source_same,'all_pins_unchanged':after['all_pins_unchanged'],'after_issues':after['issues'],'rows':rows};(out/'RESULT.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result),flush=True)
sys.exit(0 if result['pass'] else 1)
