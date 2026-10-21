"""Usage: blender -b --python rebuild.py (frozen design inputs already included)."""
import runpy,pathlib
runpy.run_path(str(pathlib.Path(__file__).resolve().parent/'Scripts/build_scene.py'),run_name='__main__')
