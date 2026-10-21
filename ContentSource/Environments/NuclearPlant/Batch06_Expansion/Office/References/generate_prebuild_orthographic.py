"""PRE-MODEL 2D dimensional drawings. No Blender import, no model rendering.
All projection coordinates come directly from dimensional specification.
"""
import pathlib,json,datetime,hashlib
R=pathlib.Path(__file__).resolve().parent
specs={'CTL_StairUnit':{'size':[3,3.4,3.1],'rise':2,'steps':12,'rail_height':1.1},'CTL_Deck':{'size':[4,3.6,.3]},'CTL_Island':{'size':[4,1.8,1.95]},'CTL_DisplayPanel':{'size':[2.6,.4,3.7]}}
class Sheet:
 def __init__(self,w,h,title,sub):
  self.a=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}"><rect width="100%" height="100%" fill="#f7f8fa"/><style>text{{font-family:Arial,sans-serif;fill:#182d36}}.g{{fill:none;stroke:#243a44;stroke-width:2}}.s{{fill:none;stroke:#b48721;stroke-width:2}}</style>',f'<text x="50" y="52" font-size="27">{title}</text>',f'<text x="50" y="82" font-size="16">{sub}</text>']
 def text(self,x,y,t,size=16):self.a.append(f'<text x="{x}" y="{y}" font-size="{size}">{t}</text>')
 def line(self,x1,y1,x2,y2,cl='g'):self.a.append(f'<line class="{cl}" x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}"/>')
 def rect(self,x,y,w,h,fill='none'):self.a.append(f'<rect class="g" x="{x}" y="{y}" width="{w}" height="{h}" fill="{fill}"/>')
 def write(self,p):p.write_text('\n'.join(self.a)+"</svg>")
def module(name,sp):
 W,D,H=sp['size'];scale=110;s=Sheet(1800,850,name+' — authoritative pre-build orthographic',f'SOURCE: analytical 2D SVG from dimensional spec, NOT AI and NOT a post-model render. Common scale {scale} px/m.')
 for i,(view,A,B) in enumerate([('FRONT X/Z',W,H),('RIGHT Y/Z',D,H),('TOP X/Y',W,D)]):
  ox=80+i*580;oy=650;s.text(ox,150,view,22)
  def ln(a,b,c,d,cls='g'):s.line(ox+a*scale,oy-b*scale,ox+c*scale,oy-d*scale,cls)
  def rc(x,y,w,h):s.rect(ox+x*scale,oy-(y+h)*scale,w*scale,h*scale)
  if name=='CTL_StairUnit':
   n=sp['steps'];rise=sp['rise'];rh=sp['rail_height']
   if i==0:
    for k in range(1,n+1):ln(0,k*rise/n,W,k*rise/n)
    for x in [.1,W-.1]:ln(x,0,x,rise+rh,'s')
   elif i==1:
    for k in range(n):ln(k*D/n,(k+1)*rise/n,(k+1)*D/n,(k+1)*rise/n)
    ln(0,0,D,rise);ln(0,rh,D,rise+rh,'s')
    for k in [0,3,6,9,12]:ln(k*D/n,k*rise/n,k*D/n,k*rise/n+rh,'s')
   else:
    rc(0,0,W,D)
    for k in range(1,n):ln(0,k*D/n,W,k*D/n)
    for x in [.1,W-.1]:ln(x,0,x,D,'s')
  else:
   rc(0,0,A,B)
   if name=='CTL_Island':
    if i==0:ln(0,1.2,W,1.2);rc(.7,1.3,2.6,.65)
    elif i==1:ln(0,1.2,D,1.2);rc(.95,1.3,.18,.65)
    else:rc(.7,.95,2.6,.18)
   if name=='CTL_DisplayPanel' and i==0:rc(.15,.3,W-.3,H-.6)
   if name=='CTL_Deck' and i==2:
    for k in range(1,8):ln(k*.5,0,k*.5,D)
  # equal-scale dimension baselines (no hidden projection distortions)
  s.line(ox,oy+35,ox+A*scale,oy+35,'s');s.text(ox+10,oy+60,f'{A:g} m; horizontal axis',16);s.text(ox,oy+95,f'Vertical extent {B:g} m',16)
 s.text(50,800,'Dimensions and interfaces govern geometry. AI sheets are separate styling candidates, not measurement authority.',17);s.write(R/(name+'_prebuild_ortho.svg'))
for n,sp in specs.items():module(n,sp)
# Region design projections derive only from plan coordinates, not scratch .blend.
s=Sheet(1800,1250,'CONTROL WING — pre-build architectural projections','SOURCE: analytical 2D geometry from region spec. Common scale 14 px/m. No perspective. Ground datum z=0 m.');k=14
for label,ox,oy,w,h in [('FRONT X/Z',70,350,48,12),('RIGHT Y/Z',1020,350,24,12),('TOP X/Y — roof omitted',70,1000,48,24)]:
 s.text(ox,oy-h*k-30,label,22);s.rect(ox,oy-h*k,w*k,h*k);s.text(ox,oy+30,f'{w} m x {h} m; 14 px/m',16)
 if label.startswith('FRONT'):
  s.rect(ox+23.9*k,oy-4.4*k,4.2*k,4.4*k)
  for x in range(4,48,8):s.line(ox+x*k,oy,ox+x*k,oy-12*k)
 elif label.startswith('RIGHT'):
  s.line(ox,oy-6*k,ox+24*k,oy-6*k,'s')
 else:
  # plan local x=world+24,y=world-38; top view uses +y upwards.
  def rect(x,y,w,h):s.rect(ox+x*k,oy-(y+h)*k,w*k,h*k)
  rect(0,8.2,10,3.6);rect(8.2,10,3.6,12.8);rect(10,19.2,32,3.6);rect(40.2,13.2,3.6,9.6)
  rect(40.5,3,3,10.2)
  for t in range(37):s.line(ox+40.5*k,oy-(3+t*10.2/36)*k,ox+43.5*k,oy-(3+t*10.2/36)*k)
  for x in [17,31]:
   for y in [8,12]:rect(x-1.825,y-.8,3.65,1.6)
  rect(24,8.1,4,1.8);rect(17.5,18.9,13,.4)
  for x in [3,45]:
   for y in [17,20]:rect(x-.7,y-.5,1.4,1)
  s.text(ox+48*k+35,oy-19*k,'Upper gallery z=6; clear width 3.6 m',17)
  s.text(ox+48*k+35,oy-17*k,'Stair: 3 units x rise 2 m; 36 treads total',17)
  s.text(ox+48*k+35,oy-15*k,'South and north ground portals: width4.2 height4.4',17)
  s.text(ox+48*k+35,oy-13*k,'West portal: world (-24,48,6); clear width3.6',17)
s.text(70,1135,'World bounds X[-24,24], Y[38,62]. Entry (2,38,0), north exit(2,62,0), west upper(-24,48,6).',20)
s.text(70,1175,'Manny conservative clearance proxy: height2.1 m, radius0.5 m. Not a UE test.',18);s.write(R/'control_region_prebuild_ortho.svg')
manifest={'created_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'generator':'generate_prebuild_orthographic.py (pure 2D analytic SVG; no model import)','specs':specs,'region':{'bounds':[-24,24,38,62],'entry':[2,38,0],'upper_port':[-24,48,6]},'files':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in R.glob('*prebuild_ortho.svg')},'authoritative':'These exact-scale pre-build projections are dimensional authority. AI candidates have separate provenance; their pixels are not measurement evidence.'};(R/'prebuild_projection_manifest.json').write_text(json.dumps(manifest,indent=2))
