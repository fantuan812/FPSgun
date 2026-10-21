from pathlib import Path
import shutil,subprocess
R=Path(__file__).resolve().parent
b=shutil.which('blender')
if not b:raise SystemExit('Blender 4.3+ required on PATH')
subprocess.run([b,'-b','-t','8','--python-exit-code','1','--python',str(R/'Batch06_Expansion/export_site.py')],check=True)
