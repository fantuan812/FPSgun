"""KITE-01: original nonfunctional game prop. Blender 4.3+, meters, +X forward.
No real weapon internals, mechanical interfaces or manufacturing specification.
"""
import bpy, math, json, sys, hashlib
from pathlib import Path
from mathutils import Vector
import numpy as np
ROOT=Path(__file__).resolve().parents[1]
for n in ['textures','exports','renders','docs']: (ROOT/n).mkdir(exist_ok=True)
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
scene=bpy.context.scene; scene.unit_settings.system='METRIC'; scene.unit_settings.scale_length=1
scene.render.engine='CYCLES'; scene.cycles.samples=32; scene.cycles.use_denoising=False
scene.render.resolution_x=1600; scene.render.resolution_y=1000; scene.render.resolution_percentage=100
scene.world.color=(.22,.22,.22)
scene.view_settings.view_transform='AgX'
modules={}; current=None
# Tileable authored micro-surface maps, not third-party textures. Metal/roughness are explicit.
def material(name,col,metal,rough):
 m=bpy.data.materials.new(name); m.use_nodes=True; ns=m.node_tree.nodes; ls=m.node_tree.links; bs=ns.get('Principled BSDF'); bs.inputs['Metallic'].default_value=metal
 rng=np.random.default_rng(73); n=512; grain=rng.normal(0,.014,(n,n,1)); rgb=np.clip(np.array(col)[None,None,:]*(1+grain*2),0,1)
 arr=np.concatenate([rgb,np.ones((n,n,1))],axis=2).astype('float32'); im=bpy.data.images.new(name+'_BaseColor',width=n,height=n); im.pixels.foreach_set(arr.ravel()); im.filepath_raw=str(ROOT/'textures'/f'{name}_BaseColor.png'); im.file_format='PNG'; im.save(); im.pack()
 t=ns.new('ShaderNodeTexImage'); t.image=im; ls.new(t.outputs['Color'],bs.inputs['Base Color'])
 arr=np.ones((n,n,4),dtype='float32'); arr[:,:,:3]=np.clip(rough+grain,0,1)
 im=bpy.data.images.new(name+'_Roughness',width=n,height=n); im.colorspace_settings.name='Non-Color'; im.pixels.foreach_set(arr.ravel()); im.filepath_raw=str(ROOT/'textures'/f'{name}_Roughness.png'); im.file_format='PNG'; im.save(); im.pack()
 t=ns.new('ShaderNodeTexImage'); t.image=im; ls.new(t.outputs['Color'],bs.inputs['Roughness'])
 return m
sand=material('M_CeramicSand',(.38,.31,.215),.3,.48); dark=material('M_Graphite',(.052,.066,.071),.8,.36); rubber=material('M_Polymer',(.022,.026,.027),0,.72); steel=material('M_EdgeMetal',(.17,.19,.20),.9,.32); teal=material('M_InventoryTeal',(.035,.24,.23),.3,.42); glass=material('M_OpticLens',(.04,.27,.3),.65,.16)
def reg(o,mat):
 o.data.materials.append(mat); modules[current].append(o); return o
def bevel(o,w=.003,seg=3):
 bpy.context.view_layer.objects.active=o
 mod=o.modifiers.new('Authored edge bevel','BEVEL'); mod.width=w; mod.segments=seg
 bpy.ops.object.modifier_apply(modifier=mod.name)
 mod=o.modifiers.new('Weighted corner normals','WEIGHTED_NORMAL'); mod.keep_sharp=True; bpy.ops.object.modifier_apply(modifier=mod.name)
 return o
def box(name,loc,dim,mat,bev=.002,rot=0):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc); o=bpy.context.object; o.name=name; o.dimensions=dim; bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 if bev: bevel(o,bev)
 o.rotation_euler.y=rot; return reg(o,mat)
def profile(name,pts,depth,mat,bev=.002,y=0):
 vs=[(x,y+s*depth/2,z) for s in [-1,1] for x,z in pts]; n=len(pts); fs=[tuple(reversed(range(n))),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
 me=bpy.data.meshes.new(name); me.from_pydata(vs,[],fs); me.update(); o=bpy.data.objects.new(name,me); scene.collection.objects.link(o)
 bpy.context.view_layer.objects.active=o; o.select_set(True)
 if bev: bevel(o,bev)
 return reg(o,mat)
def cyl(name,loc,r,depth,mat,axis='X',vertices=24):
 bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=r,depth=depth,location=loc); o=bpy.context.object; o.name=name
 if axis=='X': o.rotation_euler.y=math.pi/2
 if axis=='Y': o.rotation_euler.x=math.pi/2
 bpy.ops.object.transform_apply(location=False,rotation=True,scale=True); bevel(o,.0008,2); return reg(o,mat)
def beam(name,a,b,width,depth,mat):
 a=Vector(a); b=Vector(b); o=box(name,(a+b)/2,(width,depth,(b-a).length),mat); o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler(); return o
def start(name):
 global current; current=name; modules[name]=[]
