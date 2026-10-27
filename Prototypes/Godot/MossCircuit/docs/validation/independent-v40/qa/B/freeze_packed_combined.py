from pathlib import Path
import json,hashlib,ast
R=Path('workspace/shared');q=R/'moss-v39-B-qa';h=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest();j=lambda p:json.loads(p.read_text());pack=R/'moss-v39-B-equipment16-pack';src=R/'moss-v39-B-equipment16';source_map=R/'moss-v39-items/B-equipment16-combination/assembly-first/INPUTS.json';harness=q/'packed-harness';assert h(source_map)=='543d43c875b72b7682c312a4811094007e679c419d2142aa86c0d59728b57440'
source=j(source_map);assert len(source)==926;build=j(pack/'BUILD_REPORT.json');assert build['pass'] and build['source_inputs']==926
review=R/'moss-v39-prep/B_COMBINED_EXPORT_RAW_REVIEW.json';assert j(review)['review_pass']
original=j(R/'moss-v39-qa/PACKED_HARNESS_FREEZE.json')['bindings'];bindings=[];vectorfiles=[]
def source_vector(name,field='observations'):
 for base in ['source','source-continue']:
  path=R/'moss-v39-items/B-full-evidence'/base/'raw-first'/name/'RESULT.json'
  if path.exists():
   d=j(path);assert d['pass'] and len(d['reports'])==1 and isinstance(d['reports'][0][field],list);vectorfiles.append(path);return {'path':str(path),'selection':['reports',0,field],'field':field}
 raise AssertionError(name)
for b in original:
 name=b['case'];row={'name':name,'script':str(harness/(name+'.gd')),'checks':b['expected_checks'],'helper_owners':1 if b['helper_required'] else 0,'observations':b['observations']}
 if name in ['geometry','policy','runtime','lifecycle','motion']:row['vector']=source_vector('tests__independent_new_weapon_'+name)
 if name.startswith('audio-'):
  names={'audio-mixer':'tests__independent_feedback_mixer','audio-views':'tests__independent_feedback_views','audio-arena':'tests__independent_feedback_authority','audio-rooms':'tests__independent_feedback_authority_rooms'};row.update(write_report=True,policy=names[name],args=['{REPORT}'])
  if name=='audio-mixer':row['args'].append('{PCM}')
  else:
   route=names[name];base='source' if name=='audio-arena' else 'source-continue';file=R/'moss-v39-items/B-full-evidence'/base/'raw-first'/route/'report.json';assert file.exists();vectorfiles.append(file);row['vector']={'path':str(file),'selection':['samples' if name=='audio-views' else 'observations'],'field':'samples' if name=='audio-views' else 'observations'}
 if name=='A7-assets':row.update(write_report=True,args=[str(harness/'A7_RAW_SOURCE_ORACLE.json'),'{ORACLE}','{REPORT}'])
 bindings.append(row)
for name,checks,obs,key in [('B-pin-ring',126,14,'independent_B_pin_ring_checks'),('B-real-hooks',62,2,'independent_B_real_hook_checks'),('B-ui20',20,None,'checks'),('B-icons201',201,3,'checks'),('atlas240',240,21,'checks')]:
 row={'name':name,'script':str(harness/(name+'.gd')),'checks':checks,'count_key':key,'observations':obs,'helper_owners':1 if name in ['B-pin-ring','B-real-hooks'] else 0}
 if name in ['B-pin-ring','B-real-hooks']:
  old=j(R/'moss-v39-items/B-full-evidence/source/PLAN.json')['routes'];route=next(x for x in old if x['marker']['kind']=='json' and key in x['marker']['counts']);row['vector']=source_vector(route['name'])
 if name in ['B-icons201','atlas240']:
  route='actual_B201' if name=='B-icons201' else 'actual_atlas240';f=R/'moss-v39-items/B-equipment16-combination/source-gates/raw-first'/route/'report.json';vectorfiles.append(f);row.update(write_report=True,args=[str(harness/('EXPECTED_46.json' if name=='B-icons201' else 'EXPECTED_21.json')),'{REPORT}'],vector={'path':str(f),'selection':['observations'],'field':'observations'})
 bindings.append(row)
assert len(bindings)==16
files=[q/'run_packed_combined.py',q/'packed-report-policy.py',q/'PACKED_REPORT_POLICIES.json',source_map,review,q/'B_SOURCE_COMBINATION_RAW_REVIEW.json',q/'B_COMBINED_SOURCE_RAW_REVIEW.json',R/'moss-v39-prep/B_COMBINED_SOURCE_RAW_REVIEW.json',R/'moss-v39-items/B-full-evidence/report-schema-review/PYTHON_NEGATIVES.json',R/'moss-v39-items/B-full-evidence/report-schema-review/POLICIES.json',R/'moss-v39-items/B-full-evidence/report-schema-review/report_policy.py']+list(harness.iterdir())+vectorfiles+[pack/n for n in ['BUILD_REPORT.json','STEPS.json','source-imported-fingerprints.json','packed-resource-report.json']]
bindingsdoc=j(harness/'BINDINGS.json')
for b in bindingsdoc['bindings']:files.append(Path(b['source']));assert h(Path(b['source']))==b['source_sha256'] and h(Path(b['bound']))==b['bound_sha256']
for b in bindingsdoc['support']:files.append(Path(b['source']));assert h(Path(b['source']))==b['sha256']
ps={str(p):h(p) for p in files if p.is_file()}
for rel,value in build['files'].items():ps[str(pack/rel)]=value['sha256']
svglog=R/'moss-v39-qa/packed-first/packed-svg.stdout';ps[str(svglog)]=h(svglog);svg=[json.loads(x) for x in svglog.read_text().splitlines() if x.startswith('{')];assert len(svg)==1
prereq=[{'path':str(q/'B_SOURCE_COMBINATION_RAW_REVIEW.json'),'required_true':['review_pass','source_combination_pass']},{'path':str(q/'B_COMBINED_SOURCE_RAW_REVIEW.json'),'required_true':['review_pass','exact_before_after926']},{'path':str(review),'required_true':['review_pass']},{'path':str(R/'moss-v39-items/B-full-evidence/report-schema-review/PYTHON_NEGATIVES.json'),'required_true':['pass']}]
plan={'status':'FROZEN_PENDING_STATIC_ACCEPTANCE_NO_LEASE','source':str(src),'source_map':str(source_map),'source_map_sha256':h(source_map),'pack_root':str(pack),'pck_sha256':build['files']['linux/MossCircuit.pck']['sha256'],'pck_bytes':build['files']['linux/MossCircuit.pck']['bytes'],'pins':ps,'preconditions':prereq,'bindings':bindings,'accepted_svg_report':svg[0],'commands':22,'per_command_seconds':180,'audio_partition':'Arena435 + Rooms338 each180 total360, not single180','resources':{'checks':998,'exact_files':84,'images':72,'actions':28,'action_frames':308},'scope':'OriginalA17 finite roles + B126/62/UI20/201 + acceptedatlas240. Exact external bindings only, except A7 detached strict B-only catalog count scope; runtime actualB unmodified. Source35+435+129 remains a combination; fresh combined cold201/240 accepted separately. No native or ordinary acceptance.'}
p=q/'PACKED_COMBINED_PLAN.json';assert not p.exists();p.write_text(json.dumps(plan,indent=2)+'\n');ast.parse((q/'run_packed_combined.py').read_text());print('plan',h(p),'pins',len(ps),'bindings',len(bindings),'PCK',plan['pck_sha256'])
