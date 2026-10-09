"""Pure preflight for UE asset-name identity; no Unreal imports or asset writes."""
import re


def output_names(ids):
    # Unreal asset/package names normalize punctuation; never let distinct stable IDs collide.
    names = {}
    # Shares the Definitions package with the final DA_AssemblyCatalog asset.
    seen = {"assemblycatalog"}
    for part_id in ids:
        if not isinstance(part_id, str) or not re.fullmatch(r'[a-z0-9._-]{1,96}', part_id):
            raise ValueError('Invalid stable ID for asset authoring: ' + str(part_id))
        name = part_id.replace('.', '_').replace('-', '_')
        folded = name.casefold()
        if folded in seen:
            raise ValueError('Stable IDs collide after asset-name normalization: ' + part_id)
        seen.add(folded)
        names[part_id] = name
    return names


