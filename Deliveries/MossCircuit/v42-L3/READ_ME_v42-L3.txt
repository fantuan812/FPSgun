MossCircuit v42-L3 — eight editable mechanism icons

RESOURCE PACK
MossCircuit.pck: 33,614,416 bytes
SHA-256: bf7d6fef05ffa21a1f3c7d8f5573067062a396dd89345dad5317a15826a795e5

This is a complete external resource pack, not a standalone executable or a delta patch. The existing platform executable and its licenses remain required. Linux and Windows export-preset packs have identical resource bytes; this does not establish Windows execution.

RESTORE SAFELY
From a checkout containing Deliveries/MossCircuit and all 12 selected chunks:

python Deliveries/MossCircuit/restore_deliveries.py --version v42-L3 --verify-only
python Deliveries/MossCircuit/restore_deliveries.py --version v42-L3 --output restored-v42-L3

Close the game. Back up and hash your actual adjacent MossCircuit.pck before replacing only that resource file. Keep the backup to roll back. Restore your exact backup, not a substitute chosen from a recorded historical hash. Do not overwrite the executable, an active installation or user saves. Start the original executable normally; do not use --main-pack with a release executable.

The unchanged helper performs no download, archive extraction, installation, save migration or game launch. It refuses existing outputs and unsafe paths or symlinks, requires hardlink support, and publishes atomically per file rather than as a whole-version transaction.

CONTENTS
Eight existing mechanism inventory icons now have individual semantic SVG masters and 64×64 PNG textures: arc_relay, kill_cell, dash_resin, mirror_shell, thorn_crown, blood_valve, scrap_mine and pulse_boots. They replace the shared mechanism atlas; item identities and gameplay are unchanged. The accepted responsive BUILD interface and earlier editable artwork remain intact.

The source project includes editable masters, a short editing guide and the existing portable test entry. After importing with Godot 4.6.3, run python3 tools/run_build_ui_checks.py from the project root. See docs/V42_L3_ICONS.md for the authored change and validation summary.

LIMITS
Finite source, packed-resource, native-view and restoration checks have distinct scopes. They are not a new full-suite run, unrestricted ordinary-play test, Windows execution, physical-speaker assessment, balance certification or CI result. Earlier failed attempts remain failed rather than being relabeled by later acceptance.

The new public release includes assets, source/test code, essential installer metadata and authored notes, not new operational logs, cache/environment inventories or raw execution/provenance bundles. Historical delivery records remain unchanged.
