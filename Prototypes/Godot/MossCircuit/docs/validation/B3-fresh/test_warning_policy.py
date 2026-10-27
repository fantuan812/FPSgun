from pathlib import Path
import json
from warning_policy import classify,BODIES
O=Path(__file__).resolve().parent
p=lambda k,pid='6',t='04:32:59.656':f'** (inkscape:{pid}): WARNING **: {t}: '+BODIES[k]+'\n'
a=p('pango');b=p('gtk');cases=[('empty','',True),('pango',a,True),('gtk',b,True),('both',a+b,True),('reverse',b+a,True),('normalize_pid_time',p('pango','999','23:59:59.999'),True),('duplicate_pango',a+a,False),('duplicate_gtk',b+b,False),('fontconfig','Fontconfig error: No writable cache directories\n',False),('mixed_fontconfig',a+'Fontconfig error: No writable cache directories\n'+b,False),('other_warning',a.replace('PangoFT2FontMap','OtherMap'),False),('changed_body',a.replace('library init()','library initialize()'),False),('wrong_process',a.replace('inkscape:','godot:'),False),('wrong_level',a.replace('WARNING','ERROR'),False),('unprefixed',BODIES['pango'],False),('extra_line',a+'unrelated output\n',False),('extra_suffix',a.rstrip()+' extra\n',False),('negative_pid',a.replace(':6)',':-6)'),False),('bad_time',a.replace('04:32:59.656','unknown'),False)]
results=[]
for name,s,expected in cases:
 r=classify(s.encode());assert r['pass']==expected,name;results.append({'name':name,'expected':expected,'actual':r['pass']})
assert not classify(b'\xff')['pass'];results.append({'name':'invalid_utf8','expected':False,'actual':False})
raw=(O/'fresh-first/stderr.raw').read_bytes();assert not classify(raw)['pass'];results.append({'name':'actual_original_failed_stderr','expected':False,'actual':False})
result={'pass':True,'checks':len(results),'cases':results,'no_renderer_or_engine_executed':True};(O/'WARNING_POLICY_UNIT_RESULT.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result))
