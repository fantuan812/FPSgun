# v25 independent final acceptance

## Verdict
PASS for the fixed existing tag-progress UI batch on the pinned source and Linux resource pack. Source MANIFEST SHA256: `afb69ff2199510bbfa7e4488a15858e92fdd3b0aace1151ec8037b26af1a3e22`. All 549 original source files remain exact; all 116 production inputs are identical to the controlled-native candidate. Exactly three production files differ from accepted v24: Rules shared tag counting/activation, main read-only view, and inventory UI. No catalog/balance/art/weapon/equipment/RNG edits.

## Source and authority
76 standalone Godot scripts + final import revalidation + Python safety = 78 successful runner entries. No engine errors or input hash changes. Python safety contains three tests. The production source was genuinely cold-imported before independent native review; final tests/current docs were then added and a reused-cache import revalidation performed. This report does not call that final import a fresh cold import. The complete inventory includes the three docs/art entry points, avoiding the prior-version runner inventory omission.

The immutable interim evidence is copied byte-identically under interim/. It contains 561 actual-authority checks per baseline/candidate, 48 byte-identical records (primary contacts, ownership transitions, ordered activation, weighted pool/seeded shop/RNG), 848 independent source view checks and 21 selected controlled native UI captures. Rail+Capacitor2 remains51; Shotgun+Pouch2 emits8. Counts are equipped copies/actual stacks, over-threshold remains once-only, and ACTIVE without a benefiting weapon is honestly identified. Both modes at960×540/1280×720 and real controlled-setup CUA buy/sell/replace/scroll/Back were reviewed. Rejected oracle assumptions are retained and explicitly not product defects.

## Exact exported resources
PCK SHA256 `a7a9064413fc7bfdc1713f516ffc7d99ad6a2af2aa796089b0ddf1372779d42a`,40,683,384 bytes. Accepted unchanged Linux ELF SHA256 `2c78919325d7f29fa7607287c7c1eeac367ea4c94e7b8b6f5f4c6b20492f73d0`,71,075,864 bytes. Independent pre/post hashes are identical. No rebuild after native review.

Independent source-imported fingerprint regenerated from the QA source:55 exact files,57 imported RGBA textures,25 actions/281 frames. From an empty directory, the editor PCK reader passes825 resource/integration checks without source fallback. The independent actual tag-view/transaction-layout matrix also passes848 checks against this PCK. These are controlled headless pack checks, separate from the ordinary native test. Texture parity compares source-imported pixels, not raw transparent PNG RGB.

## Ordinary native Linux display smoke
One finite Arena seed128 first-shop route, selected because its Rail offer was already known from an offline-planned and previously observed route. This run uses only ordinary game controls through automated CUA, including tactical pause; no programmatic build/currency/enemy/progression control, source fixture, save injection or debug override. Original game-window captures are1180×812 with native letterboxing, not a claim of1280×720 export coverage.

Initial starter Rivet inventory shows all three rules0/3 INACTIVE. Actual movement/auto-fire and earned upgrades lead to the first shop with118 scrap. Chosen earned upgrades: Overcharge twice, Repair Plating, Salvage Magnet, Rapid Circuit. Rail is visible as an unowned offer while ARC GRID remains0/3. Real purchase costs42, leaving76 and retaining Rivet. Current Rail displays45.00 primary damage and1.000s interval; ARC GRID updates to1/3 INACTIVE with one matching equipped slot. The other two rules remain0/3. Normal wheel scrolling reveals the complete wrapped row text. No forced3/3, reroll hunt or full campaign was needed.

The check stopped after this display evidence. Deploy was used only to access Pause→Return to Title; no later-wave completion claim. Title return was directly observed, then Terminal Ctrl+C closed the process externally and the game window disappeared. This is not an in-app Quit or normal exit-code-zero claim.

## Limits
Windows is not executed, no audio or full-campaign/balance/fun/performance certification. Known unsupported VSync and ALSA ERR_CANT_OPEN→dummy-audio fallback remain; no game script/resource errors appeared. Controlled setup and ordinary export evidence are kept distinct. Source/archive publication and package byte verification are separate receipts; this report does not claim GitHub updated or delivery succeeded.
