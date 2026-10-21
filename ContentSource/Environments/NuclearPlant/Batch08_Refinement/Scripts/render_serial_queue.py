"""One Blender per image, strictly serial; --resume skips only hash-verified current-source images."""
from pathlib import Path
import os,tempfile,json,hashlib,sys,subprocess,datetime
R=Path(__file__).resolve().parent.parent
cache=Path(tempfile.gettempdir())/'b08_blender_shader_cache';cache.mkdir(exist_ok=True)
env=os.environ.copy();env['XDG_CACHE_HOME']=str(cache);env['MESA_SHADER_CACHE_DIR']=str(cache/'mesa');(cache/'mesa').mkdir(exist_ok=True)
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
scene=sha(R/'site_refined.blend');baseline=sha(R.parent/'Batch07_Refinement/site_refined.blend');script=sha(R/'Scripts/render_scene.py');cam=sha(R/'Config/render_cameras.json')
queue=[(False,n) for n in ['site_overview','site_cutaway','pump_connection_eye','receiving_connection_eye','cargo_detail_eye','module_gallery']]+[(True,n) for n in ['pump_connection_eye','receiving_connection_eye','cargo_detail_eye']]
records=[]
for before,name in queue:
 script_path='Scripts/render_gallery.py' if name=='module_gallery' else 'Scripts/render_scene.py';script=sha(R/script_path)
 key=('before_' if before else '')+name;pp=R/'QA/render_provenance.json';prov=json.loads(pp.read_text()) if pp.exists() else {};v=prov.get(key,{});image=R/'renders'/f'{key}.png'
 valid=image.exists() and v.get('source_scene_sha256')==(baseline if before else scene) and v.get('render_script_sha256')==script and v.get('render_camera_config_sha256')==cam and v.get('samples')==48 and v.get('resolution')==[1600,1000] and v.get('image_sha256')==sha(image)
 if '--resume' in sys.argv and valid:
  records.append({'image':key,'status':'reused_hash_verified'});print('REUSE_CURRENT',key,flush=True);continue
 command=['blender','-b','-t','4','--python-exit-code','1','--python',str(R/script_path),'--']+(['--before'] if before else [])+[name]
 with (R/'QA'/f'render_{key}.log').open('w') as log:p=subprocess.run(command,stdout=log,stderr=subprocess.STDOUT,env=env)
 records.append({'image':key,'returncode':p.returncode,'command':command});(R/'QA/render_serial_queue_record.json').write_text(json.dumps({'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'method':'one Blender process per image, sequential, writable temporary shader cache','environment_overrides':{k:env[k] for k in ['XDG_CACHE_HOME','MESA_SHADER_CACHE_DIR']},'records':records},indent=2))
 assert p.returncode==0,(key,p.returncode)
 prov=json.loads(pp.read_text());prov[key]['render_script']=script_path;pp.write_text(json.dumps(prov,indent=2))
 print('SERIAL_IMAGE_COMPLETE',key,flush=True)
(R/'QA/render_serial_queue_record.json').write_text(json.dumps({'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'method':'one Blender process per image, sequential, writable temporary shader cache','environment_overrides':{k:env[k] for k in ['XDG_CACHE_HOME','MESA_SHADER_CACHE_DIR']},'records':records},indent=2))
print('SERIAL_RENDER_QUEUE_COMPLETE',flush=True)
