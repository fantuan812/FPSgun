"""Conservative semantic summary of sampled geometry rays, not a combat guarantee."""
import json,pathlib,os
P=pathlib.Path(__file__).resolve().parent;r=json.loads((P/os.environ.get('QA_EXPOSURE_REPORT','exposure_rays.json')).read_text());out={'method':'24 directions at2m path stations. Only named opaque walls/screens/building masses counted; proxies, rails, pipes, shrubs and signage excluded. Nearby cover is NOT the same as breaking forward sight. Open intervals are reset at actual path turns, not merged into a fictitious straight firing line. No enemy positions or bullet/material simulation.','routes':{}}
def solid(n):
 n=n.lower();return any(x in n for x in ['b06_p_hall side','b06_p_hall north','b06_p_front wall','b06_service_bank / 0','b06_screen / 0','b06_utility_shelter /','open sliding leaf','external service wing','end wall panel','side concrete panel','m east red band','m north wall','m south wall','m west wall','portal_boundary_closure','reuse_sm_npp_wall_solid'])
for name,p in r['paths'].items():
 near=[];forward=[];runs=[];start=None;end=None;lastsegment=None
 for idx,s in enumerate(p['samples']):
  interval_end=p['samples'][idx+1]['station'] if idx+1<len(p['samples']) else p['length']
  segment=s.get('segment',0)
  if lastsegment is not None and segment!=lastsegment and start is not None:runs.append(end-start);start=None
  lastsegment=segment
  hits=[h['distance'] for h in s['directions'].values() if h and solid(h['object'])];near.append(min(hits) if hits else None)
  isopen=s['forward'] is None or not solid(s['forward']['object'])
  if isopen:
   if start is None:start=s['station']
   end=interval_end
  elif start is not None:runs.append(end-start);start=None
 if start is not None:runs.append(end-start)
 out['routes'][name]={'path_length_m':p['length'],'samples':len(near),'solid_within12m_samples':sum(v is not None and v<=12 for v in near),'no_named_solid_within20m_samples':sum(v is None for v in near),'max_straight_segment_forward_open_interval_m':max(runs or [0]),'limitations':'Nearby lateral shelter does not guarantee frontal crossfire protection; first-hit sampling may undercount cover behind pipes/rails'}
(P/os.environ.get('QA_SUMMARY_REPORT','exposure_summary.json')).write_text(json.dumps(out,indent=2));print(json.dumps(out,indent=2))
