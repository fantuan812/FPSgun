# Bankshot Driver + Bounce Guide source art

Exactly three new original PNGs: weapon inventory icon, independent world mount, module icon. Built-in image_gen used; no CLI fallback, third-party source art, or source-pixel edits. Full prompts: `bankshot_generation_prompts.json`. Source hashes and measured bounds: `bankshot_provenance.json`.

## Integration

- Copy the three asset PNGs preserving relative paths.
- Add `res://assets/items/bankshot_icon_manifest.json` to the UI extra-manifest list. Each entry supplies its own atlas path and measured crop.
- Merge only `weapons.bankshot_driver` from the additive world manifest into the existing world manifest; do not overwrite previous records.
- World source is1774×887, visible alpha>32 bounding rect `[134,139,1505,651]`. Grip `(320,610)`, muzzle/projectile anchor `(1639,420)` are normalized to the full source region in metadata. The muzzle sits between fork tips. Visible width is exactly32 world units via `reference_width=1505`.
- Weapon icon is1536×1024, crop `[171,85,1261,840]`; module is1447×1087, crop `[285,75,930,943]`.
- Nearest filter and existing grip/flip transform contract apply. Projectiles, field edge and contact cue are runtime geometry, not baked into these images.

## Verification and scope

All three generated source images visually inspected. Forked brass launcher silhouette differs from long Rail, cold Cryo and round discs; triangular amber/chevron module differs from round cold coil. Sources have actual alpha, broad visible margins, and nearly opaque silhouettes (weapon icon maximum alpha254, other two255). Small near-transparent generated residue/halo is deliberately preserved; measured UI crop excludes outer padding. High-resolution pixel aesthetic, not strict native pixel grid.

`python3 docs/art/check_bankshot_art.py .` runs27 read-only source resource checks (PNG identities, alpha/bounds/padding, mappings, crop containment, finite normalized anchors,32-unit mount width). Receipt: `bankshot_resource_check.json`. Optional metadata reconstruction uses `python3 docs/art/prepare_bankshot_art.py .`; it must not be run on frozen accepted artifacts.

`actual_size_preview.html` renders the original bytes with nearest-sampled measured crops at40px inventory size and32px visible mount width, with a mirrored mount and4× inspection row. Open directly in a browser. This is a source preview, not a claimed native Godot screenshot or gameplay test. Actual runtime both-facing/mode acceptance remains independent QA's later gate.

No edits to previous releases, no runtime writes and no Git publication in this handoff. AI-generation provenance is not an assertion of exclusive copyright or third-party licensing.
