#!/usr/bin/env python3
"""Independent byte-level union verification; no assumptions about part names."""
import argparse, hashlib, json, zipfile
from pathlib import PurePosixPath
p=argparse.ArgumentParser();p.add_argument('full');p.add_argument('parts',nargs='+');a=p.parse_args()
def inventory(path):
    out={}
    with zipfile.ZipFile(path) as z:
        bad=z.testzip()
        if bad: raise ValueError(f'CRC failure: {path}: {bad}')
        for i in z.infolist():
            if i.is_dir():continue
            name=i.filename
            if name in out:raise ValueError(f'duplicate member: {path}: {name}')
            if name.startswith('/') or '..' in PurePosixPath(name).parts:raise ValueError(f'unsafe member {name}')
            if '.godot' in PurePosixPath(name).parts:raise ValueError(f'import cache packaged {name}')
            data=z.read(i);out[name]={'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest()}
    return out
full=inventory(a.full);union={};duplicates=[]
for part in a.parts:
    for name,record in inventory(part).items():
        if name in union:duplicates.append(name)
        if name in union and union[name]!=record:raise ValueError(f'conflicting duplicate {name}')
        union[name]=record
missing=sorted(full.keys()-union.keys());extra=sorted(union.keys()-full.keys());changed=sorted(k for k in full.keys()&union.keys() if full[k]!=union[k])
report={'passed':not(missing or extra or changed or duplicates),'full_members':len(full),'union_members':len(union),'missing':missing,'extra':extra,'changed':changed,'duplicate_members_across_parts':duplicates,'archives':[]}
for name in [a.full]+a.parts:
    data=open(name,'rb').read();report['archives'].append({'path':name,'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest()})
print(json.dumps(report,indent=2));raise SystemExit(0 if report['passed'] else 1)
