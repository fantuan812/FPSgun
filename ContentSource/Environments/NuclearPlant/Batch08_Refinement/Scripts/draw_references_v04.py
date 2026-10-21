"""Pre-model engineering diagrams from numeric design input, not Blender renders."""
import json,pathlib,sys,math,copy
import numpy as np
import matplotlib;matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.collections import PolyCollection
from matplotlib.patches import Rectangle
R=pathlib.Path(__file__).resolve().parent.parent;sys.path.insert(0,str(R/'Scripts'))
from analytic_geometry import meshpart,transform
C=json.loads((R/'Config/design_v04.json').read_text()); old=json.loads((R/'QA/baseline_inventory.json').read_text());pal=C['material_palette'];pal.update({'ceramic':'#c3c5bb','asphalt':'#424b50'})
plt.rcParams.update({'font.family':'DejaVu Sans','font.size':9,'svg.fonttype':'none'})
BG='#f1f0e9';ink='#233740'
def geo(parts):
 return [(meshpart(p),p) for p in parts]
def draw(ax,parts,view,alpha=1):
 axes,depth,rev={'front':((0,2),1,True),'right':((1,2),0,False),'top':((0,1),2,False)}[view];polys=[]
 for (v,f),p in geo(parts):
  for face in f:
   vv=v[face]; poly=vv[:,axes]
   if abs(sum(poly[i,0]*poly[(i+1)%len(poly),1]-poly[(i+1)%len(poly),0]*poly[i,1] for i in range(len(poly))))<1e-8:continue
   polys.append((float(vv[:,depth].mean()),poly,pal.get(p['mat'],'#777777')))
 polys.sort(key=lambda x:x[0],reverse=rev)
 pc=PolyCollection([p[1] for p in polys],facecolors=[p[2] for p in polys],edgecolors='#314249',linewidths=.16,alpha=alpha);ax.add_collection(pc)
 ax.grid(True,color='#9daaa8',alpha=.17);ax.set_axisbelow(True);ax.set_aspect('equal');ax.set_facecolor(BG)
def save(fig,name):
 fig.savefig(R/'References/v04'/f'{name}.svg',facecolor=BG,bbox_inches='tight');fig.savefig(R/'References/v04'/f'{name}.png',facecolor=BG,dpi=130,bbox_inches='tight');plt.close(fig)
def sheet(mid,structure=False):
 m=C['modules'][mid];parts=copy.deepcopy(m.get('base_parts',[]))+copy.deepcopy(m['parts'])
 if structure:
  if mid=='B08_CARGO_DRESSING':parts=[p for p in parts if not any(t in p['name'] for t in ['cloth','hem','cord','eyelet','strap','tension','draped','ratchet','corner seam'])]
  elif mid=='B08_SERVICE_EDGE':parts=[p for p in parts if not any(t in p['name'] for t in ['cover','grate bearing','pressed grip','curb nose'])]
  elif mid=='B08_WALL_TERMINAL':parts=[p for p in parts if not any(t in p['name'] for t in ['terminal body','door','weather hood','hood drip','warning','triangle'])]
 verts=np.concatenate([meshpart(p)[0] for p in (m.get('base_parts',[])+m['parts'])]);lo=verts.min(0);hi=verts.max(0);ext=hi-lo;span=max(ext)*1.30;midp=(lo+hi)/2
 fig,axs=plt.subplots(1,3,figsize=(16,6.2));fig.patch.set_facecolor(BG)
 for ax,view,axes in zip(axs,['front','right','top'],[(0,2),(1,2),(0,1)]):
  draw(ax,parts,view);u,v=axes;ax.set_xlim(midp[u]-span/2,midp[u]+span/2);ax.set_ylim(midp[v]-span/2,midp[v]+span/2)
  ax.set_title({'front':'FRONT  /  -Y','right':'RIGHT  /  +X','top':'TOP  /  +Z'}[view],color=ink,pad=12);ax.set_xlabel('metres');ax.set_ylabel('metres')
 fig.suptitle(mid+'  /  '+m['title']+('\nSTRUCTURE: selected occluding skins removed; not normal appearance' if structure else '\nPRE-MODEL ORTHOGRAPHIC DESIGN'),fontsize=14,color=ink,y=.98)
 fig.text(.025,.03,f'ACTUAL ENVELOPE  {ext[0]:.3f} x {ext[1]:.3f} x {ext[2]:.3f} m    |    All three views use identical metric scale.    |    Seed 8021',fontsize=10,color=ink)
 fig.text(.025,.005,m['notes'][0],fontsize=8.5,color=ink);fig.subplots_adjust(top=.79,bottom=.17,wspace=.22)
 save(fig,mid+('_structure' if structure else ''))
