"""QA route diagram from configuration, not a pre-model reference or rendered game view."""
import json,pathlib,math
import os
os.environ.setdefault("MPLCONFIGDIR","/tmp/b06_matplotlib")
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle,Circle
P=pathlib.Path(__file__).resolve().parent;C=json.loads((P.parent/'layout.json').read_text())
fig,ax=plt.subplots(figsize=(12,10));ax.set_facecolor('#edf0ed')
for n,b in [('CORE',C['core']['hall_bounds'])]+[(k.upper(),v['bounds']) for k,v in C['regions'].items()]:
 x0,x1,y0,y1=b;ax.add_patch(Rectangle((x0,y0),x1-x0,y1-y0,fc='#bac3c8',ec='#4a545c',alpha=.75));ax.text((x0+x1)/2,(y0+y1)/2,n,ha='center',va='center',fontsize=9,color='#283a45')
for p in [C['roads']['outer_loop'],C['roads']['inner_completion']]+C['roads']['links']:
 ax.plot([v[0] for v in p],[v[1] for v in p],color='#d1d5d6',lw=10,zorder=0)
for s in C.get('infill',{}).get('service_shelters',[]):
 x,y,*_=s['center'];w,d,*_=s['size'];ax.add_patch(Rectangle((x-w/2,y-d/2),w,d,fc='#a6adb1',ec='#606970',lw=.7))
for x,y,z,rot in C.get('infill',{}).get('screen_walls',[]):
 theta=math.radians(rot);dx=-math.sin(theta)*2.5;dy=math.cos(theta)*2.5;ax.plot([x-dx,x+dx],[y-dy,y+dy],color='#8c3030',lw=2)
colors=['#c05220','#1d74a8','#518c37','#9852a3','#ba8a04','#107c75']
for (name,pp),color in zip(C['pedestrian_routes'].items(),colors):
 ax.plot([p[0] for p in pp],[p[1] for p in pp],color=color,lw=2,label=name.replace('_',' '));ax.scatter(*pp[0],color=color,s=22)
ax.set(xlim=(-82,82),ylim=(-72,72),aspect='equal',xlabel='World X (m)',ylabel='World Y (m)');ax.grid(alpha=.15)
ax.set_title('Batch06 | Actual tested walking routes\nCore preserved; elevated route at z=6 m; other routes at ground level',fontsize=13)
ax.legend(loc='upper left',bbox_to_anchor=(1.01,1),fontsize=8,frameon=False)
fig.text(.08,.02,'QA diagram from layout.json — NOT pre-model art, UE navigation, vehicle clearance or guaranteed combat cover.',fontsize=9)
fig.tight_layout(rect=(0,.04,1,1));fig.savefig(P/'route_map.svg');fig.savefig(P/'route_map.png',dpi=150)
