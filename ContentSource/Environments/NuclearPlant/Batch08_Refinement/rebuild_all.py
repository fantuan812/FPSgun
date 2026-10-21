"""One command: python3 rebuild_all.py [--render]. Requires Blender 4.3+ on PATH.
Frozen references are verified, not regenerated from the finished model.
"""
import subprocess,pathlib,sys
R=pathlib.Path(__file__).resolve().parent
def run(args):subprocess.run(args,check=True,cwd=R)
run(['blender','-b','-t','4','--python-exit-code','1','--python',str(R/'rebuild.py')])
run(['blender','-b','-t','4','--python-exit-code','1','--python',str(R/'Scripts/export_modules.py')])
if '--render' in sys.argv:
 run(['python3',str(R/'Scripts/render_serial_queue.py')])
 run(['python3',str(R/'Scripts/compare_images.py')])
print('BATCH08_REBUILD_ALL_COMPLETE')
