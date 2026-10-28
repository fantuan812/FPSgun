# Portable compact BUILD validation

Run `python3 tools/run_build_ui_checks.py` from the merged project root after a clean Godot4.6.3 import. The default project is the current directory; fixture/tool paths resolve relative to the installed runner, not an author workspace. Python3 uses only the standard library. `GODOT` or `--godot` can name the engine; `--manifest-sha256` optionally requires an exact manifest identity. Output must be new and outside source; all original streams, native exits, parsed records, per-route verdicts and before/after authored-source maps are retained. First failure stops; no automatic retry.

## Fixed14 routes

| Route | Preserved expected marker/checks | Fixture origin |
|---|---:|---|
| ui__test_ui | UI_STRUCTURE_AND_INTENTS_PASS | accepted real-disclosure adapter |
| tests__independent_ui | {'independent_ui_passed': 84} | unchanged original |
| tests__independent_focus_views | {'checks': 366} | unchanged original |
| tests__independent_tag_views | {'tag_view_checks': 848} | accepted real-disclosure adapter |
| tests__test_tag_synergy_progress | {'tag_synergy_progress_checks': 467} | accepted real-disclosure adapter |
| tests__independent_weapon_readouts | {'checks': 465} | accepted real-disclosure adapter |
| tests__test_weapon_readout | {'weapon_readout_checks': 411} | accepted real-disclosure adapter |
| tests__independent_tempering_views | {'checks': 872} | accepted real-disclosure adapter |
| tests__independent_weapon_order_views | {'checks': 512} | accepted real-disclosure adapter |
| tests__independent_scavenger_views | {'checks': 132} | accepted real-disclosure adapter |
| tests__independent_starting_loadout_views | {'checks': 544} | accepted real-disclosure adapter |
| tests__test_discrete_ui_numbers | {'discrete_ui_checks': 34} | accepted real-disclosure adapter |
| tests__test_modifier_copy | {'modifier_copy_checks': 112} | accepted real-disclosure adapter |
| context_guard | {'checks': 84} | new controlled context84 |

The11 adapted bodies actually expand the new top-level groups and existing STAT NOTES/ITEM DETAILS before original visible-content assertions. All old checks remain unchanged. The two originals are independent_ui and independent_focus_views; context_guard uses actual I/BACK/Escape and expanded focus/reopen in7 controlled contexts. Room-clear setup is controlled, not a natural combat-clear claim.

The manifest hashes every shipped fixture/tool, all frozen gameplay/data/scenes/assets/UI inputs and historical-helper dependencies. The three JSON documentation oracles read by test_modifier_copy are also pinned. Only non-oracle prose and release metadata may change without changing runtime pins. A complete authored-source snapshot (excluding generated .godot and VCS .git) must remain byte-identical during each invocation. Cold import is separate; it may generate UID metadata for the new tests. No old935 source or accepted PCK is rewritten by this entry.

Pass means14 routes /4931 numeric checks plus one UI text-marker route, with original finite scopes. It does not mean full165, all-card/all-status geometry, new ordinary acquisition, native pixels, physical sound, Windows execution or balance coverage. Dummy audio is teardown evidence, not listening. Exactly48 known historical Scavenger draw_rect warnings are accepted only as the exact complete recorded block; all other stderr/warnings fail. Original parser and strict scene-payload failures remain distinct historical evidence.
