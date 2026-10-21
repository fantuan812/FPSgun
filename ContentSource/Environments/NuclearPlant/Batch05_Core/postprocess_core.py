import bpy, pathlib, math,json
from mathutils import Vector
R=pathlib.Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(R/'core_hall.blend'))
s=bpy.context.scene
# Make all appended dependencies local, package reusable original meshes with local materials.
for group in [bpy.data.meshes,bpy.data.materials,bpy.data.curves]:
 for d in list(group):
  if d.library:d.make_local()
(R/'Reused').mkdir(exist_ok=True)
reuse={o for o in s.objects if o.name.startswith('REUSED_B04_')}
if not (R/'Reused/batch04_reuse.blend').exists():bpy.data.libraries.write(str(R/'Reused/batch04_reuse.blend'),reuse,fake_user=True,compress=True)
# Local support files guarantee deterministic regeneration without original Batch04 delivery.
# Refine concrete: restrained vertically elongated marks plus fine roughness variation.
for name in ['Pale cast concrete','Sealed aggregate floor','Graphite structure']:
 m=bpy.data.materials.get(name)
 if not m:continue
 n=m.node_tree.nodes;l=m.node_tree.links;p=n.get('Principled BSDF')
 tx=n.new('ShaderNodeTexNoise');tx.inputs['Scale'].default_value=4;tx.inputs['Detail'].default_value=2
 mp=n.new('ShaderNodeMapRange');mp.inputs['From Min'].default_value=0;mp.inputs['From Max'].default_value=1;mp.inputs['To Min'].default_value=.4 if name!='Graphite structure' else .28;mp.inputs['To Max'].default_value=.65 if name!='Graphite structure' else .44;l.new(tx.outputs['Fac'],mp.inputs['Value']);l.new(mp.outputs['Result'],p.inputs['Roughness'])
# Close coolant systems at real containment surface, rather than leaving pipe ends floating.
for o in bpy.data.collections['04_Functional_Services'].objects:
 if o.name.startswith('Primary coolant route'):
  sp=o.data.splines[0];side=1 if sp.points[0].co.x>0 else -1
  sp.points.add(2);sp.points[-2].co=(side*4,2.8,7,1);sp.points[-1].co=(side*2.8,2.8,7,1)
# True rear exit: remove one low panel and add continuous approach to exterior service loop.
for o in list(bpy.data.collections['01_Hall_Architecture'].objects):
 if o.name.startswith('End wall panel') and abs(o.location.x-2)<.01 and o.location.y>17 and abs(o.location.z-2)<.01:bpy.data.objects.remove(o,do_unlink=True)
def box(n,loc,dims,mat,col):
 mesh=bpy.data.meshes.new(n);x,y,z=[v/2 for v in dims];mesh.from_pydata([(-x,-y,-z),(x,-y,-z),(x,y,-z),(-x,y,-z),(-x,-y,z),(x,-y,z),(x,y,z),(-x,y,z)],[],[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]);mesh.materials.append(bpy.data.materials[mat]);o=bpy.data.objects.new(n,mesh);bpy.data.collections[col].objects.link(o);o.location=loc;return o
for x in [-.12,4.12]:box('Rear exit jamb',(x,18.1,2),(.18,.7,4),'Graphite structure','01_Hall_Architecture')
box('Rear exit lintel',(2,18.1,4.08),(4.4,.7,.16),'Graphite structure','01_Hall_Architecture')
box('Rear flush approach',(2,21,-.08),(4,6,.16),'Sealed aggregate floor','05_Entry_Court')
box('Rear road',(0,26,-.13),(76,8,.25),'Court asphalt','05_Entry_Court')
box('East road',(34,-2,-.13),(8,52,.25),'Court asphalt','05_Entry_Court')
box('Front loop road',(0,-30,-.13),(76,8,.25),'Court asphalt','05_Entry_Court')
# Exterior paired pump service bay is compositional support, not a competing focal object.
box('Exterior pump pad',(25,-12,-.05),(10,6,.1),'Pale cast concrete','05_Entry_Court')
pump=next((o for o in s.objects if o.name.startswith('REUSED_B04_Pump')),None)
if pump:
 for i,x in enumerate([21,26]):
  o=pump.copy();o.data=pump.data;bpy.data.collections['05_Entry_Court'].objects.link(o);o.name='Exterior reused pump '+str(i);o.location=(x,-13,0)
# Continuous painted circular service exclusion line, actual mesh ring not texture path.
verts=[];faces=[];mids=[];N=160
for i in range(N):
 a=i*2*math.pi/N;b=(i+.85)*2*math.pi/N;k=len(verts)
 verts.extend([(r*math.cos(t),r*math.sin(t),.022) for r,t in [(7.82,a),(7.94,a),(7.94,b),(7.82,b)] ]);faces.append((k,k+1,k+2,k+3));mids.append(i%2)
me=bpy.data.meshes.new('Service ring marking');me.from_pydata(verts,[],faces);me.materials.append(bpy.data.materials['Safety ochre']);me.materials.append(bpy.data.materials['Graphite structure'])
for f,mi in zip(me.polygons,mids):f.material_index=mi
ob=bpy.data.objects.new('Service ring marking',me);bpy.data.collections['06_Signage_Lights'].objects.link(ob)
# Render-independent persistence.
s['delivery_state']='Core region assembled, Blender validation pending; no UE runtime test'
bpy.ops.wm.save_as_mainfile(filepath=str(R/'core_hall.blend'),compress=True)
print('POSTPROCESS_SAVED',len(s.objects))
