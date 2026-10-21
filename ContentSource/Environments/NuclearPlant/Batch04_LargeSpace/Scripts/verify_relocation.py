"""Run in Blender after extracting all delivered ZIP parts into a new directory."""
import bpy,pathlib,json,sys
R=pathlib.Path(sys.argv[sys.argv.index('--')+1]).resolve();records=[]
for path in sorted((R/'Region').glob('*.blend')):
 bpy.ops.wm.open_mainfile(filepath=str(path));libs=[{'path':l.filepath,'exists':pathlib.Path(bpy.path.abspath(l.filepath)).is_file(),'inside_package':pathlib.Path(bpy.path.abspath(l.filepath)).resolve().is_relative_to(R)} for l in bpy.data.libraries];empty=[o.name for o in bpy.context.scene.objects if o.type=='MESH' and not len(o.data.vertices)];records.append({'scene':path.name,'libraries':libs,'empty_meshes':empty,'status':'PASS' if all(e['exists'] and e['inside_package'] for e in libs) and not empty else 'FAIL'})
print('RELOCATION_RESULT='+json.dumps(records));out=R/'Validation/relocation_open_test.json';out.write_text(json.dumps({'status':'PASS' if all(e['status']=='PASS' for e in records) else 'FAIL','test':'Isolated new directory; actual Blender reopen of every Region scene; all dependencies resolve within this package tree.','scenes':records},indent=2))
