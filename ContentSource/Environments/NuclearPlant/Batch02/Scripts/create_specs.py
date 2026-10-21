import json,pathlib,hashlib
R=pathlib.Path(__file__).resolve().parents[1];FIRST=R.parent
frozen=json.loads((FIRST/'delivery_manifest.json').read_text());checks=[]
for e in frozen['files']:
 p=FIRST/e['path'];h=hashlib.sha256(p.read_bytes()).hexdigest();checks.append({'path':e['path'],'sha256':h,'matches_delivery':h==e['sha256']})
assert all(e['matches_delivery'] for e in checks),'Batch01 changed before Batch02'
(R/'Validation/batch01_freeze_before.json').write_text(json.dumps(checks,indent=2))
def socket(i,p,n,role,w=0):return {'id':i,'position_m':p,'outward_normal':n,'role':role,'nominal_width_m':w}
wall_s=[socket('start',[0,0,0],[-1,0,0],'wall_end',.3),socket('end',[4,0,0],[1,0,0],'wall_end',.3),socket('bottom',[2,0,0],[0,0,-1],'floor_bearing'),socket('top',[2,0,4],[0,0,1],'roof_bearing')]
entries=[
('SM_NPP_Wall_Solid_4m_A','solid_wall',[4,.3,4],[0,-.15,0],[4,.15,4],wall_s),
('SM_NPP_Wall_Door_2m_A','door_wall',[4,.3,4],[0,-.15,0],[4,.15,4],wall_s+[socket('passage',[2,0,0],[0,-1,0],'walkway_port',2)]),
('SM_NPP_Wall_Window_4m_A','window_wall',[4,.3,4],[0,-.15,0],[4,.15,4],wall_s),
('SM_NPP_Wall_Corner90_A','corner_wall',[4,4,4],[0,0,0],[4,4,4],[socket('start',[0,.25,0],[-1,0,0],'wall_end',.3),socket('turn',[3.75,4,0],[0,1,0],'wall_end',.3)]),
('SM_NPP_Floor_4x4_A','floor',[4,4,.25],[0,0,-.25],[4,4,0],[socket('south',[2,0,0],[0,-1,0],'walkway_port',2),socket('north',[2,4,0],[0,1,0],'floor_edge',4),socket('west',[0,2,0],[-1,0,0],'floor_edge',4),socket('east',[4,2,0],[1,0,0],'floor_edge',4),socket('underside',[2,2,-.25],[0,0,-1],'column_bearing')]),
('SM_NPP_Roof_4x4_A','roof',[4,4,.25],[0,0,0],[4,4,.25],[socket('underside',[2,2,0],[0,0,-1],'wall_bearing')]),
('SM_NPP_ColumnHead_075m_A','column_head',[.75,.75,.25],[-.375,-.375,0],[.375,.375,.25],[socket('column',[0,0,0],[0,0,-1],'column_bearing',.5),socket('slab',[0,0,.25],[0,0,1],'slab_bearing',.75)])
]
manifest={'project':'NPP / Sector K-17','batch':2,'scope':'Seven architecture modules and a two-level maintenance building assembly; basic PBR, not final environment art.','primary_module_m':4,'grid_m':.25,'assets':[],'reuses_batch01':['SM_NPP_Column_4m_A','SM_NPP_Catwalk_Straight_4m_A','SM_NPP_Stair_4x2_Rise2_A','SM_NPP_Railing_Open_4m_A']}
for id,kind,dims,bmin,bmax,sock in entries:
 p=R/'Assets'/id;p.mkdir(parents=True,exist_ok=True)
 s={'asset_id':id,'builder':kind,'units':'meters','dimensions':dims,'bounds_min':bmin,'bounds_max':bmax,'origin_m':[0,0,0],'grid_size':.25,'connection_sockets':sock,'coordinate_convention':{'up':'+Z','front_camera':'-Y','right_camera':'+X','top_camera':'+Z'},'concept_reference':'reference_sheet.png','validation_views':['front.png','right.png','top.png'],'material_level':'basic exportable PBR; no final weathering/trim/decal treatment','dimension_policy':'0.25 m placement and interface grid; 0.30 m envelope includes sub-grid fabrication details. Wall structural body 0.24 m plus bonded face panels and inset anchor heads.'}
 if kind=='door_wall':s['opening']={'clear_x':[1,3],'clear_z':[0,3],'clear_width_m':2,'clear_height_m':3,'rough_x':[.875,3.125],'rough_z':[0,3.125],'threshold':'flush Z=0, no sill obstacle'}
 if kind=='window_wall':s['opening']={'rough_x':[.75,3.25],'rough_z':[1,3],'frame_width_m':.125,'glass_thickness_m':.025,'traversable':False}
 if kind=='corner_wall':s['corner_pilaster']={'center':[3.75,.25,2],'dimensions':[.5,.5,4]}
 if kind=='column_head':s['assembly_height_example']={'batch01_column_base_z':-.5,'batch01_column_top_z':3.5,'head_base_z':3.5,'head_top_z':3.75,'floor_surface_z':4,'floor_bottom_z':3.75}
 (p/'spec.json').write_text(json.dumps(s,indent=2));manifest['assets'].append({'asset_id':id,'kind':kind,'path':str(p.relative_to(R))})
(R/'manifest.json').write_text(json.dumps(manifest,indent=2));print('BATCH02: 7 specs; Batch01 frozen and hash-verified')
