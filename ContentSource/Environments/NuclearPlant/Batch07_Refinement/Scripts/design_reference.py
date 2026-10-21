"""Design-first dimensional source. NO bpy/Blender import. Run before modeling.
All reference polygons come from dimensioned analytic parts, not a model render.
"""
from pathlib import Path
import json,math,hashlib,datetime,copy
import numpy as np
import matplotlib;matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import Polygon,Rectangle
R=Path(__file__).resolve().parent.parent
if (R/'site_refined.blend').exists():raise RuntimeError('Initial design reference is frozen; use a separate revision for post-model changes')
for p in ['Config','References','QA']: (R/p).mkdir(exist_ok=True)
PALETTE={'concrete':'#a6aaa8','steel':'#303b40','zinc':'#7e8c90','red':'#763b32','yellow':'#cba744','wood':'#786857','tarp':'#66746d','dark':'#19272d','ceramic':'#c3c5bb','white':'#d8d9ce','asphalt':'#424b50'}
M={};cur=[]
def b(n,p,d,mat='steel',rot=0):cur.append({'type':'box','name':n,'p':p,'d':d,'mat':mat,'rz':rot})
def cyl(n,p,r,l,axis='Z',mat='zinc',segments=16):cur.append({'type':'cylinder','name':n,'p':p,'r':r,'l':l,'axis':axis,'mat':mat,'segments':segments})
def mesh(n,verts,faces,mat):cur.append({'type':'mesh','name':n,'verts':verts,'faces':faces,'mat':mat})
def line(n,a,bp,width,mat='steel'):
 cur.append({'type':'beam','name':n,'a':a,'b':bp,'width':width,'mat':mat})
def save(mid,title,desc):
 global cur
 M[mid]={'title':title,'description':desc,'parts':cur,'pivot':'floor centre, front=-Y','bevel_m':.012};cur=[]
# 1: a framed, layered ventilation + service panel. Not a fake opening.
b('shadow backing',(0,.20,3.1),(4,.12,6.2),'dark')
for x in [-1.96,1.96]:b('folded jamb',(x,0,3.1),(.08,.5,6.2),'zinc')
for z in [.05,3.3,6.15]:b('drip edge',(0,-.06,z),(4.1,.62,.10),'steel')
b('lower access leaf',(0,-.04,1.60),(3.74,.10,3.0),'steel')
for x in [-1.73,0,1.73]:b('access seam',(x,-.11,1.6),(.025,.04,2.82),'zinc')
for x in [-1.55,1.55]:b('inspection handle',(x,-.22,1.5),(.07,.10,.42),'zinc')
for z in [.72,.86,1,1.14,1.28,1.42]:b('lower inlet',(0,-.12,z),(2.6,.08,.045),'dark')
for i in range(11):
 z=3.52+i*.225
 # angled blades with thickness; actual wedge mesh
 mesh('weather louvre', [[-1.85,-.31,z],[1.85,-.31,z],[-1.85,.15,z+.14],[1.85,.15,z+.14],[-1.85,-.31,z+.045],[1.85,-.31,z+.045],[-1.85,.15,z+.185],[1.85,.15,z+.185]], [[0,1,3,2],[4,6,7,5],[0,4,5,1],[2,3,7,6],[0,2,6,4],[1,5,7,3]],'zinc')
for x in [-1.94,1.94]:
 for z in [.15,3.2,6.0]:cyl('visible anchor',(x,-.28,z),.04,.025,'Y','dark',8)
b('caution plate',(.95,-.13,2.72),(.5,.035,.24),'yellow')
save('B07_VENT_CASSETTE','Ventilation / inspection cassette','4.10 x 0.62 x 6.20 m; real folded louvers, layered jambs, removable lower leaf; facade-mounted, not a traversable doorway.')
# 2: open pipe rack, not counted as solid cover.
for x in [-2.7,2.7]:
 for y in [-1.2,1.2]:
  b('footplate',(x,y,.08),(.52,.48,.16),'zinc');b('upright',(x,y,1.9),(.16,.16,3.8))
  for dx in [-.17,.17]:cyl('anchor bolt',(x+dx,y,.18),.028,.07,mat='dark',segments=8)
 b('rack crosshead',(x,0,3.72),(.22,2.8,.24))
 for y in [-1.2,1.2]:line('knee brace',(x,y,3.05),(x,0 if y<0 else .5,3.72),.08)
