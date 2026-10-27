"""Read-only actual PCK record equivalence; not an engine or native rerun."""
from pathlib import Path
import argparse,struct,hashlib,json
p=argparse.ArgumentParser();p.add_argument('--new-pack',required=True);p.add_argument('--new-source',required=True);p.add_argument('--output',required=True);a=p.parse_args()
old=Path('<WORKSPACE>/moss-v38-svg-pack/linux/MossCircuit.pck');new=Path(a.new_pack);src=Path(a.new_source)
h=lambda b:hashlib.sha256(b).hexdigest()
def read(path):
 b=path.read_bytes();assert b[:4]==b'GDPC';version,=struct.unpack_from('<I',b,4);assert version==3;flags,base,index=struct.unpack_from('<IQQ',b,20);assert flags==2 and index<len(b);count,=struct.unpack_from('<I',b,index);pos=index+4;rows={}
 for _ in range(count):
  n,=struct.unpack_from('<I',b,pos);pos+=4;assert n>0 and n%4==0 and pos+n<=len(b);name=b[pos:pos+n].rstrip(b'\0').decode();pos+=n;off,size=struct.unpack_from('<QQ',b,pos);pos+=16;digest=b[pos:pos+16];pos+=16;ff,=struct.unpack_from('<I',b,pos);pos+=4;assert ff==0 and name not in rows and off+base+size<=index;payload=b[base+off:base+off+size];assert hashlib.md5(payload).digest()==digest;rows[name]=payload
 return b,rows
ob,orr=read(old);nb,nrr=read(new);assert h(ob)=='795ce7c1761766f73d23c5feec620c5f2d59d7ed005eb1cdfe33a6e8d54815d1';assert len(orr)==219 and set(orr)==set(nrr)
meta='art_source/stitch_drone/metadata/measured_assets.json';different=[n for n in orr if orr[n]!=nrr[n]];assert different==[meta],different
before=json.loads(orr[meta]);after=json.loads(nrr[meta]);expected=json.loads(orr[meta]);changes=[]
for kind,r in expected['records'].items():
 for i in [1,3]:
  prior=r['export_command'][i];value=prior.replace('<WORKSPACE>/moss-v38-svg-redraw/','');assert value!=prior;r['export_command'][i]=value;changes.append({'field':f'records.{kind}.export_command[{i}]','new_value':value})
assert len(changes)==8 and expected==after and nrr[meta]==(src/meta).read_bytes()
markers=[b'<WORKSPACE>/',b'<HOME>/',b'<TEMP>/',(b'lib'+b'file_'),(b'file_'+b'000000'),(b'.codex'+b'/sessions')];hits=[x.decode() for x in markers if x in nb];assert not hits,hits
oldmap=json.loads(Path('<WORKSPACE>/moss-v38-svg-candidate-prep/FINAL_INPUTS.json').read_text());changed=[n for n,v in oldmap.items() if not (src/n).is_file() or h((src/n).read_bytes())!=v];assert set(changed)=={meta,'art_source/stitch_drone/export_and_measure.py','MANIFEST.json'},changed
out={'pass':True,'scope':'Exact whole-PCK byte privacy scan and all219 MD5/payload identity comparison; no new gameplay/native execution claimed','old_pack_sha256':h(ob),'new_pack_sha256':h(nb),'new_pack_bytes':len(nb),'paths_equal':True,'records':len(nrr),'unchanged_record_payloads':218,'changed_records':different,'exact_json_string_changes':changes,'new_metadata_exact_source':True,'whole_byte_private_markers':hits,'old_source_inputs':len(oldmap),'new_source_changed_paths':changed,'runtime_resource_payloads_unchanged':True,'record_identity':{n:{'bytes':len(b),'sha256':h(b)} for n,b in nrr.items()}}
q=Path(a.output);assert not q.exists();q.write_text(json.dumps(out,indent=2)+'\n');print(json.dumps({k:v for k,v in out.items() if k!='record_identity'}))
