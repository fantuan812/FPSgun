MossCircuit v43-build-expansion — eight editable build-expansion icons

RESOURCE PACK
MossCircuit.pck: 32,368,112 bytes
SHA-256: 11c9d2c54b5671f7cf7306da5af48ba139cb33d1dd623ef3ab22ab7b29181d99

This is a complete external resource pack, not a standalone executable or a delta patch. The existing platform executable and its licenses remain required. Linux and Windows export-preset packs have identical resource bytes; this does not establish Windows execution.

RESTORE SAFELY
From a checkout containing Deliveries/MossCircuit and all 11 selected chunks:

python Deliveries/MossCircuit/restore_deliveries.py --version v43-build-expansion --verify-only
python Deliveries/MossCircuit/restore_deliveries.py --version v43-build-expansion --output restored-v43-build-expansion

Close the game. Back up and hash your actual adjacent MossCircuit.pck before replacing only that resource file. Keep the backup to roll back. Restore your exact backup, not a substitute chosen from a recorded historical hash. Do not overwrite the executable, an active installation or user saves. Start the original executable normally; do not use --main-pack with a release executable.

The unchanged helper performs no download, archive extraction, installation, save migration or game launch. It refuses existing outputs and unsafe paths or symlinks, requires hardlink support, and publishes atomically per file rather than as a whole-version transaction.

CONTENTS
Two weapon and six module inventory icons have new semantic SVG masters and transparent 64×64 PNG textures: return_disc, shock_mortar, return_spool, blast_fuse, echo_chamber, gravity_anchor, medic_seed and phase_capacitor. The old painted build-expansion atlas served only as a visual reference. These are newly authored geometric redraws, not recovered historical masters or pixel-identical replicas.

The direct inventory bindings replace that shared atlas. Item identities, prices, stack caps, game behavior, held-weapon assets and the accepted responsive BUILD layout are unchanged. Earlier editable artwork remains intact.

The source project includes editable masters, a concise editing guide, a clean 64/48/24 preview and the existing portable test entry. After importing with Godot 4.6.3, run python3 tools/run_build_ui_checks.py from the project root. See docs/V43_BUILD_EXPANSION_ICONS.md for the authored change and finite validation summary.

LIMITS
Finite source, packed-resource, native-view and restoration checks have distinct scopes. They are not a new full-suite run, unrestricted ordinary-play test, Windows execution, physical-speaker assessment, balance certification or CI result. Original strict generated-resource and stale-expectation failures remain failures; later same-package continuation does not relabel them.

The new public release includes assets, source/test code, essential installer metadata and authored notes, not new operational logs, cache/environment inventories or raw execution/provenance bundles. Historical delivery records remain unchanged.
