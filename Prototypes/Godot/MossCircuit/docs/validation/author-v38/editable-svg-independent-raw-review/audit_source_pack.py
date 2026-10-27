from pathlib import Path
import json,hashlib,xml.etree.ElementTree as ET
R=Path('workspace/shared');Q=R/'moss-v38-svg-qa';S=R/'moss-v38-svg-candidate';P=R/'moss-v38-svg-candidate-prep';O=R/'moss-v38-svg-author-review'
h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
j=lambda p:json.loads(p.read_text())
proof={};raw={};helpers=[]
def audit_routes(folder,expected):
 rows=j(folder/'STEPS.json');assert [x['case'] for x in rows]==list(expected)
 for row in rows:
  name=row['case'];a=folder/(name+'.stdout');b=folder/(name+'.stderr');text=a.read_text()+b.read_text();raw[str(a)]=h(a);raw[str(b)]=h(b)
  assert not any(x in text for x in ('ERROR:','instances leaked','resources still in use'))
  reports=[];hs=[]
  for line in a.read_text().splitlines():
   if line.startswith('{'):reports.append(json.loads(line))
   elif line.startswith('TEST_AUDIO_TEARDOWN '):hs.append(json.loads(line.split(' ',1)[1]))
  assert reports==row['reports'] and hs==row['helpers']
  assert row['native_exit']==0 and not row['timeout'] and row['seconds']<180 and row['pass'] and not row['parse_errors']
  n=expected[name]
  if n is None:assert reports==[]
  else:
   assert len(reports)==1 and reports[0].get('failures')==[]
   assert reports[0].get('checks',reports[0].get('passed',reports[0].get('independent_actions_passed')))==n
  assert len(hs)==(1 if name in ('actor','animation') else 0)
  for a in hs:
   z=a['observations'][-1];assert a['complete'] and a['capture_removed'] and not a['prepare_errors']
   assert a['tracked_owner_count']==a['requested_owner_count']>0 and a['tracked_stream_count']>0
   assert z['owners_released'] and z['streams_released'] and z['new_pushed']>=z['required_frames']>0 and z['silent_frames']>=z['required_frames']
   assert 150000<=z['elapsed_us']<=1000000 and all(v['invalid']==v['discarded']==0 for v in a['observations'])
   assert all(a['observations'][i]['new_pushed']<=a['observations'][i+1]['new_pushed'] for i in range(len(a['observations'])-1))
   helpers.append({'case':name,'folder':folder.name,'fresh':z['new_pushed'],'silent':z['silent_frames'],'elapsed_us':z['elapsed_us']})
 return len(rows)
proof['source_commands']=audit_routes(Q/'source-first',{'import':None,'svg-assets':120,'actor':418,'animation':35})
proof['packed_commands']=audit_routes(Q/'packed-first',{'assets':121,'actor':418,'animation':35})
assert (Q/'source-wrapper-exit.txt').read_text().strip()=='0'
assert (Q/'export-wrapper-exit.txt').read_text().strip()=='0'
packed_exit=Q/'packed-wrapper-exit.txt';assert packed_exit.read_text().strip()=='0'
pre=j(P/'INPUTS_PREIMPORT.json');post=j(Q/'source-first/POSTIMPORT_INPUTS.json');final=j(P/'FINAL_INPUTS.json');old=j(R/'moss-v38-final-r2-prep/FINAL_INPUTS.json')
assert len(pre)==783 and len(post)==len(final)==787 and len(old)==772
assert set(post)-set(pre)=={f'art_source/stitch_drone/source/stitch_drone_{k}.svg.import' for k in ('hover','channel','hurt','death')}
assert all(post[k]==v for k,v in pre.items());assert [k for k in final if final[k]!=post[k]]==['MANIFEST.json']
logic={k:v for k,v in old.items() if k.startswith(('scripts/','ui/','data/','scenes/'))};assert all(final[k]==v and h(S/k)==v for k,v in logic.items())
proof['logic_exact_files']=len(logic);proof['final_inputs']=787;proof['final_map_sha256']=h(P/'FINAL_INPUTS.json')
assert proof['final_map_sha256']=='ea4a577c51c98c3d9f6aad4c66a421dd0c00ef2eb705b20ea47cabea9f731401'
assert h(S/'MANIFEST.json')==j(P/'FINAL_FREEZE.json')['manifest_sha256']
sm=j(S/'art_source/stitch_drone/SOURCE_MAP.json');assert len(sm['assets'])==4
for a in sm['assets']:
 svg=S/a['editable_source'];assert h(svg)==a['source_sha256'];root=ET.fromstring(svg.read_bytes());tags={e.tag.split('}')[-1] for e in root.iter()};assert tags<= {'svg','title','desc','g','path','rect'}
 assert not any('href' in k or 'data:image' in v for e in root.iter() for k,v in e.attrib.items());assert h(S/a['runtime_path'])==a['runtime_sha256']
proof['semantic_svg_sheets']=4
B=R/'moss-v38-svg-pack';br=j(B/'BUILD_REPORT.json');steps=j(B/'STEPS.json');assert br['steps']==steps and len(steps)==7 and br['source_inputs']==787
for x in steps:
 log=B/'logs'/(x['step']+'.log');txt=log.read_text();raw[str(log)]=h(log);assert x['exit']==0 and x['pass'] and not x['engine_error'];assert not any(v in txt for v in ('ERROR:','instances leaked','resources still in use'))
assert 'Ran 3 tests' in (B/'logs/python-safety.log').read_text() and 'OK' in (B/'logs/python-safety.log').read_text()
resources=j(B/'packed-resource-report.json');assert resources['failures']==[] and resources['checks']==916 and resources['images']==62 and resources['actions']==28 and resources['action_frames']==308
proof['export_commands']=7;proof['packed_resources']=resources
report={'pass':True,'scope':'Independent read-only raw/JSON/source-phase/semantic-SVG review; no test rerun. Full live787/binary rehash deferred until native CPU lane free. Old full139/ordinary not relabelled for SVG. Native result not included.','proof':proof,'raw_sha256':raw,'strict_helper_observations':helpers,'deferred':['live full787 hashes','PCK/ELF full byte hashes','new controlled native outcome']}
(O/'SOURCE_PACK_RAW_REVIEW.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps({'pass':True,'proof':proof,'helpers':len(helpers),'raw_files':len(raw)}))
