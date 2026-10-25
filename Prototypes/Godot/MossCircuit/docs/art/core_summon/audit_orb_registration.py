"""Read-only body/orb registration audit; source PNG pixels are never edited."""
from pathlib import Path
from PIL import Image
import argparse,json
import numpy as np
p=argparse.ArgumentParser();p.add_argument('--project',type=Path,required=True);p.add_argument('--reference-project',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args()
facts=json.loads((a.project/'docs/art/core_summon/source-analysis.json').read_text())['frames'];im=np.asarray(Image.open(a.project/'assets/actions/boss_core/boss_core_summon.png'))
def center(rgba,limit=None):
 r,g,b=rgba[:,:,0].astype(int),rgba[:,:,1].astype(int),rgba[:,:,2].astype(int)
 mask=(rgba[:,:,3]>128)&(g>150)&(g>r*1.12)&(b>70)&(g>b*1.13)
 if limit is not None:mask[limit:,:]=False
 yy,xx=np.where(mask);assert len(xx)>500
 return [float(xx.mean()),float(yy.mean()),len(xx)]
old=np.asarray(Image.open(a.reference_project/'assets/enemies/boss_core.png'))[:418,:418];old_core=center(old)
old_box=json.loads((a.reference_project/'assets/enemies/enemy_manifest.json').read_text())['enemies']['boss_core']['frames'][0]['alpha_bbox']
reference_relative=[(old_core[0]-old_box[0]-old_box[2]*.5)/old_box[3],(old_core[1]-old_box[1]-old_box[3])/old_box[3]]
rows=[0,320,622,910,1199];poses=[]
for i in range(16):
 row,col=divmod(i,4);x=col*328;y=rows[row];cx,cy,n=center(im[y:rows[row+1],x:x+328],200);dx,dy=facts[i]['translation'];logical=[x+cx+dx,y+cy+dy]
 poses.append({'source_pose_index':i,'source_core_centroid':[x+cx,y+cy],'mask_pixels':n,'logical_core_centroid':logical,'relative_to_reference_height':[(logical[0]-256)/246,(logical[1]-320)/246]})
report={'method':'Core-color mask alpha>128, G>150, G>1.12R, B>70, G>1.13B. New-pose mask restricted to first200px of row-partition to exclude lower seed cue; reference full neutral cell. Color centroid is a registration aid, not pixel-perfect semantic ground truth.', 'reference_core_centroid':old_core[:2],'reference_neutral_bounds':old_box,'reference_normalized_core':reference_relative,'new_neutral_core_offset_error_fraction':[poses[0]['relative_to_reference_height'][i]-reference_relative[i] for i in range(2)],'terminal_to_initial_source_pixel_delta':[poses[-1]['logical_core_centroid'][i]-poses[0]['logical_core_centroid'][i] for i in range(2)],'poses':poses,'conclusion':'Body/orb stable across source rows; lowest root purposely moves. Source neutral/terminal differences still require real rendered-window acceptance.'}
a.output.write_text(json.dumps(report,indent=2)+'\n');print(json.dumps({k:report[k] for k in ['reference_normalized_core','new_neutral_core_offset_error_fraction','terminal_to_initial_source_pixel_delta']},indent=2))
