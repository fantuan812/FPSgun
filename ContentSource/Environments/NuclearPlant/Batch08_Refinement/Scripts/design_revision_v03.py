"""Batch08 numeric design authoring. Runs outside Blender BEFORE any B08 model exists.
Orthographic sheets are projections of design primitives, never rendered models.
"""
import json,math,pathlib,hashlib,datetime,copy
import numpy as np
R=pathlib.Path(__file__).resolve().parent.parent; P=R.parent
C={'schema':'batch08-design-first-v1','revision':'v03','seed':8021,'units':'metres','source':'../Batch07_Refinement/site_refined.blend','modules':{},'regions':{},'material_palette':{'concrete':'#969d9a','steel':'#36444a','zinc':'#89999c','dark':'#182729','yellow':'#c6a455','red':'#8a4d3d','white':'#d9ddd4','tarp':'#697d70','hem':'#495b4f','rope':'#b4a485','wood':'#7c674e','timber_edge':'#5c4833','rubber':'#262d2b'},'protected_door':{'min':[-8.6,-19.1,0],'max':[8.6,-18.25,7.2]},'render':{'width':1600,'height':1000,'samples':48},'cameras':{},'notes':['Additive scene change only. All baseline mesh geometry and transforms retained.','No open cable, rail, grate or decorative tarp layer credited as new solid protection.','Raised trench follows service margins; flush cover nominal top <=0.03m, not a runtime traversal certification.','LOD, collision cooking, texture baking and official Manny/UE checks not included.']}
def box(n,p,d,m,**kw):return {'type':'box','name':n,'p':p,'d':d,'mat':m,**kw}
def cyl(n,p,r,l,m,axis='Z',segments=12):return {'type':'cylinder','name':n,'p':p,'r':r,'l':l,'axis':axis,'segments':segments,'mat':m}
def tube(n,pts,r,m,segments=8):return {'type':'tube','name':n,'points':pts,'r':r,'segments':segments,'mat':m}
def mesh(n,v,f,m,**kw):return {'type':'mesh','name':n,'verts':v,'faces':f,'mat':m,**kw}
def addmodule(mid,title,parts,notes,**kw):C['modules'][mid]={'title':title,'parts':parts,'notes':notes,**kw}
# 01: 4m service duct / drainage edge, actual base and removable hatch hardware.
a=[box('continuous concrete footing',[0,0,.07],[4,1.05,.14],'concrete'),box('drain channel bottom',[0,-.411,.15],[3.92,.18,.02],'dark')]
for x in [-1.5,-.5,.5,1.5]:
 a += [box('curb block',[x,.375,.24],[.985,.30,.20],'concrete'),box('replaceable rubber curb nose',[x,.212,.27],[.84,.035,.12],'rubber'),box('small ochre reflector',[x,.190,.29],[.24,.012,.035],'yellow')]
for x in [-1.32,0,1.32]:
 a+=[box('removable service cover',[x,-.04,.178],[1.29,.56,.076],'steel'),box('cover raised rim',[x,-.04,.218],[1.24,.51,.012],'zinc')]
 for dx in [-.53,.53]:
  for y in [-.23,.15]:a.append(cyl('captive cover screw',[x+dx,y,.23],.017,.012,'zinc',segments=8))
 for dx in [-.39,.39]:a.append(box('recessed lift pull',[x+dx,-.04,.227],[.11,.065,.006],'dark'))
 for dx in [-.5,-.25,0,.25,.5]:a.append(box('pressed grip rib',[x+dx,-.04,.23],[.09,.34,.008],'steel',rz=25))
for y in [-.505,-.315]:a.append(box('grate angle frame',[0,y,.201],[3.96,.025,.084],'zinc'))
for x in np.linspace(-1.93,1.93,38):a.append(box('drain grate bearing bar',[float(x),-.41,.23],[.028,.18,.022],'zinc'))
for x in [-1.96,1.96]:a.append(box('grate end rim',[x,-.41,.212],[.025,.20,.058],'zinc'))
addmodule('B08_SERVICE_EDGE','Service duct + drainage / curb edge',a,['4m repeat along a non-pedestrian margin. Grounded concrete base, cover panels, screws, lift slots, grate and replaceable bumper.','Raised component height 0.34m; never place across a protected route.'],family='service_edge',bevel=.006)
# Flush crossing is a dimensioned family variant, no raised curb.
a=[box('flush dark joint bed',[0,0,.005],[4,.60,.010],'dark')]
for x in [-1.5,-.5,.5,1.5]:
 a.append(box('flush cover leaf',[x,0,.015],[.985,.57,.020],'steel'))
 for dx in [-.39,.39]:
  for y in [-.20,.20]:a.append(cyl('flush screw',[x+dx,y,.026],.014,.002,'zinc',segments=8))
 for dx in [-.3,0,.3]:a.append(box('flush embossed marker',[x+dx,0,.0255],[.075,.29,.001],'zinc',rz=25))
