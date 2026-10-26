# v21 Cryo / Fracture — frozen mechanic contract

Status: accepted for the bounded source, packed integration and native Linux observations below; remote publication is a separate gate, not implied here. Base is the immutable accepted v20 source. This batch adds exactly **one weapon and one module**, not another mode or an unrelated feature.

## Cryo Sprayer (`cryo_sprayer`)

- Price44, uncommon, tag `control`; a normal weapon slot, maximum four copies within the existing four-slot limit.
- Primary damage9, interval0.65s, player-centered radius190 world units, full angle60°.
- Nearest living in-range enemy center selects aim; distance then enemy-ID ordering is deterministic. A coincident target uses RIGHT fallback. No in-range target means no shot/cone presentation. Each living center is hit at most once per emission, ordered by distance then ID. Range/angle boundaries are inclusive with explicit float tolerances (radius0.0001 world units, normalized-dot1e-6). There is no enemy collision-radius extension.
- Global damage bonus scales primary damage; range bonus scales radius. Electric/melee damage, extra shotgun pellets and pierce do not modify the cone. Existing haste schedules firing through the shared weapon controller.
- A primary hit leaving the target alive applies `chill_until = combat_time + 1.2s`, source weapon type and normal movement factor0.65. Refresh replaces expiry, never adds stacks or charges. Primary lethal hits do not mark.
- Chill is distinct from existing resin `slow_until`. Non-boss ordinary movement uses the stronger slow, not the product. Bosses can carry/lose the mark but receive no new chill movement reduction. Existing boss/resin behavior is not changed. Committed charge speed and all warning/recovery/cooldown clocks remain unchanged.

## Fracture Coil (`fracture_coil`) / Cold Snap

- Price28, rare, unique maximum1, tag `control`, one of eight existing module slots. No global cooldown.
- Requires a Cryo-applied unexpired mark **and a different recognized weapon type**. Another Cryo copy cannot consume it; empty/unknown synthetic weapon IDs and secondary hits cannot consume. Ordinary slow alone does not create chill.
- Resolve primary damage first. Only a surviving marked target is eligible. Consume its chill (and that slow), then deal fixed16 single-target **secondary** damage. No AoE, heal, freeze/stun, extra RNG or recursive event is created.
- The new shatter command executes before existing primary-hit commands; their relative order is unchanged. Existing primary-hit mechanisms may still trigger from the original primary hit, but shatter does not create a second hit event. A shatter kill is attributed to `fracture`, not primary, so it does not create a Kill Cell primary-kill reward. Primary-lethal hits do not consume or shatter.
- No hidden cooldown: one successful consume per applied mark. A later Cryo emission can apply a new mark. Same-tick behavior follows the existing deterministic weapon-slot and target-hit order; earlier hits are not retroactively changed.
- Removing Coil disables consumption. Removing Cryo does not retroactively erase an already applied mark; it expires normally. Pause/settings/inventory freeze combat time. Enemy removal, stage cleanup and new-run reset discard target state.

The declared Cold Snap pair additionally requires a weapon type other than Cryo; Cryo+Coil-only or all-Cryo loadouts are shown **INACTIVE**. The item description and details disclose the prerequisite and slow-consumption tradeoff. The generic optional prerequisite is data-driven and affects only presentation, not combat authority.

## Architecture, assets and bounded presentation

`target_status.gd` owns pure cone/status queries; shared weapon combat applies primary hits, the effects engine emits a command, and shared effect runtime applies it. No mode-policy, UI or map branch supplies damage. Both Arena and Rooms use the same mechanics. Existing enemy/AI rules and all old catalog entries remain unchanged.

Tuning is catalog data with finite positive bounds. New refresh affinity adds the control tag and a missing-partner link, retaining positive exploration, weighted-without-replacement draws, slot/unique limits and transaction generation guards. Expanding the catalog intentionally changes shop offers for a seed; determinism is within a content version and operation sequence, not old-version offer equality.

Three new untouched generated PNGs supply two icons and an independent mounted weapon. Original world-weapon records and older art remain byte-identical. The runtime cone uses the same origin/radius/angle as authority, with low-opacity fill and outline; a small cyan diamond marks chill, and short shard lines show consume. New cone visuals cap at4, shatter visuals at8, and existing VFX retain their96-sprite cap. Reduced-flashes changes decorative opacity only. Source appearance is not a substitute for actual-size native acceptance.

## Acceptance status and limits

The initial source suite passed but an independent rotated-edge test exposed a 190.000015 float-roundoff miss at nominal radius 190. The shared radius epsilon was corrected and eight-direction boundary tests added. The rejected result is preserved separately, not called final acceptance.

Author and independent cold checks each pass 63 standalone entries plus import (64 total), with all 233 declared inputs unchanged. Focused author mechanics pass 205 checks; independent mechanics 446 and catalog/transaction/affinity 316. Three Python export negatives and 33 deterministic art-resource checks pass. The exact delivered PCK passes 790 checks, including mixed-weapon consumption in both modes without source fallback.

The earlier independent r2 controlled native evidence covers both modes, facings, actual 960×540/1280×720 windows, icons, mounted weapon, cone/mark/shatter, boss-tell coexistence, honest ACTIVE/INACTIVE prerequisites and purchase/sale controls. Separately, ordinary automated CUA controls on the exact Linux export at seed 433 earned the first shop with 122 scrap, bought Cryo 44 then Coil 28, retained Rivet, displayed Cold Snap ACTIVE, and deployed into wave 2 with visible cone and target diamond. These stills do not measure native 16-damage shatter or continuous timing. The uncertain later uncaptured result/new-run transition is explicitly retained in the independent report, not classified as a proven defect or lifecycle pass.

All old equipment definitions remain unchanged. The declared old-schema authority projection matches v20 over 12×240 fixed steps; filtering the two new entries/pair/link reproduces 400 old-pool draws and 384 transaction probes. This is not arbitrary whole-state equality or unchanged real v21 shop offers.

See `validation/independent-v21/QA_REPORT.md` and `validation/v21-cold-snap/QA_REPORT.md`. Linux logs preserve known ALSA dummy-audio fallback and llvmpipe VSync warnings. Windows is artifact-inspected only. No audio, full v21 campaign, ordinary Rooms acquisition, human balance, continuous-motion or all-combination certification is implied. Existing v20 history remains byte-identical. The tested PCK was not silently rebuilt after native acceptance.