for y,z,r in [(-.62,3.98,.18),(.38,4.12,.23)]:
 cyl('longitudinal process pipe',(0,y,z),r,6,'X')
 for x in [-2.4,0,2.4]:
  cyl('flange',(x,y,z),r+.08,.10,'X','zinc');cyl('red identification collar',(x+.07,y,z),r+.025,.10,'X','red')
  # pipe saddle visible under barrel
  b('saddle',(x,y,z-r-.05),(.25,.48,.1),'steel')
 # elbow: smooth polygon centreline, tangential from horizontal to vertical at +X
 pts=[]
 for i in range(9):
  a=i*math.pi/16;pts.append([2.75+.42*math.sin(a),y,z-.42+.42*math.cos(a)])
 cur.append({'type':'tube','name':'swept return elbow','points':pts,'r':r,'mat':'zinc','segments':12})
 cyl('return drop',(3.17,y,2.63),r,2.14,'Z')
 cyl('service flange',(3.17,y,1.72),r+.08,.12,'Z','red')
for x in [-2,0,2]:b('tray support',(x,1.05,3.2),(.16,.7,.12))
b('cable tray bed',(0,1.07,3.25),(5.8,.45,.08),'zinc')
for y in [.82,1.32]:b('tray lip',(0,y,3.32),(5.8,.04,.2),'zinc')
for x in np.linspace(-2.7,2.7,19):b('tray rung',(float(x),1.07,3.38),(.04,.5,.04),'zinc')
save('B07_PIPE_RACK','Twin process-pipe service rack','6.57 x 2.80 x 4.35 m; flanges, saddle supports, curved returns, anchored columns and secondary cable tray. OPEN equipment, not ballistic cover.')
# 3: asymmetric protective canopy / transformer core (not operational engineering).
b('bund',(0,0,.14),(5.8,4.4,.28),'concrete')
b('solid rear cover',(0,1.95,1.45),(5.8,.25,2.6),'concrete')
b('side cover',(-2.75,.4,1.45),(.3,3.4,2.6),'concrete')
for x in [-2.55,2.55]:
 for y in [-1.8,1.8]:b('canopy post',(x,y,2.35),(.14,.14,4.45))
mesh('sloping canopy',[[-2.9,-2.2,4.25],[2.9,-2.2,4.25],[2.9,2.2,4.8],[-2.9,2.2,4.8],[-2.9,-2.2,4.37],[2.9,-2.2,4.37],[2.9,2.2,4.92],[-2.9,2.2,4.92]],[[0,3,2,1],[4,5,6,7],[0,1,5,4],[1,2,6,5],[2,3,7,6],[3,0,4,7]],'steel')
for x in np.linspace(-2.8,2.8,15):line('roof standing seam',(float(x),-2.2,4.38),(float(x),2.2,4.93),.026,'zinc')
b('transformer footing',(0,0,.4),(2.9,2.1,.28),'steel')
b('oil tank',(0,0,1.55),(2.5,1.65,2.15),'zinc')
for x in [-1.45,1.45]:
 for y in np.linspace(-.68,.68,9):b('cooling fin',(x,float(y),1.5),(.32,.055,1.85),'steel')
for x in [-.72,0,.72]:
 cyl('bushing rod',(x,0,3.05),.075,.8,'Z','dark')
 for z in np.linspace(2.73,3.37,7):cyl('ceramic bell',(x,0,float(z)),.16,.065,'Z','ceramic')
b('inspection panel',(0,-.86,1.4),(.95,.055,.9),'steel');b('warning enamel',(.68,-.88,2.25),(.4,.045,.28),'yellow')
cyl('expansion reservoir',(0,.6,3.05),.28,2.2,'X','zinc')
for x in [-2.45,2.45]:
 b('guard bollard',(x,-1.6,.85),(.16,.16,1.4),'yellow');b('guard black band',(x,-1.6,1.0),(.17,.17,.22),'dark')
