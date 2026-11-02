# Amber Ram / Charger editable body sheets

## What is editable

Four newly authored, self-contained SVG masters contain nine explicit poses each:

- `charger_walk.svg` → `assets/enemies/charger.png`
- `charger_charge.svg` → `assets/actions/charger/charger_charge.png`
- `charger_hurt.svg` → `assets/actions/charger/charger_hurt.png`
- `charger_death.svg` → `assets/actions/charger/charger_death.png`

These are new semantic vector redraws, not recovered historical masters. The earlier AI-created PNGs remain references/history, not embedded raster layers. The current SVGs use named frame and anatomical groups: ivory horn/collar, rounded overlapping shoulder and haunch armor, moss ridge, shadowed belly, vents, hinge joints, legs and boots. Gait, brace, charge/recovery, flinch and collapse have distinct component poses rather than nine uniform transforms.

Keep all artwork self-contained. Do not add external resources, fonts, scripts, raster embedding, clipping masks or alpha-only alignment pixels. Exported PNGs are formal derivatives; edit the SVGs rather than painting the PNGs independently.

## Fixed registration — do not regenerate from new alpha bounds

The sheet is 1254×1254. Walk uses nine 418×418 source cells with **different existing live XYWH crops** in `enemy_manifest.json`; the runtime pads each crop back to its fixed logical canvas. Preserve every existing `region`, `alpha_bbox` and padding relationship. The walk sprite's reference height is 126 source pixels; its requested world height is **68.4**, and its base foot is **(0, 34.2)**. Do not recenter or normalize each new silhouette.

Action logical windows are 418×320, with anchor `(0.5, 0.9375)` = `(209, 300)` and zero margins. Preserve the full per-frame records, not just the nominal row table:

| Action | Per-frame source Y positions | Reference height |
| --- | --- | --- |
| Charge | 41, 41, 41, 445, 445, 445, 854, 854, 854 | 183 |
| Hurt | 37, 37, 37, 436, 436, 436, 837, 837, 837 | 174 |
| Death | **59, 63**, 70, 474, 474, 474, 875, 875, 875 | 199 |

Death frames 0/1 intentionally retain their earlier contact correction at Y59/Y63. Replacing both with nominal Y70 reintroduces a float. Existing reference heights/anchors determine scale; new measured bounding boxes do not.

All painted geometry must remain inside its fixed crop and above its original painted foot plane. Thick round stroke endcaps can protrude beyond a boot even when the boot polygon itself fits. The current rig uses butt caps on concealed thick leg segments and floor-aware low-joint thickness/hinge height, preserving real boot volume and joint centers. Inspect all frame geometry; never hide overflow with alpha masks or crop edits.

## Runtime behavior remains authoritative

The source-facing body is left. Runtime mirroring and locked aim remain unchanged. Walk selection uses the existing 9 fps logic. Charge presentation follows the actual AI phases, not a replacement nine-frame clock:

- Warning 0.65 s → visual frames 0–3.
- Charging 0.6 s → visual frames 4–6.
- Recovery 0.8 s → visual frames 7–8.

Release frame 4 is the visual charge boundary, **not a projectile emission or horn-hit socket**. Movement/contact is centered on `enemy.pos`; this enemy does not fire a projectile for its charge. Existing movement, contact distance/damage, cooldown, bounds clamping and phase-step behavior must not change for an art update.

The warning-only front brace remains the existing 120-degree cone with a 0.5 primary-damage multiplier. Its defense arc and charge route are separately drawn runtime telegraphs; do not bake them into the body art. Hurt lasts 0.27 s and does not pause authoritative AI. Death takes presentation priority and uses the existing 0.72 s corpse cleanup/reward lifecycle; the final wreck is not a permanently held actor.

## Current measurements versus historical records

Selected manifest PNG/SVG identities and walk full-cell RGBA hashes describe the new derivatives. Existing live walk crops and complete action frame records are retained. Their old alpha-bbox/clear-margin measurements are explicitly historical registration/QA facts, not fresh measurements of this redraw. Current measured alpha>8 source-window-local LTRB bounds and clearance are recorded separately in `art_source/provenance.json` under current derivations, alongside the prior raster records.

Do not run a historical raster-validation writer that rewrites live crops from the new alpha silhouette. Do not reinterpret ART raw/visible hashes as imported runtime hashes; imported textures require their own observations.

## Deterministic export and review

The pinned export uses Inkscape 1.4, page area, 1254×1254, PNG antialiasing disabled. Exact options/tool version matter; reproducibility is scoped to that setup. Known classified tool warnings are retained, not described as warning-free. Preserve the previous output and original failure evidence if any byte, pixel, containment or process boundary differs; do not silently overwrite or weaken checks.

Review all 36 frames at the actual fixed registration and selected mirrors before integration. Static inverse-affine previews are illustrations, not engine cadence, collision or directional proof. Keep the accepted rounded heavy armor/ivory horn/moss identity; fine hinge detail and subtle gait or late reaction differences may merge at small size. A bounded native family review is separate from art export and must not be presented as all-enemy/all-combat coverage.

The first pilot's flat crate-like body was held for art revision. A later pilot's first walk export failed fixed-crop containment; only that first pose ran. Those originals remain preserved. The accepted revised rig fixed the geometry rather than moving the crop, foot or scale. Later successes do not retroactively turn an earlier failed run into a clean pass.
