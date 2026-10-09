"""Author JSON fixtures from the visual source manifest, not a gameplay validator.
No Unreal import or rule-test execution. Re-run only when authoring data changes.
"""
from pathlib import Path
import argparse
import hashlib
import json


def generate(source: Path, root: Path):
    raw = source.read_bytes()
    visual = json.loads(raw)
    definitions = {}
    tags = set()
    for part_id, module in sorted(visual['modules'].items()):
        platform = module['platform_id']
        is_root = part_id == f'{platform}.core'
        part_tags = [f"mount.{module['mount_type']}"]
        if platform:
            part_tags.append(f'platform.{platform}')
        slots = []
        for slot_id, s in sorted(module['slots'].items()):
            x, y, z, w = s['rotation_xyzw']
            tx, ty, tz = s['translation_m']
            slots.append({
                'id': slot_id, 'accepts_any': [f"mount.{s['mount_type']}"],
                'required': bool(platform and s['mount_type'].startswith(platform + '.')),
                'capacity': 1, 'occupancy_tokens': [s['occupancy_group']],
                'local_transform': {'translation_cm': [100*tx, -100*ty, 100*tz],
                                    'rotation_xyzw': [-x, y, -z, w], 'scale': s['scale']},
            })
        definitions[part_id] = {
            'id': part_id, 'weapon_root': is_root, 'tags': part_tags,
            'requires_all': [], 'excludes_any': [], 'slots': slots,
            'base_stats': {'handling': 50.0, 'stability': 50.0} if is_root else {},
            'add_stats': {} if is_root else {'handling': -1.0},
            'multiply_stats': {}, 'max_durability': 100,
            'mesh': None, 'animations': {}, 'effects': {},
            'source_mesh_glb': 'ContentSource/Weapons/ModularAssemblyV1/exports/' + module['mesh_glb'],
        }
        tags.update(part_tags)
        for slot in slots:
            tags.update(slot['accepts_any'])
    data = {
        'schema_version': 1,
        'status': 'AUTHORING_DATA_NOT_UASSET_NOT_ENGINE_VALIDATED',
        'source_manifest_sha256': hashlib.sha256(raw).hexdigest(),
        'transform_contract': {'source': 'RH meters +X forward +Z up', 'target': 'UE LH centimeters +X forward +Z up',
                               'position': '(100*x,-100*y,100*z)', 'quaternion_xyzw': '(-x,y,-z,w)',
                               'mesh_import': 'Mesh basis must be converted consistently; not yet imported or verified'},
        'max_instances': 256, 'max_depth': 8, 'max_parts_per_weapon': 64,
        'definitions': definitions,
    }
    (root/'Data/Presets').mkdir(parents=True, exist_ok=True)
    (root/'Data/AssemblyCatalog.json').write_text(json.dumps(data, indent=2) + '\n')
    for preset in visual['presets']:
        instances = []
        links = []
        for n in preset['nodes']:
            instances.append({'id': n['instance_id'], 'definition_id': n['module_id'], 'durability': 100,
                              'quality': 0, 'affixes': {}, 'bound_owner': '', 'locked': False})
            if n['parent_id'] is not None:
                links.append({'child': n['instance_id'], 'parent': n['parent_id'], 'slot': n['slot_id']})
        state = {'schema_version': 1, 'revision': '0', 'instances': sorted(instances, key=lambda x:x['id']),
                 'links': sorted(links, key=lambda x:x['child'])}
        (root/'Data/Presets'/f"{preset['id']}.json").write_text(json.dumps(state, indent=2) + '\n')
    tag_path = root/'Plugins/FPSAssembly/Config/Tags/FPSAssemblyTags.ini'
    tag_path.parent.mkdir(parents=True, exist_ok=True)
    tag_path.write_text('[/Script/GameplayTags.GameplayTagsList]\n' + ''.join(
        f'+GameplayTagList=(Tag="{tag}",DevComment="FPSAssembly authored mount/platform")\n' for tag in sorted(tags)))


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('visual_manifest', type=Path)
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()
    generate(args.visual_manifest, args.root)
