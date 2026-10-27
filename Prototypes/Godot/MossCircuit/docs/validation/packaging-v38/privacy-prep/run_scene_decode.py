from pathlib import Path
import json,hashlib,os,subprocess,time
p=Path(__file__).parent; d=Path('<WORKSPACE>/moss-v38-svg-author-review/scene-diagnostic');out=p/'scene-decode-first';assert not out.exists();out.mkdir()
h=lambda x:hashlib.sha256(Path(x).read_bytes()).hexdigest()
src=Path('<WORKSPACE>/moss-v38-svg-portable');mp=p/'PORTABLE_INPUTS.json';source=json.loads(mp.read_text());pck=Path('<WORKSPACE>/moss-v38-svg-portable-pack/linux/MossCircuit.pck');script=d/'decode_scene.gd'
pins={str(x):h(x) for x in [mp,pck,script,d/'old.scn',d/'new.scn',Path(__file__)]}
a=(d/'old.scn').read_bytes();b=(d/'new.scn').read_bytes();assert len(a)==len(b)==684 and [i for i in range(684) if a[i]!=b[i]]==[508,509,510,511]
plan={'pins':pins,'cap_seconds':180,'scope':'one decode-only load of actual old/new PackedScene under new exact PCK; no instantiate; original only-metadata gate remains FAIL','byte_offsets':[508,509,510,511],'old_node_id':106410627,'new_node_id':707380806}
(out/'PLAN.json').write_text(json.dumps(plan,indent=2)+'\n')
def guard():return all(h(n)==v for n,v in pins.items()) and all(h(src/n)==v for n,v in source.items())
assert guard();env=dict(os.environ)
for k,n in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_DATA_HOME','data'),('XDG_CACHE_HOME','cache')]:
 (out/n).mkdir();env[k]=str(out/n)
(out/'empty').mkdir();t=time.monotonic();timed=False
try:r=subprocess.run(['godot','--headless','--audio-driver','Dummy','--main-pack',str(pck),'--script',str(script)],cwd=out/'empty',env=env,capture_output=True,timeout=180);aa,bb,rc=r.stdout,r.stderr,r.returncode
except subprocess.TimeoutExpired as e:aa,bb,rc=e.stdout or b'',e.stderr or b'',124;timed=True
(out/'stdout.raw').write_bytes(aa);(out/'stderr.raw').write_bytes(bb);(out/'native.exit').write_text(str(rc)+'\n')
reports=[];parse=[]
for line in aa.decode(errors='replace').splitlines():
 if line.startswith('{'):
  try:reports.append(json.loads(line))
  except ValueError as e:parse.append(str(e))
clean=not any(x in aa+bb for x in [b'SCRIPT ERROR',b'ERROR:',b'instances leaked',b'resources still in use']);unchanged=guard()
ok=len(reports)==1 and reports[0].get('pass') is True and reports[0].get('old_node_ids')==[106410627] and reports[0].get('new_node_ids')==[707380806] and reports[0].get('different_bundled_fields')==['node_ids']
res={'pass':rc==0 and not timed and clean and ok and unchanged and not parse,'native_exit':rc,'timeout':timed,'seconds':time.monotonic()-t,'reports':reports,'parse_errors':parse,'pins_and_787_source_unchanged':unchanged,'scope':plan['scope'],'plan_sha256':h(out/'PLAN.json')};(out/'RESULT.json').write_text(json.dumps(res,indent=2)+'\n');print(json.dumps(res));raise SystemExit(0 if res['pass'] else 1)