addmodule('B08_SERVICE_EDGE_FLUSH','Service edge / flush crossing variant',a,['4.0 x 0.60m; top 0.027m. Visible overlay geometry, not proof of character traversal.'],family='service_edge',bevel=.002)
# 02: wall terminal. Back fixing face +Y=0.16, terminal front faces -Y.
a=[box('mounting backplate',[0,.13,1.32],[1.52,.06,2.36],'steel')]
for x in [-.63,.63]:
 a.append(box('wall mounting rail',[x,.04,1.32],[.10,.12,2.42],'zinc'))
 for z in [.18,2.46]:a.append(cyl('wall anchor bolt',[x,-.025,z],.024,.035,'zinc','Y',8))
a += [box('sealed terminal body',[-.19,-.115,1.77],[.96,.40,1.14],'zinc'),box('door gasket',[-.19,-.324,1.77],[.91,.016,1.09],'dark'),box('folded door leaf',[-.19,-.34,1.77],[.88,.025,1.06],'steel'),box('door ID strip',[-.19,-.357,2.19],[.74,.014,.12],'white'),box('vent warning plate',[-.19,-.357,1.93],[.22,.014,.19],'yellow'),box('recessed quarter turn latch',[.16,-.36,1.62],[.036,.024,.11],'zinc'),box('projecting weather hood',[-.12,-.14,2.40],[1.38,.52,.055],'steel'),box('hood drip edge',[-.12,-.397,2.365],[1.38,.025,.075],'zinc')]
for z in [1.40,2.06]:a.append(cyl('sealed door hinge',[-.65,-.327,z],.025,.13,'zinc','Z',12))
# Explicit power receptacles and insulating collars on right.
for z,m in [(.87,'red'),(1.18,'yellow')]:
 a += [box('socket mounting block',[.52,-.07,z],[.27,.25,.24],'steel'),cyl('industrial socket collar',[.52,-.231,z],.091,.09,m,'Y',20),cyl('socket protective cap',[.52,-.286,z],.075,.028,'dark','Y',20),box('socket cap hinge',[.52,-.29,z+.083],[.13,.045,.033],'zinc')]
# Closed conduit runs physically terminate in housing glands and foot at z=.12.
for x in [-.43,-.12]:
 pts=[[x,-.12,1.20],[x,-.12,.45],[x,-.12,.27],[x,-.18,.18],[x,-.28,.15]]
 a += [tube('swept supply conduit',pts,.038,'zinc',12),cyl('housing gland',[x,-.12,1.21],.056,.08,'dark'),cyl('sealed foot sleeve',[x,-.28,.115],.063,.15,'rubber')]
 for z in [.5,.96]:a.append(box('conduit clip',[x,-.12,z],[.13,.11,.035],'steel'))
a.append(tube('earth bond',[[.52,-.09,.75],[.55,-.09,.45],[.34,-.09,.22],[.12,-.09,.17]],.012,'yellow',8))
a.append(box('foot cable termination box',[0,-.07,.12],[1.02,.44,.24],'steel'))
# Triangle is a design mark, not hidden machinery.
a.append(mesh('electrical caution triangle',[[-.27,-.366,1.88],[-.11,-.366,1.88],[-.19,-.366,2.02]],[[0,1,2]],'dark'))
# Keep all four wall anchors within the original 2.4m solid concrete band.
for part in a:
 if part['type']=='box':part['p'][2]*=.9;part['d'][2]*=.9
 elif part['type']=='cylinder':
  part['p'][2]*=.9
  if part['axis']=='Z':part['l']*=.9
 elif part['type']=='tube':
  for pnt in part['points']:pnt[2]*=.9
 elif part['type']=='mesh':
  for pnt in part['verts']:pnt[2]*=.9
