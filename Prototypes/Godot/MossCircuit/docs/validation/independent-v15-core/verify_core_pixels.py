from pathlib import Path
from PIL import Image
import numpy as np,json,hashlib,sys
root=Path(sys.argv[1]);manifest=json.loads((root/'action_manifest.json').read_text());failures=[];actions={}
for name,asset in manifest['actions'].items():
    im=Image.open(root/Path(asset['path']).name).convert('RGBA');arr=np.array(im);n=3 if name.endswith('hurt') else 4;hashes=[];centers=[];tops=[];bottoms=[];heights=[];brightness=[];translations={}
    for i,r in enumerate(asset['frames']):
        x,y,w,h=r['region'];mx,my,mw,mh=r['margin'];crop=arr[y:y+h,x:x+w];a=crop[:,:,3];ys,xs=np.where(a>=8)
        left,top,right,bottom=int(xs.min()),int(ys.min()),int(xs.max()+1),int(ys.max()+1)
        if [mx+left,my+top,right-left,bottom-top]!=r['alpha_bbox']:failures.append(f'{name}/{i}: alpha bbox mismatch')
        if min(left,top,w-right,h-bottom)<4:failures.append(f'{name}/{i}: padding')
        if (w+mw,h+mh)!=(512,400):failures.append(f'{name}/{i}: canvas')
        row,col=divmod(r['source_pose_index'],n)
        action_dx=-12 if name.endswith('hurt') else -16
        if mx-x!=round(256-im.width/n*(col+.5))+action_dx:failures.append(f'{name}/{i}: fixed source column plus fixed action registration')
        translations.setdefault(row,set()).add(my-y)
        hashes.append(hashlib.sha256(crop.tobytes()).hexdigest());tops.append(my+top);bottoms.append(my+bottom);heights.append(bottom-top)
        rgb=crop[:,:,:3].astype(float);R,G,B=rgb[:,:,0],rgb[:,:,1],rgb[:,:,2]
        cyan=(a>=8)&(G>1.15*R)&(B>1.1*R)&(G>45)&(B>40)
        cy,cx=np.where(cyan)
        if len(cy)<20:failures.append(f'{name}/{i}: insufficient cyan pixels for core proxy');centers.append(None);brightness.append(None)
        else:
            centers.append([round(float(cx.mean()+.5+mx),3),round(float(cy.mean()+.5+my),3)])
            brightness.append(round(float((.2126*R[cyan]+.7152*G[cyan]+.0722*B[cyan]).mean()),3))
    if len(hashes)!=n*n or len(set(hashes))!=n*n:failures.append(f'{name}: frame count or duplicate')
    if any(len(v)!=1 for v in translations.values()):failures.append(f'{name}: per-pose vertical registration')
    if heights[0]!=asset['reference_height']:failures.append(f'{name}: first pose reference')
    if name.endswith('death'):
        if any(b>a for a,b in zip(heights,heights[1:])):failures.append(f'{name}: body height rises')
        if any(a-b>2 for a,b in zip(tops,tops[1:])):failures.append(f'{name}: silhouette top rises >2px')
        if any(a[1]-b[1]>3 for a,b in zip(centers,centers[1:])):failures.append(f'{name}: cyan proxy rises >3px')
        if brightness[-1]>=brightness[0]*.7:failures.append(f'{name}: final core not substantially dimmer')
    actions[name]={'frames':len(hashes),'unique':len(set(hashes)),'tops':tops,'visible_lower_envelope_not_feet':bottoms,'height':heights,'cyan_core_centroid_proxy':centers,'cyan_mean_luminance_proxy':brightness,'fixed_row_dy':{r:list(v)[0] for r,v in translations.items()},'fixed_action_x_offset':-12 if name.endswith('hurt') else -16,'png_sha256':hashlib.sha256((root/Path(asset['path']).name).read_bytes()).hexdigest()}
print(json.dumps({'passed':not failures,'failures':failures,'alpha_threshold':8,'scope':'Read-only RGBA analysis. Cyan color centroid/luminance are image-derived proxies, not semantic landmarks or live GUI playback. No physical-foot claim for hovering Core.','actions':actions},indent=2));sys.exit(bool(failures))
