"""Pre-model v02 cover repair; initial freeze and initial spec remain immutable."""
from pathlib import Path
import json,math,hashlib,datetime,sys,copy
import numpy as np
import matplotlib;matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import Polygon
R=Path(__file__).resolve().parent.parent;sys.path.insert(0,str(R/'Scripts'));from analytic_geometry import meshpart,transform
C=json.loads((R/'Config/design.json').read_text());M=C['modules'];P=C['material_palette'];out=R/'References/v02';out.mkdir(exist_ok=True)

# Engineering-visual corrections discovered by independent geometry review, BEFORE v02 modeling.
for p in M['B07_LOGISTICS_CANOPY']['parts']:
 if p['name']=='steel column':
  y=p['p'][1];top=3.78+(y+3)*.55/6+.02;p['p'][2]=top/2;p['d'][2]=top
 if p['name']=='knee brace':
  x,y,z=p['a'];beam=3.78+(y+3)*.55/6;p['a']=[x,y,beam-.80];p['b']=[x*.78,y,beam]
for y in [-2.7,2.7]:
 z=3.78+(y+3)*.55/6;M['B07_LOGISTICS_CANOPY']['parts'].append({'type':'box','name':'continuous eave bearer','p':[0,y,z],'d':[9.1,.18,.18],'mat':'steel','rz':0})
for y in [-2,0,2]:
 z=4.18+(y+3.2)*.59/6.4-.08;M['B07_LOGISTICS_CANOPY']['parts'].append({'type':'box','name':'roof longitudinal purlin','p':[0,y,z],'d':[9.3,.12,.16],'mat':'zinc','rz':0})
for p in M['B07_TRANSFORMER_BAY']['parts']:
 if p['name']=='canopy post':
  y=p['p'][1];roof=4.25+(y+2.2)*.55/4.4;top=roof-.1;p['p'][2]=(.28+top)/2;p['d'][2]=top-.28
for y in [-1.8,1.8]:
 roof=4.25+(y+2.2)*.55/4.4;M['B07_TRANSFORMER_BAY']['parts'].append({'type':'box','name':'roof eave crossbearer','p':[0,y,roof-.1],'d':[5.3,.18,.2],'mat':'steel','rz':0})
for x in [-2.55,2.55]:M['B07_TRANSFORMER_BAY']['parts'].append({'type':'beam','name':'sloping roof edge support','a':[x,-1.8,4.2],'b':[x,1.8,4.65],'width':.14,'mat':'steel'})
for x in [-.7,.7]:M['B07_TRANSFORMER_BAY']['parts'].append({'type':'box','name':'reservoir support saddle','p':[x,.6,2.73],'d':[.15,.3,.25],'mat':'steel','rz':0})
for x in [-1.8,1.8]:
 for z in [.35,3.25,5.9]:M['B07_VENT_CASSETTE']['parts'].append({'type':'box','name':'rear wall mounting cleat','p':[x,.32,z],'d':[.16,.16,.3],'mat':'steel','rz':0})

cur=[]
def b(n,p,d,mat='steel'):cur.append({'type':'box','name':n,'p':p,'d':d,'mat':mat,'rz':0})
b('solid sheet',(0,0,1.05),(4,.12,2.1),'steel')
for x in [-1.94,1.94]:
 b('structural end post',(x,.025,1.05),(.12,.25,2.1),'zinc');b('anchor shoe',(x,0,.06),(.28,.38,.12),'steel')
for z in [.08,1.04,2.03]:b('sheet rail',(0,-.09,z),(4,.12,.09),'zinc')
for x in np.linspace(-1.65,1.65,12):b('sheet stiffening rib',(float(x),-.09,1.04),(.045,.10,1.85),'steel')
M['B07_SOLID_SCREEN']={'title':'Solid upper industrial screen / cut-to-width','description':'4.00m stock width, trim-scaled to3.50m on rear bays; solid sheet + rails + posts + anchor shoes. Mounted over retained 2.4m concrete to restore 4.5m original wall envelope.','parts':cur,'pivot':'lower centre, front=-Y','bevel_m':.006};cur=[]
b('solid cabinet carcass',(0,0,1.51),(2.82,2.22,3.02),'steel');b('raised plinth',(0,0,.10),(2.94,2.34,.2),'zinc')
for x in [-.69,.69]:
 b('inspection door',(x,-1.145,1.57),(1.32,.07,2.65),'zinc');b('recessed lever',(x+.39,-1.205,1.45),(.08,.07,.32),'dark')
for z in np.linspace(.45,1.1,7):b('intake slot',(0,-1.19,float(z)),(2.2,.045,.035),'dark')
b('weather cap',(0,0,3.065),(2.94,2.38,.09),'steel');b('identity band',(0,-1.19,2.7),(2.35,.045,.14),'red')
M['B07_SERVICE_CABINET']={'title':'Solid process-service cabinet','description':'Based on existing B06 service bank physical envelope, with real split doors, cap, plinth, handles and intake slots. Solid mesh silhouette; no bullet resistance claim.','parts':cur,'pivot':'floor centre, front=-Y','bevel_m':.006};cur=[]
def place(r,mid,pos,rz=0,scale=None):
 q={'module':mid,'position':pos,'rz':rz}
 if scale:q['scale']=scale
 C['regions'][r]['placements'].append(q)
