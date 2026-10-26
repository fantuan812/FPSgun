"""Strict old-content preservation audit; paths are explicit caller inputs.

This script is prepared before the v23 implementation and is not a test result.
Only the named additions and one catalog version increment are permitted.
"""
import argparse
import hashlib
import json
from pathlib import Path

p = argparse.ArgumentParser()
p.add_argument("baseline", type=Path)
p.add_argument("candidate", type=Path)
p.add_argument("output", type=Path)
a = p.parse_args()
base = json.loads((a.baseline / "data/catalog.json").read_text())
candidate = json.loads((a.candidate / "data/catalog.json").read_text())
checks = []

def check(ok, label):
    checks.append({"label": label, "pass": bool(ok)})

expected_weapons = ["rivet_gun", "scrap_shotgun", "rail_lance", "orbit_saw", "return_disc", "shock_mortar", "cryo_sprayer"]
expected_items = ["power_coil", "cooling_fan", "iron_plate", "moss_patch", "running_boots", "salvage_magnet", "lucky_chip", "lens", "capacitor", "gear", "pellet_pouch", "recycler", "arc_relay", "kill_cell", "dash_resin", "mirror_shell", "thorn_crown", "blood_valve", "scrap_mine", "pulse_boots", "return_spool", "blast_fuse", "echo_chamber", "gravity_anchor", "medic_seed", "phase_capacitor", "fracture_coil"]
for key, old_ids, addition in [("weapons", expected_weapons, "bankshot_driver"), ("items", expected_items, "bounce_guide")]:
    old = base[key]
    new = candidate[key]
    check([x["id"] for x in old] == old_ids, "baseline exact ordered " + key + " ID set")
    check(len(new) == len(old_ids) + 1 and {x["id"] for x in new} == set(old_ids + [addition]), "candidate exact " + key + " ID set, no duplicate/missing entry")
    check([x for x in new if x["id"] != addition] == old, "all inherited " + key + " fields and order unchanged")

check(set(candidate) == set(base), "catalog top-level key set unchanged")
for key, old in base.items():
    if key in ("weapons", "items", "mechanism_synergies", "affinity_links", "version"):
        continue
    check(candidate[key] == old, "unchanged catalog field " + key)
check(candidate["version"] in (base["version"], base["version"] + 1), "version unchanged or one explicit content increment")

synergies = candidate["mechanism_synergies"]
new_pairs = [x for x in synergies if x["id"] == "banked_vector"]
check([x for x in synergies if x["id"] != "banked_vector"] == base["mechanism_synergies"], "old mechanism definitions/order unchanged")
check(len(new_pairs) == 1 and set(new_pairs[0]["requires"]) == {"bankshot_driver", "bounce_guide"}, "exact one pair with exact two prerequisites")
links = candidate["affinity_links"]
old_links = [x for x in links if "bankshot_driver" not in x and "bounce_guide" not in x]
new_links = [x for x in links if "bankshot_driver" in x or "bounce_guide" in x]
check(old_links == base["affinity_links"], "old affinity links/order unchanged")
check(len(new_links) == 1 and set(new_links[0]) == {"bankshot_driver", "bounce_guide"}, "exact one new affinity link")
for file in ("data/balance.json", "data/room_encounters.json", "data/actor_actions.json"):
    check((a.baseline / file).read_bytes() == (a.candidate / file).read_bytes(), "unchanged " + file)

report = {
    "scope": "Strict accepted-v22 definition preservation; allows only two IDs, one pair/link, optional single version increment. Not a runtime test.",
    "baseline_catalog_sha256": hashlib.sha256((a.baseline / "data/catalog.json").read_bytes()).hexdigest(),
    "candidate_catalog_sha256": hashlib.sha256((a.candidate / "data/catalog.json").read_bytes()).hexdigest(),
    "checks": checks,
    "failures": [x["label"] for x in checks if not x["pass"]],
}
a.output.write_text(json.dumps(report, indent=2) + "\n")
print(json.dumps({"checks": len(checks), "failures": report["failures"]}))
raise SystemExit(bool(report["failures"]))
