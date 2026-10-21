"""Final bounded pre-model repair for the independently found pump-pad cabinet gap."""
from pathlib import Path
import json,hashlib,datetime,sys,ast
import numpy as np
import matplotlib;matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import Polygon,Rectangle
R=Path(__file__).resolve().parent.parent;sys.path.insert(0,str(R/'Scripts'));from analytic_geometry import meshpart,transform
C=json.loads((R/'Config/design_v03.json').read_text());M=C['modules'];P=C['material_palette'];out=R/'References/v04';out.mkdir(exist_ok=True)
tree=ast.parse((R/'Scripts/design_revision_v02.py').read_text());nodes=[n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name in ['ss','draw']]
for node in ast.walk(ast.Module(body=nodes,type_ignores=[])):
 if isinstance(node,ast.Constant) and isinstance(node.value,str):node.value=node.value.replace('V02 PRE-MODEL DESIGN','V04 PRE-MODEL DESIGN')
exec(compile(ast.Module(body=nodes,type_ignores=[]),'frozen_v02_drawing_functions','exec'))
p={'module':'B07_SERVICE_CABINET','position':[56.95,-16.5,0],'rz':0,'scale':[.45,1,1],'variant':'narrow_045'}
C['regions']['east_pump_yards']['placements'].append(p)
sol=ss(M[p['module']]['parts'],scale=p['scale']);v=np.concatenate([v for v,f,c in sol]);lo=v.min(0);hi=v.max(0)
C['variants']={'B07_SERVICE_CABINET/narrow_045':{'base_module':p['module'],'scale':p['scale'],'bounds_min':lo.tolist(),'bounds_max':hi.tolist(),'reference':'References/v04/B07_SERVICE_CABINET_narrow_045.svg','purpose':'Solid equipment infill between transformer and right cabinet, entirely within existing pad.'}}
C['revision']='v04';C['revision_purpose']='Close independently found continuous 113.5-117.5 degree pump-approach visibility gap with one narrow solid cabinet. No additional yard / route expansion; stop at existing standard and discovered dense sample sets.'
(R/'Config/design_v04.json').write_text(json.dumps(C,indent=2))
draw('B07_SERVICE_CABINET_narrow_045',sol,'V04 / NARROW SERVICE CABINET / X scale 0.45, YZ unchanged\nActual analytic envelope '+ ' x '.join(f'{n:.4f}' for n in hi-lo)+' m / derived stock-family variant')
r=C['regions']['east_pump_yards'];full=[];visible=[]
for q in r['placements']:
 if abs(q['position'][0]-56)<7.1 and abs(q['position'][1]+18)<4.1:
  s=ss(M[q['module']]['parts'],q['position'],q['rz'],q.get('scale',[1,1,1]));full+=s
  if q['module']!='B07_SOLID_SCREEN':visible+=s
# Only this pad is revised. The retained concrete base, unchanged roads and walls remain in earlier region sheets.
draw('pump_pad_56_minus18',full,'V04 / PUMP PAD (56, -18) / EXTERIOR ASSEMBLY\nOne narrow cabinet at (56.95, -16.50); all other frozen placements unchanged')
draw('pump_pad_56_minus18_structure',visible,'V04 / PUMP PAD EQUIPMENT / UPPER SCREENS HIDDEN\nExplicit hidden-screen assembly supplement, same scale as exterior sheet',bounds=full)
# Required whole-site overview before modeling. It is analytic, not a Blender render.
L=json.loads((R.parent/'Batch06_Expansion/layout.json').read_text());fig,ax=plt.subplots(figsize=(12,11),dpi=120);ax.set_facecolor('#ebeae4')
for nm,b in [('core',[-20,20,-18,18])]+[(k,v['bounds']) for k,v in L['regions'].items()]:
 x0,x1,y0,y1=b;ax.add_patch(Rectangle((x0,y0),x1-x0,y1-y0,facecolor='#c9ccc6',edgecolor='#777f79'));ax.text((x0+x1)/2,(y0+y1)/2,nm,ha='center')
for rn,r in C['regions'].items():
 for q in r['placements']:
  vs=np.concatenate([v for v,f,c in ss(M[q['module']]['parts'],q['position'],q['rz'],q.get('scale',[1,1,1]))]);a=vs.min(0);b=vs.max(0);ax.add_patch(Rectangle(a[:2],b[0]-a[0],b[1]-a[1],facecolor={'core_skin':'#586f7c','east_pump_yards':'#69887c','southwest_logistics':'#9a8065'}[rn],edgecolor='#34414a',alpha=.7))
for name,poly in L['pedestrian_routes'].items():
 a=np.array(poly);ax.plot(a[:,0],a[:,1],color='#dab143',lw=2.5)
ax.annotate('V04 narrow solid cabinet only',xy=(56.95,-16.5),xytext=(8,-6),arrowprops={'arrowstyle':'->','color':'#ab4735'},color='#ab4735')
ax.set_xlim(-81,81);ax.set_ylim(-71,71);ax.set_aspect('equal');ax.grid(alpha=.15);ax.set_title('V04 / PRE-MODEL SITE ASSEMBLY PLAN\nGold = unchanged protected routes. One bounded pump-pad repair.');fig.tight_layout()
for ext in ['svg','png']:fig.savefig(out/('site_layout.'+ext))
plt.close(fig)
files=[R/'Config/design_v04.json',R/'Scripts/design_revision_v04.py']+sorted(out.glob('*'))
rec={'stage':'V04_REFERENCE_BEFORE_REBUILD','utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'parent_reference_sha256':hashlib.sha256((R/'QA/reference_freeze_v03.json').read_bytes()).hexdigest(),'previous_scene_sha256':hashlib.sha256((R/'site_refined.blend').read_bytes()).hexdigest(),'inputs':{str(p.relative_to(R)):hashlib.sha256(p.read_bytes()).hexdigest() for p in files},'changes':[p],'purpose':C['revision_purpose']}
(R/'QA/reference_freeze_v04.json').write_text(json.dumps(rec,indent=2));print('V04_FROZEN',rec['utc'])