save('B07_TRANSFORMER_BAY','Transformer / protective equipment bay','5.80 x 4.40 x 4.95 m; inclined roof, thin metal frame, finned equipment, ceramic bushings and solid rear / side cover. Visual prop, not an electrical design.')
# 4 cargo: layered timber pallet, non-cubic draped cargo and tied bands + smaller crate
for cx,cy,w,d,h in [(-.85,0,2.35,2.75,2.0),(1.35,-.45,1.7,1.8,1.1)]:
 for x in [-w*.38,0,w*.38]:b('pallet runner',(cx+x,cy,.10),(.14,d,.18),'wood')
 for y in np.linspace(-d*.44,d*.44,7):b('pallet slat',(cx,cy+float(y),.25),(w,.19,.11),'wood')
 if h>1.5:
  # drape silhouette with folded upper edges, NOT a primitive cube
  verts=[[-w/2,-d/2,.35],[w/2,-d/2,.35],[w/2,d/2,.35],[-w/2,d/2,.35],[-w*.46,-d*.46,h-.15],[w*.44,-d*.46,h-.24],[w*.45,d*.44,h-.12],[-w*.44,d*.45,h-.2],[-w*.31,-d*.33,h+.14],[w*.31,-d*.33,h+.14],[w*.31,d*.31,h+.14],[-w*.31,d*.31,h+.14]]
  verts=[[x+cx,y+cy,z] for x,y,z in verts]
  mesh('draped machine cover',verts,[[0,1,5,4],[1,2,6,5],[2,3,7,6],[3,0,4,7],[4,5,9,8],[5,6,10,9],[6,7,11,10],[7,4,8,11],[8,9,10,11]],'tarp')
  for x in [cx-.65,cx+.65]:
   ribbon=[(cy-d/2-.016,.36),(cy-d*.46-.016,h-.18),(cy-d*.33,h+.16),(cy+d*.31,h+.16),(cy+d*.45+.016,h-.16),(cy+d/2+.016,.36)]
   vv=[]
   for yy,zz in ribbon:vv.extend([[x-.035,yy,zz],[x+.035,yy,zz]])
   mesh('continuous tension webbing',vv,[[2*j,2*j+1,2*j+3,2*j+2] for j in range(5)],'dark')
   b('metal buckle',(x,cy-d*.485-.024,.9),(.12,.035,.16),'zinc')
 else:
  b('timber shipping crate',(cx,cy,.8),(w-.10,d-.10,.92),'wood')
  for x in [cx-w*.38,cx+w*.38]:b('crate binding',(x,cy-d/2,.82),(.09,.05,.95),'steel')
  for z in [.42,1.18]:b('crate cleat',(cx,cy-d/2-.025,z),(w,.07,.12),'wood')
  b('shipping label',(cx,cy-d/2-.07,.86),(.44,.025,.3),'white')
save('B07_CARGO_SET','Bound machine cargo / timber pallet set','4.20 x 2.75 x 2.16 m; pallet air gaps, folded tarp silhouette, straps, buckles and braced smaller crate. Low cargo only; not claimed bulletproof.')
# 5 independent short open canopy breaks repeated full shed roof footprint.
for x in [-4.4,4.4]:
 for y in [-2.7,2.7]:
  b('steel column',(x,y,1.95),(.18,.18,3.9));b('base plate',(x,y,.08),(.42,.42,.16),'zinc')
  line('knee brace',(x,y,3),(x*.78,y,3.88),.10)
 for z in [3.78,4.20]:line('roof transverse chord',(x,-3,z),(x,3,z+.55),.12)
 for y in [-2,0,2]:line('truss web',(x,y,3.8+(y+3)*.55/6),(x,y+.7,4.2+(y+3.7)*.55/6),.08)
