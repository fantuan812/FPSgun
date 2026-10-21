import json,pathlib,math,datetime
import matplotlib;matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle
from mpl_toolkits.mplot3d.art3d import Poly3DCollection
P=pathlib.Path(__file__).resolve().parent;C=json.loads((P.parent/'layout.json').read_text());parts=[]
def part(x,y,z,w,d,h,col):parts.append((x,y,z,w,d,h,col))
for n,r in C['regions'].items():
 a,b,c,d=r['bounds'];part((a+b)/2,(c+d)/2,0,b-a,d-c,{'control':12,'maintenance':11.24,'pumps':8.51,'loading':7}[n],'#929fa8')
part(0,0,0,40,36,20,'#b26055')
for v in C['infill']['service_shelters']:
 x,y,z=v['center'];part(x,y,z,14,8,4.5,'#859b98')
for x,y,z,a in C['infill']['screen_walls']:
 w,d=(.38,5) if a==0 else (5,.38);part(x,y,z,w,d,2.3,'#9f3933')
for a,b in zip(C['elevated_connection']['path'],C['elevated_connection']['path'][1:]):
 x=(a[0]+b[0])/2;y=(a[1]+b[1])/2;part(x,y,5.68,abs(a[0]-b[0]) or 5.4,abs(a[1]-b[1]) or 5.4,.32,'#556370')
for a,b in zip(C['elevated_connection']['path'],C['elevated_connection']['path'][1:]):
 dx=b[0]-a[0];dy=b[1]-a[1];L=math.hypot(dx,dy);nx=-dy/L;ny=dx/L
 for dist in C['elevated_connection']['side_screen_centers']:
  if dist+2.5>L:continue
  for side in [-1,1]:
   x=a[0]+dx/L*dist+nx*2.7*side;y=a[1]+dy/L*dist+ny*2.7*side
   part(x,y,6,5 if dx else .38,.38 if dx else 5,2.3,'#9f3933')
for v in C['elevated_connection']['baffles']:
 x,y,z=v['center'];w,d=(2.265,2.8) if v['angle']==90 else(2.8,2.265);part(x,y,z,w,d,3,'#713d36')
fig,axs=plt.subplots(3,1,figsize=(16,15),gridspec_kw={'height_ratios':[3,1,1]})
for ax,axes,title in zip(axs,[(0,1),(0,2),(1,2)],['TOP exact plan','FRONT X-Z','RIGHT Y-Z']):
 for x,y,z,w,d,h,col in parts:
  lows=[x-w/2,y-d/2,z];dims=[w,d,h];u,v=axes;ax.add_patch(Rectangle((lows[u],lows[v]),dims[u],dims[v],facecolor=col,edgecolor='#333',lw=.6,alpha=.8))
 ax.set_aspect('equal');ax.autoscale_view();ax.grid(alpha=.2);ax.set_title(title)
for n,pts in C['pedestrian_routes'].items():axs[0].plot(*zip(*pts),lw=1.6,label=n)
axs[0].legend(fontsize=8);fig.suptitle('COMPACT REVISION / PRE-ASSEMBLY COORDINATE REFERENCE\nExisting module reuse | paired 3m bridge deck cut-union to 5.4m | minimum baffle side opening 2.41m')
fig.tight_layout();fig.savefig(P/'compact_revision_orthographic.png',dpi=120);fig.savefig(P/'compact_revision_orthographic.svg');plt.close(fig)
fig=plt.figure(figsize=(13,10));ax=fig.add_subplot(projection='3d')
for x,y,z,w,d,h,col in parts:
 a=x-w/2;b=x+w/2;c=y-d/2;e=y+d/2;t=z+h;verts=[[(a,c,z),(b,c,z),(b,e,z),(a,e,z)],[(a,c,t),(b,c,t),(b,e,t),(a,e,t)],[(a,c,z),(b,c,z),(b,c,t),(a,c,t)],[(b,c,z),(b,e,z),(b,e,t),(b,c,t)],[(b,e,z),(a,e,z),(a,e,t),(b,e,t)],[(a,e,z),(a,c,z),(a,c,t),(a,e,t)]];ax.add_collection3d(Poly3DCollection(verts,facecolors=col,edgecolors='#333',linewidths=.3,alpha=.95))
ax.set(xlim=(-80,80),ylim=(-70,70),zlim=(0,25));ax.set_box_aspect((160,140,40));ax.view_init(50,-65);ax.set_proj_type('ortho');ax.set_title('PRE-ASSEMBLY COMPACT BLOCK OVERVIEW / analytical diagram, not render')
fig.savefig(P/'compact_revision_overview.png',dpi=120)
(P/'compact_revision_provenance.json').write_text(json.dumps({'created_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'method':'pre-model numeric2D projections and orthographic massing diagram; existing module AI styling references retained','new_module_types':[],'revision':'fillNE/SW with functional shelter groups; transverse chicanes;5.4m assembled bridge deck and solid baffles','not_blender_render':True},indent=2))
