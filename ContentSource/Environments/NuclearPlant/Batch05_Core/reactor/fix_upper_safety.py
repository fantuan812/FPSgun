import bpy,os,sys,json,importlib.util
r=os.path.dirname(os.path.abspath(__file__))
bpy.ops.wm.open_mainfile(filepath=os.path.join(r,'reactor.blend'))
spec=importlib.util.spec_from_file_location('reactor_asset',os.path.join(r,'reactor_asset.py'));m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
m.C=bpy.data.collections['Reactor_Core']
for o in list(m.C.objects):
 if o.name.startswith('RC_upper_guard'):bpy.data.objects.remove(o,do_unlink=True)
m.rail(5.04,10,bpy.data.materials['RC_brushed_alloy'],bpy.data.materials['RC_oxide_red'],'RC_upper_guard','east_only')
info=json.load(open(os.path.join(r,'reactor_dimensions.json')));info['objects']=len(m.C.objects);info['upper_guard_opening']='east ladder only, 1.0 m; west closed'
json.dump(info,open(os.path.join(r,'reactor_dimensions.json'),'w'),indent=2)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(r,'reactor.blend'),compress=True)
