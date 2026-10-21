"""Rebuild current Batch08 complete map from unchanged Batch07; no implicit historical rebuild."""
from pathlib import Path
import argparse,shutil,subprocess,sys
R=Path(__file__).resolve().parent
p=argparse.ArgumentParser(description=__doc__);p.add_argument('--render',action='store_true');p.add_argument('--threads',type=int,default=4);a=p.parse_args()
blender=shutil.which('blender')
if not blender:raise SystemExit('Blender 4.3+ required on PATH')
subprocess.run([sys.executable,str(R/'restore_assets.py')],cwd=R,check=True)
S=R/'Batch08_Refinement';cmd=[blender,'-b','-t',str(a.threads),'--python-exit-code','1','--python']
subprocess.run(cmd+[str(S/'rebuild.py')],cwd=S,check=True)
subprocess.run(cmd+[str(S/'Scripts/export_modules.py')],cwd=S,check=True)
if a.render:
 # Author's validated queue uses one fresh Blender process per image (gallery has its own script).
 subprocess.run([sys.executable,str(S/'Scripts/render_serial_queue.py')],cwd=S,check=True)
 subprocess.run([sys.executable,str(S/'Scripts/compare_images.py')],cwd=S,check=True)
