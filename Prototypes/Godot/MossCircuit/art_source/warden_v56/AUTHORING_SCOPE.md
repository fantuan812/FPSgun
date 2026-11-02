# Scrap Warden — editable body art (v56)

## What is editable

Five self-contained semantic SVG masters cover 59 poses: walk 9, base attack 9, charge 16, hurt 9 and death 16. The layered olive/moss chassis, inset cream visor and amber eyes, copper stack, gray block fist, orange gauntlet, joint links and thick feet are independently described vector parts. The accepted R2 design uses overlapping front/top/side armor and component-led raised, braced, bent and collapsed poses rather than globally flattening a standing body.

PNG exports retain their original game paths:

- `assets/enemies/boss_warden.png`
- `assets/actions/boss_warden_attack.png`
- `assets/actions/boss_warden/boss_warden_charge.png`
- `assets/actions/boss_warden/boss_warden_hurt.png`
- `assets/actions/boss_warden/boss_warden_death.png`

The masters live under `art_source/warden_v56/`, excluded from engine import and release-pack payloads. Do not create a second base-attack path inside the Warden action folder.

## Registration is a contract, not a new measurement

All sheets are 1254 × 1254 pixels. The neutral world reference height is **148.2**, with base foot **[0, 74.1]**. Runtime registration remains exactly the original one:

| Clip | Frames | Logical canvas | Reference height | Draw scale | Anchor | Sprite offset |
|---|---:|---|---:|---|---|---|
| Walk | 9 | 418 × 418 | 184 | 741/920 | [209,398] | [0,-97] |
| Base attack | 9 | 418 × 340 | 213 | 247/355 | [209,328] | [0,-51.5] |
| Charge | 16 | 512 × 400 | 207 | 247/345 | [256,320] | [0,-16.5] |
| Hurt | 9 | 512 × 400 | 258 | 247/430 | [256,320] | [0,9] |
| Death | 16 | 512 × 400 | 213 | 247/355 | [256,320] | [0,-13.5] |

Walk uses the live `enemy_manifest.json` region and XYWH `alpha_bbox`, not a root-path fallback or an `alpha_bounds` override. Its original margins include half-pixel values. The whole `art_source/alpha_bounds.json` is unchanged. Action margins are integral (base attack has zero margins); full action records, anchors, reference heights and release metadata are unchanged.

The base attack's source windows are 418 × 340 at row origins 125, 508 and 843. The three intersections between the second and third rows are transparent five-pixel bands. They are legitimate overlapping windows, not a disjoint-grid mistake to repair by cropping or masking. New art preserves the bands without hiding painted geometry.

Source order is intentionally heterogeneous: base attack retains `source_frame`; charge, hurt and death retain `source_pose_index`. Hurt runtime frames 6 and 7 use physical source poses 7 and 6. Death order is `[0,1,4,5,2,6,3,8,7,9,10,11,12,13,14,15]`. Charge's authored x offset, row translations and recovery x corrections are already embodied in the existing records; do not apply them a second time.

## Pixel lineage versus live bounds

The new PNGs are SVG redraw exports, not unchanged original raster masters. Existing base-attack `sha256` and current `source_sha256` mean PNG file bytes; `source_svg_sha256` means SVG file bytes. Walk frame `pixel_sha256` means the whole original 418 × 418 source-cell RGBA, not a fixed-crop hash or an imported texture hash.

The old selected manifest records and original PNG identities remain in provenance. Original live walk crop fields, historical minimum-clearance fields and complete action frame records are preserved. New source-window-local alpha bounds and clearances are separate current QA/provenance facts; they must not replace live crops, reference heights, offsets or anchors. ART window-visible/crop-alpha identities and actually observed imported raw identities are distinct evidence, never interchangeable.

Runtime metadata authorities are the enemy manifest, generic `assets/actions/action_manifest.json` for base attack, Warden `action_manifest.json` for hurt/death, Warden `attack_manifest.json` for charge, whole `alpha_bounds.json`, and `data/actor_actions.json`. Five independent source reports use the shared typed per-sheet contract; the count derives as 10 sheet predicates + 6 metadata predicates + 12 per frame + 2 footer predicates: 126/126/210/126/210. Packed comparison requires the corresponding actual source report as its fourth argument, not an aggregate report or substituted ART raw data.

## Gameplay presentation is unchanged

The body artwork does not create damage or spawn events. Existing AI, collision, action selection, targeting and lifecycle code/data remain unchanged.

- Charge uses warning frames 0–5, charging frames 6–11 and recovery frames 12–15. The existing phase durations are 0.85, 0.6 and 0.8 seconds. Stored aim/facing behavior is unchanged.
- Base attack anticipates through frames 0–4, releases at frame 5 and recovers through frame 8. The existing attack/reaction timing is distinct from charge phase playback. Hurt and death priority/order remain unchanged.
- Charge/contact use the existing actor position. The charge telegraph and the radius-105 blast at the stored target are separate gameplay presentation, not a new hand socket or painted hitbox.
- Small named body-local impact sparks and charge dust are editable decorative accents. They are not target footprints, projectiles, hit markers or damage authority.
- Hurt duration 0.27 seconds, death duration 0.72 seconds, cleanup, rewards and the Warden-specific defeat effect are unchanged. This art change is not a broad boss-mechanics reevaluation.

## Evidence and honest limits

The original R1 three-key artwork passed numerical containment but received an art HOLD for flat frontal body and flattened pose reading. It remains preserved. Accepted R2 three keys were reused while twelve complementary keys were exported separately; the combined fifteen-key review then preceded the full five-sheet export. Full59 review and the independent fresh five-sheet repeat are separate from cold import, source/packed identity, bounded native observations and local release acceptance.

The pre-freeze charge-arm coordinate finding and its genuine geometry correction remain recorded; no failed raster was silently replaced. Full-sheet comparison pages preserve the actual registration affine and selected mirrors, without fitting or recentering. A known undelivered author page1 display was recovered explicitly and disclosed; no exactly-once-open claim is made for that page.

Walk motion, hurt 6/7, near/far charge legs and late collapse details are subtle at actual size. Raised arm links are slimmer and more mechanical than the old reference; the new style is more planar and sparsely weathered. Static sheets and mirrors demonstrate pose structure, not live cadence, locked aim, collision, damage or full combat coverage. Native numerical observations and directly imaged behavior must be reported separately.

No public Git or ledger publication is implied by this guide or a local release. The current private checkpoint should contain the current source, required fixtures/cache and all new art/review evidence physically, with any historical aliases explicitly identified.
