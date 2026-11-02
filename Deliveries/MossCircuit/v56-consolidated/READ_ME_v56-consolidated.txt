MossCircuit v56-consolidated — cumulative editable artwork through Scrap Warden

RESOURCE PACK
MossCircuit.pck: 9,640,368 bytes
SHA-256: a454088d7db2a5399f8cade065666cda83921856c2bcf2a3f35c2243d7cf4f93

This is the complete latest accepted external resource pack, not a standalone executable or a delta patch. The existing platform executable and its licenses remain required. Linux and Windows export-preset packs have identical resource bytes; that does not establish Windows execution.

RESTORE SAFELY
From a checkout containing Deliveries/MossCircuit and all 4 selected chunks:

python Deliveries/MossCircuit/restore_deliveries.py --version v56-consolidated --verify-only
python Deliveries/MossCircuit/restore_deliveries.py --version v56-consolidated --output restored-v56-consolidated

Close the game. Back up and hash your actual adjacent MossCircuit.pck before replacing only that resource file. Keep that exact backup for rollback; do not substitute a historical package merely because its hash is documented. Preserve the executable, licenses, user saves and any active installation. Start the original executable normally; do not pass --main-pack to a release executable.

The unchanged helper performs no download, archive extraction, installation, save migration or game launch. It refuses existing outputs and unsafe paths or symlinks, requires hardlink support, and publishes atomically per file rather than as a whole-version transaction.

WHAT THIS SNAPSHOT CONTAINS
The accepted latest source and resource pack include the cumulative editable redraws developed in local milestones V45 through V56: hit spark, explosion, shield impact, dash/chain effects, ground, player and the Spitter, Charger, Crawler, Flanker, Broodkeeper and Scrap Warden families. The source includes 34 new self-contained semantic SVG masters across these 12 milestones/groups, their current PNG derivatives and resource metadata, existing game code and the portable test entry. Companion clean editing guides and feature notes describe each family's scope. These are newly authored vector redraws informed by raster references, not recovered historical masters or pixel-identical replicas. Existing project licensing remains unchanged.

This is one consolidated publication after the previously published V44 snapshot. V45–V56 were locally validated milestones, not twelve separately published Git releases. Their retained feature notes describe those local checks and limits; they do not establish historical remote commits or downloads. This catalog adds only the current consolidated resource pack and these instructions, while preserving all prior public catalog records. Intermediate local packages are not presented as public downloads.

The latest accepted production and portable candidates contain 1,035 and 1,067 files respectively. These are tested candidate counts, not the complete published source-tree count: public documentation and older project history are preserved separately. After importing with Godot 4.6.3, run python3 tools/run_build_ui_checks.py from the source-project root. See docs/V56_CONSOLIDATED_ARTWORK.md for the cumulative scope and docs/V56_WARDEN.md for the latest family's finite validation details.

VALIDATION AND LIMITS
Each local milestone retained its own finite source, packed-resource, native-view and direct visual checks. The latest Scrap Warden acceptance includes five separate source and corresponding packed reports, portable default 14, composed same-package resource checks, and the accepted R2 native 885-check/65-image run. Author directly reviewed all 65 accepted originals and QA reviewed 16 selected originals. This is not a fresh replay of every earlier milestone or a new full-game suite.

Fixed-step stills do not establish real-time cadence or every natural gameplay sequence. Selected mirrors, styles, tints, contacts and timing cases are bounded comparisons. Small details can merge at runtime scale, effects can overlap, and late remnants can blend into the background. Original strict generated-data or external-fixture failures remain failures; later reviewed corrections and same-package continuations do not relabel them. The detailed feature notes preserve the relevant limits.

The separate consolidated restoration test uses the actual public V44 catalog and resource pack as its baseline, not an unpublished intermediate catalog. File restoration, backup, replacement and rollback are not execution of the delivered game binary. No new unrestricted ordinary-play, exhaustive collision/proc matrix, physical settings/speaker assessment, Windows execution, release-executable launch, balance certification or CI pass is claimed.

The public snapshot contains source/assets, portable test code, essential installer metadata and concise authored notes. New operational logs, cache/environment inventories, raw execution/provenance bundles and private recovery locators are not publication contents. Earlier public history remains intact.