addmodule('B08_WALL_TERMINAL','Wall service terminal / sealed distribution point',a,['Back mounting face +Y=0.16m must touch an existing wall; front faces -Y.','Cabinet, rail, fixings, weather hood, sockets, bonded conduit and foot junction are grounded to one assembly.'],family='wall_terminal',bevel=.004)
# 03: additive cloth and timber detail. Original B07 cargo mesh remains untouched in site.
b07=json.loads((P/'Batch07_Refinement/Config/design_v04.json').read_text())
old=copy.deepcopy(b07['modules']['B07_CARGO_SET']['parts']); rings=np.array(old[10]['verts']) if old[10]['name']=='draped machine cover' else np.array(next(p for p in old if p['name']=='draped machine cover')['verts'])
rings=rings.reshape(3,4,3)
a=[]
# Each side is a ruled analytic cloth envelope. All displacement is OUTWARD from legacy shell.
norms=[np.array([0,-1,0]),np.array([1,0,0]),np.array([0,1,0]),np.array([-1,0,0])]
def sidepoint(side,u,t):
 seg=min(1,int(t));v=t-seg;p0=rings[seg,side]*(1-u)+rings[seg,(side+1)%4]*u;p1=rings[seg+1,side]*(1-u)+rings[seg+1,(side+1)%4]*u;p=p0*(1-v)+p1*v
 # Broad creases, a few gathered folds and restrained hem waviness. No randomness.
 fold=(.5+.5*math.cos(u*math.pi*12 +.65*math.sin(t*4+side)))**5
 amp=.025+.039*fold*(.65+.35*math.cos(t*math.pi/4))
 p=p+norms[side]*amp;p[2]+=.025+(.006*math.sin(u*25+side)*(1-t/2))
 # Conservative outer cloth envelope includes unchanged old webbing; no intersection with its fold kink.
 if side==0:
  profile=float(np.interp(p[2],[.36,1.82,2.16],[-1.391,-1.281,-.9075]));p[1]=min(p[1],profile-.025)
  # Rounded local relief over both unchanged old metal buckles. Plateau includes full buckle bounds.
  for xx in [-1.5,-.2]:
   dx=max(0,abs(p[0]-xx)-.14)/.14;dz=max(0,abs(p[2]-.9)-.18)/.20;w=max(0,1-max(dx,dz));w=w*w*(3-2*w);p[1]=p[1]*(1-w)+min(p[1],-1.397)*w
 if side==2:
  profile=float(np.interp(p[2],[.36,1.84,2.16],[1.391,1.2535,.8525]));p[1]=max(p[1],profile+.025)
 return p
for side in range(4):
 v=[sidepoint(side,u,t).tolist() for t in np.linspace(0,2,25) for u in np.linspace(0,1,25)]
 f=[[j*25+i,j*25+i+1,(j+1)*25+i+1,(j+1)*25+i] for j in range(24) for i in range(24)]
 a.append(mesh('draped cloth side '+str(side),v,f,'tarp',smooth=True))
 # Hem, joined corner, shoulder seams follow actual cloth.
 a.append(tube('stitched reinforced hem '+str(side),[sidepoint(side,u,0).tolist() for u in np.linspace(0,1,25)],.011,'hem'))
 a.append(tube('reinforced corner seam '+str(side),[sidepoint(side,0,t).tolist() for t in np.linspace(0,2,25)],.009,'hem'))
 # lower metal eyelets and small tie cords, two per side.
 for u in [.15,.48,.83]:
  p=sidepoint(side,u,.11);q=p+norms[side]*.006
  tangent=(rings[0,(side+1)%4]-rings[0,side]);tangent[2]=0;tangent=tangent/np.linalg.norm(tangent)
  pts=[(q+tangent*math.cos(k*math.pi/8)*.034+np.array([0,0,math.sin(k*math.pi/8)*.034])).tolist() for k in range(17)]
  a.append(tube('brass eyelet',pts,.008,'zinc',8))
  end=p.copy();end[2]=.28
  if side==0:end[1]=-1.27
  elif side==2:end[1]=1.21
  else:
   end[0]=.29 if side==1 else -1.99;end[1]=float(min(np.linspace(-1.21,1.21,7),key=lambda y:abs(y-end[1])))
  guide=q+norms[side]*.035;guide[2]=.32
  a.append(tube('tied hem cord',[q.tolist(),guide.tolist(),end.tolist()],.008,'rope',8))
