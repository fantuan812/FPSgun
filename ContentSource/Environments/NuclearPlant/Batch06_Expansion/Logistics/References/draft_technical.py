"""PRE-MODEL deterministic 2D orthographic drafting; never reads Blender geometry."""
from pathlib import Path
import json,datetime
P=Path(__file__).resolve().parent
SPECS={
'maintenance_bay':{'dims':[26,8,11],'notes':'Open portal frame; concrete side panels; red band z0..3; truss z9.8..10.8.'},
'stair_landing':{'dims':[3,12.52,7.1],'notes':'Tread width2.6; landing width3; rise6; run9.52;34 risers; tread0.28; top landing3m; guardrail1.1.'},
'dock_bay':{'dims':[6,5.5,7.1],'notes':'Deck top1.1; canopy top7.1; open repeat interfaces. Access ramp is2.6m wide.'},
'container':{'dims':[6,2.6,2.6],'notes':'Long axis X; short-end doors; corrugated metal; all instances on dock z1.1.'},
'service_station':{'dims':[6,8,8],'notes':'Clear centre; 6m gantry; hook above4.5m; rear toolbench and repair lines.'},
'maintenance_region':{'dims':[26,34,11.2],'notes':'World x[-68,-42],y[-16,18]. EAST gate y[-3,3]; SOUTH door x[-55.5,-52.5]. NORTH upper port(-54,18,6).'},
'loading_region':{'dims':[48,20,7.2],'notes':'World x[18,66],y[-62,-42]. NORTH gate x[38,46]. SOUTH dock. Cover groups WEST and EAST; 8m middle lane.'}}
def sheet(name,d):
 W,D,H=d['dims'];scale=min(15,370/max(W,D,H));out=['<svg xmlns="http://www.w3.org/2000/svg" width="1400" height="680" viewBox="0 0 1400 680"><rect width="1400" height="680" fill="#f6f8fa"/>','<style>text{font-family:Arial;font-size:15px;fill:#172630}.label{font-size:22px;font-weight:bold}.line{fill:none;stroke:#263b49;stroke-width:2}.red{fill:#843e39;stroke:#263b49;stroke-width:1}.steel{fill:#556b76;stroke:#263b49;stroke-width:1}.floor{fill:#ccd4d7;stroke:#263b49;stroke-width:2}</style>',f'<text x="30" y="40" class="label">{name.upper()} — AUTHORITATIVE 2D ORTHOGRAPHIC SPEC</text>', '<text x="30" y="66">Pre-model drafting from dimensions. Parallel projections; not AI precision, not a post-render.</text>']
 def rect(x,y,w,h,cls='line'):out.append(f'<rect x="{x:.2f}" y="{y:.2f}" width="{w:.2f}" height="{h:.2f}" class="{cls}"/>')
 def line(a,b):out.append(f'<line x1="{a[0]}" y1="{a[1]}" x2="{b[0]}" y2="{b[1]}" class="line"/>')
 def text(x,y,s):out.append(f'<text x="{x}" y="{y}">{s}</text>')
 origins=[(45,500),(505,500),(965,500)]
 for (ox,base),a,b,label in zip(origins,[W,D,W],[H,H,D],['FRONT (+Y view)','RIGHT (+X view)','TOP (+Z view)']):
  rect(ox,base-b*scale,a*scale,b*scale,'floor');text(ox,550,label);text(ox,575,f'{a:g} m × {b:g} m')
  if label!='TOP (+Z view)':
   if name in ['maintenance_bay','maintenance_region']:rect(ox,base-3*scale,a*scale,3*scale,'red');rect(ox,base-10.8*scale,a*scale,1*scale,'steel')
   if name=='dock_bay':rect(ox,base-1.1*scale,a*scale,1.1*scale,'steel');rect(ox,base-7.1*scale,a*scale,.2*scale,'red')
   if name=='maintenance_region':
    if label.startswith('FRONT'):rect(ox+12.5*scale,base-9*scale,3*scale,3*scale,'floor')
    else:rect(ox+13*scale,base-6*scale,6*scale,6*scale,'floor')
   if name=='service_station':
    rect(ox,base-8*scale,.22*scale,8*scale,'steel');rect(ox+(a-.22)*scale,base-8*scale,.22*scale,8*scale,'steel');rect(ox,base-7.7*scale,a*scale,.5*scale,'red')
   if name=='container':
    for i in range(1,int(a/.4)):line((ox+i*.4*scale,base),(ox+i*.4*scale,base-H*scale))
   if name=='stair_landing' and label.startswith('RIGHT'):
    for i in range(34):
     x=ox+i*.28*scale;y=base-(i+1)*6/34*scale;line((x,y),(x+.28*scale,y));line((x+.28*scale,y),(x+.28*scale,base-(i+2)*6/34*scale))
    line((ox+9.52*scale,base-6*scale),(ox+12.52*scale,base-6*scale))
  elif name=='maintenance_region':
   rect(ox+4*scale,base-34*scale,15*scale,8*scale,'steel')
   rect(ox+4.2*scale,base-26*scale,2.6*scale,9.52*scale,'red')
   for xx in [10.2,19.2]:rect(ox+(xx-3)*scale,base-17*scale,6*scale,8*scale,'steel')
   # East gate must be on RIGHT edge of plan, no ambiguous AI south-gate placement.
   line((ox+26*scale,base-13*scale),(ox+26*scale+12,base-13*scale));text(ox+26*scale-80,base-15*scale,'E gate 6m')
   text(ox,base-34*scale-12,'NORTH / upper port z6')
  elif name=='loading_region':
   rect(ox+6*scale,base-5.5*scale,40*scale,5.5*scale,'steel')
   rect(ox+7*scale,base-16*scale,6*scale,2*scale,'red')
   rect(ox+35*scale,base-18*scale,10*scale,6*scale,'red')
   rect(ox+20*scale,base-20*scale,8*scale,14.5*scale)
   text(ox+20*scale,base-20*scale-12,'NORTH GATE 8m')
 text(30,620,d['notes']);text(30,650,'Scale proxy: 2.1m height, 0.5m radius; descriptive geometric check only, not a verified Manny mesh / UE runtime.')
 out.append('</svg>');(P/(name+'_technical.svg')).write_text('\n'.join(out))
for n,d in SPECS.items():sheet(n,d)
(P/'module_specs.json').write_text(json.dumps(SPECS,indent=2))
(P/'technical_drafting_receipt.json').write_text(json.dumps({'created_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'source':'dimension-driven SVG before formal rebuild','files':[n+'_technical.svg' for n in SPECS],'AI_limitations':['portal/dock elevation has depth cues','maintenance region east gate drawn on south in AI plan','stair count/rise vs labels not geometrically trusted','AI region panel proportions inconsistent'],'authoritative':'technical SVG and module_specs.json; AI only appearance'},indent=2))
