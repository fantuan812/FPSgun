# v24 author evidence

Final frozen engineering snapshot ran 73 standalone checks plus import, with 255 declared source inputs unchanged and no Godot ERROR in the regression logs. Independent source-native card approval and final independent regression/export acceptance are separate evidence. Python export safety negatives: 3 pass.

The resource-only build used existing Linux/Windows presets and produced equal packs. The accepted v23 executables were not rebuilt. The first native harness used --main-pack, which the official release template explicitly rejects because path overrides are disabled; its log/step and original portable builder are retained as a rejected harness attempt, not a game defect. Normal adjacent-PCK loading via a same-inode hard link to the unchanged ELF then passed. The corrected portable builder describes that final route. The pack was not rebuilt during this correction.

Packed resource checks passed 825 (55 exact files,57 imported images,25 actions/281frames), with no source fallback. Linux headless startup is not native GUI acceptance; Windows was not run. No PCK byte-reproducibility claim is made. All source history remains in the exact v23 recovery base, not redacted or regenerated.
