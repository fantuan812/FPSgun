from pathlib import Path
import json,hashlib,datetime,html
from PIL import Image,ImageDraw,ImageFont
R=Path(__file__).resolve().parent.parent
required=['site_refined.blend','ALL_MODULES.json','Config/design_v04.json','QA/build_record.json','QA/static_geometry.json','QA/rebuild_verification.json']
views=['site_overview','site_cutaway','core_entry','pump_eye','logistics_eye','module_gallery','before_site_overview','before_logistics_eye']
required += ['renders/'+n+'.png' for n in views]
mods=json.loads((R/'ALL_MODULES.json').read_text())
for m in mods:required += [m['blend'],'Exports/'+m['module_id']+'.glb']
required += ['Assets/B07_SERVICE_CABINET_narrow_045.blend','Exports/B07_SERVICE_CABINET_narrow_045.glb','QA/render_provenance.json','QA/before_render_provenance.json','QA/visual_review.md']
for f in required:
 if not (R/f).is_file():raise RuntimeError('Missing delivery artifact: '+f)
for freeze in ['reference_freeze.json','reference_freeze_v02.json','reference_freeze_v03.json','reference_freeze_v04.json']:
 d=json.loads((R/'QA'/freeze).read_text())
 for fn,sha in d['inputs'].items():
  assert hashlib.sha256((R/fn).read_bytes()).hexdigest()==sha,fn
provenance=json.loads((R/'QA/render_provenance.json').read_text());scene_sha=hashlib.sha256((R/'site_refined.blend').read_bytes()).hexdigest()
for n in views:
 if not n.startswith('before_'):
  assert provenance[n]['scene_sha256']==scene_sha,('stale render scene',n)
  assert provenance[n]['image_sha256']==hashlib.sha256((R/'renders'/f'{n}.png').read_bytes()).hexdigest(),('stale render image',n)
before_provenance=json.loads((R/'QA/before_render_provenance.json').read_text())
for n in views:
 if n.startswith('before_'):
  assert before_provenance[n]['image_sha256']==hashlib.sha256((R/'renders'/f'{n}.png').read_bytes()).hexdigest()
  assert before_provenance[n]['scene_sha256']==hashlib.sha256((R.parent/'Batch06_Expansion/site_expansion.blend').read_bytes()).hexdigest()
assert 'PENDING' not in (R/'QA/visual_review.md').read_text()
imgs={}
for n in views:
 with Image.open(R/'renders'/f'{n}.png') as im:
  im.verify()
 with Image.open(R/'renders'/f'{n}.png') as im:imgs[n]={'width':im.width,'height':im.height,'sha256':hashlib.sha256((R/'renders'/f'{n}.png').read_bytes()).hexdigest()}
# Side-by-side proof plates use actual matched-camera renders, not generated edits.
font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',24)
for name in ['site_overview','logistics_eye']:
 a=Image.open(R/'renders'/('before_'+name+'.png')).convert('RGB');b=Image.open(R/'renders'/(name+'.png')).convert('RGB');a=a.resize((800,500));b=b.resize((800,500));im=Image.new('RGB',(1600,550),'#182129');im.paste(a,(0,50));im.paste(b,(800,50));dr=ImageDraw.Draw(im);dr.text((20,12),'BEFORE / BATCH 06',font=font,fill='white');dr.text((820,12),'AFTER / BATCH 07',font=font,fill='white');im.save(R/'renders'/('comparison_'+name+'.png'))
