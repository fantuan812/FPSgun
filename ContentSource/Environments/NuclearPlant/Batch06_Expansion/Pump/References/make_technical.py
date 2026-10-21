"""Pre-model deterministic 2D projections, not rendered from Blender."""
import pathlib,json,datetime
R=pathlib.Path(__file__).parent
spec={'units':'m','buffer_tank':{'diameter':3.6,'height':8.5,'footing_width':4.8,'footing_height':.2,'nozzles_z':[1.1,6.8]},'maintenance_hall':{'width':20,'depth':6,'height':8,'door_width':6,'door_height':4},'fire_screen':{'width':3.6,'thickness':.3,'height':2.3,'foot_depth':1},'pipe_gantry':{'column_centers':2.4,'crossbeam_width':3,'frame_top':6.4,'pipe_axis':6.8,'pipe_radius':.22,'pipe_length':6},'zone':{'bounds':[42,68,-8,26],'hall':[46,66,19,25],'tanks':[[64,-1],[64,13.5]],'pumps':[[50,-3],[56,-3],[48,14],[54,14]],'north_header_z':3.2,'hall_approach_x':[57,58],'aisle_y':[6,10],'fire_screens':[[47.5,10.6],[54.5,5.4],[60.5,10.6]]}}
(R/'dimensions_spec.json').write_text(json.dumps(spec,indent=2))
def sheet(name,views,scale=30):
 out=['<svg xmlns="http://www.w3.org/2000/svg" width="1400" height="1000" viewBox="0 0 1400 1000"><rect width="1400" height="1000" fill="#f4f6f7"/><g font-family="sans-serif" fill="#182632"><text x="30" y="35" font-size="22">'+name+' | exact 2D orthographic dimensional guide</text><text x="30" y="65" font-size="15">Generated directly from specification before modeling. Black outlines govern geometry; AI sheets are styling only. Units: m.</text></g>']
 for i,(title,shapes,extent) in enumerate(views):
  ox=[45,760,45][i];oy=[480,480,940][i];out.append(f'<g transform="translate({ox},{oy}) scale({scale},{-scale})" fill="none" stroke="#192c3d" stroke-width="{1.6/scale}">')
  for s in shapes:
   if s[0]=='r':_,x,y,w,h=s;out.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}"/>')
   elif s[0]=='c':_,x,y,r=s;out.append(f'<circle cx="{x}" cy="{y}" r="{r}"/>')
   elif s[0]=='l':_,x,y,xx,yy=s;out.append(f'<line x1="{x}" y1="{y}" x2="{xx}" y2="{yy}"/>')
  out.append('</g>');out.append(f'<text x="{ox}" y="{oy+24}" font-family="sans-serif" font-size="17">{title} | {extent}</text>')
 out.append('</svg>');(R/(name+'_technical.svg')).write_text(''.join(out))
sheet('buffer_tank',[
('FRONT -Y', [('r',-.6,0,4.8,.2),('r',0,1,3.6,7.5),('r',3.6,1.1-.22,.6,.44),('r',3.6,6.8-.22,.6,.44),('r',.5,0,.25,1),('r',2.85,0,.25,1)],'body D3.6; overall H8.5; nozzles +X at z1.1/6.8'),
('RIGHT +X',[('r',-.6,0,4.8,.2),('r',0,1,3.6,7.5),('r',.5,0,.25,1),('r',2.85,0,.25,1),('c',1.8,1.1,.22),('c',1.8,6.8,.22)],'nozzles projected end-on'),
('TOP +Z',[('r',-.6,-.6,4.8,4.8),('c',1.8,1.8,1.8),('r',3.6,1.58,.6,.44)],'body D3.6; footing4.8 square; nozzle +X')],42)
sheet('maintenance_hall',[
('FRONT -Y',[('r',0,0,20,8),('r',7,0,6,4)],'20 W x8 H; opening6 W x4 H'),
('RIGHT +X',[('r',0,0,6,8)],'6 D x8 H'),
('TOP +Z',[('r',0,0,20,6)],'20 W x6 D')],30)
sheet('fire_screen',[
('FRONT -Y',[('r',0,0,3.6,2.3),('r',.25,0,.5,.12),('r',2.85,0,.5,.12)],'3.6 W x2.3 H'),
('RIGHT +X',[('r',.35,0,.3,2.3),('r',0,0,1,.12)],'.3 thick;1m foot depth'),
('TOP +Z',[('r',0,.35,3.6,.3),('r',.25,0,.5,1),('r',2.85,0,.5,1)],'1m feet; screen .3 thick')],95)
sheet('pipe_gantry',[
('FRONT -X (pipe end)',[('r',.19,0,.22,6.1),('r',2.59,0,.22,6.1),('r',0,6.1,3,.3),('r',1.3,6.4,.4,.18),('c',1.5,6.8,.22)],'centers2.4; beam bottom6.1/top6.4; pipe z6.8 D.44'),
('RIGHT -Y',[('r',2.89,0,.22,6.1),('r',2.85,6.1,.3,.48),('r',0,6.58,6,.44)],'6m pipe is perpendicular to crossbeam'),
('TOP +Z',[('r',0,1.28,6,.44),('r',2.85,0,.3,3)],'crossbeam3 alongY; pipe6 alongX')],46)
z=spec['zone'];top=[('r',0,0,26,34),('r',4,27,20,6),('l',0,14,26,14),('l',0,18,26,18)]
for x,y in z['pumps']:top.append(('r',x-42-2,y+8-1,4,2))
for x,y in z['tanks']:top.append(('c',x-42,y+8,1.8))
for x,y in z['fire_screens']:top.append(('r',x-42-1.8,y+8-.15,3.6,.3))
for x,y in [(43,4),(49,4),(55,4),(60,-1),(60,13.5)]:top.append(('r',x-42-.15,y+8-1.5,.3,3))
front=[('r',6,2.98,16,.44),('r',4,0,20,8),('r',11,0,6,4),('r',20.2,1,3.6,7.5)]
side=[('r',27,0,6,8),('r',5.2,1,3.6,7.5),('r',19.7,1,3.6,7.5)]
sheet('zone', [('FRONT -Y',front,'26 W x8.5 max H'),('RIGHT +X',side,'34 D x8.5 max H'),('TOP +Z',top,'26x34; east-west aisle localY14..18')],11.5)
(R/'technical_provenance.json').write_text(json.dumps({'generated_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'method':'deterministic SVG projections from dimension spec, no Blender render','authoritative':True,'AI_limitations':['gantry v2 top still inconsistent','tank v2 proportions are design only','region AI adds details and placements not exact'], 'model_rebuild_required_after_this_file':True},indent=2))
