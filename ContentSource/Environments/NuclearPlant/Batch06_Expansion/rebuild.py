"""Rebuild every Batch06 region and total scene from local sources. Does not modify historical batches."""
import pathlib,shutil,subprocess,sys
R=pathlib.Path(__file__).resolve().parent;blender=shutil.which('blender')
if not blender:raise SystemExit('Blender 4.3+ executable required on PATH')
for rel in ['Office/build_office.py','Logistics/build_logistics.py','Pump/build_pumps.py','build_connector_assets.py','build_expansion.py']:
 subprocess.run([blender,'-b','-t','8','--python-exit-code','1','--python',str(R/rel)],cwd=R,check=True)
if '--render' in sys.argv:
 subprocess.run([blender,'-b','-t','8','--python-exit-code','1','--python',str(R/'render_expansion.py'),'--','site_overview','site_cutaway','site_entry','service_street','north_connection'],cwd=R,check=True)
