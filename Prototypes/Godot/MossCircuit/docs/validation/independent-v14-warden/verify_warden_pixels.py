from PIL import Image
from pathlib import Path
import json,hashlib,sys
root=Path(sys.argv[1]);reports={};failures=[]
for kind in ('boss_warden',):
    manifest=json.loads((root/'action_manifest.json').read_text())
    for name,action in manifest['actions'].items():
        image=Image.open(root/Path(action['path']).name).convert('RGBA');hashes=[];heights=[];widths=[];feet=[];centers=[];tops=[];row_translations={}
        for index,r in enumerate(action['frames']):
            x,y,w,h=r['region'];mx,my,mw,mh=r['margin'];crop=image.crop((x,y,x+w,y+h));bbox=crop.getchannel('A').point(lambda a:255 if a>=8 else 0).getbbox()
            if not bbox:failures.append(f'{name}/{index}: empty');continue
            left,top,right,bottom=bbox
            expected=[mx+left,my+top,right-left,bottom-top]
            if r['alpha_bbox']!=expected:failures.append(f'{name}/{index}: alpha bbox mismatch')
            if (w+mw,h+mh)!=(512,400):failures.append(f'{name}/{index}: canvas')
            if min(left,top,w-right,h-bottom)<4:failures.append(f'{name}/{index}: visible edge padding')
            if x<0 or y<0 or x+w>image.width or y+h>image.height:failures.append(f'{name}/{index}: source overrun')
            cols=3 if name.endswith('hurt') else 4
            source_index=r['source_pose_index']; row,col=divmod(source_index,cols)
            if mx-x!=round(256-image.width/cols*(col+.5)):failures.append(f'{name}/{index}: not fixed source-column registration')
            row_translations.setdefault(row,set()).add(my-y)
            tops.append(my+top)
            hashes.append(hashlib.sha256(crop.tobytes()).hexdigest());heights.append(bottom-top);widths.append(right-left);feet.append(my+bottom);centers.append(mx+(left+right)/2)
        expected_count=9 if name.endswith('hurt') else 16
        if len(hashes)!=expected_count or len(set(hashes))!=expected_count:failures.append(f'{name}: count or exact duplicate')
        if max(feet)!=320 or min(feet)<308:failures.append(f'{name}: feet outside reviewed 12px source tolerance')
        if any(len(values)!=1 for values in row_translations.values()):failures.append(f'{name}: per-pose vertical registration')
        if name.endswith('death') and any(a>b for a,b in zip(tops,tops[1:])):failures.append(f'{name}: death silhouette top rises')
        if action['reference_height']!=heights[0]:failures.append(f'{name}: first height mismatch')
        if name.endswith('death') and any(b-a>2 for a,b in zip(heights,heights[1:])):failures.append(f'{name}: death grows by more than 2 source pixels')
        reports[name]={'frames':len(hashes),'unique':len(set(hashes)),'visible_feet':feet,'heights':heights,'widths':widths,'bbox_centers':centers,'silhouette_tops':tops,'common_row_translations':{k:list(v) for k,v in row_translations.items()},'max_consecutive_height_ratio':max(abs(b-a)/action['reference_height'] for a,b in zip(heights,heights[1:])),'sha256':hashlib.sha256((root/Path(action['path']).name).read_bytes()).hexdigest()}
print(json.dumps({'passed':not failures,'alpha_threshold':8,'scope':'Read-only pixel analysis; no raster edits; not live GUI playback','failures':failures,'actions':reports},indent=2));sys.exit(bool(failures))
