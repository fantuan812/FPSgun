#!/usr/bin/env python3
"""Original semantic vector drawing. No image reads, tracing, or raster embedding.
Edit PALETTE and POSES, then regenerate SVGs; SVG groups remain independently editable.
"""
import json, pathlib
ROOT=pathlib.Path(__file__).resolve().parents[1]
PALETTE=dict(ink='#18242c',shade='#37434a',copper='#a76535',gold='#dda854',light='#f5d691',core='#138f9d',cyan='#60dce0',white='#d0fff0',moss='#6a7d4a',dead='#44595b')
POSES={
'hover':dict(bob=[0,-1,-2,-1,0,1,2,1,0],tilt=[0,-1,-2,-1,0,1,2,1,0],arm=[0,1,2,1,0,-1,-2,-1,0]),
'channel':dict(bob=[0,-1,-1,-2,-2,-2,-1,0,1],tilt=[0,0,0,0,0,0,-2,0,0],arm=[0,-2,-4,-6,-8,-10,-12,-5,0]),
'hurt':dict(bob=[0,0,1,2,1,0,-1,0,0],tilt=[0,8,12,9,5,-3,-2,1,0],arm=[0,2,4,3,2,0,-1,0,0]),
'death':dict(bob=[0,1,2,3,4,5,6,6,6],tilt=[0,8,18,35,60,78,80,81,82],arm=[0,3,5,8,12,16,18,19,20])}
def rect(x,y,w,h,fill,extra=''):return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{PALETTE.get(fill,fill)}" {extra}/>'
def path(d,fill,extra=''):return f'<path d="{d}" fill="{PALETTE.get(fill,fill)}" {extra}/>'
def group(id,s,transform=''):return f'<g id="{id}"'+(f' transform="{transform}"' if transform else '')+'>'+s+'</g>'
def sprite(kind,i):
 p=POSES[kind];dy=p['bob'][i];tilt=p['tilt'][i];arm=p['arm'][i];dead=kind=='death' and i>=5
 prefix=f'{kind}-{i}-';parts=[]
 # independent thread antennae and two brass sewing needles
 threads=path('M28 8 L29 16 L34 21 L40 18 L45 22 L49 20','none',f'stroke="{PALETTE["dead" if dead else "core"]}" stroke-width="1.5"')
 threads+=path('M40 10 L41 16 L47 21 L50 27','none',f'stroke="{PALETTE["dead" if dead else "cyan"]}" stroke-width="1"')
 needles=path('M24 22 L25 12 L29 4 L32 3 L30 8 L28 15 L28 22 Z','gold')+path('M34 22 L36 15 L42 8 L45 8 L43 12 L39 16 L38 22 Z','copper')
 needles+=path('M28 7 L30 5 M41 11 L43 10','none',f'stroke="{PALETTE["ink"]}" stroke-width="1.2"')
 parts+=[group(prefix+'threads',threads),group(prefix+'needles',needles)]
 # far articulated clamp arm
 a=rect(42,32,4,6,'shade')+path('M45 34 L50 37 L49 44 L44 47 L42 44 L46 41 L47 38 L44 37 Z','gold')+rect(46,37,2,3,'cyan' if not dead else 'dead')
 parts.append(group(prefix+'far-arm',a,f'rotate({-arm} 44 34)'))
 # coil drum: thick flanges, stepped cylinder, individually editable winding bars
 body=path('M23 22 L39 22 L44 25 L44 41 L39 46 L23 46 L19 42 L19 26 Z','ink')+rect(24,26,17,15,'core' if not dead else 'dead')
 for n in range(5):body+=path(f'M24 {28+n*2.5} L39 {26+n*2.5} L41 {28+n*2.5} L26 {30+n*2.5} Z','cyan' if not dead else 'shade')
 body+=rect(22,26,3,16,'copper')+rect(39,26,3,16,'shade')
 body+=path('M21 21 L39 21 L44 24 L44 27 L39 29 L22 28 L18 25 L18 23 Z','gold')+path('M21 21 L39 21 L41 23 L38 25 L23 25 L20 23 Z','shade')+rect(23,22,14,1,'light')
 body+=path('M20 40 L24 42 L40 42 L44 40 L44 44 L40 47 L23 46 L20 44 Z','copper')+path('M21 40 L25 42 L40 42 L43 40 L43 43 L39 45 L24 44 L21 43 Z','gold')
 parts.append(group(prefix+'spool-shell',body))
 # left-facing sensor eye, no bright living eye in final collapse
 eye=path('M18 28 L23 27 L27 30 L27 35 L23 38 L18 37 L15 34 L15 30 Z','copper')+rect(17,29,7,7,'ink')+rect(18,30,5,5,'dead' if dead else 'cyan')
 if not dead:eye+=rect(18,30,2,3,'white')
 parts.append(group(prefix+'sensor-eye',eye))
 front=rect(18,38,5,3,'shade')+path('M18 38 L15 39 L13 44 L14 48 L17 50 L19 47 L17 45 L18 42 L21 41 Z','ink')+path('M15 40 L18 39 L18 42 L15 45 L13 44 Z','gold')+path('M16 46 L17 48 L18 46','none',f'stroke="{PALETTE["copper"]}" stroke-width="1"')
 parts.append(group(prefix+'near-clamp',front,f'rotate({arm} 21 39)'))
 nozzle=rect(27,46,10,3,'ink')+rect(29,48,6,2,'gold')
 if not dead:
  height=(9+[0,1,2,1,0,-1,-2,-1,0][i]) if kind!='death' else max(2,9-i)
  nozzle+=path(f'M29 50 L35 50 L36 54 L32 {50+height} L28 54 Z','core')+path(f'M30 50 L34 50 L34 54 L32 {48+height} L30 54 Z','cyan')+rect(31,52,2,3,'white')
 parts.append(group(prefix+'thruster',nozzle))
 if kind=='channel' and 2<=i<=6:
  energy=path('M15 43 L21 44 L25 42 L29 45 L35 43 L40 45 L46 42','none',f'stroke="{PALETTE["cyan"]}" stroke-width="{1 if i<6 else 2}"')
  if i==6:energy+=path('M13 38 L15 42 L19 43 L15 44 L13 48 L12 44 L8 43 L12 42 Z','white')
  parts.append(group(prefix+'channel-energy',energy))
 if kind=='hurt' and 1<=i<=5:
  parts.append(group(prefix+'impact-sparks',rect(11,27,2,2,'cyan')+rect(47,31,2,2,'cyan')+rect(16,52,2,2,'white')))
 content=group(prefix+'pose',''.join(parts),f'translate(0 {dy}) rotate({tilt} 32 37)')
 if kind=='death' and i>=4:
  debris=rect(18,59,4,2,'copper')+rect(43,59,3,2,'shade')+rect(22,57,2,2,'gold')
  content+=group(prefix+'debris',debris)
 return content

def generate():
 for kind in POSES:
  cells=[]
  for i in range(9):cells.append(group(f'frame-{i}',sprite(kind,i),f'translate({i%3*418+17} {i//3*418+17}) scale(6)'))
  svg='<svg xmlns="http://www.w3.org/2000/svg" width="1254" height="1254" viewBox="0 0 1254 1254"><title>Stitch Drone original editable '+kind+' sheet</title><desc>Hand-authored semantic geometry. Frame order row-major0..8. No embedded raster.</desc>'+''.join(cells)+'</svg>'
  (ROOT/'source'/f'stitch_drone_{kind}.svg').write_text(svg)
 (ROOT/'source'/'palette_and_poses.json').write_text(json.dumps(dict(palette=PALETTE,poses=POSES),indent=2)+'\n')
if __name__=='__main__':generate()
