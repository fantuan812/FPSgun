from reference import *
import json
checks=[]
def ck(ok,label):
 checks.append({'label':label,'pass':bool(ok)})
 if not ok:raise AssertionError(label)
row={'max_stack':1,'return_pickup_radius':18.,'return_pickup_limit':3,'pickup_sources':['normal','energy']}
ck(profile(row)=={'radius':18.,'maximum':3,'sources':['normal','energy']},'canonical profile')
for q in [1,1.,3.,8,8.]:ck(bool(profile(dict(row,return_pickup_limit=q))),'integral JSON-compatible '+repr(q))
for field,values in {'return_pickup_limit':[True,False,None,'3',0,9,2.5,float('nan'),float('inf')],'return_pickup_radius':[True,None,'18',0,-1,64.1,float('nan'),float('inf')],'pickup_sources':[['normal','normal'],['energy','energy'],['normal','medical'],['normal'],['normal',1],None],'max_stack':[True,0,2,None]}.items():
 for value in values:ck(not profile(dict(row,**{field:value})),'profile rejection '+field+repr(value))
for p,want in [((50,17),True),((50,18),False),((120,0),False),((0,17),True),((0,18),False),((100,17),True),((50,-17),True)]:ck(segment_inside((100,0),(0,0),p,18)==want,'A closed strict '+repr(p))
ck(not segment_inside((0,0),(0,0),(0,0),18),'zero segment excluded')
for v in [float('nan'),float('inf'),-float('inf')]:ck(not segment_inside((v,0),(0,0),(1,1),18),'nonfinite endpoint '+repr(v))
ck(segment_inside((100,100),(0,0),(50,60),18),'diagonal interior margin')
ck(not segment_inside((100,100),(0,0),(50,80),18),'diagonal exterior margin')
for args,want,label in [((.2,.03,False,.01),[((101.,0.),(99.,0.))],'D split'),((.015,.03,False,.01),[((101.,0.),(100.5,0.))],'D life-clipped'),((.005,.03,False,.01),[],'D outbound expiry'),((0,.03,True,0),[],'life exhausted'),((.2,0,True,0),[],'dt zero')]:
 got=return_piece((100.,0.),(0.,0.),100,*args)
 ck(len(got)==len(want) and all(abs(got[i][j][k]-want[i][j][k])<1e-9 for i in range(len(want)) for j in range(2) for k in range(2)),label)
ck(not return_piece((10.,0.),(0.,0.),100,.2,.03,True,0),'arrival entry no sweep')
def disc(name,quota=3):return {'id':name,'scavenger':dict(snapshot(row),remaining=quota)}
def sw(d,a=(100,0),b=(0,0)):return {'disc':d,'start':a,'end':b}
def p(name,pos=(50,0),**kwargs):return dict(identity=name,pos=pos,xp=1,coins=1,**kwargs)
d=disc('A');left,events=pickup_phase([p('P0'),p('P1'),p('P2'),p('P3')],[sw(d)])
ck([x['identity'] for x in events]==['P3','P2','P1'] and [x['identity'] for x in left]==['P0'] and d['scavenger']['remaining']==0,'C reverse pickup quota')
a,b=disc('A',1),disc('B',1);left,events=pickup_phase([p('P0'),p('P1'),p('P2'),p('P3')],[sw(b),sw(a)])
ck([(e['identity'],e['winner']) for e in events]==[('P3','B'),('P2','A')],'C reverse disc tie')
d=disc('A');left,events=pickup_phase([p('magnet',(20,0))],[sw(d,(7,0),(7,1))],pickup_radius=30,dt=.05)
ck(len(events)==1 and events[0]['pos']==(7.,0.) and events[0]['winner']=='A','B postmagnet not physical recheck')
left,events=pickup_phase([p('magnet',(20,0))],[],pickup_radius=30,dt=.05)
ck(len(left)==1 and left[0]['pos']==(7.,0.) and not events,'B no sweep retains moved pickup')
d=disc('A');left,events=pickup_phase([p('local',(13,0))],[sw(d)],pickup_radius=30,dt=.05)
ck(events[0]['winner']=='player' and d['scavenger']['remaining']==3,'B original local wins no quota')
d=disc('A');left,events=pickup_phase([p('original')],[sw(d)],append_on_event=p('new'))
ck([x['identity'] for x in left]==['new'] and len(events)==1,'E event-appended waits original range')
d=disc('A');left,events=pickup_phase([p('normal'),p('energy',source='energy'),p('medical',source='medical')],[sw(d)])
ck([e['source'] for e in events]==['energy','normal'] and [x['identity'] for x in left]==['medical'] and d['scavenger']['remaining']==1,'F source preservation and medical exclusion')
for bad in [True,3.,-1,4,None]:
 d=disc('A');d['scavenger']['remaining']=bad;ck(not eligible(sw(d),p('bad')),'runtime actual integer remaining '+repr(bad))
for bad in [True,3.,0,9,None]:
 d=disc('A');d['scavenger']['maximum']=bad;ck(not eligible(sw(d),p('bad')),'runtime actual integer maximum '+repr(bad))
a,b=snapshot(row),snapshot(row);a['remaining']=0;a['sources'].clear();ck(b['remaining']==3 and b['sources']==['normal','energy'],'snapshot ownership no alias')
print(json.dumps({'status':'PASS_REFERENCE_MODEL_ONLY','checks':len(checks),'records':checks},indent=2))
