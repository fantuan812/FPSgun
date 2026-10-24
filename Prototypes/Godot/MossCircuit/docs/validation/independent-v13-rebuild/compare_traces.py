import json,sys
b,c=(json.load(open(x))['cases'] for x in sys.argv[1:3]); failures=[]
for key in sorted(b.keys()|c.keys()):
    if b.get(key)!=c.get(key):
        bf=b.get(key,{}).get('frames',[]);cf=c.get(key,{}).get('frames',[])
        first=next((i for i,(x,y) in enumerate(zip(bf,cf)) if x!=y),min(len(bf),len(cf)))
        failures.append({'case':key,'first_mismatch_frame':first})
for label,cases in [('baseline',b),('candidate',c)]:
    for k,v in cases.items():
        if k.endswith('fallback=false') and v!=cases.get(k.replace('fallback=false','fallback=true')):failures.append({'case':label+'/'+k,'mismatch':'authored versus fallback'})
print(json.dumps({'passed':not failures,'baseline_cases':len(b),'candidate_cases':len(c),'frames_compared':sum(len(v['frames']) for v in b.values()),'failures':failures},indent=2));sys.exit(bool(failures))
