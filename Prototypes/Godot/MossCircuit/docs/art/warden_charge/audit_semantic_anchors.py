"""Read-only same-feature neutral pose audit; does not rewrite any pixels."""
from pathlib import Path
from PIL import Image
import argparse,json
import numpy as np
from scipy.ndimage import label,find_objects
p=argparse.ArgumentParser();p.add_argument('--project',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args()
root=a.project.resolve();image=np.asarray(Image.open(root/'assets/actions/boss_warden/boss_warden_charge.png'))
facts=json.loads((root/'docs/art/warden_charge/source-analysis.json').read_text())['frames'];records=[]
for i in [0,15]:
 f=facts[i];x,y,w,h=f['source_alpha_bbox'];rgba=image[y:y+h,x:x+w];r,g,b=rgba[:,:,0].astype(int),rgba[:,:,1].astype(int),rgba[:,:,2].astype(int)
 mask=(rgba[:,:,3]>=128)&(r>140)&(g>130)&(b>90)&(g>r*.72)&(b>r*.5);mask[int(h*.5):,:]=False
 labels,n=label(mask);features=[]
 for j,s in enumerate(find_objects(labels)):
  m=labels[s]==j+1;area=int(m.sum())
  if area>15:
   yy,xx=np.where(m);cx=float(xx.mean()+s[1].start+x);cy=float(yy.mean()+s[0].start+y)
   features.append({'pixels':area,'source_centroid':[cx,cy]})
 features.sort(key=lambda f:f['pixels'],reverse=True)
 # First component is the semantic faceplate. Third is the right shoulder
 # highlight; second is the upper chest. Both neutral poses have same ordering.
 chosen={name:features[index] for name,index in [('faceplate',0),('shoulder',2)]}
 for feature in chosen.values():
  cx,cy=feature['source_centroid'];dx,dy=f['translation'];correction=f.get('authored_x_correction',0)
  feature['logical_centroid_before']=[cx+dx-correction,cy+dy]
  feature['logical_centroid_after']=[cx+dx,cy+dy]
 records.append({'source_pose_index':i,'authored_x_correction':f.get('authored_x_correction',0),'features':chosen})
report={'method':'4-connected components of upper-half alpha>=128 & R>140 & G>130 & B>90 & G>0.72R & B>0.5R; visually matched neutral bright faceplate and shoulder. Not a whole-body bbox-center measurement.', 'poses':records,'interpretation':'Same-height neutral semantic anchors translated left in uncorrected final pose. Author recovery X correction restores terminal neutral without source edit, per-frame scaling or bbox normalization.'}
a.output.write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2))
