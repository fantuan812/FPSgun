"""Original industrial reactor, meter units. build_reactor() has no scene/world/camera side effects."""
import bpy, math, json, os
from mathutils import Vector
from math import sin, cos, pi
ROOT=os.path.dirname(os.path.abspath(__file__))
C=None

def material(name,color,metal=0,rough=.4):
    m=bpy.data.materials.get('RC_'+name) or bpy.data.materials.new('RC_'+name)
    m.diffuse_color=(*color,1); m.use_nodes=True
    n=m.node_tree.nodes; n.clear()
    out=n.new('ShaderNodeOutputMaterial'); bs=n.new('ShaderNodeBsdfPrincipled');m.node_tree.links.new(bs.outputs['BSDF'],out.inputs['Surface'])
    bs.inputs['Base Color'].default_value=(*color,1);bs.inputs['Metallic'].default_value=metal;bs.inputs['Roughness'].default_value=rough
    noise=n.new('ShaderNodeTexNoise');noise.inputs['Scale'].default_value=7;noise.inputs['Detail'].default_value=2
    bump=n.new('ShaderNodeBump');bump.inputs['Strength'].default_value=.10;bump.inputs['Distance'].default_value=.025
    m.node_tree.links.new(noise.outputs['Fac'],bump.inputs['Height']);m.node_tree.links.new(bump.outputs['Normal'],bs.inputs['Normal'])
    roughmap=n.new('ShaderNodeMapRange');roughmap.inputs['From Min'].default_value=0;roughmap.inputs['From Max'].default_value=1
    roughmap.inputs['To Min'].default_value=max(.18,rough-.08);roughmap.inputs['To Max'].default_value=min(.62,rough+.14)
    m.node_tree.links.new(noise.outputs['Fac'],roughmap.inputs['Value']);m.node_tree.links.new(roughmap.outputs['Result'],bs.inputs['Roughness'])
    col=n.new('ShaderNodeValToRGB');col.color_ramp.elements[0].position=.15;col.color_ramp.elements[0].color=(*(c*.83 for c in color),1)
    col.color_ramp.elements[1].position=.85;col.color_ramp.elements[1].color=(*(min(1,c*1.08) for c in color),1)
    m.node_tree.links.new(noise.outputs['Fac'],col.inputs['Fac'])
    ao=n.new('ShaderNodeAmbientOcclusion');ao.inputs['Distance'].default_value=.12;ao.samples=8;ao.only_local=True
    dirt=n.new('ShaderNodeMixRGB');dirt.blend_type='MULTIPLY';dirt.inputs[0].default_value=.18
    m.node_tree.links.new(col.outputs['Color'],dirt.inputs[1]);m.node_tree.links.new(ao.outputs['Color'],dirt.inputs[2]);m.node_tree.links.new(dirt.outputs[0],bs.inputs['Base Color'])
    return m

def link(o,name,mat=None):
    o.name=name
    for cc in list(o.users_collection): cc.objects.unlink(o)
    C.objects.link(o)
    if mat: o.data.materials.append(mat)
    return o

def bevel(o,w=.035):
    mod=o.modifiers.new('Manufactured edge radii','BEVEL');mod.width=w;mod.segments=2
    if hasattr(o.data,'polygons'):
        for p in o.data.polygons:p.use_smooth=True
        mod=o.modifiers.new('Weighted corner normals','WEIGHTED_NORMAL');mod.keep_sharp=True
    return o

def cube(name,loc,dim,mat,edge=.025):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=link(bpy.context.object,name,mat);o.dimensions=dim;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    return bevel(o,edge) if edge else o

def cyl(name,loc,r,depth,mat,vertices=64,axis=None):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=r,depth=depth,location=loc)
    o=link(bpy.context.object,name,mat)
    if axis:o.rotation_euler=Vector(axis).to_track_quat('Z','Y').to_euler()
    return bevel(o,.025)

def beam(name,a,b,width,mat):
    va,vb=Vector(a),Vector(b);o=cube(name,(va+vb)/2,(width,width,(vb-va).length),mat,.014);o.rotation_euler=(vb-va).to_track_quat('Z','Y').to_euler();return o

def pipe(name,pts,r,mat):
    cu=bpy.data.curves.new(name,'CURVE');cu.dimensions='3D';cu.resolution_u=2;cu.bevel_depth=r;cu.bevel_resolution=3
    sp=cu.splines.new('POLY');sp.points.add(len(pts)-1)
    for p,v in zip(sp.points,pts):p.co=(*v,1)
    ob=bpy.data.objects.new(name,cu);C.objects.link(ob);ob.data.materials.append(mat);return ob