qa=json.loads((R/'QA/static_geometry.json').read_text());rb=json.loads((R/'QA/rebuild_verification.json').read_text());build=json.loads((R/'QA/build_record.json').read_text())
assert rb['passed'];assert build['baseline_unchanged'];assert not build['protected_geometry_changes'];assert build['render_camera_sha256']==hashlib.sha256((R/'Config/render_cameras.json').read_bytes()).hexdigest()
summary={'units':'metres','seed':7021,'base_commit':'74249eb5b9c656e16f9c1e932a10e851f3e11a32','source_baseline':'../Batch06_Expansion/site_expansion.blend','baseline_sha256':build['baseline_sha256'],'scene':'site_refined.blend','active_design':'Config/design_v04.json','module_count':len(mods),'derived_variant_count':1,'variant_assets':['Assets/B07_SERVICE_CABINET_narrow_045.blend'],'camera_config':'Config/render_cameras.json','placement_count':len(build['placements']),'modified_yards':12,'regions':['core_skin','east_pump_yards','southwest_logistics'],'reference_chain':['QA/reference_freeze.json','QA/reference_freeze_v02.json','QA/reference_freeze_v03.json','QA/reference_freeze_v04.json'],'images':imgs,'rebuild_verified':rb['passed'],'unchanged_protected_baseline_objects':build['preserved_objects'],'new_geometry_route_interference':{k:len(v['new_geometry_issues']) for k,v in qa['route_tests'].items()},'static_occlusion':{},'not_verified':['UE runtime','official Manny mesh or skeleton','navmesh','swept capsule','ballistic protection'],'legacy_limit':'Six existing upper trim edge ray contacts retained; see QA/legacy_touchpoints.json. Coplanar roads show Cycles artifacts; final / before renders use baseline EEVEE.'}
for key in ['ground_excluding_open_rack','rising_9degree_excluding_open_rack']:
 q=qa['line_of_sight'][key];summary['static_occlusion'][key]={'rays':q['rays'],'before_near_occluded':q['before_near_occluded'],'after_near_occluded':q['after_near_occluded'],'lost':sum(len(x['lost_near_occlusion_directions']) for x in q['changed_witnesses']),'gained':sum(len(x['gained_near_occlusion_directions']) for x in q['changed_witnesses'])}
summary['artifacts']=[{'path':str(f.relative_to(R)),'bytes':f.stat().st_size,'sha256':hashlib.sha256(f.read_bytes()).hexdigest()} for f in sorted(R.rglob('*')) if f.is_file() and '__pycache__' not in str(f) and not f.name.endswith('.blend1') and f.name not in ['SHA256SUMS','batch_manifest.json','index.html']]
(R/'batch_manifest.json').write_text(json.dumps(summary,indent=2));(R/'SHA256SUMS').write_text('\n'.join(x['sha256']+'  '+x['path'] for x in summary['artifacts'])+'\n')
css='body{background:#121b22;color:#d7dfdf;font:16px system-ui;max-width:1400px;margin:32px auto;padding:0 24px}a{color:#d9b56f}h1{font-size:40px}img{max-width:100%;display:block;background:#25343b}section{margin:36px 0}.grid{display:grid;grid-template-columns:repeat(2,1fr);gap:20px}.small{color:#97a8af}code{color:#d9b56f}'
parts=['<!doctype html><meta charset="utf-8"><title>Batch07 — Industrial refinement</title><style>'+css+'</style><h1>BATCH 07 / INDUSTRIAL REFINEMENT</h1><p>7 modules · 3 regions · 12 bounded yard refinements · full cumulative scene</p><p><a href="site_refined.blend">Complete Blender scene</a> · <a href="README.zh-CN.md">中文说明</a> · <a href="batch_manifest.json">Manifest / hashes</a></p>']
for name in ['comparison_site_overview','site_overview','site_cutaway','comparison_logistics_eye','core_entry','pump_eye','logistics_eye','module_gallery']:
 parts+=['<section><h2>'+html.escape(name.replace('_',' ').upper())+'</h2><a href="renders/'+name+'.png"><img src="renders/'+name+'.png"></a></section>']
parts+=['<h2>MODULES / REFERENCE-BEFORE-MODEL CHAIN</h2><div class="grid">']
for m in mods:parts+=['<section><h3>'+m['module_id']+'</h3><img src="'+m['reference'].replace('.svg','.png')+'"><p><a href="'+m['blend']+'">BLEND</a> · <a href="Exports/'+m['module_id']+'.glb">GLB</a> · <a href="'+m['reference']+'">Pre-model orthographic SVG</a></p></section>']
parts+=['<section><h3>07a / NARROW CABINET VARIANT</h3><img src="References/v04/B07_SERVICE_CABINET_narrow_045.png"><p><a href="Assets/B07_SERVICE_CABINET_narrow_045.blend">BLEND</a> · <a href="Exports/B07_SERVICE_CABINET_narrow_045.glb">GLB</a></p></section>']
parts+=['</div><p class="small">Static Blender only. Open pipe racks excluded from cover comparison. No UE runtime or official Manny validation.</p>'];(R/'index.html').write_text('\n'.join(parts))
print('DELIVERY_READY',len(summary['artifacts']),len(mods),summary['static_occlusion'])
