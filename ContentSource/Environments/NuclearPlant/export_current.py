"""Export four current Batch08 reusable module assets as GLB; not a full-site interchange file."""
from pathlib import Path
import argparse,shutil,subprocess
R=Path(__file__).resolve().parent
p=argparse.ArgumentParser(description=__doc__);g=p.add_mutually_exclusive_group();g.add_argument('--batch07',action='store_true',help='Explicitly regenerate eight older Batch07 module GLBs');g.add_argument('--batch06',action='store_true',help='Explicitly regenerate older Batch06 full-site GLB/FBX');a=p.parse_args()
blender=shutil.which('blender')
if not blender:raise SystemExit('Blender 4.3+ required on PATH')
script=R/('Batch06_Expansion/export_site.py' if a.batch06 else ('Batch07_Refinement/Scripts/export_modules.py' if a.batch07 else 'Batch08_Refinement/Scripts/export_modules.py'))
subprocess.run([blender,'-b','-t','4','--python-exit-code','1','--python',str(script)],cwd=script.parent,check=True)
