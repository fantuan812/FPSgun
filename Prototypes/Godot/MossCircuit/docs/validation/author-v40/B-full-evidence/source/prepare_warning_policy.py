from pathlib import Path
import hashlib,json
from warning_policy import classify
q=Path(__file__).parent;h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
oldraw=Path('evidence-workspace/moss-v39-prep/final-full/full-first/aggregate/independent_scavenger_views.gd.log');raw=oldraw.read_text();tail=raw[raw.index('WARNING:'):]
old=Path('evidence-workspace/moss-v39-final-r2/scripts/main.gd');new=Path('evidence-workspace/moss-v39-B-full/scripts/main.gd')
assert old.read_text().splitlines()[788]==new.read_text().splitlines()[796]
block='WARNING: The draw_rect() "width" argument has no effect when "filled" is "true".\n     at: draw_rect (scene/main/canvas_item.cpp:823)\n     GDScript backtrace (most recent call first):\n         [0] _draw (res://scripts/main.gd:789)\n'
assert tail==block*48
policy={'route':'tests__independent_scavenger_views','count':48,'block':block.replace('main.gd:789','main.gd:797'),'old_expression_line':789,'new_expression_line':797,'expression':old.read_text().splitlines()[788],'evidence':{str(p):h(p) for p in [oldraw,old,new]},'scope':'Only exact prior filled+width warning at unchanged expression. Full raw preserved; not warning-free acceptance.'}
(q/'KNOWN_WARNING_POLICY.json').write_text(json.dumps(policy,indent=2)+'\n')
b=policy['block'].encode();cases=[('exact48',b*48,policy,True),('47',b*47,policy,False),('49',b*49,policy,False),('body',b.replace(b'width',b'WIDTH')*48,policy,False),('extra_line',b*48+b'EXTRA\n',policy,False),('error',b*48+b'ERROR: bad\n',policy,False),('wrong_line',b.replace(b':797',b':789')*48,policy,False),('other_route',b*48,None,False),('empty_allowed_route',b'',policy,False),('empty_normal_route',b'',None,True)]
results=[{'case':n,'expected':e,'actual':classify(s,p)['accepted'],'pass':classify(s,p)['accepted']==e} for n,s,p,e in cases];assert all(r['pass'] for r in results)
(q/'WARNING_POLICY_PYTHON_TEST.json').write_text(json.dumps({'pass':True,'checks':len(results),'cases':results,'policy_sha256':h(q/'KNOWN_WARNING_POLICY.json'),'classifier_sha256':h(q/'warning_policy.py'),'scope':'Pure Python finite classifier negatives; no Godot'},indent=2)+'\n');print('10 literal Python warning checks PASS')
