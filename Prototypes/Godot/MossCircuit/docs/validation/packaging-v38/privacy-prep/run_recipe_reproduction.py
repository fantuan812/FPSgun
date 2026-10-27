from pathlib import Path
import json,hashlib,subprocess,os,shutil,time
p=Path(__file__).parent;old=Path('<WORKSPACE>/moss-v38-svg-candidate/art_source/stitch_drone');out=p/'recipe-reproduction';assert not out.exists();out.mkdir();staging=out/'staging';staging.mkdir();shutil.copytree(old/'source',staging/'source');shutil.copy2(p/'export_and_measure.py',staging/'export_and_measure.py')
h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();before={str(x.relative_to(old)):h(x) for x in old.rglob('*') if x.is_file()};recipe=h(p/'export_and_measure.py');env=os.environ.copy()
for key,n in [('HOME','home'),('XDG_CONFIG_HOME','config'),('XDG_DATA_HOME','data'),('XDG_CACHE_HOME','cache')]:
 (out/n).mkdir();env[key]=str(out/n)
t=time.monotonic();timed=False
try:z=subprocess.run(['python',str(staging/'export_and_measure.py')],capture_output=True,env=env,timeout=180);a,b,rc=z.stdout,z.stderr,z.returncode
except subprocess.TimeoutExpired as e:a,b,rc=e.stdout or b'',e.stderr or b'',124;timed=True
(out/'stdout.raw').write_bytes(a);(out/'stderr.raw').write_bytes(b);(out/'native.exit').write_text(str(rc)+'\n')
errors=[]
try:
 assert rc==0 and not timed
 measured=json.loads((staging/'metadata/measured_assets.json').read_text());expected=json.loads(Path('<WORKSPACE>/moss-v38-public-prep/art_source/stitch_drone/metadata/measured_assets.json').read_text());assert measured==expected
 assert all(h(staging/'source'/x.name)==h(x) for x in (old/'source').iterdir() if x.is_file())
 for kind,row in measured['records'].items():assert h(staging/'exports'/('stitch_drone_'+kind+'.png'))==row['png_sha256']
 assert b'<WORKSPACE>/' not in (staging/'metadata/measured_assets.json').read_bytes()
except Exception as e:errors.append(repr(e))
changes=[n for n,s in before.items() if not(old/n).exists() or h(old/n)!=s]
result={'pass':rc==0 and not timed and not errors and not changes and h(p/'export_and_measure.py')==recipe,'native_exit':rc,'timeout':timed,'seconds':time.monotonic()-t,'errors':errors,'old_source_changes':changes,'recipe_sha256':recipe,'scope':'Isolated staging regeneration: four source SVGs, eight PNG exports with repeat identity, all measured values equal original; only eight command records now portable. No Godot or game-candidate writes.'};(out/'RESULT.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result));raise SystemExit(0 if result['pass'] else 1)
