# v7 independent QA

Independent action scenarios: 35 checks, headless only.

Verified authored six-action resources; death > hurt > dash > attack priority; movement/other-slot preparation cannot replace an active release; real firing starts at the authored release frame without delaying the projectile; subsequent attacks replay after the merge window; Boss pre-release frames occur without projectiles and release frame coincides with actual AI firing; authored/fallback same sampled damage and RNG; pause freezes reaction; death tail final frame; reset invalidates pending result; corpse leaves combat/rewards once, expires and is capped; title-to-restart with living enemies; telegraph z-order.

Caught and fixed during review: title lifecycle retaining freed sprites; hero action reference body size and foot anchor jumping relative to legacy walking; two legacy pause checks migrated from implementation-specific speed_scale to observable frame/age/walk-time freeze. Manifest release_frame values 3/5/4 confirmed after author integration.

PNG checks: 54 distinct nonempty action frames, six source SHA values and threshold-8 alpha bounds/regions independently checked. Regions are fixed 418×340 (not assumed square). Hero attack source PNG visually inspected: preparation, release, recoil and recovery differ. Assets remain high-resolution pixel-inspired, not certified strict low-resolution grids.

Limitations: finite deterministic test cases; no real GUI compositing, Windows export, performance certification or human playtest. Reused idle and shared procedural ordinary-enemy poses are not represented as new authored animation sheets.
