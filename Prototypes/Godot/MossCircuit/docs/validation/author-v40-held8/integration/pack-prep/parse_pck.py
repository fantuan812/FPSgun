from pathlib import Path
import struct,hashlib,json,sys

def parse(path):
 b=Path(path).read_bytes();magic,version,major,minor,patch=struct.unpack_from('<5I',b,0);assert magic==0x43504447 and version==3
 flags,base,index=struct.unpack_from('<IQQ',b,20);assert flags==2
 assert 0<=index<=len(b)-4 and 0<=base<=len(b)
 count,=struct.unpack_from('<I',b,index);assert count<1000000;cursor=index+4;rows={}
 for _ in range(count):
  assert cursor+4<=len(b)
  length,=struct.unpack_from('<I',b,cursor);cursor+=4;assert length>0 and cursor+length+36<=len(b)
  rawpath=b[cursor:cursor+length];cursor+=length;name=rawpath.rstrip(b'\0').decode();assert name and not name.startswith('/') and '\\' not in name and '\0' not in name and all(part not in ['', '.', '..'] for part in name.split('/'))
  offset,size=struct.unpack_from('<QQ',b,cursor);cursor+=16;md5=b[cursor:cursor+16];cursor+=16;fileflags,=struct.unpack_from('<I',b,cursor);cursor+=4
  assert name not in rows and fileflags==0 and offset+base+size<=index
  data=b[offset+base:offset+base+size];assert hashlib.md5(data).digest()==md5,name
  rows[name]={'bytes':size,'sha256':hashlib.sha256(data).hexdigest(),'flags':fileflags}
 return {'pack_sha256':hashlib.sha256(b).hexdigest(),'bytes':len(b),'count':count,'files':rows}
if __name__=='__main__':
 result=parse(sys.argv[1]);Path(sys.argv[2]).write_text(json.dumps(result,indent=2)+'\n');print(result['count'],result['pack_sha256'])
