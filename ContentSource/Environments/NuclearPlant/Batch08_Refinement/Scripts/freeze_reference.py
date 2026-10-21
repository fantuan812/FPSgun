import pathlib,json,hashlib,datetime
R=pathlib.Path(__file__).resolve().parent.parent
assert not (R/'QA/reference_freeze.json').exists(),'Freeze already exists; revisions require a new version directory/record.'
models=list((R/'Assets').glob('*.blend'))+list((R/'Regions').glob('*.blend'))+list(R.glob('*.blend'))
assert not models,models
inputs=[R/'Config/design.json',R/'Scripts/design_spec.py',R/'Scripts/draw_references.py',R/'Scripts/analytic_geometry.py',R/'QA/premodel_design_check.json',R/'QA/reference_review.md']+sorted((R/'References').glob('*'))
C=json.loads((R/'Config/design.json').read_text());source=(R/C['source']).resolve()
f={'stage':'PRE_MODEL_REFERENCE_FREEZE','utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'models_present_at_freeze':[],'model_absence_verified':True,'source_path':C['source'],'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'reference_type':'Analytic orthographic design drawings produced outside Blender. Not model renders.','inputs':{str(p.relative_to(R)):hashlib.sha256(p.read_bytes()).hexdigest() for p in inputs}}
(R/'QA/reference_freeze.json').write_text(json.dumps(f,indent=2));print(json.dumps({'utc':f['utc'],'source_sha256':f['source_sha256'],'inputs':len(inputs),'models_present':models},default=str))
