"""Synthetic Python-only timeout controls of exact proposed run() AST; never invokes Godot."""
from pathlib import Path
import ast,types,subprocess as real_subprocess,tempfile,os,sys,json,re,hashlib
here=Path(__file__).resolve().parent;source=here/'run_regression.logging_only.py';tree=ast.parse(source.read_text());selected=[n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name in ['success_marker','run']];assert len(selected)==2
expected_stdout=b'PASS: synthetic reached\\n'.replace(b'\\n',b'\n');expected_stderr=b'ERROR: synthetic before timeout\\n'.replace(b'\\n',b'\n')
programs=["import os,time;os.write(1,"+repr(expected_stdout)+");os.write(2,"+repr(expected_stderr)+");time.sleep(2)","import os,time;os.write(1,b'partial\\xff\\x00');os.write(2,b'err\\xfe');time.sleep(2)","print('PASS: synthetic normal')"]
class Proxy:
 TimeoutExpired=real_subprocess.TimeoutExpired
 def __init__(self):self.index=0;self.calls=[]
 def run(self,argv,**kw):
  assert kw['timeout']==180 and kw['capture_output'] is True and kw['text'] is True
  self.calls.append({'declared_case_cap':kw['timeout'],'synthetic_child_seconds':.2,'no_godot':True})
  program=programs[self.index];self.index+=1
  return real_subprocess.run([sys.executable,'-u','-c',program],capture_output=True,text=True,timeout=.2)
proxy=Proxy();out=here/'synthetic-timeout-results';assert not out.exists();out.mkdir();namespace={'subprocess':proxy,'time':__import__('time'),'args':types.SimpleNamespace(godot='NEVER_EXECUTED_GODOT'),'project':Path('/not-executed'),'env':os.environ.copy(),'output':out,'records':[],'re':re,'json':json};exec(compile(ast.Module(body=selected,type_ignores=[]),str(source),'exec'),namespace)
for name in ['timeout-with-marker-and-error','timeout-invalid-utf8','normal-success']:namespace['run'](name,[])
rows=namespace['records'];assert rows[0]['exit']==124 and rows[0]['error'] and rows[0]['success_marker'] and not rows[0]['pass'];assert rows[1]['exit']==124 and not rows[1]['pass'];assert rows[2]['exit']==0 and rows[2]['pass']
assert (out/'timeout-with-marker-and-error.timeout.stdout').read_bytes()==expected_stdout;assert (out/'timeout-with-marker-and-error.timeout.stderr').read_bytes()==expected_stderr;assert (out/'timeout-invalid-utf8.timeout.stdout').read_bytes()==b'partial\xff\x00';assert (out/'timeout-invalid-utf8.timeout.stderr').read_bytes()==b'err\xfe'
assert 'timed out' in (out/'timeout-with-marker-and-error.log').read_text();assert '\ufffd' in (out/'timeout-invalid-utf8.log').read_text();assert not (out/'normal-success.timeout.stdout').exists()
x={'pass':True,'scope':'Independent expected byte/return/error/marker assertions around exact proposed run() AST, synthetic Python subprocess wrapper only; no Godot/no production target. Wrapper uses.2s solely for synthetic child; exact function still requests180.','cases':3,'candidate_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'calls':proxy.calls,'records':rows};(out/'RESULT.json').write_text(json.dumps(x,indent=2)+'\n');print(json.dumps(x))