def ring(name,ri,ro,z,h,mat,start=0,end=2*pi,n=96):
    vs=[]
    for j in range(n+1):
        a=start+(end-start)*j/n
        vs.extend([(ri*cos(a),ri*sin(a),z-h),(ro*cos(a),ro*sin(a),z-h),(ro*cos(a),ro*sin(a),z),(ri*cos(a),ri*sin(a),z)])
    fs=[]
    for j in range(n):
        for k in range(4):fs.append((4*j+k,4*j+(k+1)%4,4*(j+1)+(k+1)%4,4*(j+1)+k))
    fs.extend([(3,2,1,0),(4*n,4*n+1,4*n+2,4*n+3)])
    me=bpy.data.meshes.new(name);me.from_pydata(vs,[],fs);me.update();o=bpy.data.objects.new(name,me);C.objects.link(o);o.data.materials.append(mat);return bevel(o,.012)

def radial_cube(name,r,a,z,dim,mat):
    o=cube(name,(r*cos(a),r*sin(a),z),dim,mat);o.rotation_euler.z=a;return o

def arcpipe(name,r,z,start,end,mat,th=.04):
    return pipe(name,[(r*cos(start+(end-start)*i/40),r*sin(start+(end-start)*i/40),z) for i in range(41)],th,mat)

def rail(radius,z,mat,red,prefix,gaps=True):
    # 3.2 m clear openings toward east and west; guard panels are absent across both connections.
    gap=.235 if gaps else .03
    arcs=([(.10,2*pi-.10)] if gaps=='east_only' else [(gap,pi-gap),(pi+gap,2*pi-gap)]) if gaps else [(0,2*pi)]
    for arc,(a,b) in enumerate(arcs):
        for zz in [z+.1,z+.56,z+1.1]:arcpipe(prefix+'_continuous_rail',radius,zz,a,b,mat)
        count=max(2,int((b-a)*radius/1.45))
        for j in range(count+1):
            ang=a+(b-a)*j/count
            cyl(prefix+'_post',(radius*cos(ang),radius*sin(ang),z+.55),.045,1.1,mat,12)
        for j in range(count):
            # Alternating red solid infill and open bays, makes shape legible and plausible sightlines.
            aa=a+(b-a)*(j+.15)/count;bb=a+(b-a)*(j+.85)/count
            if j%3!=1:ring(prefix+'_red_infill',radius-.06,radius+.015,z+.78,.50,red,aa,bb,6)
    return arcs

