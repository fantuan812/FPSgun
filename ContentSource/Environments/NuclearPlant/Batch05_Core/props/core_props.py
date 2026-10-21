"""Industrial props; Blender 4.3; units metres. build_props() -> {name: Collection}.
Collections contain origin-relative geometry, ready for collection instancing.
Generated geometry is original; no third-party assets/textures.
"""
import bpy, math, json, os
from mathutils import Vector
ROOT=os.path.dirname(os.path.abspath(__file__))
COL=None

def mat(name,c,metal=0,rough=.55):
    m=bpy.data.materials.get(name) or bpy.data.materials.new(name); m.diffuse_color=(*c,1); m.use_nodes=True
    b=m.node_tree.nodes.get('Principled BSDF'); b.inputs['Base Color'].default_value=(*c,1); b.inputs['Metallic'].default_value=metal; b.inputs['Roughness'].default_value=rough
    return m

def coll(name):
    global COL
    COL=bpy.data.collections.new(name); bpy.context.scene.collection.children.link(COL); return COL

def finish(o,name,m,bevel=0):
    o.name=name
    for c in list(o.users_collection): c.objects.unlink(o)
    COL.objects.link(o)
    if m: o.data.materials.append(m)
    if bevel:
        mod=o.modifiers.new('Manufactured edge radius','BEVEL'); mod.width=bevel; mod.segments=2
        mod=o.modifiers.new('Weighted corner normals','WEIGHTED_NORMAL')
    return o

def box(n,p,s,m,b=.025):
    bpy.ops.mesh.primitive_cube_add(size=1,location=p); o=bpy.context.object; o.dimensions=s; bpy.ops.object.transform_apply(location=False,rotation=False,scale=True); return finish(o,n,m,b)

def cyl(n,p,r,h,m,axis='Z',vertices=32):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=r,depth=h,location=p); o=bpy.context.object
    if axis=='X': o.rotation_euler[1]=math.pi/2
    if axis=='Y': o.rotation_euler[0]=math.pi/2
    for f in o.data.polygons: f.use_smooth=len(f.vertices)==4
    return finish(o,n,m,.008)

def sphere(n,p,s,m):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=32,ring_count=16,radius=1,location=p); o=bpy.context.object; o.scale=s
    for f in o.data.polygons: f.use_smooth=True
    return finish(o,n,m)

def ring(n,p,major,minor,m,axis='Z'):
    bpy.ops.mesh.primitive_torus_add(major_radius=major,minor_radius=minor,major_segments=32,minor_segments=8,location=p); o=bpy.context.object
    if axis=='X':o.rotation_euler[1]=math.pi/2
    if axis=='Y':o.rotation_euler[0]=math.pi/2
    for f in o.data.polygons:f.use_smooth=True
    return finish(o,n,m)

def beam(n,a,b,r,m):
    a,b=Vector(a),Vector(b);o=cyl(n,(a+b)/2,r,(b-a).length,m);o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler();return o

def bolts(n,p,r,axis,m,count=8):
    for i in range(count):
        a=2*math.pi*i/count
        q=list(p)
        if axis=='X':q[1]+=r*math.cos(a);q[2]+=r*math.sin(a)
        elif axis=='Y':q[0]+=r*math.cos(a);q[2]+=r*math.sin(a)
        else:q[0]+=r*math.cos(a);q[1]+=r*math.sin(a)
        cyl(n+f'_{i}',q,.034,.055,m,axis,6)

