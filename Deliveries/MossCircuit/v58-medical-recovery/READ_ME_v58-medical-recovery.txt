MossCircuit v58-medical-recovery — RECOVERY-R2 resource pack

CURRENT RESOURCE PACK
MossCircuit.pck: 5,066,064 bytes
SHA-256: 0d68d99f05f7a7ad81b088d2d35b6a9b664fafa31294f4ccf1b18e42989acd07

This is the newly exported, separately tested RECOVERY-R2 package, not a byte-for-byte recovery of the original candidate with SHA-256 8d363c0fc8902174cdad8c173d01811eb9e16acd142f64848fcf5145c702368b. That original complete binary and raw execution records became unavailable before v58 publication. Earlier acceptance and failures remain historical; they are not presented as fresh results for this package. The reviewed seven-file feature overlay remains exact.

This is a complete external resource pack, not an executable, archive or delta patch. The existing compatible platform executable and licenses remain required. No executable is included or updated. Windows execution has not been tested.

RESTORE SAFELY
From the repository root containing Deliveries/MossCircuit and both selected chunks:

python Deliveries/MossCircuit/restore_deliveries.py --version v58-medical-recovery --verify-only
python Deliveries/MossCircuit/restore_deliveries.py --version v58-medical-recovery --output restored-v58-medical-recovery

Windows users may substitute py -3 for python. The unchanged helper verifies each chunk and both complete outputs against sizes, SHA-256 hashes and Git blob identities. It refuses existing outputs, unsafe paths and symlinks; the output filesystem must support hard links. It publishes atomically per file, not as a whole-version transaction. It does not download, unpack, install, migrate saves or launch the game.

Close the game. Back up and hash your actual adjacent MossCircuit.pck before manually replacing only that resource file with the restored pack. Preserve the exact backup for rollback; a recorded historical hash is not a substitute for your own backup. Do not overwrite the executable, an active installation or user saves. Start the original executable normally, not with --main-pack. For rollback, close the game again and restore the exact backed-up resource, checking its original hash. Retain prior deliveries. Resource-only restoration checks do not establish executable preservation or execution.

CHANGE
The catalog appends exactly one bidirectional Medic Winch / Medic Seed affinity link, from 14 to 15 links. With only either component owned and the default Rivet Gun, the missing eligible counterpart's weight is 3.5 rather than 1.0 under the existing +2.5 missing-partner bonus. This is a selection weight, not a guaranteed offer or advertised probability. Other owned tags retain the existing capped rules. Buying both removes missing status. Selling one restores the bias toward it; selling the last removes the bias. Reservations are not ownership; held-card metadata remains a historical snapshot.

No new item, combat behavior, price, refund, reward, limit, weighting constant, artwork or UI is introduced. Medic Winch still moves existing medical pickups, rather than creating pickups or healing directly. The full pack retains the accepted v57 artwork and other resources.

FRESH RECOVERY-R2 VALIDATION
Eight focused source routes passed: medical 1,099; current B 27; B projection 24; historical A links 17; shop 216; reservation 520; B pickup sources 34; historical B cache 20. The existing 14-route compact BUILD entry passed 4,931 numeric checks and one text-marker route, with its exact 48 permitted historical Scavenger warnings under the unchanged policy.

The exact new package passed fingerprint verification, 1,068 resource checks, 1,099 medical checks and a bounded 30-frame headless startup using the Godot 4.6.3 editor as pack reader, from an empty working directory without source-resource fallback. Fresh independent execution passed 1,099 source checks, 1,099 packed checks and 21 negative reservation/projection checks; review audited all 26 fresh author routes. The earlier 8,268-check ensemble and 14-check supplement were not rerun and are not claimed for this package.

Against the actual v57 baseline, 298 of 301 package members are byte-identical, with no additions/removals. Changed members are the intended catalog, UID cache with 15 added test-path mappings, and the generated scene identifier. Only four of 684 serialized scene bytes differ; a Godot-loaded comparison confirms that only bundled node_ids differs. No test bodies, documentation or tools are included in the pack. Serialization and script-member order differ from the unavailable original candidate, so this package has its own new identity.

No new full 165-route regression, native exported executable, rendered GUI, Windows, physical audio/input, ordinary-play acquisition, all-seed balance, full campaign or CI pass is claimed. Read Prototypes/Godot/MossCircuit/docs/V58_RECOVERY_R2_PACKAGE.md for current package provenance and limits. The older medical acquisition note retains its original-candidate evidence unchanged.

PUBLIC SNAPSHOT
All 96 preceding catalog file records and seven historical reconstructed-archive records remain exact; only this current pack and its instructions are appended. The source consists of the seven unchanged reviewed overlay files, an authored RECOVERY-R2 note, README and accurate cumulative MANIFEST. The compact manifest reconciles ten stale v57 dependency pins and two medical pins without altering the ten runtime files or route/warning policy. Verified source-version identities are recorded separately in SOURCE_VERSIONS.json. This update includes no private operational logs or execution caches.