for i,(x,y) in enumerate(C['replace_shelter_centers']):
 r='southwest_logistics' if x<0 else 'east_pump_yards'
 # Same solid-wall path as baseline, 4.50m total height. Back stock panels trimmed 4->3.5.
 for xx in [-5.25,-1.75,1.75,5.25]:place(r,'B07_SOLID_SCREEN',[x+xx,y+3.875,2.4],0,[.875,1,1])
 for xx in [-6.875,6.875]:
  for yy in [-2,2]:place(r,'B07_SOLID_SCREEN',[x+xx,y+yy,2.4],90)
 # Restore old bank shielding in open-cargo and open-pipe yards, moving low cargo / racks forward inside the original pad.
 if i in [1,2,5,7,8,11]:
  pp=C['regions'][r]['placements']
  locals_=[p for p in pp if p['module'] in ['B07_CARGO_SET','B07_PIPE_RACK'] and abs(p['position'][0]-x)<6 and abs(p['position'][1]-y)<4]
  for j,p in enumerate(locals_):
   if p['module']=='B07_CARGO_SET':p['position']=[x+(-3.5 if j%2==0 else 3.0),y-1.55,0];p['rz']=0
   else:p['position']=[x+(-3.5 if j%2==0 else 3.0),y-2.3,0];p['rz']=0
  for xx in [-3.5,0,3.5]:place(r,'B07_SERVICE_CABINET',[x+xx,y+1.5,0])
# Keep exact unrounded concrete corner shielding, original box envelope.
# Move outboard pallet sets clear of the short canopy's side wall, within old yard screen footprint.
for p in C['regions']['southwest_logistics']['placements']:
 if p['module']=='B07_CARGO_SET' and p['rz']==90:
  for x,y in C['replace_shelter_centers']:
   if x<0 and abs(p['position'][0]-x-4)<.01 and abs(p['position'][1]-y-1.4)<.01:p['position']=[x+5.2,y+.6,0];break
# Avoid the entire retained sliding-door travel / parked-leaf envelope, not just the central opening.
for p in C['regions']['core_skin']['placements']:
 if p['module']=='B07_VENT_CASSETTE' and p['position'][1]<-18:
  x=p['position'][0];p['position'][0]=math.copysign(10.75 if abs(x)<10 else 16.75,x)
for p in C['regions']['core_skin']['custom_parts']:
 if p['name']=='facade vertical fin':
  x=p['p'][0];p['p'][0]=math.copysign({6:5.5,12:13.8,18:19.4}[abs(x)],x)
C['protected_sliding_door_envelope']={'min':[-8.6,-19.1,0],'max':[8.6,-18.25,7.2],'basis':'Conservative static union of closed aperture and both open parked leaves (outer original x=8.35) plus clearance. Not animated engine validation.'}
C['revision']='v02';C['revision_purpose']='Restore avoidable ground and rising-ray occlusion losses without extending yard footprints or routes.'
C['cameras']['pump_eye']={'position':[56,-25.3,1.65],'target':[56,-17,2.4],'lens':25}
C['cameras']['logistics_eye']={'position':[-38,-63,1.65],'target':[-38,-48,2.4],'lens':27}
(R/'Config/design_v02.json').write_text(json.dumps(C,indent=2))
def ss(parts,pos=[0,0,0],rz=0,scale=[1,1,1]):
 return [(transform(meshpart(p)[0]*np.array(scale),pos,rz),meshpart(p)[1],P[p['mat']]) for p in parts]
def draw(name,solids,title,bounds=None):
 allv=np.concatenate([v for v,f,c in (bounds or solids)]);lo=allv.min(0);hi=allv.max(0);span=max(hi-lo)+1.2;fig,axs=plt.subplots(1,3,figsize=(18,6.2),dpi=120);fig.patch.set_facecolor('#f3f2ec')
 for ax,(label,axes,depth,sign) in zip(axs,[('FRONT -Y',(0,2),1,1),('RIGHT +X',(1,2),0,-1),('TOP +Z',(0,1),2,-1)]):
  pol=[]
  for v,faces,c in solids:
   for f in faces:vv=v[f];pol.append((float(vv[:,depth].mean())*sign,vv[:,axes],c))
  for _,v,c in sorted(pol,key=lambda p:p[0],reverse=True):ax.add_patch(Polygon(v,closed=True,facecolor=c,edgecolor='#29353b',linewidth=.25))
  cc=(lo+hi)/2;ax.set_xlim(cc[axes[0]]-span/2,cc[axes[0]]+span/2);ax.set_ylim(cc[axes[1]]-span/2,cc[axes[1]]+span/2);ax.set_aspect('equal');ax.set_facecolor('#f3f2ec');ax.grid(alpha=.15);ax.set_title(label);ax.set_xlabel('metres')
 fig.suptitle(title,fontsize=12);fig.text(.02,.012,'V02 PRE-MODEL DESIGN / same metric scale, no perspective / not a model render',fontsize=10);fig.tight_layout(rect=(0,.05,1,.88))
 for ext in ['svg','png']:fig.savefig(out/(name+'.'+ext))
 plt.close(fig)
