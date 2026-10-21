import bpy,os,importlib.util
r=os.path.dirname(os.path.abspath(__file__))
bpy.ops.wm.open_mainfile(filepath=os.path.join(r,'reactor.blend'))
spec=importlib.util.spec_from_file_location('reactor_asset',os.path.join(r,'reactor_asset.py'));m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
for args in [('dark_forged_steel',(.065,.082,.10),.78,.33),('brushed_alloy',(.34,.38,.40),.82,.29),('equipment_enamel',(.46,.49,.48),.42,.40),('oxide_red',(.36,.035,.027),.35,.39),('carbon_recess',(.012,.019,.024),.45,.46),('warning_ochre',(.70,.40,.035),.25,.43)]:m.material(*args)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(r,'reactor.blend'),compress=True)
