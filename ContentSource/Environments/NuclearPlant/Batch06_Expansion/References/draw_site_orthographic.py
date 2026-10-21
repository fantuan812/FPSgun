"""Analytical orthographic MASSING reference from layout.json. Heights are design proposals."""
import json,pathlib,hashlib
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle
P=pathlib.Path(__file__).resolve().parent
raw=(P.parent/'layout.json').read_bytes();layout=json.loads(raw)
# Preserve input footprints. Explicit proposed heights, never claim as-built regional dimensions.
parts=[('CORE',[-20,20,-18,18],20,'#bc6559'),('W WING',[-30,-20,-7,17],8,'#c3c7c8'),('E WING',[20,30,-7,17],8,'#c3c7c8')]
heights={'control':12,'maintenance':11.24,'pumps':8.51,'loading':7}
for k,v in layout['regions'].items():parts.append((k.upper(),v['bounds'],heights[k],'#b9c6cd'))
for i,v in enumerate(layout.get('infill',{}).get('service_shelters',[])):
 x,y,z=v['center'];w,d,h=v['size'];parts.append(('UTILITY '+str(i+1),[x-w/2,x+w/2,y-d/2,y+d/2],h,'#9dabae'))
fig=plt.figure(figsize=(16,14),facecolor='white');gs=fig.add_gridspec(3,2,height_ratios=[3.5,1,1])
ax=fig.add_subplot(gs[0,:]); ax.set_title('TOP / exact parallel projection - source plan footprints',fontsize=14)
b=layout['site_bounds'];ax.add_patch(Rectangle((b[0],b[2]),b[1]-b[0],b[3]-b[2],fill=False,lw=2))
for path in [layout['roads']['outer_loop']]+layout['roads']['links']+ [layout['roads']['inner_completion'],[[-34,-30],[34,-30],[34,26],[-34,26]]]:
 xs,ys=zip(*path);ax.plot(xs,ys,color='#e0e3e5',lw=12,solid_capstyle='butt',zorder=0)
for name,(x0,x1,y0,y1),h,c in parts:
 ax.add_patch(Rectangle((x0,y0),x1-x0,y1-y0,facecolor=c,edgecolor='black',lw=1));ax.text((x0+x1)/2,(y0+y1)/2,name,ha='center',va='center',fontsize=8)
for x,y,z,a in layout.get('infill',{}).get('screen_walls',[]):
 w,d=(.38,5) if a==0 else (5,.38);ax.add_patch(Rectangle((x-w/2,y-d/2),w,d,facecolor='#8d3934',zorder=5))
for v in layout.get('walk_ribbons',[]):
 x,y,z=v['center'];w,d=v['size'];ax.add_patch(Rectangle((x-w/2,y-d/2),w,d,facecolor='#c8cbbf',alpha=.35,zorder=0))
p=layout['elevated_connection']['path'];ax.plot([v[0] for v in p],[v[1] for v in p],color='#aa7c28',lw=3)
ax.set(xlim=(-85,85),ylim=(-75,75),xlabel='X / m',ylabel='Y / m');ax.set_aspect('equal');ax.set_xticks(range(-80,81,10));ax.set_yticks(range(-70,71,10));ax.grid(alpha=.18)
for row,axis,title,lim in [(1,'x','SOUTH / looking north (X-Z projection)',(-80,80)),(2,'y','EAST / looking west (Y-Z projection)',(-70,70))]:
 a=fig.add_subplot(gs[row,:]);a.set_title(title,fontsize=12)
 # Paint farther masses first to produce a simple solid envelope projection.
 seq=sorted(parts,key=lambda p:(p[1][2]+p[1][3])/2,reverse=True) if axis=='x' else sorted(parts,key=lambda p:(p[1][0]+p[1][1])/2)
 for name,box,h,c in seq:
  q0,q1=box[:2] if axis=='x' else box[2:];a.add_patch(Rectangle((q0,0),q1-q0,h,facecolor=c,edgecolor='black',lw=1))
 # Datum and ceiling are mathematical coordinates, not generated scale markings.
 a.axhline(0,color='black');a.axhline(20,color='#bc6559',lw=.7,ls='--');a.set(xlim=lim,ylim=(-1,24),xlabel=f'{axis.upper()} / m',ylabel='Z / m');a.set_aspect('equal');a.set_yticks([0,6,8,10,12,20]);a.grid(alpha=.2)
fig.suptitle('BATCH 06 - WHOLE-SITE ORTHOGRAPHIC MASSING REFERENCE\n160 x 140 m | no perspective | not an as-built survey',fontsize=16)
fig.text(.05,.018,'Core height 20 m from Batch05; design envelopes: control12m, maintenance11.24m, pump equipment8.51m, loading7m (regional drawings override).\nFootprints from layout.json; red marks are solid cover screens; detailed regional elevations require independent model validation. Not UE-tested.',fontsize=10)
fig.subplots_adjust(top=.92,bottom=.08,hspace=.35)
fig.savefig(P/'site_orthographic_exact_layout.png',dpi=150);fig.savefig(P/'site_orthographic_exact_layout.svg')
(P/'site_orthographic_exact_layout.json').write_text(json.dumps({'method':'deterministic parallel coordinate projection','source_layout_sha256':hashlib.sha256(raw).hexdigest(),'input_layout':str(P.parent/'layout.json'),'parts':parts,'status':'exact input footprint projection; proposed regional heights; not as-built','core_height_m':20},indent=2))
