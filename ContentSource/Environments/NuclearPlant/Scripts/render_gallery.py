import bpy,json,pathlib,math,sys
from mathutils import Vector
R=pathlib.Path(__file__).resolve().parents[1]
FILTER=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
for e in json.loads((R/'manifest.json').read_text())['assets']:
 if FILTER and not any(f in e['asset_id'] for f in FILTER):continue
 p=R/e['path'];sp=json.loads((p/'spec.json').read_text());bpy.ops.wm.open_mainfile(filepath=str(p/'model.blend'));s=bpy.context.scene
 center=Vector([(a+b)/2 for a,b in zip(sp['bounds_min'],sp['bounds_max'])]);bpy.ops.object.camera_add(location=center+Vector((9,-12,9)));o=bpy.context.object;o.name='BEAUTY_3Q';o.rotation_euler=(center-o.location).to_track_quat('-Z','Y').to_euler();o.data.type='ORTHO';o.data.ortho_scale=6.4;s.camera=o;s.render.resolution_x=768;s.render.resolution_y=768;s.cycles.samples=64;s.render.filepath=str(p/'beauty.png');bpy.ops.render.render(write_still=True)
print('GALLERY_COMPLETE')
