from pathlib import Path
import json,hashlib,copy
from report_policy import classify
q=Path(__file__).parent;old=Path('evidence-workspace/moss-v39-prep/final-full/full-first/aggregate');h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()

def tree(value, key=''):
 if isinstance(value,dict):return {'kind':'dict','fields':{k:tree(v,k) for k,v in value.items()}}
 if isinstance(value,list):return {'kind':'list','items':[tree(v,key) for v in value]}
 if type(value) is bool:return {'kind':'bool'}
 if type(value) in (int,float):
  integer_keys={'index','frames','fresh_pushed_frames','queued_frames_at_start','pushed_before','pushed_after','discarded_before','discarded_after','nonfinite','nonzero_scalars','compared_frames','first_expected','first_observed','lag_frames','buffer_frames','explicit_stop_all_calls_during_controller','positive_control_stop_delta','stop_calls_through_snapshot'}
  return {'kind':'int' if key in integer_keys or key.endswith('_us') else 'number'}
 if isinstance(value,str) and ('sha256' in key):return {'kind':'hex64'}
 return {'kind':'literal','value':value}
def first_numeric(value,path=()):
 if type(value) in (int,float):return path
 if isinstance(value,dict):
  for k,v in value.items():
   found=first_numeric(v,path+(k,))
   if found is not None:return found
 if isinstance(value,list):
  for k,v in enumerate(value):
   found=first_numeric(v,path+(k,))
   if found is not None:return found
 return None
def replace_at(value,path,replacement):
 cursor=value
 for key in path[:-1]:cursor=cursor[key]
 cursor[path[-1]]=replacement

