"""Run from system Python. Isolated one-click replay, serial Blender processes only."""
import pathlib,tempfile,shutil,subprocess,json,hashlib,datetime
R=pathlib.Path(__file__).resolve().parent.parent;started=datetime.datetime.now(datetime.timezone.utc).isoformat()
with tempfile.TemporaryDirectory(prefix='b08_rebuild_',dir='/tmp') as td:
 root=pathlib.Path(td);dst=root/R.name;shutil.copytree(R,dst,ignore=shutil.ignore_patterns('Assets','Regions','renders','Exports','site_refined.blend','site_refined.blend1','__pycache__'))
 for d in ['Assets','Regions','renders','Exports']:(dst/d).mkdir(exist_ok=True)
 source=root/'Batch07_Refinement';source.mkdir();shutil.copy2(R.parent/'Batch07_Refinement/site_refined.blend',source/'site_refined.blend')
 def run(args,log):
  p=subprocess.run(args,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True);(R/'QA'/log).write_text(p.stdout);assert p.returncode==0,(args,p.stdout[-2000:])
 run(['python3',str(dst/'rebuild_all.py')],'rebuild_replay.log')
 run(['blender','-b','-t','4','--python-exit-code','1','--python',str(R/'Scripts/scene_signature.py'),'--',str(R/'site_refined.blend'),str(dst/'site_refined.blend'),str(R/'QA/rebuild_signature_comparison.json')],'rebuild_compare.log')
 a=json.loads((R/'QA/rebuild_signature_comparison.json').read_text());exports=[]
 for p in sorted((dst/'Exports').glob('*.glb')):
  q=R/'Exports'/p.name;exports.append({'file':p.name,'rebuild_sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'original_sha256':hashlib.sha256(q.read_bytes()).hexdigest(),'byte_identical':p.read_bytes()==q.read_bytes()})
 shutil.copy2(dst/'QA/build_record.json',R/'QA/rebuild_build_record.json')
 result={'stage':'ISOLATED_ONE_COMMAND_REPLAY','started_utc':started,'finished_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'command':'python3 Scripts/check_rebuild.py','actual_isolated_entrypoint':'python3 rebuild_all.py','baseline_copy_sha256':hashlib.sha256((source/'site_refined.blend').read_bytes()).hexdigest(),'geometry_signature_equal':a['equal'],'changed_objects':a['changed_objects'],'module_glb_comparison':exports,'reference_hashes_rechecked_by_builder':True,'temporary_replay_outputs_removed_after_validation':True,'limitations':'This establishes deterministic geometry/placement and module export, not byte-identical Blender .blend containers, runtime collision, performance or UE validation.'};(R/'QA/rebuild_verification.json').write_text(json.dumps(result,indent=2));assert a['equal'] and all(x['byte_identical'] for x in exports)
 print('B08_ISOLATED_REBUILD_PASS')
