# v14 Warden reaction-only engineering QA

Baseline: published v13 `56a6c721850fc3ef67caa0f766661a3970eb6a59`, 870 retained paths. Engine: Godot 4.6.3 stable. Date: 2026-10-24.

## Final verification

The final 2-PNG/manifest integration passed a fresh cache-free headless import and all **44 standalone test entry points**: 40 tests in `tests/`, the UI test, and three art-icon checks. Policy fixtures are inputs used by their owning tests, not standalone SceneTree entries. Full exit codes, engine-error checks and logs are under `logs/`.

- Author Warden reaction test: **38 assertions**, covering same-tick hurt/release, original charge movement and blast damage, no replay after hurt, lethal interruption before blast, terminal death, one-time protocol/reward and wave3 timer/settlement boundaries.
- Independent Warden reaction test: **942 assertions**, both modes/half-health phases and authority-state/overlay boundaries, first-pose scale, both facing directions, pause/reduced flashes/reset and death tail.
- Existing authored action suite: **314 assertions**. The exact approved set now contains21 IDs; only new Warden death joins the16-frame list. Old IDs/assertions remain.
- All **159 old runtime/scene/UI/assets/authority-data files** checked are byte-identical. Every runtime `.gd` is unchanged. The configuration checker verifies exactly two Warden reaction mappings plus one added manifest path, with no other `actor_actions.json` changes.
- Source analysis reproduces the installed Warden manifest byte-for-byte from the unchanged PNGs. Independent pixel/trace evidence is in `../independent-v14-warden/`; finite same-seed parity is not a proof over all play.

## Scope and limitations

Only Warden hurt9/.27s and death16/.72s are new. Existing charge/blast AI and shared attack9 presentation remain unchanged; no attack variant/lock policy, extra damage/event, timer or RNG change. Core hurt/death is still procedural. Early boss defeat does not bypass the arena timer; original settlement need not await corpse art, and original modal states freeze the visual tail.

Logical anchors/first-pose heights are verified, not a claim that visible feet or silhouette centers never move. Natural source pose variation is retained. Source sheet inspection does not equal live GUI play. No GUI/Windows export, audio/save/network or balance acceptance is claimed.

The initial pre-art author probe passed31 existing-authority assertions and failed exactly the two missing-resource assertions, as expected before images existed. That probe is not counted as final PASS. The full final suite uses the new assets and frozen independent script.

## Reproduction

```bash
python docs/validation/v14-warden/run_regression.py --output /tmp/moss-v14-qa
python docs/art/warden/build_metadata.py --project . --output /tmp/moss-v14-art
python docs/validation/v14-warden/verify_unchanged.py --baseline /path/to/published-v13 --candidate . --output /tmp/moss-v14-unchanged.json
```

The runner sets writable HOME and all three XDG directories. For a true cold import, use a fresh extracted ZIP (no `.godot` is shipped). Final delivery CRC/manifest/old-path verification happens independently on the frozen ZIP; package evidence is kept separately to avoid self-referential archive hashes.