# Module meshes are unchanged and retain their frozen v03 module sheets.
# Region designs use exact additive geometry with simplified transparent existing context volumes.
def worldparts(region):
 out=[]
 for p in region['placements']:
  m=C['modules'][p['module']]
  for q in m['parts']:
   v,f=meshpart(q);v=v*np.array(p.get('scale',[1,1,1]));v=transform(v,p['position'],p['rz']);out.append({'type':'mesh','name':q['name'],'verts':v.tolist(),'faces':f,'mat':q['mat']})
 out+=region['custom_parts'];return out
from matplotlib.lines import Line2D
routes=json.loads((R.parent/'Batch06_Expansion/layout.json').read_text())['pedestrian_routes']
def context(ax,b,view):
 for o in old:
  mn=np.array(o['bbox_min']);mx=np.array(o['bbox_max']);
  if mx[0]<b[0] or mn[0]>b[1] or mx[1]<b[2] or mn[1]>b[3]:continue
  if mx[2]<-.02:continue
  if view=='top':
   if (mx[0]-mn[0])*(mx[1]-mn[1])<.5:continue
   col='#bfc6c3' if mx[2]>.3 else '#d4d9d5';ax.add_patch(Rectangle(mn[:2],mx[0]-mn[0],mx[1]-mn[1],facecolor=col,edgecolor='#a6b0ad',lw=.2,alpha=.55,zorder=0))
  else:
   if mx[2]<1:continue
   axis=0 if view=='front' else 1
   ax.add_patch(Rectangle((mn[axis],mn[2]),mx[axis]-mn[axis],mx[2]-mn[2],facecolor='#c8ceca',edgecolor='#aab5b1',lw=.2,alpha=.16,zorder=0))
 if view=='top':
  for n,poly in routes.items():
   if n=='upper_link':continue
   x,y=np.array(poly).T;ax.plot(x,y,color='#cd6757',lw=1.7,ls='--',zorder=5)
   # Explicit 2m clear band, not just centreline.
   for a,c in zip(np.array(poly[:-1]),np.array(poly[1:])):
    d=c-a;n=np.array([-d[1],d[0]])/np.linalg.norm(d);pp=np.array([a+n,c+n,c-n,a-n]);ax.add_collection(PolyCollection([pp],facecolors='#df9c7d',edgecolors='none',alpha=.12,zorder=4))
