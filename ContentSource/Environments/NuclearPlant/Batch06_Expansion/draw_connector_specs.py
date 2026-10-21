"""Pre-model 2D projection drawings from dimensions; does not load Blender or any mesh."""
import json,pathlib,datetime
R=pathlib.Path(__file__).resolve().parent;O=R/'References'/'Connectors';O.mkdir(exist_ok=True)
# axis conventions x width, y depth, z height; each record is a semantic primitive cuboid.
specs={
'B06_BRIDGE':{'dims':[3.06,6,7.1],'parts':[[0,0,5.84,3,6,.32,'#36434c']]+[[x,y,2.84,.26,.26,5.68,'#36434c'] for x in [-1.3,1.3] for y in [-2.8,2.8]]+[[x,0,z,.055,6,.055,'#36434c'] for x in [-1.5,1.5] for z in [6.15,6.58,7.0725]]+[[x,y,6.55,.06,.06,1.1,'#36434c'] for x in [-1.5,1.5] for y in [-2.97,0,2.97]]+[[x,0,6.4,.035,6,.25,'#8b3430'] for x in [-1.5,1.5]]},
'B06_UTILITY_SHELTER':{'dims':[14,8,4.5],'parts':[[0,0,4.39,14,8,.22,'#36434c'],[0,3.875,2.25,14,.25,4.5,'#b6babc'],[-6.875,0,2.25,.25,8,4.5,'#b6babc'],[6.875,0,2.25,.25,8,4.5,'#b6babc']]},
'B06_SERVICE_BANK':{'dims':[2.8,2.265,3],'parts':[[0,0,1.5,2.8,2.2,3,'#36434c'],[0,-1.11,1.6,2.2,.06,2.3,'#b6babc'],[0,-1.15,2.4,2,.03,.15,'#8b3430']]},
'B06_SCREEN':{'dims':[5,.38,2.3],'parts':[[0,0,1.15,5,.35,2.3,'#b6babc'],[0,0,2.18,5,.38,.18,'#8b3430']]},
'B06_GATE':{'dims':[10.6,.3,5.6],'parts':[[-5.15,0,2.8,.3,.3,5.6,'#36434c'],[5.15,0,2.8,.3,.3,5.6,'#36434c'],[0,0,5.375,10.6,.3,.45,'#8b3430']]},
'B06_FENCE':{'dims':[8.3,.35,2.4],'parts':[[-4,0,1.2,.3,.3,2.4,'#36434c'],[4,0,1.2,.3,.3,2.4,'#36434c'],[0,0,.22,8,.35,.44,'#b6babc']]+[[0,0,z,8,.06,.06,'#36434c'] for z in [.8,1.7,2.3]]}}
for name,s in specs.items():
 out=['<svg xmlns="http://www.w3.org/2000/svg" width="1500" height="1000" viewBox="0 0 1500 1000">','<rect width="1500" height="1000" fill="#f6f5ef"/>',f'<text x="45" y="45" font-family="sans-serif" font-size="26">{name} — PRE-MODEL DIMENSIONAL PROJECTIONS</text>','<text x="45" y="80" font-family="sans-serif" font-size="17">Orthographic axis-drop drawings from spec; NOT AI image and NOT Blender render. Units: m.</text>']
 scale=min(46,510/max(s['dims']));
 for label,axes,base in [('FRONT',(0,2),(330,440)),('RIGHT',(1,2),(1080,440)),('TOP',(0,1),(330,800))]:
  i,j=axes;bx,by=base;labely=125 if label!='TOP' else 575;out.append(f'<text x="{bx-150}" y="{labely}" font-family="sans-serif" font-size="22">{label}</text>')
  for part in s['parts']:
   x,y,z,dx,dy,dz,col=part;cent=[x,y,z];d=[dx,dy,dz];xx=bx+(cent[i]-d[i]/2)*scale;yy=by-(cent[j]+d[j]/2)*scale
   out.append(f'<rect x="{xx}" y="{yy}" width="{max(d[i]*scale,1)}" height="{max(d[j]*scale,1)}" fill="{col}" fill-opacity=".72" stroke="#15252d" stroke-width="1.5"/>')
  out.append(f'<text x="{bx-150}" y="{by+75}" font-family="sans-serif" font-size="17">span {s["dims"][i]} m / height-axis {s["dims"][j]} m</text>')
 out+=['<text x="45" y="960" font-family="sans-serif" font-size="16">Authority: numeric specification. Concept materials: graphite / pale concrete / oxide red. Assembly joints specified in layout.json.</text>','</svg>'];(O/(name+'_technical.svg')).write_text('\n'.join(out))
 try:
  import cairosvg;cairosvg.svg2png(bytestring='\n'.join(out).encode(),write_to=str(O/(name+'_technical.png')))
 except ImportError:pass
(R/'connector_spec.json').write_text(json.dumps({'created_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'type':'pre-model authority','modules':specs},indent=2))
