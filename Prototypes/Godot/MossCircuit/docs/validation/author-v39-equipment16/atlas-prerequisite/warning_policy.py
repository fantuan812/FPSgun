"""Exact, bounded renderer-warning exception; not a Godot log policy."""
import re
BODIES={
'pango':"Failed to wrap object of type 'PangoFT2FontMap'. Hint: this error is commonly caused by failing to call a library init() function.",
'gtk':"Failed to wrap object of type 'GtkRecentManager'. Hint: this error is commonly caused by failing to call a library init() function."}
HEADER=re.compile(r'^\*\* \(inkscape:[0-9]+\): WARNING \*\*: [0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3}: (.*)$')
def classify(data):
 try:text=data.decode('utf-8','strict')
 except UnicodeDecodeError:return {'pass':False,'reason':'invalid_utf8'}
 counts={k:0 for k in BODIES};normalized=[]
 for line in text.splitlines():
  if not line.strip():continue
  m=HEADER.fullmatch(line)
  if not m:return {'pass':False,'reason':'unrecognized_nonempty_line','line':line}
  keys=[k for k,v in BODIES.items() if m.group(1)==v]
  if len(keys)!=1:return {'pass':False,'reason':'unrecognized_warning_body','line':line}
  k=keys[0];counts[k]+=1
  if counts[k]>1:return {'pass':False,'reason':'duplicate_warning','kind':k}
  normalized.append('** (inkscape:<PID>): WARNING **: <TIME>: '+BODIES[k])
 return {'pass':True,'counts':counts,'normalized':normalized,'scope':'Only up to one each exact PangoFT2FontMap/GtkRecentManager warning; other stderr rejected'}