mesh('lean roof',[[-4.8,-3.2,4.18],[4.8,-3.2,4.18],[4.8,3.2,4.77],[-4.8,3.2,4.77],[-4.8,-3.2,4.27],[4.8,-3.2,4.27],[4.8,3.2,4.86],[-4.8,3.2,4.86]],[[0,3,2,1],[4,5,6,7],[0,1,5,4],[1,2,6,5],[2,3,7,6],[3,0,4,7]],'steel')
for x in np.linspace(-4.7,4.7,24):line('standing roof seam',(float(x),-3.2,4.28),(float(x),3.2,4.87),.025,'zinc')
b('red fascia',(0,-3.22,4.15),(9.6,.10,.26),'red')
b('rear solid waist screen',(0,2.92,1.2),(9.2,.22,2.4),'concrete')
for x in [-4.45,4.45]:b('side solid cover',(x,1.6,1.2),(.22,2.6,2.4),'concrete')
save('B07_LOGISTICS_CANOPY','Short logistics receiving canopy','9.60 x 6.44 x 4.90 m; open front, thin sloped seam roof, exposed truss / knee braces, 2.40m solid back/side cover.')
# analytic mesh used identically by reference drawing and later Blender builder
code=r'''
import math,numpy as np
CUBE_FACES=[[0,3,2,1],[4,5,6,7],[0,1,5,4],[1,2,6,5],[2,3,7,6],[3,0,4,7]]
def meshpart(p):
 t=p['type']
 if t=='mesh':return np.array(p['verts'],float),p['faces']
 if t=='box':
  x,y,z=p['d'];v=np.array([[-x,-y,-z],[x,-y,-z],[x,y,-z],[-x,y,-z],[-x,-y,z],[x,-y,z],[x,y,z],[-x,y,z]],float)/2
  a=math.radians(p.get('rz',0));rot=np.array([[math.cos(a),-math.sin(a),0],[math.sin(a),math.cos(a),0],[0,0,1]]);return v@rot.T+np.array(p['p']),CUBE_FACES
 if t=='beam':
  a,b=np.array(p['a']),np.array(p['b']);z=b-a;length=np.linalg.norm(z);z=z/length;x=np.cross(z,[0,1,0]);
  if np.linalg.norm(x)<1e-6:x=np.cross(z,[1,0,0])
  x=x/np.linalg.norm(x);y=np.cross(z,x);q={'type':'box','d':[p['width'],p['width'],length],'p':[0,0,0]};v,f=meshpart(q);return v@np.array([x,y,z])+(a+b)/2,f
 if t=='cylinder':
  n=p.get('segments',16);r=p['r'];l=p['l'];v=[]
  for z in [-l/2,l/2]:
   for i in range(n):v.append([r*math.cos(i*2*math.pi/n),r*math.sin(i*2*math.pi/n),z])
  v=np.array(v)
  if p.get('axis','Z')=='X':v=v[:,[2,0,1]]
  if p.get('axis','Z')=='Y':v=v[:,[0,2,1]]
  f=[list(range(n-1,-1,-1)),list(range(n,2*n))]+[[i,(i+1)%n,(i+1)%n+n,i+n] for i in range(n)]
  return v+np.array(p['p']),f
 if t=='tube':
  pts=np.array(p['points']);n=p.get('segments',12);v=[]
  for i,c in enumerate(pts):
   tangent=pts[min(i+1,len(pts)-1)]-pts[max(0,i-1)];tangent/=np.linalg.norm(tangent);u=np.cross(tangent,[0,1,0]);u/=np.linalg.norm(u);w=np.cross(tangent,u)
   for k in range(n):v.append(c+p['r']*(math.cos(k*2*math.pi/n)*u+math.sin(k*2*math.pi/n)*w))
  f=[[i*n+k,i*n+(k+1)%n,(i+1)*n+(k+1)%n,(i+1)*n+k] for i in range(len(pts)-1) for k in range(n)]
  return np.array(v),f
 raise ValueError(t)
def transform(v,pos,rz):
 a=math.radians(rz);rot=np.array([[math.cos(a),-math.sin(a),0],[math.sin(a),math.cos(a),0],[0,0,1]])
 return v@rot.T+np.array(pos)
'''
(R/'Scripts'/'analytic_geometry.py').write_text(code)
exec(code)
# bounded treatment composition; all placements are in retained hardstands.
regions={k:{'placements':[],'custom_parts':[],'description':d} for k,d in [('core_skin','Original hall envelope / portals unchanged; mounted facade bays and upper ribs only.'),('east_pump_yards','Six former identical utility sheds repurposed as process / electrical yards inside their old hardstands.'),('southwest_logistics','Six former identical sheds replaced by short receiving canopy / cargo combinations; 2.4m solid cover retained.') ]}
def place(region,mid,pos,rot=0):regions[region]['placements'].append({'module':mid,'position':pos,'rz':rot})
# Front lower cassettes deliberately leave +/-4m main opening untouched.
for x in [-14,-8,8,14]:place('core_skin','B07_VENT_CASSETTE',[x,-18.55,3.0])
# East upper wall, above service wing and well away from ground routes.
for y in [-12,-4,4,12]:place('core_skin','B07_VENT_CASSETTE',[20.55,y,10],90)
# Upper frontal architectural fins / cornice: drawn and frozen as region parts first.
cur=[]
for x in [-18,-12,-6,6,12,18]:b('facade vertical fin',(x,-18.45,13.4),(.18,.62,12.2),'steel')
for z in [10.3,18.9]:b('facade horizontal shadow rail',(0,-18.49,z),(39.6,.36,.18),'steel')
for y in [-16,-8,0,8,16]:b('east vertical fin',(20.46,y,13.7),(.62,.18,11.6),'steel')
b('east upper shadow rail',(20.5,0,18.9),(.3,35.8,.18),'steel')
regions['core_skin']['custom_parts']=cur;cur=[]
removals=[]
# Front row along south-west retains its original open route rectangles.
for i,(x,y) in enumerate([(-20,-43),(-20,-56),(-38,-43),(-38,-56),(-56,-43),(-56,-56)]):
 removals.append([x,y]);r='southwest_logistics'
 if i in [0,3,4]:
  place(r,'B07_LOGISTICS_CANOPY',[x-1.1,y+.35,0],0)
  place(r,'B07_CARGO_SET',[x-1.8,y+.6,0],0 if i%2==0 else 180)
  place(r,'B07_CARGO_SET',[x+4.0,y+1.4,0],90)
 else:
  place(r,'B07_CARGO_SET',[x-3.8,y+.9,0],-5)
  place(r,'B07_CARGO_SET',[x+1.5,y+1.1,0],180)
  # This bay stays cargo-only; no equipment overlap.
 # Solid old footprint back screen + one short side; no cover regression to thin pipes.
 cur=[];b('retained cover back',(x,y+3.875,1.2),(14,.25,2.4),'concrete');b('retained cover left',(x-6.875,y,1.2),(.25,8,2.4),'concrete');b('retained cover right',(x+6.875,y,1.2),(.25,8,2.4),'concrete')
 regions[r]['custom_parts']+=cur;cur=[]
