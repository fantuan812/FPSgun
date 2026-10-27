# MossCircuit: editable asset source standard

Effective for new formal assets from 2026-10-27. This policy records the new production standard; it does not retroactively certify or rewrite historical releases.

## Authoritative source

- New formal artwork must be redrawn as editable SVG or HTML/CSS, with meaningful editable shapes, layers, text and parameters. Wrapping or embedding an AI-generated bitmap in SVG is not a redraw and does not satisfy this standard.
- AI-generated images may be retained only as clearly labelled references. Keep references separate from production assets and exclude them from runtime asset discovery, selection and exports.
- Runtime PNG files are derived exports, not the authoritative artwork. Keep the editable source and enough export instructions to regenerate them without requesting a new generated image.

## Reproducible export and acceptance

Record the source files and their hashes, exporter/tool version, configuration, dimensions, scale, transparency, colour settings and exact export command or procedure. Record exported file hashes and decoded RGBA hashes with dimensions/format, together with source-to-export provenance.

Validate the actual runtime import, atlas tile regions, margins, transparent bounds and animation frame mapping. Review the rendered appearance at the intended game sizes, including effects and state transitions. A source-file hash alone is not visual acceptance, and an exported PNG alone is not proof that an editable redraw exists.

## Historical assets and migration

Previously accepted snapshots, including v32–v37, retain their original files and evidence. Generated raster artwork in those snapshots is legacy material awaiting migration, not artwork newly certified under this policy. Do not rewrite old commits, replace original evidence, or relabel old test outcomes as redraw acceptance.

Migrate assets in separately versioned changes: retain the historical provenance, provide the new editable source and reproducible exports, and repeat the applicable visual/import/runtime checks. An in-development generated reference, including the initial v38 Stitch Drone reference, is not a new formal release asset until the redraw and acceptance are complete. This policy does not claim that any such migration has already passed.
