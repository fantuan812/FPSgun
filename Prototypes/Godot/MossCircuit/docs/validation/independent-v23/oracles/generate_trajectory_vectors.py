"""Pre-implementation analytic no-enemy fixtures, not a copy of the game solver.
Closed-form straight/folded-axis cases with expected points supplied explicitly.
Run from any directory; output is beside this script. No engine imports.
"""
from pathlib import Path
import math,json
rows=[]
def add(name,size,start,direction,distance,end,reflections,terminal='budget',travel=None):
    rows.append(dict(case=name,size=size,start=start,direction=direction,budget=distance,advance=distance/470+1,expected=dict(position=end,reflections=reflections,terminal=terminal,traveled=distance if travel is None else travel)))
for mode,(w,h) in [('arena',(1440,960)),('rooms',(960,640))]:
    s=[w,h];c=[w/2,h/2]
    for label,start,d,end in [
      ('right',[w-100,h/2],[1,0],[w-100,h/2]),
      ('left',[100,h/2],[-1,0],[100,h/2]),
      ('bottom',[w/2,h-100],[0,1],[w/2,h-100]),
      ('top',[w/2,100],[0,-1],[w/2,100])]:
        add(mode+'/'+label,s,start,d,200,end,1)
        boundary=[w if d[0]>0 else 0 if d[0]<0 else start[0],h if d[1]>0 else 0 if d[1]<0 else start[1]]
        add(mode+'/'+label+'-budget-at-boundary',s,start,d,100,boundary,0)
    add(mode+'/initial-outward',s,[0,h/2],[-1,0],100,[100,h/2],1)
    add(mode+'/initial-inward',s,[0,h/2],[1,0],100,[100,h/2],0)
    add(mode+'/initial-tangent',s,[0,h/2],[0,1],100,[0,h/2+100],0)
    a=200/math.sqrt(2)-100
    add(mode+'/corner-both-axes',s,[w-100,h-100],[1,1],200,[w-a,h-a],1)
    add(mode+'/initial-corner-outward',s,[w,h],[1,1],100,[w-100/math.sqrt(2),h-100/math.sqrt(2)],1)
    add(mode+'/two-reflections',s,[w-100,h/2],[1,0],w+200,[100,h/2],2)
    add(mode+'/third-boundary-absorbs',s,[w-100,h/2],[1,0],3*w,[w,h/2],2,'third_boundary',100+2*w)
    add(mode+'/center-base-budget',s,c,[1,0],900,[w-(900-w/2),h/2],1)
# Hand-checked exact values; these exercise neither Guide nor moving targets.
assert rows[0]['expected']['position']==[1340,480]
assert next(r for r in rows if r['case']=='arena/center-base-budget')['expected']['position']==[1260,480]
assert next(r for r in rows if r['case']=='rooms/center-base-budget')['expected']['position']==[540,320]
out={'scope':'32 analytic static no-enemy fixtures; direction normalized by consumer; 470 snapshot speed; clamp handled separately; not executed against implementation yet','rows':rows}
assert len(rows)==32
Path(__file__).with_name('trajectory_vectors.json').write_text(json.dumps(out,indent=2)+'\n')
print('generated',len(rows),'analytic cases')
