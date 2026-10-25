# v17 art scale estimate erratum

The v16 Warden art handoff `docs/art/warden_charge/README.md` described the old terminal alignment defect as roughly 10 world pixels. That prose estimate was too low. **Source measurements, metadata correction, source PNG bytes and accepted native-window evidence remain correct and unchanged.** This note does not rewrite the immutable v16 release.

Actual `_spawn_kind` constructs `Art.actor(path, 57.0 * enemy.scale, 9.0)`. Boss assets use enemy source visible height, so the registered height is the requested visible body height.

| Quantity | Correct conversion |
|---|---|
| Warden `scale=2.6` | visible height `57×2.6=148.2` world px |
| Warden charge `reference_height=207` | `148.2/207≈0.71594` world px per source px |
| Warden final authored X correction 31 source px | `31×148.2/207≈22.194` world px; about 27.28 screen px when 960 viewport is shown 1180 wide |
| Core `scale=2.9` | visible height `57×2.9=165.3` world px |
| Core summon `reference_height=246` | `165.3/246≈0.67195` world px per source px |
| Core measured terminal orb delta 8.37635×3.25154 source px | about 5.6285×2.1849 world px; about 6.92×2.69 screen px when 960 viewport is shown 1180 wide |

The earlier staged Core prose estimate of 3×1 world pixels was likewise too low and has been corrected before integration. These are geometric conversions, not perceptual-acceptance thresholds. Core GUI inspection must use the actual Boss spawn scale, both facing directions, and current source-AI phase handoff; a small source-pixel delta may still be noticeable at Boss scale. Native screenshots or live rendering, not a thumbnail, determine whether another targeted registration correction is needed.
