import json,pathlib
R=pathlib.Path(__file__).resolve().parents[1]
def sock(i,p,n):return {'id':i,'position_m':p,'outward_normal':n,'nominal_deck_width_m':2.0,'clear_width_m':1.75}
assets=[
('Catwalks','SM_NPP_Catwalk_Straight_4m_A','straight',[4,2,1.3],[0,-1,-.2],[4,1,1.1],[sock('start',[0,0,0],[-1,0,0]),sock('end',[4,0,0],[1,0,0])]),
('Catwalks','SM_NPP_Catwalk_Corner90_A','corner',[4,4,1.3],[0,-1,-.2],[4,3,1.1],[sock('start',[0,0,0],[-1,0,0]),sock('turn',[3,3,0],[0,1,0])]),
('Catwalks','SM_NPP_Catwalk_TJunction_A','tee',[4,4,1.3],[0,-1,-.2],[4,3,1.1],[sock('start',[0,0,0],[-1,0,0]),sock('end',[4,0,0],[1,0,0]),sock('branch',[2,3,0],[0,1,0])]),
('Stairs','SM_NPP_Stair_4x2_Rise2_A','stairs',[4,2,3.3],[0,-1,-.2],[4,1,3.1],[sock('lower',[0,0,0],[-1,0,0]),sock('upper',[4,0,2],[1,0,0])]),
('Railings','SM_NPP_Railing_Open_4m_A','rail_open',[4,.125,1.1],[0,-.0625,0],[4,.0625,1.1],[]),
('Railings','SM_NPP_Railing_Infill_2m_B','rail_infill',[2,.125,1.1],[0,-.0625,0],[2,.0625,1.1],[]),
('Structure','SM_NPP_Column_4m_A','column',[.5,.5,4],[-.25,-.25,0],[.25,.25,4],[]),
('Pipes','SM_NPP_PipeSupport_2m_A','pipe_support',[2,.5,2],[-1,-.25,0],[1,.25,2],[])
]
manifest=[]
for cat,id,kind,dims,bmin,bmax,sockets in assets:
 p=R/'ModularKit'/cat/id;p.mkdir(parents=True,exist_ok=True)
 s={'asset_id':id,'category':cat,'builder':kind,'units':'meters','dimensions':dims,'bounds_min':bmin,'bounds_max':bmax,'origin_m':[0,0,0],'grid_size':.25,'primary_module_size':4,'walkable_surface_z':0 if kind in ['straight','corner','tee'] else None,'connection_sockets':sockets,'coordinate_convention':{'up':'+Z','front_camera':'-Y','right_camera':'+X','top_camera':'+Z'},'reference_views':['front.png','right.png','top.png'],'concept_reference':'reference_sheet.png','materials':['M_NPP_SteelGraphite','M_NPP_Galvanized','M_NPP_SafetyYellow','M_NPP_BoltSteel'],'uv_policy':'UV0 per-part box projection in real meters; UV1 non-overlap generated atlas; no textures required','collision_policy':'UCX closed convex boxes, rail blockers and stair ramp; hidden in beauty renders; exported separately and per-asset FBX','detail_note':'0.25 m is socket and assembly grid. Sub-grid fabrication details and 0.20 m stair risers are intentional.'}
 if kind=='corner':s['footprint_rects']=[[0,4,-1,1],[2,4,1,3]]
 if kind=='tee':s['footprint_rects']=[[0,4,-1,1],[1,3,1,3]]
 if kind=='straight':s['footprint_rects']=[[0,4,-1,1]]
 if kind=='stairs':s.update({'steps':10,'rise_m':2,'run_m':4,'tread_m':.4,'riser_m':.2,'rail_top_z_formula':'1.1 + 0.5 * X'})
 (p/'spec.json').write_text(json.dumps(s,indent=2));manifest.append({'asset_id':id,'category':cat,'kind':kind,'path':str(p.relative_to(R)),'stage':'first_batch'})
(R/'manifest.json').write_text(json.dumps({'project':'NPP / Sector K-17','scope':'Original near-future nuclear power facility. First modular production batch and original whole-site graybox, not a replica of any game map.','assets':manifest},indent=2))
zones=[
 {'id':'01_REACTOR','name':'Reactor containment','center':[-48,32,12],'size':[48,48,24],'color':[.48,.57,.58]},
 {'id':'02_TURBINE','name':'Turbine hall','center':[16,40,8],'size':[64,32,16],'color':[.57,.63,.63]},
 {'id':'03_CONTROL','name':'Control and security','center':[-48,-28,6],'size':[32,24,12],'color':[.68,.72,.70]},
 {'id':'04_PUMP','name':'Pump and water treatment','center':[8,-16,4],'size':[32,24,8],'color':[.48,.61,.64]},
 {'id':'05_COOLING','name':'Cooling yard','center':[72,32,6],'size':[32,48,12],'color':[.48,.55,.57]},
 {'id':'06_TRANSFORMER','name':'Electrical switchyard','center':[64,-36,2],'size':[40,32,4],'color':[.68,.65,.55]},
 {'id':'07_SERVICE','name':'Service and logistics','center':[-4,-60,4],'size':[48,24,8],'color':[.62,.65,.61]},
 {'id':'08_INTAKE','name':'Water intake station','center':[-84,40,4],'size':[16,32,8],'color':[.48,.56,.62]}
]
block={'site_bounds_m':[224,192],'base_grid_m':.25,'building_grid_m':4,'zones':zones,'routes':{'ground':'Main service loop at Z=0 with 8 m wide roads','maintenance':'Connected elevated walkways at Z=4','upper':'Reactor upper ring and turbine mezzanine at Z=8'},'gameplay_note':'Spatial planning graybox only. No UE traversal, clearance, gameplay balance or fire-code certification performed.'}
(R/'Blockout'/'layout_spec.json').write_text(json.dumps(block,indent=2))
(R/'StyleGuide'/'asset_inventory.md').write_text('''# NPP / Sector K-17 — asset inventory\n\nOriginal near-future industrial facility, not a replica of any existing game map.\n\n## Batch 01 (production in this delivery)\n- 4 × 2 m straight catwalk\n- 4 × 4 m L-footprint 90-degree catwalk\n- 4 × 4 m T-junction catwalk\n- 4 × 2 m stair, 2 m rise\n- 4 m open safety railing\n- 2 m framed infill safety railing\n- 4 m steel support column\n- 2 m wide paired pipe support\n\n## Planned future batches (inventory, not completed assets)\n- Architecture: 4 m concrete walls, door / window / corner variants, slab and roof tiles\n- Pipes: 1 / 2 / 4 m pipe lengths, elbows, tee, valve, flanges\n- Equipment: pump, transformer, electrical cabinet, consoles\n- Hero: reactor containment, annular mezzanine, turbine assembly\n- Exterior: 4 / 8 m perimeter fence, road segment, bollard, floodlight mast\n\n## Palette and treatment\nGraphite structural steel, galvanized grating, safety ochre/yellow, restrained teal panels. Functional, bolted construction with subtle roughness variation. No copied brands, map layout, or proprietary game geometry.\n\n## Geometry authority\nSpec.json and actual Blender meshes are authoritative. Generated reference sheets guide materials and construction language only. Image generation does not certify dimensions.\n''')
print('8 module specs and site layout written')
