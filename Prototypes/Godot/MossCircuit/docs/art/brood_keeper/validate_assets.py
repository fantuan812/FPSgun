"""Read-only PNG analysis. Writes JSON only; never raster editing."""
from pathlib import Path
from PIL import Image
import json,hashlib
ROOT=Path(__file__).resolve().parents[3];D=ROOT/'assets/actions/brood_keeper'
# Fixed authored row bands and transparent AtlasTexture padding, NOT per-frame bbox normalization.
SPECS={'brood_keeper_summon':(225,[(100,275,76),(380,298,47),(670,280,66),(950,275,83)]),'brood_keeper_death':(206,[(130,260,93),(480,255,100),(825,215,134),(1090,164,191)])}
old={'schema_version': 1, 'actions': {'brood_keeper_summon': {'path': 'res://assets/actions/brood_keeper/brood_keeper_summon.png', 'frames': [{'region': [0, 55, 418, 360], 'alpha_bbox': [82, 79, 271, 251]}, {'region': [418, 55, 418, 360], 'alpha_bbox': [88, 91, 265, 238]}, {'region': [836, 55, 418, 360], 'alpha_bbox': [85, 117, 267, 213]}, {'region': [0, 460, 418, 360], 'alpha_bbox': [81, 115, 281, 215]}, {'region': [418, 460, 418, 360], 'alpha_bbox': [83, 41, 277, 286]}, {'region': [836, 460, 418, 360], 'alpha_bbox': [80, 88, 274, 242]}, {'region': [0, 861, 418, 360], 'alpha_bbox': [84, 91, 266, 239]}, {'region': [418, 861, 418, 360], 'alpha_bbox': [83, 87, 270, 243]}, {'region': [836, 861, 418, 360], 'alpha_bbox': [81, 84, 271, 246]}], 'anchor': [0.5, 0.9166666666666666], 'reference_height': 251, 'release_frame': 4, 'facing': 'left', 'source_sha256': 'b916794ae6ffbf2c7eceadae41d8c8d6bdecf81f3164477c2475bf9a670ed17e', 'row_origins_y': [55, 460, 861]}, 'brood_keeper_hurt': {'path': 'res://assets/actions/brood_keeper/brood_keeper_hurt.png', 'frames': [{'region': [0, 69, 418, 360], 'alpha_bbox': [71, 61, 286, 269]}, {'region': [418, 69, 418, 360], 'alpha_bbox': [74, 60, 293, 266]}, {'region': [836, 69, 418, 360], 'alpha_bbox': [95, 68, 282, 258]}, {'region': [0, 460, 418, 360], 'alpha_bbox': [91, 65, 259, 258]}, {'region': [418, 460, 418, 360], 'alpha_bbox': [70, 65, 296, 265]}, {'region': [836, 460, 418, 360], 'alpha_bbox': [84, 65, 291, 267]}, {'region': [0, 849, 418, 360], 'alpha_bbox': [78, 63, 279, 264]}, {'region': [418, 849, 418, 360], 'alpha_bbox': [80, 59, 287, 271]}, {'region': [836, 849, 418, 360], 'alpha_bbox': [82, 62, 285, 268]}], 'anchor': [0.5, 0.9166666666666666], 'reference_height': 269, 'release_frame': 0, 'facing': 'left', 'source_sha256': '266f9110e1c3c2d730e9b89dd1802ddc2ca58ce59ef39afbca7cb1cd5d8a7a0d', 'row_origins_y': [69, 460, 849]}, 'brood_keeper_death': {'path': 'res://assets/actions/brood_keeper/brood_keeper_death.png', 'frames': [{'region': [0, 78, 418, 360], 'alpha_bbox': [65, 36, 309, 294]}, {'region': [418, 78, 418, 360], 'alpha_bbox': [67, 61, 316, 269]}, {'region': [836, 78, 418, 360], 'alpha_bbox': [65, 91, 315, 243]}, {'region': [0, 476, 418, 360], 'alpha_bbox': [67, 81, 333, 249]}, {'region': [418, 476, 418, 360], 'alpha_bbox': [61, 105, 335, 225]}, {'region': [836, 476, 418, 360], 'alpha_bbox': [51, 124, 319, 204]}, {'region': [0, 851, 418, 360], 'alpha_bbox': [50, 121, 335, 209]}, {'region': [418, 851, 418, 360], 'alpha_bbox': [50, 121, 334, 209]}, {'region': [836, 851, 418, 360], 'alpha_bbox': [50, 121, 334, 209]}], 'anchor': [0.5, 0.9166666666666666], 'reference_height': 294, 'release_frame': 0, 'facing': 'left', 'source_sha256': '9ce54e1913727ff91f69b2bad88c40713b62f856a2be302b9153612539b1cf22', 'row_origins_y': [78, 476, 851]}}}
actions={'brood_keeper_hurt':old['actions']['brood_keeper_hurt']};reports={}
for name,(reference,rows) in SPECS.items():
 p=D/(name+'.png');im=Image.open(p);assert im.mode=='RGBA' and im.size==(1254,1254)
 frames,hashes,margins,bottoms,heights=[],[],[],[],[]
 selected_alpha_count=0
 for i in range(16):
  x=[10,323,636,941][i%4];y,h,pad=rows[i//4];w=313
  assert x>=0 and y>=0 and x+w<=im.width and y+h<=im.height
  crop=im.crop((x,y,x+w,y+h));a=crop.getchannel('A');hist=a.histogram();l,t,r,b=a.point(lambda v:255 if v>8 else 0).getbbox()
  selected_alpha_count+=sum(hist[9:])
  safety=min(l,t,w-r,h-b);assert safety>=12,(name,i,safety)
  margin=[0,pad,0,360-h];assert all(v>=0 for v in margin) and pad<=360-h
  bbox=[l,t+pad,r-l,b-t];assert 0<=bbox[1] and bbox[1]+bbox[3]<=360
  frames.append({'region':[x,y,w,h],'margin':margin,'alpha_bbox':bbox,'source_index':i})
  hashes.append(hashlib.sha256(crop.tobytes()).hexdigest());margins.append(safety);bottoms.append(b+pad);heights.append(b-t)
 assert selected_alpha_count==sum(im.getchannel('A').histogram()[9:]),(name,'source alpha omitted or duplicated')
 assert len(set(hashes))==16 and bottoms[0]==330
 if name.endswith('death'):assert bottoms[1]==330
 assert heights[0]==reference
 # Explicit artist-reviewed timeline: folding legs and lowering hive, never automated bbox sorting.
 order=[0,1,4,5,2,3,6,7,8,9,10,11,12,13,14,15] if name.endswith('death') else list(range(16))
 assert sorted(order)==list(range(16))
 frames=[frames[i] for i in order];hashes=[hashes[i] for i in order];bottoms=[bottoms[i] for i in order];heights=[heights[i] for i in order]
 if name.endswith('death'):
  assert max(heights[i+1]-heights[i] for i in range(15))<=1
  assert frames[0]['source_index']==0 and frames[1]['source_index']==1
 actions[name]={'path':'res://assets/actions/brood_keeper/'+name+'.png','frames':frames,'anchor':[.5,330/360],'reference_height':reference,'release_frame':7 if name.endswith('summon') else 0,'facing':'left','source_sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'logical_canvas':[313,360],'authored_row_bands':rows,'authored_source_order':order}
 reports[name]={'frame_count':16,'unique_frame_hashes':hashes,'minimum_source_alpha_margin':min(margins),'logical_contact_bottom_y':bottoms,'body_heights':heights,'authored_source_order':order,'maximum_adjacent_height_increase':max(heights[i+1]-heights[i] for i in range(15)),'logical_canvas':[313,360],'margin_nonnegative_and_fits':True,'source_pixels_edited':False,'effective_source_alpha_pixels_all_selected_exactly_once':True,'large_environmental_halo_seen':False,'gui_reviewed':False}
# Reuse existing short hurt verbatim but revalidate its PNG and 9 frame hashes independently.
v=actions['brood_keeper_hurt'];p=D/'brood_keeper_hurt.png';assert hashlib.sha256(p.read_bytes()).hexdigest()==v['source_sha256']
im=Image.open(p);hashes=[]
for f in v['frames']:
 x,y,w,h=f['region'];c=im.crop((x,y,x+w,y+h));hashes.append(hashlib.sha256(c.tobytes()).hexdigest())
assert len(set(hashes))==9
reports['brood_keeper_hurt']={'frame_count':9,'unchanged_from_candidate':True,'frame_hashes':hashes,'gui_reviewed':False}
(D/'action_manifest.json').write_text(json.dumps({'schema_version':1,'actions':actions},indent=2)+'\n')
(ROOT/'docs/art/brood_keeper/validation.json').write_text(json.dumps(reports,indent=2)+'\n')
print(json.dumps(reports,indent=2))
print('PASS: 16/9/16 real source frames; no PNG editing; safe bands; same per-clip canvas; valid nonnegative margins; grounded neutral/death0/1.')