for mid,m in M.items():
 sol=ss(m['parts']);v=np.concatenate([v for v,f,c in sol]);dims=v.max(0)-v.min(0)
 draw(mid,sol,mid+' / actual analytic envelope '+ ' x '.join(f'{n:.4f}' for n in dims)+' m\n'+m['title'])
for mid in ['B07_TRANSFORMER_BAY','B07_LOGISTICS_CANOPY','B07_CARGO_SET']:
 m=M[mid];hide=['sloping canopy','roof standing seam','lean roof','standing roof seam','red fascia'] if mid!='B07_CARGO_SET' else ['draped machine cover','continuous tension webbing','metal buckle']
 draw(mid+'_structure',ss([p for p in m['parts'] if p['name'] not in hide]),mid+' / STRUCTURE - ROOF OR TARP HIDDEN\nSame scale as exterior sheet. Structural joints corrected before v02 build.',bounds=ss(m['parts']))
for rn,r in C['regions'].items():
 sol=ss(r['custom_parts'])
 for p in r['placements']:sol+=ss(M[p['module']]['parts'],p['position'],p['rz'],p.get('scale',[1,1,1]))
 draw(rn,sol,'V02 REGION / '+rn+'\nRestore 4.5m side/rear shielding; functional interior variation preserved')
# Focused single-yard plan exposes devices without the upper screen projection hiding them.
for label,x,y in [('pump_yard_detail',56,-32),('cargo_yard_detail',-20,-56)]:
 rn='east_pump_yards' if x>0 else 'southwest_logistics';r=C['regions'][rn];sol=[]
 for p in r['placements']:
  if abs(p['position'][0]-x)<7.1 and abs(p['position'][1]-y)<4.1 and p['module']!='B07_SOLID_SCREEN':sol+=ss(M[p['module']]['parts'],p['position'],p['rz'],p.get('scale',[1,1,1]))
 draw(label,sol,'V02 ASSEMBLY DETAIL / '+label+'\nUpper perimeter screens intentionally hidden to show bank / cargo / rack arrangement')
# Top-level site assembly overview for the revised instance locations.
from matplotlib.patches import Rectangle
L=json.loads((R.parent/'Batch06_Expansion/layout.json').read_text());fig,ax=plt.subplots(figsize=(12,11),dpi=120);ax.set_facecolor('#ebeae4')
for nm,b in [('core',[-20,20,-18,18])]+[(k,v['bounds']) for k,v in L['regions'].items()]:
 x0,x1,y0,y1=b;ax.add_patch(Rectangle((x0,y0),x1-x0,y1-y0,facecolor='#c9ccc6',edgecolor='#777f79'));ax.text((x0+x1)/2,(y0+y1)/2,nm,ha='center')
for rn,r in C['regions'].items():
 for p in r['placements']:
  vs=np.concatenate([v for v,f,c in ss(M[p['module']]['parts'],p['position'],p['rz'],p.get('scale',[1,1,1]))]);lo=vs.min(0);hi=vs.max(0);ax.add_patch(Rectangle(lo[:2],hi[0]-lo[0],hi[1]-lo[1],facecolor={'core_skin':'#586f7c','east_pump_yards':'#69887c','southwest_logistics':'#9a8065'}[rn],edgecolor='#34414a',alpha=.7))
for name,poly in L['pedestrian_routes'].items():
 a=np.array(poly);ax.plot(a[:,0],a[:,1],color='#dab143',lw=2.5)
ax.set_xlim(-81,81);ax.set_ylim(-71,71);ax.set_aspect('equal');ax.grid(alpha=.15);ax.set_title('V02 / PRE-MODEL SITE ASSEMBLY PLAN\nGold: unchanged protected routes / 4.5m solid screening retained inside former yards');fig.tight_layout()
for ext in ['svg','png']:fig.savefig(out/('site_layout.'+ext))
plt.close(fig)
files=[R/'Config/design_v02.json',R/'Scripts/design_revision_v02.py']+sorted(out.glob('*'))
rec={'stage':'V02_REFERENCE_BEFORE_REBUILD','utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'base_initial_freeze_sha256':hashlib.sha256((R/'QA/reference_freeze.json').read_bytes()).hexdigest(),'previous_scene_sha256':hashlib.sha256((R/'site_refined.blend').read_bytes()).hexdigest(),'inputs':{str(p.relative_to(R)):hashlib.sha256(p.read_bytes()).hexdigest() for p in files},'purpose':C['revision_purpose']}
(R/'QA/reference_freeze_v02.json').write_text(json.dumps(rec,indent=2));print('V02_FROZEN',rec['utc'],len(files))