policy={};sources={};tests=[]
specs=[('tests__independent_feedback_authority',435,'summary_with_details',{'observations':36}),('tests__independent_feedback_authority_rooms',338,'summary_with_details',{'observations':36}),('tests__independent_feedback_mixer',236,'mixer',{'windows':51,'shapes':5}),('tests__independent_feedback_views',168,'summary_with_details',{'samples':8}),('tests__independent_settlement_types',1164,'exact',{'audio_observations':204}),('independent_B_icons',201,'exact',{'observations':3})]
for name,count,kind,collections in specs:
 if name=='independent_B_icons':
  f=Path('evidence-workspace/moss-v39-items/B-full-evidence/source/raw-first/independent_B_icons/report.json');log=f.parent/'stdout.raw'
 else:
  stem=name.removeprefix('tests__');f=old/(stem+'.json');log=old/(stem+'.gd.log')
 full=json.loads(f.read_text());summaries=[json.loads(l) for l in log.read_text().splitlines() if l.startswith('{')];assert len(summaries)==1;summary=summaries[0]
 assert full['checks']==count
 exact={}
 if kind=='mixer':exact={'status':'PASS','driver':'Dummy'}
 if name=='tests__independent_settlement_types':exact={'invalid_decisions':102,'audio_scope':full['audio_scope']}
 p={'kind':kind,'checks':count,'summary_keys':sorted(summary),'full_keys':sorted(full),'shared_keys':['checks','failures'],'scope':full['scope'],'collections':collections,'exact_fields':exact}
 if name=='independent_B_icons':
  # Schema literals from independently frozen probe, not generated from runtime output.
  p['summary_keys']=['checks','failures','observations','scope'];p['full_keys']=p['summary_keys'].copy()
  p['scope']='actual46 UI resource binding/loading plus B3 independent visible RGBA; no native layer/ordinary claim'
  probe=Path('evidence-workspace/moss-v39-B-qa/assets/independent_B_icons.gd');sources[str(probe)]=h(probe)
 p['detail_trees']={key:tree(full[key]) for key in collections}
 if kind=='mixer':
  p['detail_trees']['engine']=tree(full['engine']);p['detail_trees']['node_gains']=tree(full['node_gains'])
 if name=='independent_B_icons':
  expected_path=Path('evidence-workspace/moss-v39-B-qa/assets/EXPECTED.json');expected=json.loads(expected_path.read_text());sources[str(expected_path)]=h(expected_path)
  rows=[]
  for id in sorted(expected['new']):
   e=expected['new'][id];rows.append({'id':id,'raw_rgba_sha256':'0'*64,'source_png_rgba_sha256':e['rgba_sha256'],'visible_rgba_sha256':e['visible_rgba_sha256'],'alpha_sha256':e['alpha_sha256'],'atlas':expected['icons'][id]['atlas']})
  p['detail_trees']['observations']=tree(rows)
  for schema,row in zip(p['detail_trees']['observations']['items'],rows):
   for key in ['source_png_rgba_sha256','visible_rgba_sha256','alpha_sha256']:schema['fields'][key]={'kind':'literal','value':row[key]}
 policy[name]=p;sources[str(f)]=h(f);sources[str(log)]=h(log)
 cases=[('valid',summary,full,True)]
 a=copy.deepcopy(full);a.pop('scope');cases.append(('missing_scope',summary,a,False))
 a=copy.deepcopy(full);a['scope']=[];cases.append(('scope_type',summary,a,False))
 a=copy.deepcopy(full);a['scope']+=' altered';cases.append(('scope_conflict',summary,a,False))
 a=copy.deepcopy(full);a['extra']=1;cases.append(('extra_key',summary,a,False))
 a=copy.deepcopy(full);a['checks']+=1;cases.append(('shared_count_conflict',summary,a,False))
 a=copy.deepcopy(full);a['failures']=['error'];cases.append(('failure',summary,a,False))
 for key in collections:
  a=copy.deepcopy(full);a[key]='x'*collections[key];cases.append((key+'_wrongtype',summary,a,False))
  a=copy.deepcopy(full);a[key][0]='bad';cases.append((key+'_element',summary,a,False))
  a=copy.deepcopy(full);a[key].pop();cases.append((key+'_length',summary,a,False))
 for key in collections:
  a=copy.deepcopy(full);a[key][0]={};cases.append((key+'_emptydict',summary,a,False))
  a=copy.deepcopy(full);first=next(iter(a[key][0]));del a[key][0][first];cases.append((key+'_missingfield',summary,a,False))
  a=copy.deepcopy(full);first=next(iter(a[key][0]));a[key][0][first]=[];cases.append((key+'_nestedtype',summary,a,False))
  numeric=first_numeric(full[key])
  if numeric is not None:
   a=copy.deepcopy(full);replace_at(a[key],numeric,float('nan'));cases.append((key+'_NAN',summary,a,False))
 if kind=='mixer':
  a=copy.deepcopy(full);a['engine']['wrong']=a['engine'].pop(next(iter(a['engine'])));cases.append(('engine_same_length_wrongkey',summary,a,False))
  a=copy.deepcopy(full);a['node_gains']['wrong']=a['node_gains'].pop(next(iter(a['node_gains'])));cases.append(('gain_same_length_wrongkey',summary,a,False))
  for value in [True,float('inf'),-1.0]:
   a=copy.deepcopy(summary);a['seconds']=value;cases.append(('seconds_'+str(value),a,full,False))
 for label,s,f,expected in cases:
  actual=classify(s,f,p)['accepted'];tests.append({'route':name,'case':label,'expected':expected,'actual':actual,'pass':actual==expected})
assert all(t['pass'] for t in tests)
(q/'POLICIES.json').write_text(json.dumps({'policies':policy,'source_evidence_pins':sources,'scope':'Literal frozen prior-authority schema plus independent201 probe; not target gameplay expected regeneration'},indent=2)+'\n')
(q/'PYTHON_NEGATIVES.json').write_text(json.dumps({'pass':True,'checks':len(tests),'tests':tests,'policy_sha256':h(q/'POLICIES.json'),'classifier_sha256':h(q/'report_policy.py'),'scope':'pure Python only; does not rerun or relabel original36STOPFAIL'},indent=2)+'\n');print(len(tests),'pure Python schema predicates PASS')
