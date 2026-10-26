# v28 GitHub-only delivery

Source, finite evidence and a complete runtime resource pack are published on the existing FPSgun development branch. No redundant executable or ZIP chain is produced. `Deliveries/MossCircuit/CATALOG.json` preserves all earlier 54 logical delivery records and appends v28 PCK/instructions; historical original bytes remain intact.

Use the unchanged verified restore helper with `--version v28`, then follow the versioned instructions: verify the accepted ELF/EXE and new PCK hashes, close the game, make a distinct verified old-PCK backup, and replace only the adjacent PCK manually. First installs must recover the complete historical v19 platform bundle and licenses. No automatic installation, network request or overwrite occurs in the helper. Hardlinks are required; publication is atomic per file, not a whole-version transaction. Windows helper/runtime execution is not claimed.

PCK: 41,361,216 bytes; SHA-256 `5db5ded8a5b18eb6ac391b58a261e245588aa52cd7dbc65575f5101fb5828f69`, stored in 14 ordered chunks. Existing Linux executable SHA-256 `2c78919325d7f29fa7607287c7c1eeac367ea4c94e7b8b6f5f4c6b20492f73d0`; Windows executable `91724f15024a3a545e28ccd83134403d31ce2323a38e51c95e4dfa282f732ab6`. Both preset packs match; neither executable was rebuilt.

Read `docs/validation/independent-v28/QA_REPORT.md` for source, controlled, native, ordinary and packed-resource evidence boundaries. Exact run diagnostics, closure and before/after identity checks are explicit. A branch/tree match alone is not a fresh file-byte download: publication verification separately records fresh distinct-object readback and eligible prior exact SHA-256/Git-SHA/size proofs. Immutable version records link the accepted source commit after publication.
