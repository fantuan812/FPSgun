from pathlib import Path
import sys,json,hashlib,subprocess,time,datetime,os
from PIL import Image
from warning_policy import classify
O=Path(__file__).parent;H=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
assert len(sys.argv)==3 and sys.argv[1]=='--plan-sha256';sha=sys.argv[2];assert H(O/'FRESH_PLAN.json')==sha;plan=json.loads((O/'FRESH_PLAN.json').read_text());assert plan['status']=='FROZEN_WAIT_QA_WINDOW';out=O/'fresh-first';assert not out.exists()
def guard():
 assert H(O/'FRESH_PLAN.json')==sha
 for p,h in {**plan['input_pins'],**plan['execution_pins']}.items():assert H(p)==h,p
 assert H(plan['inkscape_binary'])==plan['inkscape_binary_sha256']
guard();out.mkdir();rows=[]
for asset in plan['assets']:
 folder=out/asset['id'];folder.mkdir();env=os.environ.copy()
 for key,name in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_DATA_HOME','data'),('XDG_CACHE_HOME','cache'),('INKSCAPE_PROFILE_DIR','inkscape-profile')]:
  (folder/name).mkdir();env[key]=str(folder/name)
 error=None;after_error=None;native=None;timed=False;classification=None;tick=time.monotonic();start=datetime.datetime.now(datetime.timezone.utc).isoformat();stdout=b'';stderr=b'';identity={}
 command=[plan['inkscape_binary'],asset['svg'],'--export-type=png','--export-png-antialias=0','--export-filename='+str(folder/'fresh.png')]
 try:
  guard();r=subprocess.run(command,env=env,stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=180);native=r.returncode;stdout=r.stdout;stderr=r.stderr
  assert native==0;assert not stdout.strip(),'unexpected stdout';classification=classify(stderr);assert classification['pass'],classification
  png=folder/'fresh.png';assert H(png)==asset['png_sha256'] and png.read_bytes()==Path(asset['png']).read_bytes();im=Image.open(png).convert('RGBA');bbox=im.getbbox();alpha=[i for i,v in enumerate(im.getchannel('A').histogram()) if v];assert im.size==(64,64) and alpha==[0,255];assert [bbox[0],bbox[1],bbox[2]-bbox[0],bbox[3]-bbox[1]]==asset['bbox_xywh'];rgba=hashlib.sha256(im.tobytes()).hexdigest();assert rgba==asset['rgba_sha256'];identity={'png_sha256':H(png),'rgba_sha256':rgba,'alpha_values':alpha,'bbox':asset['bbox_xywh']}
 except subprocess.TimeoutExpired as e:timed=True;stdout=e.stdout or b'';stderr=e.stderr or b'';error=repr(e)
 except Exception as e:error=repr(e)
 try:guard()
 except Exception as e:after_error=repr(e)
 (folder/'stdout.raw').write_bytes(stdout);(folder/'stderr.raw').write_bytes(stderr);(folder/'native.exit').write_text(str(native)+'\n')
 row={'id':asset['id'],'command':command,'start_utc':start,'elapsed_seconds':time.monotonic()-tick,'native_exit':native,'timeout':timed,'error':error,'after_guard_error':after_error,'warning_classification':classification,'identity':identity,'pass':native==0 and error is None and after_error is None and not timed};rows.append(row);result={'pass':len(rows)==3 and all(x['pass'] for x in rows),'completed':len(rows),'plan_sha256':sha,'rows':rows,'scope':plan['scope']};(out/'RESULT.json').write_text(json.dumps(result,indent=2)+'\n')
 if not row['pass']:break
print(json.dumps(result));raise SystemExit(0 if result['pass'] else 1)