def build_reactor():
    global C
    C=bpy.data.collections.new('Reactor_Core');bpy.context.scene.collection.children.link(C)
    steel=material('dark_forged_steel',(.065,.082,.10),.78,.33)
    alloy=material('brushed_alloy',(.34,.38,.40),.82,.29)
    pale=material('equipment_enamel',(.46,.49,.48),.42,.40)
    red=material('oxide_red',(.36,.035,.027),.35,.39)
    black=material('carbon_recess',(.012,.019,.024),.45,.46)
    yellow=material('warning_ochre',(.70,.40,.035),.25,.43)
    # Concrete mounted base and lower service compartment.
    cyl('RC_mounting_plinth',(0,0,.15),4.5,.3,steel)
    cyl('RC_base_service_shell',(0,0,2.15),3.95,4.0,pale)
    for z in [.35,.62,3.75,4.12]:ring('RC_base_structural_band',3.87,4.12,z,.16,steel)
    for i in range(20):
        a=2*pi*i/20
        radial_cube('RC_lower_column',4.01,a,2.18,(.16,.18,3.7),steel)
        if i%5 not in [0]:
            radial_cube('RC_service_door',4.015,a,1.9,(.10,1.02,2.38),steel)
            radial_cube('RC_door_inset',4.08,a,1.92,(.05,.85,2.12),pale)
            radial_cube('RC_service_handle',4.13,a+.075,1.8,(.05,.04,.30),black)
            for zz in [2.62,2.72,2.82]:radial_cube('RC_louvre',4.12,a,zz,(.04,.70,.035),black)
    # Main ring platform with top exactly 4.5 m, underside structural spokes.
    ring('RC_main_walkway',4.03,7,4.5,.23,steel)
    ring('RC_walkway_inner_tread',4.85,6.88,4.512,.012,alloy)
    ring('RC_platform_outer_fascia',6.92,7.05,4.43,.40,steel)
    ring('RC_platform_safety_edge',6.83,6.93,4.525,.012,yellow)
    for i in range(32):
        a=2*pi*i/32
        beam('RC_platform_radial_joist',(3.92*cos(a),3.92*sin(a),4.12),(6.95*cos(a),6.95*sin(a),4.12),.15,steel)
        beam('RC_platform_knee_brace',(3.9*cos(a),3.9*sin(a),2.9),(6.4*cos(a),6.4*sin(a),4.1),.12,steel)
        # Tiny cross-grain strips break reflection without obstructing walkable surface.
        radial_cube('RC_tread_joint',5.86,a,4.526,(2.02,.018,.008),black)
    rail(6.93,4.5,alloy,red,'RC_main_guard',True)
    # Layered containment core: alternating heavy segmented bands and recessed cooling collars.
    cyl('RC_containment_body',(0,0,8.35),3.67,7.7,alloy)
    levels=[(4.75,4.15,.3),(5.15,3.95,.23),(5.85,4.0,.3),(6.2,3.85,.2),(7.2,4.10,.38),(7.65,3.97,.18),(8.6,3.95,.25),(9.1,4.1,.34),(10.2,4.05,.3),(11.05,4.0,.34),(11.8,3.88,.2),(12.45,3.76,.32)]
    for i,(z,r,h) in enumerate(levels):
        ring('RC_containment_flange_%02d'%i,3.58,r,z,h,steel if i%3 else pale)
        ring('RC_flange_polished_lip',r-.025,r+.035,z+.025,.045,alloy)
        if i in [2,4,7,9]:
            for j in range(32):
                a=j*2*pi/32
                cyl('RC_flange_bolt',(r*.97*cos(a),r*.97*sin(a),z+.065),.055,.09,black,8)
    # Broad red ring with individually segmented panels, no game branding.
    for j in range(24):
        a=j*2*pi/24+.016;b=(j+1)*2*pi/24-.016
        ring('RC_mid_red_service_panel',3.69,3.76,8.50,.62,red,a,b,5)
        radial_cube('RC_panel_fastener',3.79,(a+b)/2,8.40,(.045,.075,.075),alloy)
    # Second red containment band, pale removable service panels and six uniformly spaced risers.
    for j in range(24):
        aa=j*2*pi/24+.018;bb=(j+1)*2*pi/24-.018
        ring('RC_lower_red_containment_band',3.69,3.77,6.86,.46,red,aa,bb,5)
    for j in range(16):
        aa=j*2*pi/16+.03;bb=(j+1)*2*pi/16-.03
        ring('RC_upper_pale_inspection_panel',3.68,3.80,11.77,.60,pale if j%3 else steel,aa,bb,5)
        for da in [.08,-.08]:
            radial_cube('RC_panel_corner_stud',3.84,(aa+bb)/2+da,11.68,(.04,.045,.045),black)
    for j in range(6):
        aa=pi/6+j*pi/3;xx,yy=4.25*cos(aa),4.25*sin(aa)
        pipe('RC_sixfold_service_riser',[(3.73*cos(aa),3.73*sin(aa),5.42),(xx,yy,5.8),(xx,yy,9.40),(3.77*cos(aa),3.77*sin(aa),9.72)],.09,alloy)
        for zz in [6.3,7.8,9.0]:
            cyl('RC_service_riser_clamp',(xx,yy,zz),.135,.09,steel,20)
    # Vertical heat exchangers set into upper body.
    for i in range(32):
        a=i*2*pi/32
        radial_cube('RC_upper_heat_rib',3.72,a,10.97,(.19,.09,1.2),black)
    ring('RC_upper_service_deck',3.86,5.1,10,.18,steel)
    ring('RC_upper_deck_tread',4.08,5.01,10.012,.012,alloy)
    rail(5.04,10,alloy,red,'RC_upper_guard','east_only')
    # Crown geometry, central lid and inspection hatches.
    cyl('RC_crown_conical_neck',(0,0,12.55),3.45,.45,pale)
    ring('RC_crown_rim',3.3,3.77,12.92,.22,steel)
    cyl('RC_top_lid',(0,0,12.91),3.35,.18,alloy)
    cyl('RC_top_pressure_hatch',(0,0,13.20),1.12,.4,steel)
    for i in range(12):
        a=i*2*pi/12
        beam('RC_crown_radial_seam',(1.15*cos(a),1.15*sin(a),13.03),(3.25*cos(a),3.25*sin(a),13.03),.055,steel)
        cyl('RC_crown_bolt',(3.55*cos(a),3.55*sin(a),12.98),.085,.12,black,8)
    # Four auxiliary suspended accumulators; brackets, endcap collars and valve handwheel.
    for i,aa in enumerate([45,135,225,315]):
        a=math.radians(aa);r=4.50;x,y=r*cos(a),r*sin(a)
        beam('RC_accumulator_top_mount',(3.6*cos(a),3.6*sin(a),9.2),(x,y,9.2),.18,steel)
        beam('RC_accumulator_bottom_mount',(3.6*cos(a),3.6*sin(a),6.5),(x,y,6.5),.18,steel)
        cyl('RC_aux_accumulator_%d'%i,(x,y,7.95),.62,2.65,alloy)
        for zz in [6.65,6.82,8.95,9.22]:
            ob=cyl('RC_aux_flange',(x,y,zz),.76,.15,steel)
        cyl('RC_aux_red_band',(x,y,7.05),.635,.20,red)
        cyl('RC_aux_cap',(x,y,9.38),.52,.25,pale)
        # Downpipe ends at main housing, not walkway.
        pts=[(x,y,6.45),(x,y,5.7),(x*.88,y*.88,5.3),(x*.8,y*.8,5.3)]
        pipe('RC_aux_return_pipe',pts,.10,alloy)
    # Paired large coolant trunks along north/south sides, leaving east/west entrances clear.
    for side in [-1,1]:
        for xx in [-1.4,1.4]:
            yy=side*5.15
            pts=[(xx,side*3.7,5.0),(xx,side*4.65,5.0),(xx,side*5.00,5.35),(xx,yy,5.8),(xx,yy,11.9),(xx,side*5.00,12.45),(xx,side*4.65,12.9),(xx,side*3.3,12.9)]
            pipe('RC_main_coolant_trunk',pts,.20,alloy)
            for z in [6.8,9.2,12.0]:
                cyl('RC_coolant_coupling',(xx,yy,z),.29,.17,steel,32)
                beam('RC_pipe_anchor',(xx,yy,z),(xx,side*3.8,z),.08,steel)
    # Twin crown risers at rear; curved-looking quarter arcs instead of impossible sharp corners.
    for xx in [-.62,.62]:
        pts=[(xx,3.55,10.4),(xx,3.55,13.45)]
        for j in range(9):
            a=j*pi/16;pts.append((xx,3.0+.55*cos(a),13.45+.55*sin(a)))
        pts += [(xx,1.9,14.0),(xx,1.6,13.7),(xx,1.6,13.2)]
        pipe('RC_crown_riser',pts,.115,steel)
    # Caged fixed maintenance ladder links the two platforms; top landing is open to the upper ring.
    for yy in [-.36,.36]:
        beam('RC_access_ladder_rail',(5.38,yy,4.5),(5.38,yy,11.10),.065,alloy)
    for i in range(20):
        zz=4.68+i*.28
        beam('RC_access_ladder_rung',(5.38,-.36,zz),(5.38,.36,zz),.045,alloy)
    cube('RC_ladder_top_landing',(5.19,0,9.95),(.52,.82,.10),steel)
    for zz in [6.5,7.5,8.5,9.5,10.65]:
        pts=[(5.38+.62*cos(-pi/2+j*pi/20),.62*sin(-pi/2+j*pi/20),zz) for j in range(21)]
        pipe('RC_ladder_cage_hoop',pts,.027,red)
    for a in [-pi/2,-pi/4,0,pi/4,pi/2]:
        beam('RC_ladder_cage_upright',(5.38+.62*cos(a),.62*sin(a),6.5),(5.38+.62*cos(a),.62*sin(a),10.65),.035,alloy)
    # Original identification plaque on front equipment skin, not copied branding.
    radial_cube('RC_id_plate',4.13,-pi/2,3.18,(.06,1.6,.43),red)
    cu=bpy.data.curves.new('RC_label','FONT');cu.body='CORE / 05';cu.size=.24;cu.align_x='CENTER';cu.extrude=.002
    ob=bpy.data.objects.new('RC_original_identification',cu);C.objects.link(ob);ob.location=(0,-4.18,3.08);ob.rotation_euler=(pi/2,0,0);ob.data.materials.append(pale)
    C['design']='Original AZ3-inspired layered reactor. Not an engineering design or exact map reconstruction.'
    C['platform_z_m']=4.5;C['upper_platform_z_m']=10.0;C['entry_clear_width_m']=3.2
    return C

if __name__=='__main__':
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    col=build_reactor()
    bpy.context.scene.unit_settings.system='METRIC'
    info={'collection':col.name,'center_m':[0,0,0],'main_body_radius_m':4.0,'main_walkway_z_m':4.5,'main_walkway_radii_m':[4.85,6.88],'upper_walkway_z_m':10,'outer_platform_radius_m':7.05,'rail_height_m':1.1,'entry_angles_deg':[0,180],'entry_clear_width_m':3.2,'nominal_max_height_m':14.115,'surface_service_risers':6,'objects':len(col.objects),'notes':'No floor, world or camera changes in build_reactor(). Main platform top 4.5. Authored modular meter units; not structurally certified.'}
    with open(os.path.join(ROOT,'reactor_dimensions.json'),'w') as f:json.dump(info,f,indent=2)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT,'reactor.blend'),compress=True)
    print('REACTOR_READY',json.dumps(info))
