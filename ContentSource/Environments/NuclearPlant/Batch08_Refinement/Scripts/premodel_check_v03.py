import json,pathlib,sys,math
import numpy as np
R=pathlib.Path(__file__).resolve().parent.parent;sys.path.insert(0,str(R/'Scripts'))
from analytic_geometry import meshpart,transform
C=json.loads((R/'Config/design_v03.json').read_text());L=json.loads((R.parent/'Batch06_Expansion/layout.json').read_text())
mins={};maxs={}
for m,v in C['modules'].items():
 vv=np.concatenate([meshpart(p)[0] for p in v['parts']]);assert np.isfinite(vv).all();mins[m]=vv.min(0);maxs[m]=vv.max(0)
checks=[];issues=[];contacts=[]
for rn,r in C['regions'].items():
 for i,p in enumerate(r['placements']):
  vv=np.concatenate([meshpart(q)[0] for q in C['modules'][p['module']]['parts']]);vv=transform(vv*np.array(p.get('scale',[1,1,1])),p['position'],p['rz']);lo=vv.min(0);hi=vv.max(0)
  if p['module']=='B08_SERVICE_EDGE_FLUSH':assert hi[2]<=.03
  # Narrow-phase route segment point samples, AABB conservative for these axis-aligned instances.
  if hi[2]>.06:
   for route,poly in L['pedestrian_routes'].items():
    if route=='upper_link':continue
    for aa,bb in zip(poly[:-1],poly[1:]):
     aa=np.array(aa);bb=np.array(bb);d=bb-aa;steps=max(1,int(np.linalg.norm(d)/.1));n=np.array([-d[1],d[0]])/np.linalg.norm(d)
     for t in np.linspace(0,1,steps+1):
      pp=aa+t*d
      for off in [-1,0,1]:
       qq=pp+n*off
       if all(qq>=lo[:2]-1e-5) and all(qq<=hi[:2]+1e-5):issues.append({'region':rn,'index':i,'module':p['module'],'route':route,'sample':qq.tolist()})
  if p['module']=='B08_WALL_TERMINAL':
   face=transform(np.array([[0,.16,1]]),p['position'],p['rz'])[0]
   tag=p['tag'];target={'pump_hall_wall_contact':46,'transformer_external_wall_contact':49,'transformer_internal_wall_contact':49.25,'maintenance_wall_contact':-16,'receiving_external_wall_contact':-39,'receiving_internal_wall_contact':-52.84 if p['position'][1]<-50 else -39.84}[tag]
   axis=0 if rn=='east_service_link' else 1;gap=abs(face[axis]-target);assert gap<1e-5,(tag,gap)
   contacts.append({'index':i,'region':rn,'tag':tag,'back_contact_point':face.tolist(),'target_axis':axis,'target_plane':target,'analytic_gap_m':gap,'backplate_max_z_m':float(hi[2])})
  checks.append({'region':rn,'index':i,'module':p['module'],'min':lo.tolist(),'max':hi.tolist()})
report={'stage':'PRE_MODEL_ANALYTIC_DESIGN_CHECK','route_width_m':2,'height_filter_m':.06,'route_issues':issues,'wall_contacts':contacts,'placements':checks,'module_bounds':{m:{'min':mins[m].tolist(),'max':maxs[m].tolist()} for m in mins},'limitations':'AABB and route samples on proposed axis-aligned instances; later evaluated-mesh QA remains required. Flush surfaces below 0.03m not a capsule traversal test.'}
(R/'QA/premodel_design_check_v03.json').write_text(json.dumps(report,indent=2));print('PREMODEL CHECK',len(issues),'route issues',len(contacts),'wall contacts')
assert not issues
