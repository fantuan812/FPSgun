# v29 source and direct resource-pack delivery

The accepted implementation adds only the optional fixed-10-scrap upgrade resolution. See V29_UPGRADE_SALVAGE.md and the frozen contract for exact guards, queue/RNG behavior, experimental tuning and finite validation limits.

The complete new PCK is 41,363,792 bytes, SHA-256 `77d6b41df3cea5036f99608a837983767f31c2e680c2622c1a83654adf2e6cfc`. Both platform presets produce identical bytes. The original accepted Linux ELF/Windows EXE are unchanged; this is not a new executable build or Windows run.

From the complete repository, use `python Deliveries/MossCircuit/restore_deliveries.py --version v29 --output restored-v29`. Read the restored instructions, verify executable/PCK hashes, close the game, make a unique verified old-PCK backup, and manually replace only the adjacent PCK. First installations still need the complete historical v19 platform package/licenses. The helper does not install, execute, download or overwrite; it requires hardlinks and is atomic per file, not per batch. Windows execution is untested.

All earlier 56 catalog records remain unchanged; the new PCK/instructions are explicitly GitHub-only files, not historical chat attachments. Old source and validation history are inherited unchanged through the accepted Git base; the manifest describes the complete logical source tree, not another local copy of all history. Reachable publication and immutable source-version identities are verified after acceptance, not inferred from this document.

Independent source/native/export evidence is in validation/independent-v29; author logs and source/pack identities are in validation/author-v29. Generated profiles/config/cache are excluded from evidence. Current-session display settings, cloud audio/VSync limitations and external Ctrl+C closure are explicit in the runtime instructions.
