# Bounded v21 integrated art acceptance

Reviewed 2026-10-25 against the programmer-confirmed v21 r2 source, whose production bytes match the independent v21 r2 snapshot.

**PASS within scope. No art or metadata revision requested.**

Read-only deterministic resource check: `python3 docs/art/check_cryo_resources.py . ../v20-source` — **33 checks passed**, recorded in `cryo_resource_check.json`. This verifies exact generated PNG hashes, RGBA/dimensions/alpha bounds/padding, valid UI crop rectangles, unchanged six old weapon records, integrated Cryo geometry, finite normalized grip/muzzle anchors, analytic 32-unit visible length and both-facing mirror geometry, and presence of nearest-filter/mirror runtime contract.

Actual native screenshot pixels independently inspected: arena960 neutral/chill/shatter/mirrored/boss; rooms1280 mirrored/shatter/inventory/coil-card; rooms960 inactive. Exact file identities and SHA-256 values are recorded in `native_capture_hashes.json`. Screens are controlled setup/frozen poses, not ordinary play.

- Inventory: broad flared Cryo nozzle + reservoir versus round copper ring/cracked crystal Fracture silhouette are distinct; readable at shown card scale. Cropped icons avoid excess blank margins. Scroll-clipped card content is expected viewport clipping, not malformed source art.
- World mount: compact cold-colored gun aligns to hero hand; right and mirrored left muzzle remain in front. No detached hand/background rectangle or obvious alpha halo in these native captures. Crisp small-scale sampling is consistent with existing assets.
- Feedback: low-opacity cyan cone leaves ground/enemies readable; small cyan diamond marks are separate from enemy silhouette. Shatter feedback is visible without obscuring actors. Boss orange danger perimeter remains visually dominant and distinct from cyan cone. Bottom QA caption/boss text overlap belongs to fixture, not shipped UI.
- Prerequisite copy: ACTIVE for mixed weapon type and INACTIVE for duplicate-Cryo are visibly differentiated in shown cards.

Limits: static images do not certify animation timing, full-motion clarity, long-run performance, balance, ordinary exported acquisition, or every UI scroll position. Cone is deliberately player-centered per accepted mechanics rather than muzzle-origin. Existing source aesthetic is high-resolution pixel-style, not strict native pixel grid. No v20 or frozen snapshot files edited; no remote writes performed.
