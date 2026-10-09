"""Generate C++ fixture data from the same authored JSON. Does not execute tests."""
from pathlib import Path
import json


def quote(s):
    return json.dumps(s, ensure_ascii=True)


def generate(root):
    data = json.loads((root/'Data/AssemblyCatalog.json').read_text())
    lines = ['#pragma once', '#include "Rules/AssemblyRules.h"',
             '// Generated authored data; not evidence that these fixtures passed.',
             'inline fpsassembly::Catalog AuthoredCatalog() {', 'fpsassembly::Catalog c;']
    for field in ('max_instances', 'max_depth', 'max_parts_per_weapon'):
        lines.append(f'c.{field} = {data[field]};')
    for key, d in sorted(data['definitions'].items()):
        lines += ['{ fpsassembly::Definition d;', f'd.id = {quote(key)};', f'd.weapon_root = {str(d["weapon_root"]).lower()};']
        for field in ('tags', 'requires_all', 'excludes_any'):
            for value in d[field]:
                lines.append(f'd.{field}.insert({quote(value)});')
        lines.append(f'd.max_durability = {d["max_durability"]};')
        for field in ('base_stats', 'add_stats', 'multiply_stats'):
            for stat, value in d[field].items():
                lines.append(f'd.{field}[{quote(stat)}] = {value};')
        for s in d['slots']:
            lines += ['{ fpsassembly::Slot s;', f's.id = {quote(s["id"])};',
                      f's.required = {str(s["required"]).lower()};', f's.capacity = {s["capacity"]};']
            for field in ('accepts_any', 'occupancy_tokens'):
                for value in s[field]:
                    lines.append(f's.{field}.insert({quote(value)});')
            lines += ['d.slots.push_back(s); }']
        lines += ['c.definitions.emplace(d.id, d); }']
    lines += ['return c; }', 'inline std::map<std::string, fpsassembly::State> AuthoredPresets() {',
              'std::map<std::string, fpsassembly::State> states;']
    for path in sorted((root/'Data/Presets').glob('*.json')):
        state = json.loads(path.read_text())
        lines += ['{ fpsassembly::State s;', f's.revision = {state["revision"]};']
        for i in state['instances']:
            lines += ['{ fpsassembly::Instance i;', f'i.id = {quote(i["id"])};', f'i.definition_id = {quote(i["definition_id"])};',
                      f'i.durability = {i["durability"]};', f'i.quality = {i["quality"]};', 's.instances.emplace(i.id, i); }']
        for link in state['links']:
            lines.append('s.links.push_back({' + ','.join(quote(link[k]) for k in ('child','parent','slot')) + '});')
        lines += [f'states.emplace({quote(path.stem)}, s); }}']
    lines += ['return states; }']
    (root/'Tests/AssemblyFixtures.h').write_text('\n'.join(lines) + '\n')


if __name__ == '__main__':
    generate(Path(__file__).resolve().parents[1])
