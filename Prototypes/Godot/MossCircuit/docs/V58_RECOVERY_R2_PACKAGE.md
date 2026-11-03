# Medical Recovery: RECOVERY-R2 package provenance

## Current delivery identity

The v58-medical-recovery delivery uses the newly exported **RECOVERY-R2** resource pack:

- File: `MossCircuit.pck`
- Size: **5,066,064 bytes**
- SHA-256: `0d68d99f05f7a7ad81b088d2d35b6a9b664fafa31294f4ccf1b18e42989acd07`
- Git blob: `1b7680e08e1e1b94b1e878344b61796ce4170e8f`

This is a new binary with fresh checks, not a byte-for-byte recovery of the original candidate. The seven previously reviewed feature, test and documentation files remain byte-identical. The sole runtime source change from v57 is still the appended bidirectional Medic Winch / Medic Seed affinity link. No runtime script, price, reward, combat rule, artwork or UI changed during recovery.

## Why this is a new package

The original candidate had SHA-256 `8d363c0fc8902174cdad8c173d01811eb9e16acd142f64848fcf5145c702368b`. Its complete binary and raw execution records became unavailable before v58 publication. Retained partial bytes and metadata were insufficient to recover the exact complete file, and an attempted reconstruction did not match. Neither that attempt nor the new export is represented as successful recovery of the original binary.

RECOVERY-R2 was exported from the restored, reviewed source. Package serialization differs, including script-member ordering and the generated scene identifier. The new full-package identity above is authoritative. The original package's recorded acceptance and failures remain historical documentation; its lost raw records were not recreated or relabeled as R2 results. The earlier [medical acquisition note](V58_MEDICAL_RECOVERY_ACQUISITION.md) remains unchanged, and its package-specific evidence refers to that original candidate. This addendum governs the current delivered package.

## Fresh checks on RECOVERY-R2

Godot 4.6.3 was used for the following newly executed checks:

- Eight focused source routes: medical affinity **1,099**, current B catalog **27**, B projection **24**, historical A links **17**, shop **216**, reservation **520**, B pickup sources **34**, and historical B cache **20** checks.
- Existing compact BUILD entry: **14 routes**, **4,931 numeric checks** and one text-marker route. Its exact **48 previously permitted Scavenger warnings** remain accepted under the unchanged policy. This is not warning-free acceptance.
- Exact new package: fingerprint verification, **1,068 resource checks**, **1,099 medical checks**, and a **30-frame headless startup**. The Godot editor read the pack from an empty working directory without source-resource fallback; this is not an exported-executable launch.
- Fresh independent execution: **1,099 source checks**, **1,099 packed checks**, and **21 negative reservation/projection checks**. Independent review also audited all **26 fresh author routes** and the actual package bytes. The earlier 8,268-check ensemble and 14-check supplement were not rerun and are not claimed for R2.

The new pack was hashed before and after independent execution. The scoped checks and review passed. Source inputs and the frozen pack remained unchanged during these checks.

## Package comparison against v57

Both the actual v57 baseline and RECOVERY-R2 contain **301 members**, with no additions or removals. **298 members are byte-identical**. The changed members are the intended catalog, UID cache and serialized main scene. The new catalog exactly matches the reviewed source. The UID cache adds 15 test-path mappings and changes or removes none; test bodies, documentation and tools remain excluded.

Both serialized scenes are 684 bytes; only four bytes at offsets 508–511 differ. A separate Godot-loaded comparison confirms that only the bundled `node_ids` field changes, from 884837641 to 1732091407, while all other bundled fields match. This finite comparison establishes scene equivalence within those checked fields, not deterministic package serialization.

## Limits and restoration

These results are finite source/PCK/editor-reader checks. No new full 165-route regression, native exported executable, rendered GUI, Windows execution, physical audio/input, ordinary-play acquisition, all-seed balance, full campaign or CI pass is claimed. Selection weights are not guaranteed offers or advertised probabilities.

Use the [version-specific restoration instructions](../../../../Deliveries/MossCircuit/v58-medical-recovery/READ_ME_v58-medical-recovery.txt). The existing compatible executable and licenses remain required. Close the game, back up and hash the actual adjacent resource file, replace only that resource manually, and retain the exact backup for rollback. Resource-file restoration checks do not establish executable preservation or execution.
