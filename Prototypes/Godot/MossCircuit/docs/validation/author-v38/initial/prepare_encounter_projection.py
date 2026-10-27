from pathlib import Path
import json,hashlib,difflib
r=Path('workspace/shared');base=r/'moss-v37-final';work=r/'moss-v38-work';out=r/'moss-v38-prep/fixture-projection';out.mkdir(exist_ok=True)
files=['tests/independent_reservation_records.gd','tests/independent_annulus_data.gd','tests/independent_brace_geometry.gd'];
for n in files:
 p=out/'originals'/n;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes((base/n).read_bytes())
blocks={}
for key,n in [('encounters','data/encounters.json'),('rooms','data/room_encounters.json')]:
 old=(base/n).read_text();new=(work/n).read_text();a=0
 while a<min(len(old),len(new)) and old[a]==new[a]:a+=1
 z=0
 while z<min(len(old)-a,len(new)-a) and old[-z-1]==new[-z-1]:z+=1
 before=old[a:len(old)-z];after=new[a:len(new)-z];assert new.count(after)==1 and new.replace(after,before)==old
 blocks[key]={'old':before,'new':after,'old_sha':hashlib.sha256(old.encode()).hexdigest(),'new_sha':hashlib.sha256(new.encode()).hexdigest()}
newrow=json.loads((work/'data/encounters.json').read_text())['enemies'][-1]
s='extends RefCounted\n## Test-only strict v38 declaration then reverse original byte identity. No golden replacement.\n'
s+='const DECLARED_ROW = '+json.dumps(json.dumps(newrow,separators=(',',':')))+'\n'
for key,d in blocks.items():
 for which in ['old','new','old_sha']:s+='const '+key.upper()+'_'+which.upper()+' = '+json.dumps(d[which])+'\n'
s+='''static func project(encounter_raw:String,room_raw:String)->Dictionary:
 var fail:Dictionary={"pass":false,"encounter_bytes":"","room_bytes":"","encounters":{},"rooms":{}}
 var c:Variant=JSON.parse_string(encounter_raw);var rooms:Variant=JSON.parse_string(room_raw)
 if not c is Dictionary or not rooms is Dictionary:return fail
 if not c.get("enemies") is Array or c.enemies.size()!=8 or c.enemies[-1]!=JSON.parse_string(DECLARED_ROW):return fail
 if not c.get("waves") is Array or c.waves.size()!=6 or not c.waves[3].get("pool") is Array or c.waves[3].pool!=JSON.parse_string('["charger","spitter","flanker","stitch_drone"]'):return fail
 if not rooms.get("stages") is Array or rooms.stages.size()!=3:return fail
 for i in [1,2]:
  if not rooms.stages[i].get("enemies") is Array or rooms.stages[i].enemies.size()!=5 or rooms.stages[i].enemies[-1]!=JSON.parse_string('{"kind":"stitch_drone","at":[0.5,0.18]}'):return fail
 if encounter_raw.count(ENCOUNTERS_NEW)!=1 or room_raw.count(ROOMS_NEW)!=1:return fail
 var original_encounters:String=encounter_raw.replace(ENCOUNTERS_NEW,ENCOUNTERS_OLD)
 var original_rooms:String=room_raw.replace(ROOMS_NEW,ROOMS_OLD)
 if original_encounters.sha256_text()!=ENCOUNTERS_OLD_SHA or original_rooms.sha256_text()!=ROOMS_OLD_SHA:return fail
 return {"pass":true,"encounter_bytes":original_encounters,"room_bytes":original_rooms,"encounters":JSON.parse_string(original_encounters),"rooms":JSON.parse_string(original_rooms)}
'''
p=out/'candidate/tests/support/v38_encounter_projection.gd';p.parent.mkdir(parents=True,exist_ok=True);p.write_text(s)
for n in files:
 s=(base/n).read_text();s=s.replace('extends SceneTree\n','extends SceneTree\nconst EncounterHistory=preload("res://tests/support/v38_encounter_projection.gd")\n',1)
 if 'reservation_records' in n:
  needle=' ck(FileAccess.get_sha256("res://data/encounters.json")==';assert needle in s
  insertion=' var encounter_history:Dictionary=EncounterHistory.project(FileAccess.get_file_as_string("res://data/encounters.json"),FileAccess.get_file_as_string("res://data/room_encounters.json"))\n ck(encounter_history.get("pass",false),"strict declared v38 row/wave/Rooms append and original raw identity")\n'
  s=s.replace(needle,insertion+' ck(encounter_history.encounter_bytes.sha256_text()==',1)
  s=s.replace('ck(FileAccess.get_sha256("res://data/room_encounters.json")==','ck(encounter_history.room_bytes.sha256_text()==',1)
 else:
  name='c' if 'annulus_data' in n else 'config'
  needle=' ck(AI.validate('+name+').is_empty(),';idx=s.index(needle);end=s.index('\n',idx)+1
  ins=' var encounter_history:Dictionary=EncounterHistory.project(FileAccess.get_file_as_string("res://data/encounters.json"),FileAccess.get_file_as_string("res://data/room_encounters.json"))\n ck(encounter_history.get("pass",false),"strict v38 additions before original historical roster oracle")\n '+name+'=encounter_history.encounters\n'
  s=s[:end]+ins+s[end:]
 p=out/'candidate'/n;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(s)
 diff=''.join(difflib.unified_diff((base/n).read_text().splitlines(True),s.splitlines(True),fromfile='v37/'+n,tofile='candidate/'+n));(out/(Path(n).stem+'.patch')).write_text(diff)
(out/'DECLARATION.json').write_text(json.dumps({'newrow':newrow,'blocks':blocks,'scope':'Only three historical fixtures and one new test helper; old SHA assertions retained; candidate outside source pending static review'},indent=2)+'\n')
print(out)
