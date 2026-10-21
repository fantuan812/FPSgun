"""Rebuild the latest complete map; legacy batches are never rebuilt implicitly."""
from pathlib import Path
import argparse, shutil, subprocess, sys

R=Path(__file__).resolve().parent
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--render',action='store_true',help='Also render the final Batch07 views')
p.add_argument('--threads',type=int,default=8)
a=p.parse_args()
blender=shutil.which('blender')
if not blender:raise SystemExit('Blender 4.3+ required on PATH')
subprocess.run([sys.executable,str(R/'restore_assets.py')],cwd=R,check=True)
cmd=[blender,'-b','-t',str(a.threads),'--python-exit-code','1','--python']
subprocess.run(cmd+[str(R/'Batch07_Refinement/rebuild.py')],cwd=R/'Batch07_Refinement',check=True)
# Author's exporter also creates the independently reusable narrow-cabinet Blend.
subprocess.run(cmd+[str(R/'Batch07_Refinement/Scripts/export_modules.py')],cwd=R/'Batch07_Refinement',check=True)
if a.render:
    subprocess.run(cmd+[str(R/'Batch07_Refinement/Scripts/render_scene.py'),'--','site_overview','site_cutaway','core_entry','pump_eye','logistics_eye','module_gallery'],cwd=R/'Batch07_Refinement',check=True)
