"""v04 pre-model local-ground crossing revision; no old ground or other parts changed."""
import json,pathlib,copy
R=pathlib.Path(__file__).resolve().parent.parent
C=json.loads((R/'Config/design_v03.json').read_text());C['revision']='v04'
for mid,m in C['modules'].items():m['reference']='References/v03/'+mid+'.png'
C['modules']['B08_SERVICE_EDGE_FLUSH']['title']='Service edge / low-step crossing cover'
C['modules']['B08_SERVICE_EDGE_FLUSH']['notes']=['Nominal 4.0 x 0.60m; local mesh top +0.027m. Place against actual old ground using the frozen v04 station profile, not world zero.','Low-step cover, not an absolutely flush surface and not a UE traversal acceptance.']
G=[]
def group(id,rn,index,axis,segments,end_ground):
 G.append({'id':id,'region':rn,'original_v03_placement_index':index,'axis':axis,'segments':[{'min':a,'max':b,'old_ground_z':g,'cover_top_z':z,'relative_top_m':round(z-g,6)} for a,b,g,z in segments],'old_ground_at_external_ends':end_ground,'internal_top_steps_m':[round(abs(segments[i+1][3]-segments[i][3]),6) for i in range(len(segments)-1)],'external_end_steps_m':[round(abs(segments[0][3]-end_ground[0]),6),round(abs(segments[-1][3]-end_ground[1]),6)]})
group('E07','east_service_link',7,'Y',[(-16,-8,-.05,-.023)],[-.05,0])
group('E08','east_service_link',8,'Y',[(4,8,0,.027)],[0,0])
group('E09','east_service_link',9,'Y',[(8,12,0,.027)],[0,0])
group('E10','east_service_link',10,'X',[(44.5,46,-.05,-.023),(46,48,-.015,-.005),(48,49,0,.010)],[-.05,0])
for index,x in [(19,-56),(21,-38),(23,-20)]:group('SW'+str(index),'southwest_receiving',index,'Y',[(-38.88,-38,0,.010),(-38,-36,-.015,-.005)],[0,-.015])
for rn,r in C['regions'].items():
 out=[]
 for i,p in enumerate(r['placements']):
  g=next((g for g in G if g['region']==rn and g['original_v03_placement_index']==i),None)
  if not g:out.append(p);continue
  for j,s in enumerate(g['segments']):
   q=copy.deepcopy(p);q['position'][0 if g['axis']=='X' else 1]=(s['min']+s['max'])/2;q['position'][2]=round(s['cover_top_z']-.027,6);q['scale'][0]=(s['max']-s['min'])/4;q['crossing_group']=g['id'];q['segment_index']=j;q['old_ground_z']=s['old_ground_z'];q['relative_cover_top_m']=s['relative_top_m'];out.append(q)
 r['placements']=out;r['description']=r['description'].replace('flush covers','low-step covers')
C['crossing_groups']=G;C['revision_changes']=['Only the 7 low-step crossing-cover assemblies are locally lowered/split against actual unchanged old ground.','E07 top 27mm above datum and 23mm below old slab at north end. E08/E09 remain the previously compliant 27mm.','E10 top relative heights 27/10/10mm, adjacent top jumps 18/15mm. Three SW branches have 10mm relative tops with 15mm terrain-transition jumps.','Crossing footprints unchanged; modules reused, no added map area or old-ground alteration. No claim of capsule/UE traversal.']
C['notes'][2]='Low-step crossing covers have 10 or 27mm top height relative to local old ground; maximum adjacent end level change 27mm, not a runtime traversal certification.'
(R/'Config/design_v04.json').write_text(json.dumps(C,indent=2))
(R/'QA/crossing_level_design_v04.json').write_text(json.dumps({'stage':'PRE_MODEL_LOCAL_GROUND_PROFILE','source':'Independent v03/support_audit.json original retained-ground samples; original B07 ground remains unchanged.','groups':G,'max_relative_cover_top_m':max(s['relative_top_m'] for g in G for s in g['segments']),'max_internal_top_step_m':max([0]+[v for g in G for v in g['internal_top_steps_m']]),'max_external_end_step_m':max(v for g in G for v in g['external_end_steps_m']),'scope':'These are geometric cover-to-old-ground and within-cover level differences. Adjacent raised service-edge endpoints are service interfaces, not a character route certification.'},indent=2))
print('V04_PROFILE_SPEC',len(G),sum(len(r['placements']) for r in C['regions'].values()))
