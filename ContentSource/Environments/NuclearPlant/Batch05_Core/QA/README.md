# Batch05 Core independent Blender QA

## Scope
Read-only inspection of the actual `core_hall.blend`, procedural sources and actual renders, against the user's request for an AZ3-inspired core area, coordinated industrial elements and larger rooms. The official AZ3 image is a style reference, not a surveyed floor plan. The image-generation concept and orthographic guidance are design aids, not a strict user-required pipeline or proof of finished geometry.

## Fixed issues found in inspection
- Both main stair routes had a structural brace and a gallery luminaire crossing headspace. At the sampled treads their clearance ranged from 1.68 m down to 0.06 m. Builder removed the interfering front brace/support and moved the light to the gallery proper. Retest passed.
- Large coolant pipes ended in open space short of the containment shell. Builder extended them into their actual device interface.
- Main annular walkway pipes created an overly narrow outside bypass. Builder moved the pipe routes inward; the tested outside walking band is now clear.
- The original front-road extension crossed the existing curb and shrubs. Builder shortened/repositioned that landscaping; retest passed.
- First preview had extreme Cycles noise, cropped crown and a mirrored rear CONTROL label. All five final Eevee renders were visually inspected. Noise, framing, mirrored lettering and central status-screen beam occlusion are corrected. Side and platform cameras were moved onto actual standing surfaces; exterior camera was moved onto the service road. The cutaway deliberately hides roof/front/right wall; its retained wall sign looks floating only in this visualization, not in the intact source.

## Actual static checks
Blender 4.3.2 reopened the final-at-checkpoint file with 1830 scene objects and no external library or unpacked image dependency. `check_scene.py` generated `clearance_report.json` without saving or modifying the scene.

The tested intended routes have 1703 sampling points, all with support within 0.25 m below the starting surface and no upward hit within 1.80 m, starting 0.055 m above that surface. Routes include main-ring radii 6.0 and 6.5 m, a sampled 0.6 m-wide band around radius 6.4 m, both radial bridges, both 25-step stair runs, ground ring radius 9 m, front entry, rear exit and the external service-road loop.

A deliberately inspected inner annulus at radius 5.5 m has four pipe obstructions. It is an equipment-occupied band, not an approved clear walking loop. Do not claim the entire platform surface is unobstructed.

## Limits
These are discrete vertical ray tests, not a swept capsule, continuous collision solver, navmesh, structural engineering assessment or UE gameplay test. They do not establish running, jumping, mantle/climbing, collision export or camera comfort in-game. The upper platform has a modeled fixed maintenance ladder but no tested character climbing logic. The source and exports need separate package/reopen validation after final packaging. This is an original AZ3-inspired scene, not an exact reconstruction or a finished full map.

## Re-run
From the packaged `QA` directory: `blender -b ../core_hall.blend --python check_scene.py`. The checker writes its report beside the script and never saves the scene.

The frozen geometry checked after floor underlay correction has SHA-256 `97f43189220fab7f2e776df9859050c23b64de8cec45d7352ff086f70a7e0309`. Floor panels end at -0.005 m; the continuous dark underlay ends at -0.015 m, leaving a 10 mm recessed joint rather than a deep opening. All intended route samples were rerun after this correction.

## Horizontal bridge entry check
`check_bridge_horizontal.py` traced 30 bridge-axis rays from x ±15 m to x ±6 m, at five lateral offsets spanning 1.2 m and heights 0.5, 1.0 and 1.5 m above the deck. All rays were unobstructed. The apparent crossbar at the bridge/ring join in the platform render is projection overlap, not a rail blocking the sampled entry. This does not replace swept collision validation.

## Final conclusion
The original AZ3-inspired core hall, coordinated service equipment and its immediate approach meet this batch's visual and static Blender checks. The result is a core-area scene iteration, not an exact copied map, full external level, final AAA art certification or playable UE acceptance. No additional scene edits were made by this independent checker.
