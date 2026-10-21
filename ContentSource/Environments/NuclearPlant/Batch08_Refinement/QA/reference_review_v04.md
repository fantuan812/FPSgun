# v04 pre-model local crossing revision review

Reviewed actual crossing_ground_profiles.png, east_service_link.png and southwest_receiving_plan.png before model creation. The seven original crossing groups now explicitly reference the retained old ground rather than world zero. E07 and unchanged E08/E09 are 27mm high; E10 is 27/10/10mm; each split SW branch is 10mm. Maximum within-cover level change is18mm and maximum external end difference from original ground is27mm. The numerical table is QA/crossing_levels_v04.md.

Only low-step cover placements were split/lowered. All module part geometry, non-crossing custom parts, cargo, terminals and old scene remain unchanged. Existing v03 module orthographic references remain active; v04 regional orthographic/master plans and enlarged vertical engineering profiles describe the new assembly. Vertical exaggeration is explicitly labelled on the profile sheet.

V03 partial rendering was stopped after its first frame because its world-zero crossing height was not the intended local-ground limit. No remaining obsolete render queue ran. All prior model binaries and images are retained in work history/QA gates, not substituted for final outputs. All target final model paths are absent for this freeze.