def build_props():
    steel=mat('CP_Steel',(.095,.12,.13),.7,.42); teal=mat('CP_TealEnamel',(.12,.27,.28),.4,.38)
    gray=mat('CP_Aluminium',(.43,.49,.49),.8,.34); concrete=mat('CP_Concrete',(.38,.39,.37),0,.86)
    yellow=mat('CP_SafetyOchre',(.78,.44,.065),.15,.5); rubber=mat('CP_Rubber',(.023,.028,.027),0,.82)
    ceramic=mat('CP_Ceramic',(.42,.24,.13),.1,.24); wood=mat('CP_Wood',(.32,.23,.13),0,.82)
    paint=mat('CP_LightStencil',(.75,.78,.73),.0,.6)
    out={}
    c=coll('CP_PressureSkid');out[c.name]=c
    # Engineered skid rails, cross members and isolated pressure shell.
    for y in [-1.12,1.12]:box('PV_skid_longitudinal', (0,y,.14),(7.7,.22,.28),steel)
    for x in [-3.65,-2.3,0,2.3,3.65]:box('PV_skid_cross',(x,0,.16),(.18,2.65,.26),steel)
    for x in [-2.3,2.3]:
        box('PV_saddle_foot',(x,0,.39),(.45,1.68,.14),gray)
        box('PV_saddle_web',(x,0,.7),(.28,1.4,.56),steel)
        for y in [-.63,.63]:cyl('PV_saddle_anchor',(x,y,.49),.045,.08,gray)
    cyl('PV_shell',(0,0,1.65),.94,5.65,teal,'X',48)
    for x in [-2.825,2.825]:sphere('PV_dished_head',(x,0,1.65),(.56,.94,.94),teal)
    for x in [-2.3,2.3]:ring('PV_saddle_band',(x,0,1.65),.953,.035,gray,'X')
    for x in [-2.825,2.825]:ring('PV_head_weld',(x,0,1.65),.94,.018,gray,'X')
    # End flange and pipe connection.
    cyl('PV_outlet_neck',(3.5,0,1.65),.16,.5,gray,'X')
    cyl('PV_outlet_flange',(3.73,0,1.65),.25,.11,steel,'X');bolts('PV_flange_bolt',(3.80,0,1.65),.205,'X',gray)
    cyl('PV_feed_neck',(-3.5,0,1.65),.16,.5,gray,'X');cyl('PV_feed_flange',(-3.73,0,1.65),.25,.11,steel,'X')
    # Top manway, relief valve and handwheel.
    cyl('PV_manway_neck',(-.75,0,2.57),.3,.25,teal);cyl('PV_manway_cover',(-.75,0,2.72),.4,.1,gray);bolts('PV_manway_bolt',(-.75,0,2.79),.34,'Z',steel,12)
    cyl('PV_valve_branch',(1.4,0,2.66),.09,.35,gray);cyl('PV_valve_body',(1.4,0,2.88),.14,.18,yellow)
    beam('PV_valve_stem',(1.4,0,2.93),(1.4,0,3.12),.024,steel);ring('PV_handwheel',(1.4,0,3.12),.19,.018,yellow)
    for a in [0,math.pi/2]:beam('PV_handwheel_spoke',(1.4-.18*math.cos(a),-.18*math.sin(a),3.12),(1.4+.18*math.cos(a),.18*math.sin(a),3.12),.012,yellow)
    # Access step/ladder tied to skid, not floating.
    for x in [-1.1,-.5]:beam('PV_ladder_stringer',(x,-1.24,.3),(x,-1.02,2.64),.035,gray)
    for z in [.5,.85,1.2,1.55,1.9,2.25,2.6]:beam('PV_ladder_rung',(-1.1,-1.24+(z-.3)/2.34*.22,z),(-.5,-1.24+(z-.3)/2.34*.22,z),.025,gray)
    box('PV_identification_plate',(0,-.95,1.62),(.62,.025,.24),steel,.005)
    for i in range(4):box('PV_plate_mark',(0,-.968,1.55+i*.045),(.43-i*.055,.006,.012),paint,.001)
    # Double transformer.
    c=coll('CP_TransformerPad');out[c.name]=c
    box('TX_concrete_pad',(0,0,.12),(6,4,.24),concrete,.06)
    for x in [-1.5,1.5]:
        for y in [-.6,.6]:box('TX_base_skid',(x,y,.38),(1.9,.15,.28),steel)
        box('TX_oil_tank',(x,0,1.24),(1.45,1.5,1.48),teal,.08)
        box('TX_bolted_lid',(x,0,2.02),(1.56,1.6,.12),gray,.025)
        for yy in [-1,1]:
            for j in range(10):box('TX_radiator_fin',(x-.65+j*.145,yy*.9,1.25),(.045,.44,1.15),gray,.01)
            for zz in [.72,1.78]:beam('TX_header',(x-.7,yy*.88,zz),(x+.7,yy*.88,zz),.055,steel)
        for xx in [-.45,0,.45]:
            cyl('TX_bushing_stem',(x+xx,.15,2.35),.045,.65,gray)
            for z in [2.15,2.27,2.39,2.51]:cyl('TX_ceramic_shed',(x+xx,.15,z),.125,.065,ceramic)
            cyl('TX_terminal',(x+xx,.15,2.7),.065,.1,gray)
        cyl('TX_conservator',(x,-.36,2.43),.22,1.27,teal,'X')
        for xx in [-.48,.48]:beam('TX_reservoir_mount',(x+xx,-.36,2.05),(x+xx,-.36,2.31),.035,steel)
        box('TX_cable_entry',(x+.48,-.79,.86),(.4,.2,.48),steel)
        for dx in [-.1,.1]:cyl('TX_cable_down',(x+.48+dx,-.82,.52),.04,.53,rubber)
        box('TX_warning_plaque',(x,-.765,1.44),(.31,.025,.3),yellow,.005)
        for xx in [-.68,.68]:
            for yy in [-.68,.68]:cyl('TX_lid_bolt',(x+xx,yy,2.1),.025,.05,steel,vertices=6)
    # Barrier has a New Jersey profile, not a rectangular slab.
    c=coll('CP_RoadBarrier');out[c.name]=c
    profile=[(-.32,0),(.32,0),(.32,.15),(.16,.5),(.115,.92),(-.115,.92),(-.16,.5),(-.32,.15)]
    vs=[(x,y,z) for x in [-1,1] for y,z in profile];faces=[tuple(range(7,-1,-1)),tuple(range(8,16))]+[(i,(i+1)%8,(i+1)%8+8,i+8) for i in range(8)]
    mesh=bpy.data.meshes.new('Barrier_profile');mesh.from_pydata(vs,[],faces);mesh.update();o=bpy.data.objects.new('BR_concrete_profile',mesh);COL.objects.link(o);o.data.materials.append(concrete)
    mod=o.modifiers.new('Cast edge radius','BEVEL');mod.width=.018;mod.segments=2;o.modifiers.new('Weighted normals','WEIGHTED_NORMAL')
    for x in [-.75,.75]:
        box('BR_reflector',(x,-.121,.76),(.17,.018,.12),yellow,.005)
        ring('BR_lifting_eye',(x,0,.94),.045,.012,steel,'Y')
    for x in [-.48,.48]:box('BR_foot',(x,0,.055),(.26,.72,.11),concrete,.015)
    # Palletized instrument case.
    c=coll('CP_UtilityPallet');out[c.name]=c
    for x in [-.5,0,.5]:box('UT_pallet_runner',(x,0,.075),(.14,1,.15),wood,.01)
    for y in [-.43,-.215,0,.215,.43]:box('UT_pallet_board',(0,y,.17),(1.2,.18,.045),wood,.006)
    box('UT_instrument_case',(0,0,.63),(1.05,.85,.86),steel,.045)
    box('UT_lid',(0,0,1.08),(1.09,.89,.08),teal,.025)
    for x in [-.39,.39]:
        for y in [-.43,.43]:box('UT_corner_bracket',(x,y,.65),(.09,.035,.8),gray,.01)
        box('UT_lid_latch',(x,-.46,1.01),(.065,.03,.16),yellow,.006)
    for y in [-.2,.2]:box('UT_front_vent',(0,-.44,.7+y),(.54,.016,.028),rubber,.004)
    for x in [-.54,.54]:
        beam('UT_handle',(x,-.13,.78),(x,.13,.78),.025,gray)
        for yy in [-.13,.13]:beam('UT_handle_standoff',(x,yy,.78),(x*.96,yy,.72),.02,gray)
    # AZ3-inspired original reactor-room service equipment, not copied game assets.
    red=mat('CP_ReactorRed',(.5,.045,.035),.3,.48)
    pale=mat('CP_CabinetWhite',(.55,.59,.59),.3,.48)
    screen=mat('CP_ScreenGlass',(.015,.09,.105),.3,.24)
    glow=mat('CP_CyanDisplay',(.07,.65,.72),.1,.3)
    bs=glow.node_tree.nodes.get('Principled BSDF');bs.inputs['Emission Color'].default_value=(.05,.6,.72,1);bs.inputs['Emission Strength'].default_value=.7
    c=coll('CP_ReactorConsole');out[c.name]=c
    box('RC_base',(0,0,.13),(2.45,1.15,.26),steel,.06)
    verts=[(x,y,z) for z in [.24] for y in [-.46,.46] for x in [-1.125,1.125]]
    verts += [(x,y,.98+y*math.tan(math.radians(14))) for y in [-.46,.46] for x in [-1.125,1.125]]
    mesh=bpy.data.meshes.new('RC_wedge_body');mesh.from_pydata(verts,[],[(0,2,3,1),(4,5,7,6),(0,1,5,4),(2,6,7,3),(0,4,6,2),(1,3,7,5)]);mesh.update()
    ob=bpy.data.objects.new('RC_wedge_body',mesh);COL.objects.link(ob);ob.data.materials.append(pale)
    mod=ob.modifiers.new('Cabinet edge radius','BEVEL');mod.width=.03;mod.segments=2;ob.modifiers.new('Weighted normals','WEIGHTED_NORMAL')
    # Sloped desk surface rises at rear, with inset display and keyboard faces.
    desk=box('RC_sloping_desk',(0,0,1.03),(2.5,1.25,.12),steel,.025);desk.rotation_euler[0]=math.radians(14)
    for x in [-.68,.68]:
        o=box('RC_screen_frame',(x,.2,1.16),(1.02,.62,.045),gray,.02);o.rotation_euler[0]=math.radians(14)
        o=box('RC_screen_glass',(x,.19,1.185),(.91,.51,.018),screen,.006);o.rotation_euler[0]=math.radians(14)
        for k in range(6):
            o=box('RC_screen_readout',(x-.35+k*.12,.23,1.217),(.06,.07+k*.025,.005),glow,.001);o.rotation_euler[0]=math.radians(14)
        for j in range(3):
            for k in range(10):
                o=box('RC_keyboard_key',(x-.35+k*.078,-.39+j*.065,1.005+j*.016),(.055,.044,.015),gray,.003);o.rotation_euler[0]=math.radians(14)
    for x in [-1.12,1.12]:cyl('RC_emergency_stop',(x,-.35,1.021),.055,.035,red)
    for z in [.35,.42,.49,.56]:box('RC_air_vent',(0,-.472,z),(1.15,.02,.025),rubber,.003)
    c=coll('CP_ElectricalCabinetBank');out[c.name]=c
    box('EC_plinth',(0,0,.12),(3.15,.85,.24),steel)
    for x in [-1,0,1]:
        box('EC_cabinet',(x,0,1.27),(.97,.75,2.3),pale,.03)
        box('EC_door',(x,-.39,1.28),(.9,.04,2.14),pale,.015)
        box('EC_control_panel',(x,-.42,1.65),(.55,.025,.46),steel,.008)
        box('EC_display',(x-.08,-.44,1.72),(.28,.015,.16),screen,.003)
        box('EC_display_trace',(x-.08,-.452,1.72),(.21,.005,.018),glow,.001)
        for xx in [-.17,0,.17]:cyl('EC_panel_switch',(x+xx,-.46,1.52),.027,.035,gray,'Y',12)
        box('EC_pull',(x+.33,-.45,1.13),(.035,.08,.24),steel,.01)
        for z in [.45,.52,.59,.66]:box('EC_vent',(x,-.42,z),(.6,.018,.024),rubber,.002)
        box('EC_number_band',(x,-.42,2.18),(.6,.018,.09),red,.002)
    c=coll('CP_VerticalServiceTank');out[c.name]=c
    box('VT_foundation',(0,0,.12),(2.2,2.2,.24),concrete,.04)
    for x,y in [(-.6,-.6),(-.6,.6),(.6,-.6),(.6,.6)]:
        box('VT_footplate',(x,y,.29),(.3,.3,.1),steel)
        box('VT_support',(x,y,.67),(.16,.16,.68),steel)
    cyl('VT_shell',(0,0,2.65),.83,3.3,pale,vertices=48)
    sphere('VT_top_dome',(0,0,4.3),(.83,.83,.4),pale);sphere('VT_bottom_dome',(0,0,1),(.83,.83,.3),pale)
    for z in [1.1,4.2]:ring('VT_shell_weld',(0,0,z),.835,.02,gray)
    cyl('VT_top_connection',(0,0,4.75),.1,.35,steel);cyl('VT_top_flange',(0,0,4.94),.19,.08,gray);bolts('VT_top_bolt',(0,0,5),.15,'Z',steel)
    cyl('VT_lower_branch',(0,-.98,1.1),.12,.55,steel,'Y');cyl('VT_lower_flange',(0,-1.23,1.1),.2,.08,gray,'Y');bolts('VT_lower_bolt',(0,-1.29,1.1),.16,'Y',steel)
    cyl('VT_valve_stem',(0,-1.05,1.35),.03,.35,steel);ring('VT_red_valve',(0,-1.05,1.55),.18,.02,red)
    for z in [1.3,3.8]:beam('VT_ladder_mount',(.87,0,z),(1.1,0,z),.035,steel)
    for y in [-.25,.25]:beam('VT_ladder_side',(1.1,y,.35),(1.1,y,4.7),.025,gray)
    for i in range(14):beam('VT_ladder_rung',(1.1,-.25,.5+i*.3),(1.1,.25,.5+i*.3),.02,gray)
    box('VT_identification',(0,-.84,2.7),(.5,.025,.3),steel,.005)
    c=coll('CP_RedGuardPanel');out[c.name]=c
    for x in [-.95,.95]:
        box('RG_foot',(x,0,.04),(.22,.24,.08),steel,.01)
        box('RG_post',(x,0,.61),(.07,.07,1.14),steel,.01)
    box('RG_red_infill',(0,0,.61),(1.82,.055,.88),red,.015)
    box('RG_top_rail',(0,0,1.2),(2,.09,.09),gray,.015)
    box('RG_lower_rail',(0,0,.15),(2,.07,.07),steel,.01)
    for x in [-.89,.89]:
        for z in [.22,1.02]:cyl('RG_panel_bolt',(x,-.038,z),.017,.025,gray,'Y',6)
    return out

def inventory(cols):
    result={}
    for name,c in cols.items():
        pts=[o.matrix_world@Vector(v) for o in c.objects if o.type=='MESH' for v in o.bound_box]
        lo=[min(v[i] for v in pts) for i in range(3)]; hi=[max(v[i] for v in pts) for i in range(3)]
        result[name]={'objects':len(c.objects),'vertices':sum(len(o.data.vertices) for o in c.objects if o.type=='MESH'),'bounds_min':lo,'bounds_max':hi,'dimensions_m':[hi[i]-lo[i] for i in range(3)]}
    return result

if __name__=='__main__':
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    cols=build_props();bpy.context.view_layer.update()
    bpy.context.scene.unit_settings.system='METRIC'
    with open(os.path.join(ROOT,'inventory.json'),'w') as f:json.dump(inventory(cols),f,indent=2)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT,'props.blend'),compress=True)
    print('PROPS_SAVED',os.path.join(ROOT,'props.blend'))
