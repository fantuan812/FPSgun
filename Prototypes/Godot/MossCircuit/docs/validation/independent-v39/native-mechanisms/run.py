from pathlib import Path
import json,hashlib,subprocess,os,time
from PIL import Image
q=Path(__file__).parent;p=q/'PLAN.json';h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();ph=h(p);plan=json.loads(p.read_text());expected=json.loads(Path(plan['input_map']).read_text());root=Path(plan['source'])
def snap(r):return {str(f.relative_to(r)):h(f) for f in r.rglob('*') if f.is_file() and '.godot' not in f.relative_to(r).parts}
def pins():return h(p)==ph and all(Path(f).is_file() and h(Path(f))==v for f,v in plan['pins'].items())
assert os.environ.get('DISPLAY') or os.environ.get('WAYLAND_DISPLAY');assert pins() and snap(root)==expected
assert json.loads(Path(plan['packed_result']).read_text())['pass'] is True and json.loads(Path(plan['packed_review']).read_text())['review_pass'] is True
out=q/'raw-first';assert not out.exists();out.mkdir();images=out/'images';images.mkdir();reader=out/'empty-reader';reader.mkdir();env=dict(os.environ)
for k,n in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_DATA_HOME','data'),('XDG_CACHE_HOME','cache')]:
 (out/n).mkdir();env[k]=str(out/n)
rc=125;timed=False;errors=[];a=b=b'';reports=[];helpers=[];start=time.monotonic()
try:
 try:
  z=subprocess.run(plan['command'],env=env,cwd=reader,capture_output=True,timeout=180);a,b,rc=z.stdout,z.stderr,z.returncode
 except subprocess.TimeoutExpired as e:a,b,rc=e.stdout or b'',e.stderr or b'',124;timed=True
 (out/'native.stdout').write_bytes(a);(out/'native.stderr').write_bytes(b);(out/'native.exit').write_text(str(rc)+'\n')
 for line in a.decode(errors='strict').splitlines():
  if line.startswith('{'):reports.append(json.loads(line))
  elif line.startswith('TEST_AUDIO_TEARDOWN '):helpers.append(json.loads(line.split(' ',1)[1]))
except Exception as e:errors.append(repr(e))
finally:
 if not(out/'native.stdout').exists():(out/'native.stdout').write_bytes(a)
 if not(out/'native.stderr').exists():(out/'native.stderr').write_bytes(b)
 (out/'native.exit').write_text(str(rc)+'\n');post=snap(root);(out/'POST_INPUTS.json').write_text(json.dumps(post,indent=2,sort_keys=True)+'\n')
 semantic=False;helper_ok=False;image_ok=False
 try:
  semantic=len(reports)==1 and isinstance(reports[0],dict) and reports[0].get('checks')==128 and reports[0].get('failures')==[] and isinstance(reports[0].get('observations'),list) and len(reports[0]['observations'])==36 and all(isinstance(x,dict) for x in reports[0]['observations']) and [x['image'] for x in reports[0]['observations']]==plan['expected_images']
  helper_ok=len(helpers)==1
  for x in helpers:
   z=x['observations'][-1];helper_ok=helper_ok and x['complete'] is True and x['capture_removed'] is True and x['prepare_errors']==[] and x['requested_owner_count']==x['tracked_owner_count']==x['game_owner_count']==1 and x['tracked_stream_count']>0 and z['owners_released'] is True and z['streams_released'] is True and 150000<=z['elapsed_us']<=1000000 and z['new_pushed']>=z['required_frames']>0 and z['silent_frames']>=z['required_frames'] and all(v['invalid']==v['discarded']==v['prepare_errors']==0 and v['owner_count']==v['game_owner_count']==1 for v in x['observations'])
  imgs=sorted(images.glob('*.png'));image_ok=[x.name for x in imgs]==sorted(plan['expected_images']) and all(Image.open(x).size==(960,540) for x in imgs)
 except (ValueError,TypeError,KeyError,IndexError,OSError) as e:errors.append(repr(e))
 clean=not any(s in (a+b).decode(errors='replace') for s in ['SCRIPT ERROR','Parse Error','ERROR:','instances leaked','resources still in use']);result={'pass_gate':rc==0 and not timed and not errors and semantic and helper_ok and image_ok and clean and post==expected and pins(),'native_exit':rc,'seconds':time.monotonic()-start,'timeout':timed,'errors':errors,'semantic':semantic,'helper_ok':helper_ok,'image_ok':image_ok,'clean':clean,'source_unchanged':post==expected,'pins_unchanged':pins(),'reports':reports,'helpers':helpers,'pixels_reviewed':False,'scope':plan['scope']};(out/'RESULT.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps({k:v for k,v in result.items() if k not in ['reports','helpers']}),flush=True)
raise SystemExit(0 if result['pass_gate'] else 1)