for rn,r in C['regions'].items():
 parts=worldparts(r);b=r['bounds'];span=max(b[1]-b[0],b[3]-b[2])*1.07;cent=[(b[0]+b[1])/2,(b[2]+b[3])/2]
 fig,axs=plt.subplots(1,3,figsize=(19,7.5));fig.patch.set_facecolor(BG)
 for ax,view in zip(axs,['front','right','top']):
  context(ax,b,view);draw(ax,parts,view)
  if view=='top':ax.set_xlim(cent[0]-span/2,cent[0]+span/2);ax.set_ylim(cent[1]-span/2,cent[1]+span/2)
  else:axis=0 if view=='front' else 1;ax.set_xlim(cent[axis]-span/2,cent[axis]+span/2);ax.set_ylim(-2,span-2)
  ax.set_title(view.upper()+' / same metric scale');ax.set_xlabel('world metres')
 fig.suptitle(r['title']+'\nB08 PRE-MODEL REGIONAL ASSEMBLY / orthographic views',fontsize=15,y=.98,color=ink)
 fig.text(.03,.05,'Grey: unchanged existing scene envelope  |  coloured: exact proposed B08 parts  |  dashed red: inherited route centrelines + 2m sampled bands',fontsize=10)
 fig.text(.03,.025,r['description'],fontsize=9);fig.subplots_adjust(top=.86,bottom=.12,wspace=.2);save(fig,rn)
 # Separate readable plan with exact connected footprint extents and station labels.
 fig,ax=plt.subplots(figsize=(12,10));fig.patch.set_facecolor(BG);context(ax,b,'top');draw(ax,parts,'top');ax.set_xlim(b[0]-1,b[1]+1);ax.set_ylim(b[2]-1,b[3]+1)
 for i,p in enumerate(r['placements']):
  if p['module']=='B08_WALL_TERMINAL':ax.annotate('T'+str(i),p['position'][:2],xytext=(5,5),textcoords='offset points',fontsize=9,color='#713d2e')
 ax.set_xlabel('WORLD X / metres');ax.set_ylabel('WORLD Y / metres');ax.set_title(r['title']+'\nPRE-MODEL MASTER PLAN / same frozen design',fontsize=14);save(fig,rn+'_plan')
# Whole existing map plus finite intervention footprints. No model geometry read/rendered.
fig,ax=plt.subplots(figsize=(14,12));fig.patch.set_facecolor(BG);context(ax,[-80,80,-70,70],'top')
for rn,r in C['regions'].items():
 draw(ax,worldparts(r),'top');b=r['bounds'];ax.add_patch(Rectangle((b[0],b[2]),b[1]-b[0],b[3]-b[2],facecolor='none',edgecolor='#2b7175',lw=1.3,ls='--'));ax.text(b[0],b[3]+1,r['title'],fontsize=9,color='#195b5e')
ax.add_patch(Rectangle((-8.6,-19.1),17.2,.85,facecolor='#d89072',edgecolor='#9e4933',lw=.8));ax.text(-8.6,-21.5,'retained sliding-door motion envelope',fontsize=8,color='#9e4933')
ax.set_xlim(-81,81);ax.set_ylim(-71,71);ax.set_xlabel('WORLD X / metres');ax.set_ylabel('WORLD Y / metres');ax.set_title('NUCLEAR PLANT / BATCH08 LIMITED SERVICE-LINK PLAN\nExisting 160 x 140m site unchanged; additive work in two bounded regions',fontsize=15);save(fig,'site_layout')
print('PREMODEL_REFERENCES_DONE')

fig,axs=plt.subplots(7,1,figsize=(13,14));fig.patch.set_facecolor(BG)
for ax,g in zip(axs,C['crossing_groups']):
 ax.set_facecolor(BG)
 for s in g['segments']:
  a,b,z,h=s['min'],s['max'],s['old_ground_z'],s['cover_top_z'];ax.fill_between([a,b],[-.09,-.09],[z,z],color='#c3c7c3',alpha=.7);ax.plot([a,b],[z,z],color='#777e7a',lw=2);ax.plot([a,b],[h,h],color='#22666b',lw=4);ax.text((a+b)/2,h+.009,f"ground {z:+.3f} / cover {h:+.3f} / +{(h-z)*1000:.0f} mm",ha='center',fontsize=8)
 ax.set_ylim(-.085,.065);ax.set_xlim(g['segments'][0]['min']-.1,g['segments'][-1]['max']+.1);ax.set_title(g['id']+' / WORLD '+g['axis']+' station | relative heights measured against original retained ground',fontsize=10,loc='left');ax.set_ylabel('Z metres');ax.grid(alpha=.2)
fig.suptitle('V04 PRE-MODEL CROSSING LEVEL PROFILES\nVertical scale enlarged for readability; not same-scale orthographic views',fontsize=14,color=ink);fig.text(.05,.012,'No old ground edited. Grey = existing ground; teal = cover maximum including screws. External end steps <=27 mm; internal steps <=18 mm. Not UE traversal certification.',fontsize=9);fig.tight_layout(rect=[0,.035,1,.95]);save(fig,'crossing_ground_profiles')
