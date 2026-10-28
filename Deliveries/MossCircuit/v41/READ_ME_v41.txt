MossCircuit v41 — compact BUILD, responsive shops and editable icons

RESOURCE PACK
MossCircuit.pck: 34,751,752 bytes
SHA-256: cd3671bf1e90a2a69f70cf8d625bee41bc4ba9107a071f8628253dee0aef86b2

This is a complete external resource pack, not a standalone executable or a delta patch. The existing platform executable and its licenses remain required. Linux and Windows export-preset resource packs have identical bytes; this does not establish Windows execution.

RESTORE AND REPLACE SAFELY
From a checkout containing Deliveries/MossCircuit and all 12 selected chunks:

python Deliveries/MossCircuit/restore_deliveries.py --version v41 --verify-only
python Deliveries/MossCircuit/restore_deliveries.py --version v41 --output restored-v41

Close the game. Back up and hash your actual adjacent MossCircuit.pck, then replace only that resource file. Keep the backup until you have checked the update. Restore that exact backup to roll back; a recorded historical hash is not a substitute for your installation's own backup. Do not overwrite the executable, an active installation or user saves. Start the original executable normally; do not use --main-pack with a release executable.

The restoration helper does not download, extract archives, install, migrate saves or launch the game. It refuses existing outputs and unsafe paths or symlinks, requires hardlink support, and publishes atomically per file rather than as a whole-version transaction.

WHAT CHANGED
BUILD opens with a compact overview and expandable details. Long cards retain their full mechanics. Shop columns stack at narrow widths, and icons align with their identifying names. The five SVG-backed inventory icons are Bankshot Driver, Bounce Guide, Cryo Sprayer, Feedback Diode and Fracture Coil. Gameplay, prices, charges, cooldowns and acquisition rules are unchanged.

The source release includes editable SVG masters and a portable test entry: after importing the project with Godot 4.6.3, run python3 tools/run_build_ui_checks.py from the project root. See docs/V41_COMPACT_BUILD.md and docs/V41_VALIDATION_SUMMARY.md in the source project for the authored change and validation summaries.

VALIDATION LIMITS
The current package passed finite source, packed-resource, controlled native-view and resize checks. Local restoration covered two positive and eight negative controls, plus resource-file replacement and rollback while protecting the unchanged executable. These checks are not a new full-suite run, unrestricted ordinary-play test, Windows execution, physical-speaker assessment, balance certification or CI result. Long cards may still require scrolling. Earlier failed attempts remain failed; later accepted checks do not relabel them.

Operational logs, cache/environment inventories, execution records and raw review bundles are not part of this new public release. The concise summaries describe the completed checks without embedding those artifacts. Historical delivery records remain unchanged.
