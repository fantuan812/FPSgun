"""Export current Batch07 reusable modules to GLB, not a full-site interchange file."""
from pathlib import Path
import argparse,shutil,subprocess
R=Path(__file__).resolve().parent
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--batch06',action='store_true',help='Explicitly regenerate the older Batch06 full-site GLB/FBX instead')
a=p.parse_args();blender=shutil.which('blender')
if not blender:raise SystemExit('Blender 4.3+ required on PATH')
script=R/('Batch06_Expansion/export_site.py' if a.batch06 else 'Batch07_Refinement/Scripts/export_modules.py')
subprocess.run([blender,'-b','-t','8','--python-exit-code','1','--python',str(script)],cwd=script.parent,check=True)
