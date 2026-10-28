MossCircuit v44-muzzle — editable nine-frame muzzle flash

RESOURCE PACK
MossCircuit.pck: 32,104,816 bytes
SHA-256: 7174331f979cb3c37dae98f00005796b389c095c8ee077999c713781b45b5ea1

This is a complete external resource pack, not a standalone executable or a delta patch. The existing platform executable and its licenses remain required. Linux and Windows export-preset packs have identical resource bytes; this does not establish Windows execution.

RESTORE SAFELY
From a checkout containing Deliveries/MossCircuit and all 11 selected chunks:

python Deliveries/MossCircuit/restore_deliveries.py --version v44-muzzle --verify-only
python Deliveries/MossCircuit/restore_deliveries.py --version v44-muzzle --output restored-v44-muzzle

Close the game. Back up and hash your actual adjacent MossCircuit.pck before replacing only that resource file. Keep the backup to roll back. Restore your exact backup, not a substitute chosen from a recorded historical hash. Do not overwrite the executable, an active installation or user saves. Start the original executable normally; do not use --main-pack with a release executable.

The unchanged helper performs no download, archive extraction, installation, save migration or game launch. It refuses existing outputs and unsafe paths or symlinks, requires hardlink support, and publishes atomically per file rather than as a whole-version transaction.

CONTENTS
The muzzle flash has a newly authored semantic SVG master and a transparent 1254×1254 PNG sheet, arranged as nine row-major 418×418 cells. This is an editable geometric redraw informed by the earlier raster, not a recovered historical master or a pixel-identical replica.

The same runtime path, per-cell anchor, 30 fps timing, 0.3-second lifetime, 36×28 world-unit size and alpha mix are retained. Reduced-effects opacity stays 0.4. Firing hooks, pooling, random state, damage, the other five effect sheets, held-weapon artwork and the BUILD layout are unchanged.

The source includes the editable master, a concise editing guide and the existing portable test entry. After importing with Godot 4.6.3, run python3 tools/run_build_ui_checks.py from the project root. See docs/V44_MUZZLE_FLASH.md for the authored change and finite validation summary.

LIMITS
Finite source and packed-resource checks, controlled native captures and file-restoration controls have distinct scopes. Five selected directional firing cases in both styles do not cover every caller and direction; actual held-muzzle pose angles can differ from requested vectors. Standalone timeline views do not establish firing alignment. Faint late embers can blend into textured backgrounds, especially in reduced-effects mode.

These checks are not a wall-clock 30 fps video, new full-suite run, unrestricted ordinary-play test, physical settings or speaker assessment, Windows execution, delivery-executable launch, balance certification or CI result. Original strict fixture/generated-scene failures remain failures; later finite correction and same-package continuation do not relabel them.

The public release includes source/assets/test code, essential installer metadata and authored notes, not new operational logs, cache/environment inventories or raw execution/provenance bundles. Earlier delivery records and project licensing remain unchanged.