for i,(x,y) in enumerate([(34,42),(34,55),(52,42),(52,55),(56,-18),(56,-32)]):
 removals.append([x,y]);r='east_pump_yards'
 if i in [0,3,4]:
  place(r,'B07_TRANSFORMER_BAY',[x-3.0,y+.6,0]);place(r,'B07_PIPE_RACK',[x+2.5,y,0],90)
 else:
  place(r,'B07_PIPE_RACK',[x-3.0,y-.15,0],90);place(r,'B07_PIPE_RACK',[x+3.0,y-.15,0],90)
 cur=[];b('retained cover back',(x,y+3.875,1.2),(14,.25,2.4),'concrete');b('retained cover left',(x-6.875,y,1.2),(.25,8,2.4),'concrete');b('retained cover right',(x+6.875,y,1.2),(.25,8,2.4),'concrete')
 regions[r]['custom_parts']+=cur;cur=[]
# Thin flush drainage and pad joints are designed geometry, not post-model decoration.
for x,y in removals:
 r='southwest_logistics' if x<0 else 'east_pump_yards';cur=[]
 b('flush drain channel',(x,y-3.45,.009),(11,.36,.018),'dark')
 for xx in np.linspace(x-5.4,x+5.4,46):b('flush grate bars',(float(xx),y-3.45,.022),(.045,.34,.018),'zinc')
 for xx in [-3.5,0,3.5]:b('pad expansion joint',(x+xx,y,.008),(.025,7.6,.012),'dark')
 for xx in [-5.5,-4.8,4.8,5.5]:b('faded safety pad mark',(x+xx,y-3.8,.014),(.42,.13,.014),'yellow')
 regions[r]['custom_parts']+=cur;cur=[]
