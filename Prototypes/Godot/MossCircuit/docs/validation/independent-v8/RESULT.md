# v8 independent QA

Final clean Godot 4.6.3 headless import and all 20 GDScript test entries passed; no ERROR/WARNING in final logs. New independent checks: 217. Author weapon checks: 159. Historical regressions retained.

Verified:
- Runtime body attack loads clean_hero_attack.png, not the baked pistol; source nine frames viewed unarmed. Six dedicated single-PNG weapon resources are used by final manifest, not the retired atlas.
- Four mixed slots and four duplicate-ID slots, actual shop replacement/sale including same-ID replacement invalidation.
- Shared grip/muzzle matrix on mirrored Sprite2D; projectile and rounded-pixel VFX origin; normal-distance barrel local-x / projectile ray / selected target consistency for four slots and four quadrants.
- Zero-vector safe fallback; player-centered range-circle intersection and actual projectile lifetime endpoint; near targets at 0/1/8/16/25 units across four slots; launch/flight hit deduplication and first-circle-entry penetration order.
- Spread has common origin and distinct directions; recoil does not feed logic pose; arena border is not a projectile wall.
- Disc hides only owning held slot and returns on terminal cleanup; pause freezes recoil; death/restart clears presentation; auxiliary firing does not falsely trigger main-hand body action.

Geometry is intentionally changed from v7 player+16 emission: actual hit results may differ. Damage numbers, cooldown policy, nearest-target gate and RNG contract are retained, not all previous hit geometry. Very short distances below the local sideways muzzle offset have no exact aiming solution; clamped pose plus launch-segment collision is the defined fallback. Orbit remains discrete radial sweep; mortar visual travel does not determine blast timing/damage.

Final source PNGs were all viewed; broad environmental halos from the rejected atlas are absent. Small low-alpha edge speckles remain (alpha 1–8 comprises 1.94–6.69% of nonzero weapon pixels). Metadata checks and this observation do not certify a perfect cutout or in-game readability. Nine clean body frames are distinct/nonempty; all seven source hashes match manifests.

Evidence: final-*.log, tested-source-hashes.json (110 files), independent_weapon_rig.gd. No true GUI compositing, Windows export, performance certification or human playtest; denied GUI route was not retried. No Git writes or obsolete v7 upload replay performed by QA.
