import pathlib,json,hashlib,subprocess,os,xml.etree.ElementTree as E
from PIL import Image
r=pathlib.Path('<WORKSPACE>/moss-v38-svg-redraw');o=pathlib.Path(__file__).parent
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
measured=json.loads((r/'metadata/measured_assets.json').read_text())['records'];actions=json.loads((r/'metadata/action_manifest.json').read_text())['actions'];hover=json.loads((r/'metadata/enemy_manifest_entry.json').read_text())['stitch_drone']
rows=[]
for kind in ['hover','channel','hurt','death']:
 s=r/'source'/f'stitch_drone_{kind}.svg';p=r/'exports'/f'stitch_drone_{kind}.png';root=E.parse(s).getroot();tags={e.tag.split('}')[-1] for e in root.iter()};assert tags <= {'svg','title','desc','g','path','rect'};assert root.attrib['viewBox']=='0 0 1254 1254'
 ids=[e.get('id') for e in root.iter() if e.get('id')];assert len(ids)==len(set(ids));assert all('frame-'+str(i) in ids for i in range(9))
 for e in root.iter():
  for k,v in e.attrib.items():assert not any(x in v.lower() for x in ['data:','http:','https:','url(']) and not k.lower().endswith('href')
 im=Image.open(p).convert('RGBA');assert im.size==(1254,1254);frames=[]
 for i in range(9):
  x,y=i%3*418,i//3*418;c=im.crop((x,y,x+418,y+418));a=c.getchannel('A');b=a.point(lambda v:255 if v>=8 else 0).getbbox();l,t,rr,bb=b;w,h=rr-l,bb-t;assert min(l,t,418-rr,418-bb)>0
  assert measured[kind]['frames'][i]['alpha_bbox']==[l,t,w,h]
  m=hover['frames'][i] if kind=='hover' else actions['stitch_drone_'+kind]['frames'][i]
  if kind=='hover':assert m['region']==[x,y,418,418] and m['alpha_bbox']==[l,t,w,h]
  else:
   assert m['region']==[x+l,y+t,w,h] and m['margin']==[(418-w)//2,398-h,418-w,418-h]
   assert actions['stitch_drone_'+kind]['anchor']==[.5,398/418] and actions['stitch_drone_'+kind]['reference_height']==336
  frames.append({'alpha8_bbox':[l,t,w,h],'minimum_border':min(l,t,418-rr,418-bb)})
 fresh=[]
 for n in [1,2]:
  out=o/f'{kind}-independent-{n}.png';z=subprocess.run(['inkscape',str(s),'--export-type=png','--export-filename='+str(out)],capture_output=True,env=dict(os.environ,INKSCAPE_PROFILE_DIR=str(o/'profile')),timeout=60);(o/f'{kind}-{n}.log').write_bytes(z.stdout+z.stderr);assert z.returncode==0;assert out.read_bytes()==p.read_bytes();fresh.append(sha(out))
 rows.append({'kind':kind,'svg_sha256':sha(s),'png_sha256':sha(p),'fresh_export_sha256':fresh,'allowed_tags':sorted(tags),'frames':frames})
assert rows[0]['frames'][0]['alpha8_bbox'][3]==336
out={'pass':True,'scope':'Independent staging XML, semantic groups, alpha8 geometry/manifests and two fresh exports per SVG. Not Godot/PCK/native acceptance.','sheets':4,'cells':36,'fresh_exports':8,'rows':rows,'visual':'Directly viewed 36-frame runtime-nearest contact sheet; distinct channel, hurt tilt and dark collapsed death final frames. Native remains pending.'}
(o/'STAGING_REVIEW.json').write_text(json.dumps(out,indent=2)+'\n');print(json.dumps({'pass':True,'sheets':4,'cells':36,'fresh_exports':8}))