config={'schema':'batch07-design-first-v1','seed':7021,'units':'metres','source':'../Batch06_Expansion/site_expansion.blend','modules':M,'regions':regions,'replace_shelter_centers':removals,'preserve':'All original hall structure, doors, stairs, bridge and explicit proxies. Existing solid route screens untouched. New props remain inside existing hardstands.','style':'Restrained cast concrete / graphite steel / oxide red / small ochre safety accents. AZ3 industrial mood only, not a replica.','material_palette':PALETTE,'render':{'width':1600,'height':1000,'samples':48},'cameras':{'site_overview':{'position':[145,-170,135],'target':[0,0,0],'lens':39},'core_entry':{'position':[0,-59,1.65],'target':[0,-12,8],'lens':26},'pump_eye':{'position':[45,-25,1.65],'target':[54,-15,3.0],'lens':25},'logistics_eye':{'position':[-10,-50,1.65],'target':[-41,-43,2.4],'lens':27}}}
(R/'Config'/'design.json').write_text(json.dumps(config,indent=2))
# reference triangles are source mesh projections without render lighting or perspective.
def solids(parts,pos=[0,0,0],rz=0):return [(transform(meshpart(p)[0],pos,rz),meshpart(p)[1],PALETTE[p['mat']]) for p in parts]
def reference(name,ss,title,subtitle,bounds_ss=None):
 allv=np.concatenate([v for v,f,c in (bounds_ss if bounds_ss is not None else ss)]);lo=allv.min(0);hi=allv.max(0);span=max(hi-lo)+1.2;fig,axs=plt.subplots(1,3,figsize=(18,6.2),dpi=120);fig.patch.set_facecolor('#f3f2ec')
 for ax,(label,axes,depth,sign) in zip(axs,[('FRONT  -Y',(0,2),1,1),('RIGHT  +X',(1,2),0,-1),('TOP  +Z',(0,1),2,-1)]):
  ax.set_facecolor('#f3f2ec');polys=[]
  for v,faces,c in ss:
   for f in faces:
    vv=v[f];polys.append((float(vv[:,depth].mean())*sign,vv[:,axes],c))
  for _,vv,c in sorted(polys,key=lambda p:p[0],reverse=True):ax.add_patch(Polygon(vv,closed=True,facecolor=c,edgecolor='#26343b',linewidth=.25))
  cc=(lo+hi)/2;ax.set_xlim(cc[axes[0]]-span/2,cc[axes[0]]+span/2);ax.set_ylim(cc[axes[1]]-span/2,cc[axes[1]]+span/2);ax.set_aspect('equal',adjustable='box');ax.grid(alpha=.15);ax.set_title(label,fontsize=11);ax.set_xlabel('metres');ax.set_ylabel('metres')
 fig.suptitle(title+'\n'+subtitle,fontsize=13);fig.text(.02,.01,'DESIGN INPUT • Same scale in all three views • Orthographic analytic projection • NOT a model render',fontsize=10);fig.tight_layout(rect=(0,.05,1,.88))
 for ext in ['svg','png']:fig.savefig(R/'References'/f'{name}.{ext}')
 plt.close(fig)
