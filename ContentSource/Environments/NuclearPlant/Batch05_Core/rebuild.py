"""Run from any directory: python rebuild.py [--render]. Requires Blender 4.3+."""
import pathlib,subprocess,sys,shutil
R=pathlib.Path(__file__).resolve().parent
blender=shutil.which('blender')
if not blender:raise SystemExit('Blender executable not found on PATH')
stages=['build_core.py','postprocess_core.py','fix_clearance.py','refresh_reactor.py','material_finish.py','fix_loop.py','finish_scene.py']
for stage in stages:
 print('REBUILD STAGE:',stage,flush=True)
 subprocess.run([blender,'-b','-t','8','--python-exit-code','1','--python',str(R/stage)],check=True)
if '--render' in sys.argv:
 subprocess.run([blender,'-b','-t','8','--python-exit-code','1','--python',str(R/'render_core.py'),'--','core_eye_front','core_eye_side','core_platform','core_entry','core_cutaway'],check=True)
print('COMPLETE: '+str(R/'core_hall.blend'))
