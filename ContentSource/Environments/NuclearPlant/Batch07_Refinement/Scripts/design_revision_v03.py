"""Narrow pre-model repair: three receiving-bay central cabinets, no new module types."""
from pathlib import Path
import json,hashlib,datetime,sys,math,ast
import numpy as np
import matplotlib;matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import Polygon,Rectangle
R=Path(__file__).resolve().parent.parent;sys.path.insert(0,str(R/'Scripts'));from analytic_geometry import meshpart,transform
C=json.loads((R/'Config/design_v02.json').read_text());M=C['modules'];P=C['material_palette'];out=R/'References/v03';out.mkdir(exist_ok=True)
# Reuse the frozen v02 analytic orthographic drawing functions, not Blender-generated imagery.
tree=ast.parse((R/'Scripts/design_revision_v02.py').read_text());nodes=[n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name in ['ss','draw']]
for node in ast.walk(ast.Module(body=nodes,type_ignores=[])):
 if isinstance(node,ast.Constant) and isinstance(node.value,str):node.value=node.value.replace('V02 PRE-MODEL DESIGN','V03 PRE-MODEL DESIGN')
exec(compile(ast.Module(body=nodes,type_ignores=[]),'frozen_v02_drawing_functions','exec'))
r=C['regions']['southwest_logistics'];changes=[]
for x,y in [(-20,-43),(-38,-56),(-56,-43)]:
 for p in r['placements']:
  if p['module']=='B07_CARGO_SET' and abs(p['position'][0]-(x-1.8))<.001 and abs(p['position'][1]-(y+.6))<.001:
   old=p['position'][:];p['position'][1]=y-1.55;changes.append({'cargo_before':old,'cargo_after':p['position'][:]})
 p={'module':'B07_SERVICE_CABINET','position':[x,y+1.5,0],'rz':0};r['placements'].append(p);changes.append({'solid_cabinet_added':p})
# A fourth repair restores actual solid occlusion in front of the pump-entry pad.
# The pipe rack is intentionally excluded from the cover comparison; relocate it clear of the cabinet.
r=C['regions']['east_pump_yards']
for p in r['placements']:
 if p['module']=='B07_PIPE_RACK' and p['position']==[58.5,-18,0]:
  old=p.copy();p['position']=[59,-20.3,0];p['rz']=0;changes.append({'rack_before':old,'rack_after':p.copy()})
p={'module':'B07_SERVICE_CABINET','position':[59.5,-16.5,0],'rz':0};r['placements'].append(p);changes.append({'pump_solid_cabinet_added':p})
C['revision']='v03';C['revision_purpose']='Restore final six rising-ray losses on three logistics aprons and three pipe-excluded pump-approach losses using four solid cabinets; shift existing cargo / one pipe rack clear. No expanded footprint.'
(R/'Config/design_v03.json').write_text(json.dumps(C,indent=2))
for rn in ['southwest_logistics','east_pump_yards']:
 r=C['regions'][rn];sol=ss(r['custom_parts'])
 for p in r['placements']:sol+=ss(M[p['module']]['parts'],p['position'],p['rz'],p.get('scale',[1,1,1]))
 draw(rn,sol,'V03 PRE-MODEL / '+rn+'\nFour solid-cabinet repairs across two regions; cargo / pipe rack moved clear. Other fixed modules unchanged.')
# Plan entire site with unchanged route centrelines and all revised module footprints.
L=json.loads((R.parent/'Batch06_Expansion/layout.json').read_text());fig,ax=plt.subplots(figsize=(12,11),dpi=120);ax.set_facecolor('#ebeae4')
for nm,b in [('core',[-20,20,-18,18])]+[(k,v['bounds']) for k,v in L['regions'].items()]:
 x0,x1,y0,y1=b;ax.add_patch(Rectangle((x0,y0),x1-x0,y1-y0,facecolor='#c9ccc6',edgecolor='#777f79'));ax.text((x0+x1)/2,(y0+y1)/2,nm,ha='center')
for rn,r in C['regions'].items():
 for p in r['placements']:
  vs=np.concatenate([v for v,f,c in ss(M[p['module']]['parts'],p['position'],p['rz'],p.get('scale',[1,1,1]))]);lo=vs.min(0);hi=vs.max(0);ax.add_patch(Rectangle(lo[:2],hi[0]-lo[0],hi[1]-lo[1],facecolor={'core_skin':'#586f7c','east_pump_yards':'#69887c','southwest_logistics':'#9a8065'}[rn],edgecolor='#34414a',alpha=.7))
for name,poly in L['pedestrian_routes'].items():
 a=np.array(poly);ax.plot(a[:,0],a[:,1],color='#dab143',lw=2.5)
ax.set_xlim(-81,81);ax.set_ylim(-71,71);ax.set_aspect('equal');ax.grid(alpha=.15);ax.set_title('V03 / PRE-MODEL SITE ASSEMBLY PLAN\nGold = unchanged protected routes. Only three bounded logistics-bay repairs.');fig.tight_layout()
for ext in ['svg','png']:fig.savefig(out/('site_layout.'+ext))
plt.close(fig)
files=[R/'Config/design_v03.json',R/'Scripts/design_revision_v03.py']+sorted(out.glob('*'))
rec={'stage':'V03_REFERENCE_BEFORE_REBUILD','utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'parent_reference_sha256':hashlib.sha256((R/'QA/reference_freeze_v02.json').read_bytes()).hexdigest(),'previous_scene_sha256':hashlib.sha256((R/'site_refined.blend').read_bytes()).hexdigest(),'inputs':{str(p.relative_to(R)):hashlib.sha256(p.read_bytes()).hexdigest() for p in files},'changes':changes}
(R/'QA/reference_freeze_v03.json').write_text(json.dumps(rec,indent=2));print('V03_FROZEN',rec['utc'])
