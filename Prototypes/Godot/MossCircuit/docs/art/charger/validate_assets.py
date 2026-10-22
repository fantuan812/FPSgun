"""Read-only PNG QA; writes only JSON manifests/reports, never edited raster files."""
from pathlib import Path
import hashlib, json
from PIL import Image
ROOT = Path(__file__).resolve().parents[3]
DIR = ROOT / 'assets/actions/charger'
SPECS = {'charger_charge': ([41,445,854],183), 'charger_hurt': ([37,436,837],174), 'charger_death': ([70,474,875],199)}
actions, reports = {}, {}
for name, (ys, height) in SPECS.items():
    path = DIR / (name+'.png')
    im = Image.open(path)
    assert im.mode == 'RGBA' and im.size == (1254,1254)
    frames, hashes, margins = [], [], []
    for i in range(9):
        x,y = (i%3)*418, ys[i//3]
        # Two authored grounded keyframes only, not automatic bbox normalization.
        if name == 'charger_death' and i in (0,1):
            y -= (11,7)[i]
        assert x+418<=im.width and y+320<=im.height
        crop = im.crop((x,y,x+418,y+320))
        alpha = crop.getchannel('A')
        bbox = alpha.point(lambda v:255 if v>8 else 0).getbbox()
        assert bbox
        l,t,r,b = bbox
        margin = min(l,t,418-r,320-b)
        assert margin>=12, (name,i,bbox)
        assert alpha.histogram()[0] / (418*320) > .4
        frames.append({'region':[x,y,418,320], 'alpha_bbox':[l,t,r-l,b-t]})
        hashes.append(hashlib.sha256(crop.tobytes()).hexdigest())
        margins.append(margin)
    assert len(set(hashes))==9
    actions[name]={'path':'res://assets/actions/charger/'+name+'.png','frames':frames,'anchor':[.5,300/320],'reference_height':height,'release_frame':4 if name=='charger_charge' else 0,'facing':'left','source_sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'row_origins_y':ys}
    if name == 'charger_death':
        actions[name]['authored_contact_corrections'] = {'0':{'region_y_delta':-11,'reason':'grounded_neutral_keyframe'},'1':{'region_y_delta':-7,'reason':'grounded_knee_buckle_keyframe'}}
        assert frames[0]['alpha_bbox'][1]+frames[0]['alpha_bbox'][3] == 300
        assert frames[1]['alpha_bbox'][1]+frames[1]['alpha_bbox'][3] == 300
    reports[name]={'nonempty_unique_frames':9,'minimum_effective_alpha_margin':min(margins),'frame_sha256':hashes,'large_environmental_halo_seen':False,'gui_integration_reviewed':False}
(DIR/'action_manifest.json').write_text(json.dumps({'schema_version':1,'actions':actions},indent=2)+'\n')
(ROOT/'docs/art/charger/validation.json').write_text(json.dumps(reports,indent=2)+'\n')
print('PASS 27 nonempty unique frames, RGBA, fixed canvas, alpha>8 margin >=12, SHA recorded. No GUI assertion.')
