import bpy,pathlib,json,math
R=pathlib.Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(R/'core_hall.blend'))
s=bpy.context.scene
CFG=json.loads((R/'core_config.json').read_text())
# Restrained values preserve the primary dark-metal / secondary pale-concrete hierarchy.
for m in bpy.data.materials:
 name=m.name
 if name=='Sealed aggregate floor':color=tuple(CFG['palette']['Sealed aggregate floor'])
 elif name.startswith('M_NPP_ProcessTeal'):color=tuple(CFG['source_palette_override']['process_pump'])
 elif name=='Oxide red panels':color=tuple(CFG['palette']['Oxide red panels'])
 elif name.startswith('CP_') and 'White' in name:color=(.28,.32,.33)
 else:continue
 m.diffuse_color=(*color,1);bs=m.node_tree.nodes.get('Principled BSDF')
 if bs:
  for lk in list(bs.inputs['Base Color'].links):m.node_tree.links.remove(lk)
  bs.inputs['Base Color'].default_value=(*color,1)
  no=m.node_tree.nodes.new('ShaderNodeTexNoise');no.inputs['Scale'].default_value=7;no.inputs['Detail'].default_value=2
  ra=m.node_tree.nodes.new('ShaderNodeValToRGB');ra.color_ramp.elements[0].color=tuple(v*.8 for v in color)+(1,);ra.color_ramp.elements[1].color=tuple(v*1.18 for v in color)+(1,);m.node_tree.links.new(no.outputs['Fac'],ra.inputs[0]);m.node_tree.links.new(ra.outputs[0],bs.inputs['Base Color'])
# Main diagnostic wall display under the ring, supported off the containment shell.
c=bpy.data.collections['06_Signage_Lights']
def mat(n,col,em=0):
 m=bpy.data.materials.new(n);m.diffuse_color=(*col,1);m.use_nodes=True;p=m.node_tree.nodes['Principled BSDF'];p.inputs['Base Color'].default_value=(*col,1);p.inputs['Roughness'].default_value=.35;p.inputs['Emission Color'].default_value=(*col,1);p.inputs['Emission Strength'].default_value=em;return m
screen=mat('Diagnostic screen deep blue',(.008,.035,.06),.35);ink=mat('Diagnostic cyan type',(.15,.58,.67),1.2);dim=mat('Diagnostic dim grid',(.035,.12,.15),.5)
def box(n,loc,dims,m):
 x,y,z=[a/2 for a in dims];me=bpy.data.meshes.new(n);me.from_pydata([(-x,-y,-z),(x,-y,-z),(x,y,-z),(-x,y,-z),(-x,-y,z),(x,-y,z),(x,y,z),(-x,y,z)],[],[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]);me.materials.append(m);o=bpy.data.objects.new(n,me);c.objects.link(o);o.location=loc;return o
box('Diagnostic panel housing',(0,-4.35,3),(4.9,.24,1.6),bpy.data.materials['Graphite structure'])
box('Diagnostic active display',(0,-4.48,3),(4.65,.03,1.36),screen)
for x in [-1.9,1.9]:box('Display shell mount',(x,-4.02,3),(.15,.6,.15),bpy.data.materials['Graphite structure'])
for z in [2.55,2.75,2.95,3.15]:box('Display grid',(0,-4.502,z),(4.3,.01,.008),dim)
for i in range(14):box('Telemetry bar',(-2.1+i*.15,-4.51,2.68),(.08,.015,.08+.18*(.5+.5*math.sin(i*.9))),ink)
for t,loc,size in [('R / 01',(1.2,-4.52,2.9),.32),('CORE  /  STABLE',(-.75,-4.52,3.35),.16),('COOLANT   94.8 %',(1.05,-4.52,2.65),.12)]:
 cv=bpy.data.curves.new('Diagnostic label','FONT');cv.body=t;cv.size=size;cv.align_x='CENTER';cv.materials.append(ink);o=bpy.data.objects.new('Diagnostic label',cv);c.objects.link(o);o.location=loc;o.rotation_euler=(math.pi/2,0,0)
bpy.ops.wm.save_as_mainfile(filepath=str(R/'core_hall.blend'),compress=True)
print('FINISH_SAVED')
