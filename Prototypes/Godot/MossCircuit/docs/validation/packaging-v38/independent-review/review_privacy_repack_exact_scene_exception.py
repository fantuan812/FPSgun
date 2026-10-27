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
meta='art_source/stitch_drone/metadata/measured_assets.json';different=[n for n in orr if orr[n]!=nrr[n]];scene='.godot/exported/133200997/export-3ad5c15c4f3250da0cc7c1af1770d85f-main.scn'
assert set(different)=={meta,scene},different
oldscene,newscene=orr[scene],nrr[scene]
assert len(oldscene)==len(newscene)==684
assert h(oldscene)=='6e84105e22580ec5cee259a3987ee987b6c46dff29110d096a6512aeedec143c'
assert h(newscene)=='8899c818542ea9c9191c272392cf3f81df1209629dd31211fc74004e5a015e68'
assert [i for i in range(684) if oldscene[i]!=newscene[i]]==[508,509,510,511]
assert struct.unpack_from('<I',oldscene,508)[0]==106410627 and struct.unpack_from('<I',newscene,508)[0]==707380806
assert oldscene[491:508]==newscene[491:508]==b'node_ids\0'+struct.pack('<II',32,1)
decode_path=Path('<WORKSPACE>/moss-v38-packaging-privacy-prep/scene-decode-first/RESULT.json')
assert h(decode_path.read_bytes())=='77aff88805db53f8ff71a3eca47e3c06f658c69e8b0cecd7b01ed1bee6a1edd0'
decode=json.loads(decode_path.read_text());assert decode['pass'] and decode['native_exit']==0 and decode['reports'][0]['different_bundled_fields']==['node_ids']
before=json.loads(orr[meta]);after=json.loads(nrr[meta]);expected=json.loads(orr[meta]);changes=[]
for kind,r in expected['records'].items():
 for i in [1,3]:
  prior=r['export_command'][i];value=prior.replace('<WORKSPACE>/moss-v38-svg-redraw/','');assert value!=prior;r['export_command'][i]=value;changes.append({'field':f'records.{kind}.export_command[{i}]','new_value':value})
assert len(changes)==8 and expected==after and nrr[meta]==(src/meta).read_bytes()
markers=[b'<WORKSPACE>/',b'<HOME>/',b'<TEMP>/',(b'lib'+b'file_'),(b'file_'+b'000000'),(b'.codex'+b'/sessions')];hits=[x.decode() for x in markers if x in nb];assert not hits,hits
oldmap=json.loads(Path('<WORKSPACE>/moss-v38-svg-candidate-prep/FINAL_INPUTS.json').read_text());portablemap=json.loads(Path('<WORKSPACE>/moss-v38-packaging-privacy-prep/PORTABLE_INPUTS.json').read_text());assert set(oldmap)==set(portablemap);changed=[n for n in oldmap if oldmap[n]!=portablemap[n]];assert set(changed)=={meta,'art_source/stitch_drone/export_and_measure.py','MANIFEST.json'};assert all(h((src/n).read_bytes())==portablemap[n] for n in changed)
out={'pass':True,'scope':'Exact whole-PCK byte privacy scan and all219 MD5/payload identity comparison; no new gameplay/native execution claimed','old_pack_sha256':h(ob),'new_pack_sha256':h(nb),'new_pack_bytes':len(nb),'paths_equal':True,'records':len(nrr),'unchanged_record_payloads':217,'changed_records':different,'exact_json_string_changes':changes,'new_metadata_exact_source':True,'whole_byte_private_markers':hits,'old_source_inputs':len(oldmap),'new_source_changed_paths':changed,'runtime_resources_except_explicit_scene_id_bytes_unchanged':True,'scene_exception':{'scope':'Exact one-export pair only, not blanket serialization tolerance','bytes':684,'different_offsets':[508,509,510,511],'old_id':106410627,'new_id':707380806,'all_other_scene_bytes_equal':True,'actual_decode_result_sha256':h(decode_path.read_bytes())},'original_gate_status':'strict only-metadata FAIL retained in portable-review.*; this is a separately authorized exact-exception gate','record_identity':{n:{'bytes':len(b),'sha256':h(b)} for n,b in nrr.items()}}
q=Path(a.output);assert not q.exists();q.write_text(json.dumps(out,indent=2)+'\n');print(json.dumps({k:v for k,v in out.items() if k!='record_identity'}))
