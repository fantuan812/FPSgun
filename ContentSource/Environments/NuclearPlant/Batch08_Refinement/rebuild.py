"""Run with Blender: blender -b -t 4 --python rebuild.py"""
import pathlib,runpy
R=pathlib.Path(__file__).resolve().parent
runpy.run_path(str(R/'Scripts/build_scene.py'),run_name='__main__')
