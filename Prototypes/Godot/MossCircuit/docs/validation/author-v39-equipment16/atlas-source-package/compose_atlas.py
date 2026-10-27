"""Compose sixteen accepted SVG icon sources; never read runtime raster pixels as art."""
from pathlib import Path
import xml.etree.ElementTree as E,json,hashlib,copy
R=Path(__file__).resolve().parent
E.register_namespace('', 'http://www.w3.org/2000/svg');NS='{http://www.w3.org/2000/svg}'
layout=json.load(open(R/'layout.json'));root=E.Element(NS+'svg',{'width':'256','height':'256','viewBox':'0 0 256 256','shape-rendering':'crispEdges','role':'img'});E.SubElement(root,NS+'title').text='MossCircuit editable equipment atlas — sixteen semantic icons'
for i,row in enumerate(layout['icons']):
 s=E.parse(R/row['source']).getroot();assert s.attrib.get('viewBox')=='0 0 64 64';assert not any(e.tag==NS+'image' for e in s.iter());x,y=row['rect'][:2];group=E.SubElement(root,NS+'g',{'id':'icon-'+row['id'],'data-icon-id':row['id'],'transform':f'translate({x} {y})'})
 for child in list(s):
  c=copy.deepcopy(child)
  for node in c.iter():
   if 'id' in node.attrib:node.set('id',row['id']+'--'+node.attrib['id'])
  group.append(c)
(R/'art_source/equipment_atlas_editable.svg').write_text(E.tostring(root,encoding='unicode')+'\n')
# All source content is inline; no file:// fetch or external image dependency.
svg=E.tostring(root,encoding='unicode');palette={e.attrib['data-palette']:e.attrib['fill'] for e in root.iter() if 'data-palette' in e.attrib}
controls=''.join(f'<label>{k}<input type="color" value="{v}" oninput="paint(\'{k}\',this.value)"></label>' for k,v in sorted(palette.items()))
cards=''.join('<section><h2>'+row['id']+'</h2>'+ (R/row['source']).read_text()+'</section>' for row in layout['icons'])
(R/'preview.html').write_text('''<!doctype html><html lang="zh-CN"><meta charset="utf-8"><title>Editable equipment atlas</title><style>body{background:#15252b;color:#e7e2ca;font:14px system-ui;margin:24px}aside{display:flex;flex-wrap:wrap;gap:12px}label{display:flex;align-items:center;gap:5px}input{width:32px}.atlas svg{width:512px;height:auto;image-rendering:pixelated}main{display:grid;grid-template-columns:repeat(4,1fr);gap:12px}section{background:#21343b;padding:14px}section svg{width:128px;height:128px;image-rendering:pixelated}h2{font-size:14px}button{margin:10px;padding:10px}</style><h1>16格可编辑装备图集 · 独立候选</h1><p>每个ID有独立语义图层；调色作用于SVG元素，保存为SVG源码。无外部读取；非已集成版本。</p><aside>'''+controls+'''</aside><div class="atlas">'''+svg+'''</div><button onclick="save()">保存已调色图集 SVG</button><main>'''+cards+'''</main><script>function paint(k,v){document.querySelectorAll('[data-palette="'+k+'"]').forEach(e=>e.setAttribute('fill',v))}function save(){let s=document.querySelector('.atlas svg').cloneNode(true),b=new Blob([new XMLSerializer().serializeToString(s)],{type:'image/svg+xml'}),a=document.createElement('a');a.href=URL.createObjectURL(b);a.download='equipment_atlas_editable.svg';a.click();setTimeout(()=>URL.revokeObjectURL(a.href),1000)}</script></html>''')
print('Composed 16 semantic groups, 256x256 SVG and fully inline HTML preview; no PNG export')