# Roof top grid, raised over old cover and straps.
v=[]
for vv in np.linspace(0,1,17):
 for uu in np.linspace(0,1,21):
  p=(rings[2,0]*(1-uu)+rings[2,1]*uu)*(1-vv)+(rings[2,3]*(1-uu)+rings[2,2]*uu)*vv;p[2]+=.045+.008*math.sin(uu*12)*math.sin(vv*9);v.append(p.tolist())
f=[[j*21+i,j*21+i+1,(j+1)*21+i+1,(j+1)*21+i] for j in range(16) for i in range(20)]
a.append(mesh('creased cloth crown',v,f,'tarp',smooth=True))
# Close the four corner gores and crown perimeter: cloth is a continuous outer shell.
for side in range(4):
 vv=[]
 for t in np.linspace(0,2,25):vv.extend([sidepoint(side,1,t).tolist(),sidepoint((side+1)%4,0,t).tolist()])
 ff=[[2*i,2*i+1,2*i+3,2*i+2] for i in range(24)];a.append(mesh('cloth corner gore '+str(side),vv,ff,'tarp',smooth=True))
 vv=[]
 for u in np.linspace(0,1,25):
  outer=sidepoint(side,u,2);inner=rings[2,side]*(1-u)+rings[2,(side+1)%4]*u;inner[2]+=.045
  vv.extend([outer.tolist(),inner.tolist()])
 ff=[[2*i,2*i+1,2*i+3,2*i+2] for i in range(24)];a.append(mesh('cloth crown joining seam '+str(side),vv,ff,'tarp',smooth=True))
