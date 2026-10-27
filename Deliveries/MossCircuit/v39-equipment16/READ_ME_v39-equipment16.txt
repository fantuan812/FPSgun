MossCircuit v39-equipment16 — asset-only editable inventory atlas

RESOURCE PACK
MossCircuit.pck: 42,250,592 bytes
SHA-256: fac259f0e5406c8b3ab56f21c4b7bf5113ae58d50fdc02344fbc09b8b273f23d
Both Linux/Windows resource packs are identical bytes; this is not Windows execution evidence. Use the existing verified executable, unchanged SHA-256 2c78919325d7f29fa7607287c7c1eeac367ea4c94e7b8b6f5f4c6b20492f73d0 (Linux). No new executable is included.

RESTORE
From a checkout containing Deliveries/MossCircuit, run:
python Deliveries/MossCircuit/restore_deliveries.py --version v39-equipment16 --verify-only
python Deliveries/MossCircuit/restore_deliveries.py --version v39-equipment16 --output restored-equipment16
The unchanged helper matches the version string exactly; the hyphenated version is intentional. Verify before installing. Close the game, manually back up your existing PCK, then replace only the adjacent MossCircuit.pck. Restore that backup to undo the change. Do not overwrite an active installation, executable or user saves. This is resource-file replacement, not a gameplay-save migration.

CONTENT
Exactly one old generated inventory atlas is replaced by a semantic SVG source/derived PNG with16 existing IDs in4x4 64px cells. No game rules, weapons, modules, held art or other atlas changes; no B expansion. A's10 weapons/33 items/5 starters remain. The active raster-authoritative legacy file count goes56→55 (one sheet, not16 files). Migration remains partial.

VERIFICATION BOUNDARIES
Cold source import plus actual UI21 source identity passed240 checks. Runtime visibleRGBA permits zero-alpha RGB normalization only, retains all alpha and nonzero-alpha RGB, and reports raw imported hashes separately. All21 imported raw hashes differ from sourcePNG raw hashes; do not claim raw equality.

The original resource gate remains5/8 FAIL: first4 preparation/export routes passed, then an oracle incorrectly required full source import-descriptor bytes in the exported pack. The same PCK was reused; no re-export. A separate correction for only that descriptor requires the exact original remap section plus LF/NUL, without deps/params. Corrected full254-record MD5/privacy/oldresource-exclusion audit, source fingerprints, actual packed968 (78 exact files,69 images,28 actions/308frames), and packed UI21/240 passed. All21 packed raw observations match source-imported observations exactly. No original8/8 PASS claim.

Actual native UI178 passed. First inventory-card fixture79/2FAIL remains because it tested local panel visibility rather than effective modal visibility. Fixture-only API correction then passed145, three controlled groups and21 original960x540 card images. All21 were independently viewed; real inventory cards, icons and fixedBACK are readable; controlled BACK/reopen/Escape and Tab isolation were checked. This is not natural shop acquisition or a new ordinary run. VSync warnings remain; Dummy audio is not physical listening evidence.

A gameplay evidence is inherited with its original149/151FAIL and separately corrected903/837/124 combination, not a new full aggregate. Prior A ordinary attempts used the prior A pack and do not establish ordinary play with migrated pixels. Earlier strict atlas export/log failures are retained; bounded known renderer warnings do not relax any Godot gate. No campaign-completion, performance, all-seed balance or Windows-runtime claim.

This instructions file describes local verified content. Delivery helper checks and source publication have their own receipts; SOURCE_VERSIONS points to an actual source commit only after publication/readback. Historical catalog entries and prior deliveries remain unchanged.
