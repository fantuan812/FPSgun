"""Run INSIDE Unreal Editor Python, never with ordinary Python.

Two explicit phases:
  import_meshes(repo_root, '/Game/FPSAssemblyDemo', report_path)
  author_definitions(repo_root, reviewed_report_path)

Not executed for this delivery. Requires FPSAssembly plugin, Editor Python, and a
working GLB import factory (for example the project's configured Interchange GLTF).
The import report starts basis_verified=False. Inspect real imported geometry
against the documented RH->LH contract before marking it verified for authoring.
No overwriting existing assets; no guessed soft references; no claim of automatic
import-axis acceptance. Import errors may leave partial NEW assets for inspection.
"""
from pathlib import Path
import hashlib
import json
import unreal
from AssemblyAssetNames import output_names


PROPERTIES = ('id', 'weapon_root', 'tags', 'requires_all', 'excludes_any', 'slots',
              'base_stats', 'add_stats', 'multiply_stats', 'max_durability',
              'mesh', 'animations', 'effects')


def read_source(repo_root):
    root = Path(repo_root).resolve()
    file = root/'Data/AssemblyCatalog.json'
    raw = file.read_bytes()
    return root, json.loads(raw), hashlib.sha256(raw).hexdigest()


def import_meshes(repo_root, destination, report_path):
    root, data, digest = read_source(repo_root)
    if not destination.startswith('/Game/') or '..' in destination:
        raise ValueError('Use a new /Game/ destination')
    names = output_names(data['definitions'])  # Preflight the entire batch before any import.
    tools = unreal.AssetToolsHelpers.get_asset_tools()
    tasks, rows = [], []
    for part_id, definition in sorted(data['definitions'].items()):
        source = (root/definition['source_mesh_glb']).resolve()
        source.relative_to(root)
        if not source.is_file():
            raise FileNotFoundError(source)
        # Isolated subfolder prevents material/texture name collisions across module imports.
        folder = destination + '/Meshes/' + names[part_id]
        if unreal.EditorAssetLibrary.does_directory_exist(folder):
            raise RuntimeError('Refusing existing import folder: ' + folder)
        task = unreal.AssetImportTask()
        for key, value in {'filename':str(source), 'destination_path':folder,
                           'destination_name':'SM_' + names[part_id],
                           'automated':True, 'save':True, 'replace_existing':False}.items():
            task.set_editor_property(key, value)
        tasks.append(task)
        rows.append({'id':part_id, 'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),
                     'asset_path':None, 'basis_verified':False})
    tools.import_asset_tasks(tasks)
    for task, row in zip(tasks, rows):
        meshes = []
        for asset_path in task.get_editor_property('imported_object_paths'):
            asset = unreal.load_asset(asset_path)
            if isinstance(asset, unreal.StaticMesh):
                meshes.append(asset.get_path_name())
        if len(meshes) != 1:
            raise RuntimeError(f"{row['id']}: expected exactly one imported StaticMesh, got {meshes}")
        row['asset_path'] = meshes[0]
    report = {'catalog_sha256':digest, 'destination':destination, 'meshes':rows,
              'status':'IMPORTED_NOT_BASIS_VERIFIED',
              'required_review':'Compare actual source entry pivots, meter scale, +X/+Z, Y reflection and side-light -90deg source X orientation.'}
    Path(report_path).write_text(json.dumps(report, indent=2) + '\n')
    return report


def author_definitions(repo_root, reviewed_report_path):
    root, data, digest = read_source(repo_root)
    names = output_names(data['definitions'])  # Preflight before any asset creation.
    report = json.loads(Path(reviewed_report_path).read_text())
    if report['catalog_sha256'] != digest:
        raise RuntimeError('Import report belongs to another catalog version')
    rows = {r['id']:r for r in report['meshes']}
    if len(rows) != len(report['meshes']) or set(rows) != set(data['definitions']):
        raise RuntimeError('Missing, duplicate or unexpected module mappings')
    for part_id, definition in data['definitions'].items():
        row = rows[part_id]
        source = (root/definition['source_mesh_glb']).resolve()
        source.relative_to(root)
        if row.get('basis_verified') is not True or hashlib.sha256(source.read_bytes()).hexdigest() != row['source_sha256']:
            raise RuntimeError('Unverified or changed source mesh: ' + part_id)
        mesh = unreal.load_asset(row['asset_path'])
        if not isinstance(mesh, unreal.StaticMesh):
            raise RuntimeError('Mapping is not an actual StaticMesh: ' + part_id)
        definition['mesh'] = mesh.get_path_name()
    destination = report['destination'] + '/Definitions'
    asset_names = ['DA_' + names[key] for key in sorted(rows)] + ['DA_AssemblyCatalog']
    for name in asset_names:
        if unreal.EditorAssetLibrary.does_asset_exist(destination + '/' + name):
            raise RuntimeError('Refusing existing data asset: ' + name)
    # Native parser and Compile own rules/tags/transforms, the Python importer does not reimplement them.
    result = unreal.FPSAssemblyAuthoring.create_transient_catalog(unreal.get_transient_package(), json.dumps(data))
    transient, reason = result
    if not transient:
        raise RuntimeError('Catalog rejected: ' + reason)
    tools = unreal.AssetToolsHelpers.get_asset_tools()
    definitions = []
    for src in transient.get_editor_property('definitions'):
        factory = unreal.DataAssetFactory()
        factory.set_editor_property('data_asset_class', unreal.FPSAssemblyDefinition)
        name = 'DA_' + names[str(src.get_editor_property('id'))]
        asset = tools.create_asset(name, destination, unreal.FPSAssemblyDefinition, factory)
        if not asset:
            raise RuntimeError('Failed new asset; inspect partial import: ' + name)
        for prop in PROPERTIES:
            asset.set_editor_property(prop, src.get_editor_property(prop))
        if not unreal.EditorAssetLibrary.save_loaded_asset(asset):
            raise RuntimeError('Save failed: ' + asset.get_path_name())
        definitions.append(asset)
    factory = unreal.DataAssetFactory()
    factory.set_editor_property('data_asset_class', unreal.FPSAssemblyCatalog)
    catalog = tools.create_asset('DA_AssemblyCatalog', destination, unreal.FPSAssemblyCatalog, factory)
    if not catalog:
        raise RuntimeError('Failed catalog creation')
    catalog.set_editor_property('definitions', definitions)
    for field in ('max_instances','max_depth','max_parts_per_weapon'):
        catalog.set_editor_property(field, data[field])
    if not unreal.EditorAssetLibrary.save_loaded_asset(catalog):
        raise RuntimeError('Catalog save failed')
    return catalog.get_path_name()