for mid,m in M.items():reference(mid,solids(m['parts']),mid+' / '+m['title'],m['description'])
for mid in ['B07_TRANSFORMER_BAY','B07_LOGISTICS_CANOPY','B07_CARGO_SET']:
 m=M[mid];hide=['sloping canopy','roof standing seam','lean roof','standing roof seam','red fascia'] if mid!='B07_CARGO_SET' else ['draped machine cover','continuous tension webbing','metal buckle']
 shown=[p for p in m['parts'] if p['name'] not in hide]
 reference(mid+'_structure',solids(shown),mid+' / STRUCTURE STUDY - ROOF OR TARP HIDDEN','Supplementary hidden-cover construction view; same scale as the standard sheet. NOT an ordinary exterior top view.',bounds_ss=solids(m['parts']))
for name,r in regions.items():
 ss=solids(r['custom_parts'])
 for p in r['placements']:ss+=solids(M[p['module']]['parts'],p['position'],p['rz'])
 if name=='core_skin':
  p={'type':'box','p':[0,0,10],'d':[40,36,20],'mat':'concrete'};ss=solids([p])+ss
 reference(name,ss,'REGION / '+name,r['description'])
# Separate layout overview explicitly shows retained context and protected routes.
base=json.loads((R.parent/'Batch06_Expansion'/'layout.json').read_text());fig,ax=plt.subplots(figsize=(13,12),dpi=130);fig.patch.set_facecolor('#f3f2ec');ax.set_facecolor('#e5e5dc')
for nm,bounds in [('CORE',[-20,20,-18,18])]+[(k,v['bounds']) for k,v in base['regions'].items()]:
 x0,x1,y0,y1=bounds;ax.add_patch(Rectangle((x0,y0),x1-x0,y1-y0,facecolor='#bcbfba',edgecolor='#758079'));ax.text((x0+x1)/2,(y0+y1)/2,nm,ha='center',color='#434e53')
for p in base['infill']['service_shelters']:
 x,y,z=p['center'];ax.add_patch(Rectangle((x-7,y-4),14,8,fill=False,edgecolor='#7d8987',linestyle='--'))
for name,r in regions.items():
 for p in r['placements']:
  vv=np.concatenate([v for v,f,c in solids(M[p['module']]['parts'],p['position'],p['rz'])]);a=vv.min(0);bnd=vv.max(0);ax.add_patch(Rectangle(a[:2],bnd[0]-a[0],bnd[1]-a[1],facecolor={'core_skin':'#536775','east_pump_yards':'#67847c','southwest_logistics':'#9d8061'}[name],edgecolor='#33434b',alpha=.8))
for name,p in base['pedestrian_routes'].items():
 a=np.array(p);ax.plot(a[:,0],a[:,1],color='#dba82a',lw=3,alpha=.8)
ax.set_xlim(-81,81);ax.set_ylim(-71,71);ax.set_aspect('equal');ax.grid(alpha=.15);ax.set_title('BATCH 07 / PRE-MODEL SITE ASSEMBLY PLAN\nBlue: core skin | Green: process / electrical | Brown: logistics\nGold: existing protected walking routes | dashed: original shelter footprint');ax.set_xlabel('X metres');ax.set_ylabel('Y metres');fig.tight_layout()
for ext in ['svg','png']:fig.savefig(R/'References'/f'site_layout.{ext}')
plt.close(fig)
# Immutable revision record creates the reference-before-model chain.
files=[R/'Config'/'design.json',R/'Scripts'/'analytic_geometry.py',R/'Scripts'/'design_reference.py']+sorted((R/'References').glob('*'))
record={'stage':'PRE_MODEL_REFERENCE_FREEZE','utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'source_sha256':hashlib.sha256((R.parent/'Batch06_Expansion'/'site_expansion.blend').read_bytes()).hexdigest(),'model_exists_at_freeze':(R/'site_refined.blend').exists(),'inputs':{str(f.relative_to(R)):hashlib.sha256(f.read_bytes()).hexdigest() for f in files},'projection':'linear coordinate projection, no perspective; same metric scale in all three views on every sheet','note':'Reference design generated without Blender/bpy. Modeling script must verify hashes before building.'}
if record['model_exists_at_freeze']:raise RuntimeError('Refuse to overwrite initial freeze after modeling; create revision-specific files instead')
(R/'QA'/'reference_freeze.json').write_text(json.dumps(record,indent=2));print('REFERENCE_FREEZE',record['utc'],len(files))
