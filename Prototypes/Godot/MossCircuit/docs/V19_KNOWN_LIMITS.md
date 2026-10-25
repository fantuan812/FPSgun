# v19 known limits

- Windows is exported and PE/package-inspected only; no actual Windows runtime or Wine claim.
- Cloud Linux audio output could not initialize ALSA and used a dummy fallback; audio acceptance is outstanding. llvmpipe VSync control is also limited.
- Native Arena supplemental review observed an inherited UI-composition issue: opaque top/bottom Boss HUD regions can obscure actors or ground tells near the playfield edges. This is not a new export regression and is not fixed by v19; it is a separate scoped follow-up.
- Rebuilds may have different engine-generated scene/UID-cache bytes. Delivered executable/PCK identities, not a bit-reproduction promise, tie native GUI evidence to the platform archives.
- No human balancing, complete dungeon or complete cross-platform certification is implied.
