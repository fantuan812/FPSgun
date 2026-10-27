# Offline semantic SVG editability proof — planned, unexecuted

This is separately authorized source-code editability testing, NOT a workaround for browser URL denial and NOT validation of browser color controls/download.

Scope: one lock_memory.svg independent copy. Preserve all frozen moss-v39-art files unchanged. In copy only, change fill from #78e3e6 to #f04a8a on precisely the3 elements with data-palette=cyan. Save editable SVG. XML namespaces, hierarchy, semantic groupIDs, titles/descriptions, all geometry attributes and non-target attributes must be structurally identical.

Hand expected pixel result at64×64/antialias0: center6×6=36 plus two L brackets(9×3+3×6)=45 each, total126 opaque cyan pixels. Expected output differs only at those126 original RGBA(120,227,230,255) positions, nowRGBA(240,74,138,255). All other RGBAbytes, alpha mask/bbox, dimensions unchanged. Existing output original PNG hash is c2c0dc6bbfac54565b4a95c76fc8e14ac38e6d3... (full actual hash pinned in freeze; not this prose abbreviation).

Only two Inkscape CLI exports: untouched copiedSVG→baseline PNG, edited savedSVG→edited PNG, exact existing antialias0 flags. Baseline export must equal accepted stagingPNG bytes; edited image equality tested against explicit color replacement mask. Save output PNGs as test evidence only, not formal assets; original package never modified. Capture all before/after package hashes, commandlines/returncodes/stdoutstderr, XMLdiff, numericpixel result, and direct enlargednearest side-by-side authorview. No imagegen/network/browser operation.

Bounds: QA grants CPU micro-window before either export; each export max30seconds, stop first failure, no retry or adjusting expected126. Source-edit script/expected values frozen before execution. If renderer behavior fails assumption retain failure and diagnose; do not loosen geometry/alpha/color predicates to green. Return serial execution window immediately after terminal result. Browser interaction remains BLOCKED_UNVERIFIED regardless of this result.
