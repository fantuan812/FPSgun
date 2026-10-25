# v19 — desktop export readiness

This increment keeps v18 gameplay, balance, assets, scenes and input authority unchanged. It adds unsigned Linux and Windows x86-64 export presets, a cold-build workflow, pinned official template verification, packed-resource tests and accompanying engine license notices. Platform binaries are separate delivery archives, not source-repository blobs.

## Rebuild locally

Use the **standard Godot 4.6.3 editor**, Python 3.11 or later and sufficient free space (the official all-platform template archive is approximately 1.26 GB). Both commands below write to new sibling directories, not into the project or system settings:

```sh
python3 tools/fetch_export_templates.py --output ../moss-templates
python3 tools/build_desktop.py --project . --templates ../moss-templates/4.6.3.stable --output ../moss-desktop-build
```

The downloader checks the official archive's complete size/SHA256 before extracting only the required desktop files. The builder refuses a pre-existing output directory, verifies every selected template, creates a fresh source copy and isolated absolute HOME/XDG directories, then imports, exports and checks resources. No signing certificate, encryption key, remote deployment or system-wide installation is used. `BUILD_REPORT.json` and step logs describe the result. A failed check is not acceptance.

Official references: [Godot 4.6.3 release](https://github.com/godotengine/godot-builds/releases/tag/4.6.3-stable), [export configuration and non-resource filters](https://docs.godotengine.org/en/4.6/tutorials/export/exporting_projects.html), [command-line export](https://docs.godotengine.org/en/4.6/tutorials/editor/command_line_tutorial.html). The exact asset URL, archive digest and selected-file digests are recorded in `tools/godot_templates.json`.

## Packed resources, not merely title startup

The presets explicitly include JSON read dynamically through `FileAccess`, including action/icon manifests and `art_source/alpha_bounds.json`. QA fixtures, source-only art candidates, docs and tools are excluded from the runtime package. All action sheets and catalog textures remain available through Godot's imported-resource remaps.

The pack validator runs an editor reader against the PCK from a directory without source fallback. It compares exact script/JSON bytes, main-scene structure, project settings and **source-imported** texture RGBA; it also exercises all dynamic actions, enemy creation and both modes' shop/inventory. Raw PNG RGBA is not the correct visual baseline because existing Godot import settings process transparent-border RGB. No source pixels or import settings were changed to make the check pass.

Cold export is reproducible as a workflow and validated resource contract, **not a bit-for-bit PCK promise**. Separate runs can differ in engine-generated scene metadata and UID-cache entries. Exact delivered binary/PCK hashes identify the native-GUI-tested artifacts; rebuilding creates new artifacts requiring their own identity and acceptance checks. Engine-generated binary scene differences are compared by scene structure/properties, not ignored as arbitrary data.

## Platform and acceptance boundaries

- Linux: an ELF x86-64 executable plus external `MossCircuit.pck`. Native-window results belong in the final independent report; headless startup alone is not GUI acceptance.
- Windows: a PE32+ x86-64 GUI executable plus the same resource pack. It is unsigned and **exported/artifact-inspected, not Windows-runtime validated**. No Windows host or Wine execution is claimed.
- Keep the executable and PCK together after extracting the whole platform archive. Linux extractors must preserve the executable bit; restore it if needed.
- The cloud GUI environment reports unsupported VSync control under llvmpipe and an unavailable ALSA output device with dummy-audio fallback. Do not mistake those for zero total engine errors or successful audio validation. Script/resource errors are checked separately.
- No human balance, complete dungeon or cross-platform performance certification is implied.

Each runnable archive includes its own checksums, short instructions, Godot's license text and third-party notices obtained from the pinned engine. See [Godot's attribution guidance](https://docs.godotengine.org/en/4.6/about/complying_with_licenses.html). These engine notices do not assign a new license to the game's source or artwork.