# Tension bands overlap cloth, single uninterrupted strip front -> top -> rear.
for x in [-1.5,-.2]:
 # Both edges sampled on the actual cloth surface, 4mm face offset: no floating flat band.
 vv=[]
 for t in np.linspace(0,2,33):
  lo=min(1,int(t));ff=t-lo;left=rings[lo,0]*(1-ff)+rings[lo+1,0]*ff;right=rings[lo,1]*(1-ff)+rings[lo+1,1]*ff
  for xx in [x-.037,x+.037]:
   u=(xx-left[0])/(right[0]-left[0]);p=sidepoint(0,u,t);p[1]-=.004;vv.append(p.tolist())
 for yy in np.linspace(rings[2,0,1],rings[2,3,1],17):
  for xx in [x-.037,x+.037]:
   uu=(xx-rings[2,0,0])/(rings[2,1,0]-rings[2,0,0]);vt=(yy-rings[2,0,1])/(rings[2,3,1]-rings[2,0,1]);zz=2.14+.045+.008*math.sin(uu*12)*math.sin(vt*9)+.004;vv.append([xx,yy,zz])
 for t in np.linspace(2,0,33):
  lo=min(1,int(t));ff=t-lo;left=rings[lo,3]*(1-ff)+rings[lo+1,3]*ff;right=rings[lo,2]*(1-ff)+rings[lo+1,2]*ff
  for xx in [x-.037,x+.037]:
   u=(right[0]-xx)/(right[0]-left[0]);p=sidepoint(2,u,t);p[1]+=.004;vv.append(p.tolist())
 ff=[[2*i,2*i+1,2*i+3,2*i+2] for i in range(len(vv)//2-1)];a.append(mesh('continuous replacement tension band',vv,ff,'dark'))
 for sy in [-1,1]:
  side=0 if sy<0 else 2;t=.66;lo=0;ff=t
  if side==0:
   left=rings[0,0]*(1-ff)+rings[1,0]*ff;right=rings[0,1]*(1-ff)+rings[1,1]*ff;u=(x-left[0])/(right[0]-left[0])
  else:
   left=rings[0,3]*(1-ff)+rings[1,3]*ff;right=rings[0,2]*(1-ff)+rings[1,2]*ff;u=(right[0]-x)/(right[0]-left[0])
  surface=sidepoint(side,u,t);yy=surface[1]+sy*.033;zz=surface[2]
  a += [box('ratchet frame',[x,yy,zz],[.125,.075,.19],'zinc'),box('ratchet dark inset',[x,yy+sy*.044,zz],[.074,.015,.12],'dark'),box('ratchet lever',[x,yy+sy*.06,zz+.075],[.12,.03,.035],'zinc')]
# Composite crate gains construction seams, corner protection and fasteners (no new boxes scattered).
for x in [.58,2.12]:
 for y in [-1.31,.41]:
  a.append(box('crate corner angle',[x,y,.80],[.07,.065,.91],'zinc'))
for x in [.82,1.10,1.38,1.66,1.94]:
 a.append(box('crate board seam',[x,-1.304,.80],[.009,.004,.88],'timber_edge'))
for x in [.704,1.996]:
 for z in [.44,.62,.98,1.18]:a.append(cyl('crate countersunk nail',[x,-1.415 if z in [.44,1.18] else -1.382,z],.013,.014,'zinc','Y',8))
for x in [-1.74,-.85,.043,.704,1.35,1.996]:
 for y in [-1.21,.34]:a.append(cyl('pallet deck nail',[x,y,.307],.012,.006,'zinc','Z',8))
# Label backing (text labels added in Blender from predeclared strings).
a.append(box('shipping tag replacement',[1.35,-1.441,.86],[.44,.014,.30],'white'))
addmodule('B08_CARGO_DRESSING','Cloth / pallet / shipping-case refinement',a,['Additive overlay on the exact B07 cargo group; original cargo is retained unchanged beneath the shell.','Cloth has explicit outward folds, continuous straps, reinforced hems, metal eyelets and tied cords; linked instancing keeps one unique mesh.','Standalone asset includes the exact B07 base plus this dressing. No engine LOD or collision certification.'],family='cargo',bevel=0,base_module='B07_CARGO_SET',base_parts=old)
# Two explicitly bounded interventions, no expansion of map.
C['regions']={'east_service_link':{'title':'Pump building / yard service connection','bounds':[40,68,-36,26],'placements':[],'custom_parts':[],'description':'Continuous service edge along the west pump-plant margin, flush covers at protected pedestrian crossing, paired wall interfaces at building and transformer yard.'},'southwest_receiving':{'title':'Maintenance-to-receiving service band','bounds':[-69,-12,-61,-15],'placements':[],'custom_parts':[],'description':'One service spine from maintenance wall to existing receiving pads; no new cargo placements.'}}
def place(r,m,p,rz=0,scale=None,tag=None):
 d={'module':m,'position':p,'rz':rz}
 if scale:d['scale']=scale
 if tag:d['tag']=tag
 C['regions'][r]['placements'].append(d)
# East north-south band x44.5. Gaps at east-service entry y8 and diagonal walk near y-11.
for y in [-18,-6,-2,2,14,18,22]:place('east_service_link','B08_SERVICE_EDGE',[44.5,y,0],90,tag='east_spine')
for y in [-12,6,10]:place('east_service_link','B08_SERVICE_EDGE_FLUSH',[44.5,y,0],90,scale=[2 if y==-12 else 1,1,1],tag='protected_crossing')
place('east_service_link','B08_SERVICE_EDGE_FLUSH',[46.75,-18,0],0,scale=[1.125,1,1],tag='yard_feed')
place('east_service_link','B08_WALL_TERMINAL',[45.84,22,0],-90,tag='pump_hall_wall_contact')
place('east_service_link','B08_WALL_TERMINAL',[48.84,-18,0],-90,tag='transformer_external_wall_contact')
place('east_service_link','B08_WALL_TERMINAL',[49.41,-20.0,0],90,tag='transformer_internal_wall_contact')
# Terminal foot to spine: low plate only; exact rectangle computed as plan input.
C['regions']['east_service_link']['custom_parts'] += [box('building foot connection',[45.10,22,.014],[1.42,.44,.028],'steel'),box('internal terminal foot lead',[49.70,-20,.012],[.60,.40,.024],'steel')]
# Southwest vertical from maintenance south face to receiving north strip.
for y in [-18,-22,-26,-30,-34]:place('southwest_receiving','B08_SERVICE_EDGE',[-66,y,0],90,tag='maintenance_supply')
for x in [-63.5,-59.5,-55.5,-51.5,-47.5,-43.5,-39.5,-35.5,-31.5,-27.5,-23.5,-19.5,-15.5]:place('southwest_receiving','B08_SERVICE_EDGE',[x,-36,0],0,tag='receiving_spine')
place('southwest_receiving','B08_WALL_TERMINAL',[-66,-16.16,0],0,tag='maintenance_wall_contact')
# Feed branches terminate at north/back faces of existing walls. 2.4m wall contact y=-38.875.
for x in [-56,-38,-20]:
 place('southwest_receiving','B08_SERVICE_EDGE_FLUSH',[x,-37.44,0],90,scale=[.72,1,1],tag='receiving_branch')
 place('southwest_receiving','B08_WALL_TERMINAL',[x,-38.84,0],180,tag='receiving_external_wall_contact')
# Interior servicing behind cargo; attached to rear concrete faces, never put into 2m apron.
for x,y in [(-42.4,-53.00),(-24.4,-40.00),(-60.4,-40.00)]:place('southwest_receiving','B08_WALL_TERMINAL',[x,y,0],0,tag='receiving_internal_wall_contact')
for p in b07['regions']['southwest_logistics']['placements']:
 if p['module']=='B07_CARGO_SET':place('southwest_receiving','B08_CARGO_DRESSING',p['position'],p['rz'],tag='existing_cargo_overlay')
# Purposeful slab-panel perimeter gives service band a grounded use, not dirt scattered over whole site.
C['regions']['southwest_receiving']['custom_parts'] += [box('service apron edge joint',[-65.9,-26,.008],[1.8,20,.016],'dark'),box('service apron walk side',[-65.9,-26,.009],[1.75,20,.018],'concrete'),box('receiving spine apron',[-39.5,-36,.008],[52,1.8,.016],'concrete')]
# Explicit junction cap at small L corner, not an undocumented raised overlap.
C['regions']['southwest_receiving']['custom_parts'].append(box('L joint connection cover',[-65.6,-36,.015],[.8,.56,.03],'steel'))
# Light service-floor markings with no object scatter, lower than existing 0.03m decals.
for r,rects in [('east_service_link',[(44.5,-12,3.6),(44.5,8,5.4)]),('southwest_receiving',[(-56,-37.45,1.4),(-38,-37.45,1.4),(-20,-37.45,1.4)])]:
 for x,y,length in rects:
  for dx in [-.55,.55]:C['regions'][r]['custom_parts'].append(box('service crossing edge stencil',[x+dx,y,.006],[.06,length,.008],'yellow'))
# Camera definitions are fixed before scene construction; source daylight is unchanged.
C['cameras']=copy.deepcopy(b07['cameras']);C['cameras'].update(json.loads((P/'Batch07_Refinement/Config/render_cameras.json').read_text())['cameras'])
C['cameras'].update({'pump_connection_eye':{'position':[42.0,-22.5,1.65],'target':[47.8,-8.0,1.65],'lens':23},'receiving_connection_eye':{'position':[-61.5,-33.5,1.65],'target':[-55,-37.5,1.5],'lens':25},'cargo_detail_eye':{'position':[-40.9,-62,1.65],'target':[-39.5,-57.2,1.3],'lens':38}})
C['ground_labels']=[{'body':'SERVICE / E-04','p':[44.5,-4,.031],'rz':90,'size':.22},{'body':'RECEIVING  /  KEEP CLEAR','p':[-38,-34.9,.029],'rz':0,'size':.32}]
C['modules']['B08_WALL_TERMINAL']['labels']=[{'body':'SVC / ISOLATE','position':[-.19,-.368,1.946],'size':.058,'material':'dark'}]
C['modules']['B08_CARGO_DRESSING']['labels']=[{'body':'NP - SPARES\nDRY STORE / 02','position':[1.35,-1.451,.89],'size':.047,'material':'dark'}]
# V02 grounding: extend hidden bedding down to the lowest existing datum (-0.05m), never raise tops.
for mid,partname in [('B08_SERVICE_EDGE','continuous concrete footing'),('B08_SERVICE_EDGE_FLUSH','flush dark joint bed')]:
 for part in C['modules'][mid]['parts']:
  if part['name']==partname:
   top=part['p'][2]+part['d'][2]/2;part['p'][2]=(top-.05)/2;part['d'][2]=top+.05
C['modules']['B08_WALL_TERMINAL']['parts'].append(box('leveling grout under foot junction',[0,-.07,-.025],[1.02,.44,.05],'concrete'))
for rn,r in C['regions'].items():
 for part in r['custom_parts']:
  if part['name']=='service crossing edge stencil':
   if rn=='southwest_receiving':part['p'][2]-=.015
   elif part['p'][1]<-8:part['p'][2]-=.05
  elif part['type']=='box' and part['p'][2]-part['d'][2]/2>=-.001:
   top=part['p'][2]+part['d'][2]/2;part['p'][2]=(top-.05)/2;part['d'][2]=top+.05
C['revision_changes']=['Hidden service-edge/flush/terminal and apron bedding reaches existing -0.05m datum, unchanged top heights.','Three receiving interior terminals moved to actual canopy waist-screen front planes and 0.23m clear of side screens.','Cloth envelope clears preserved old buckles/webbing; new ratchets placed higher, eyelets and tie cords contact cloth/deck.']
# V03: manufacture ribbons directly from the actual piecewise-linear cloth triangles.
# This is a pre-model numeric operation: no Blender model is read to generate these inputs.
mp=C['modules']['B08_CARGO_DRESSING']['parts']
for part in mp:
 if part['type']=='mesh' and any(k in part['name'] for k in ['draped cloth side','creased cloth crown','cloth corner gore','cloth crown joining seam']):
  triangles=[]
  for face in part['faces']:
   for k in range(1,len(face)-1):triangles.append([face[0],face[k],face[k+1]])
  part['faces']=triangles
mp[:]=[p for p in mp if p['name']!='continuous replacement tension band']
def clip_x(poly,value,keep_greater):
 out=[]
 for a,b in zip(poly,poly[1:]+poly[:1]):
  ia=a[0]>=value-1e-10 if keep_greater else a[0]<=value+1e-10;ib=b[0]>=value-1e-10 if keep_greater else b[0]<=value+1e-10
  if ia:out.append(a)
  if ia!=ib:
   f=(value-a[0])/(b[0]-a[0]);out.append(a+(b-a)*f)
 return out
surfaces=[]
for p in mp:
 n=p['name'];normal=None
 if n=='draped cloth side 0':normal=np.array([0,-1,0])
 elif n=='draped cloth side 2':normal=np.array([0,1,0])
 elif n=='creased cloth crown':normal=np.array([0,0,1])
 elif n=='cloth crown joining seam 0':normal=np.array([0,-1,1])/math.sqrt(2)
 elif n=='cloth crown joining seam 2':normal=np.array([0,1,1])/math.sqrt(2)
 if normal is not None:surfaces.append((p,normal))
for x in [-1.5,-.2]:
 vv=[];ff=[]
 for p,normal in surfaces:
  vs=np.array(p['verts'])
  for face in p['faces']:
   poly=[v.copy() for v in vs[face]];poly=clip_x(poly,x-.037,True)
   if len(poly)<3:continue
   poly=clip_x(poly,x+.037,False)
   if len(poly)<3:continue
   # Remove duplicate plane intersections and zero-area facets.
   cleaned=[]
   for point in poly:
    if not cleaned or np.linalg.norm(point-cleaned[-1])>1e-8:cleaned.append(point)
   if len(cleaned)>1 and np.linalg.norm(cleaned[0]-cleaned[-1])<1e-8:cleaned.pop()
   poly=cleaned
   if len(poly)<3 or sum(np.linalg.norm(np.cross(poly[i]-poly[0],poly[i+1]-poly[0])) for i in range(1,len(poly)-1))<1e-9:continue
   start=len(vv);n=len(poly);vv.extend([(p+normal*.001).tolist() for p in poly]);vv.extend([(p+normal*.007).tolist() for p in poly]);ff.append([start+i for i in reversed(range(n))]);ff.append([start+n+i for i in range(n)])
   for i in range(n):ff.append([start+i,start+(i+1)%n,start+n+(i+1)%n,start+n+i])
 mp.append(mesh('mesh-conformal 6mm webbing ribbon',vv,ff,'dark'))
C['revision_changes']=['Only correct shoulder webbing discontinuity seen in same-camera low-resolution visual gate.','Cloth silhouette vertices unchanged from v02; quads explicitly triangulated for deterministic surface projection.','74mm-wide bands clipped to those actual triangles; 1mm lower-surface offset and 6mm thickness. Layout, bedding, old cargo, materials and daylight unchanged.']
(R/'Config/design_v03.json').write_text(json.dumps(C,indent=2))
print('DESIGN_SPEC_WRITTEN',len(C['modules']),sum(len(r['placements']) for r in C['regions'].values()))
