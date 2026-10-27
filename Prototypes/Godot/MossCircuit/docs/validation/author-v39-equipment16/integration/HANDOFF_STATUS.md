# Equipment16 isolated integration — current handoff

Source candidate: `evidence-workspace/moss-equipment16-integration-candidate`.
888-file post-import identity: `POST_IMPORT_888_PINS.json` SHA256 `bec2314a1d91b6e3535117ccd36e6fb6df72d3ba9021639627bc7c45d4b76c90`.
Base A869 remained unchanged throughout. Historical docs/MANIFEST were not sanitized or rewritten; external888map is candidate authority, and old excluded MANIFEST is not claimed current inventory. No B/branch/upload modifications.

Actual PCK (same Linux/Windows preset bytes):
`pack-gate/linux/MossCircuit.pck`
SHA256 `fac259f0e5406c8b3ab56f21c4b7bf5113ae58d50fdc02344fbc09b8b273f23d`,42250592bytes.

## Actual evidence, with failure history preserved

- Assembly exact19adds/2removes/2changes from A869→886, then cold importer exactly2new sidecars→888. All base source pins unchanged.
- Cold actual240checks/21icons(16+A5) pass. SourcePNG crops fullRGBA exact; Godot-imported transparentRGB differs, and that is explicitly not source raw equality. Only alpha0RGB canonicalization was used for source-visible identity, with raw hashes separately recorded.
- Original resource run17581: first4phases PASS, fifth real PCK audit FAIL because full `.import` raw equality was an incorrect expectation. The original5/8FAIL and logs remain untouched.
- Independent diagnosis confirmed exact212B export format for only the new PNG.import: preserve source remap prefix bytes, strip deps/params, oneLF+NUL. uid/path/type/importer/metadata unchanged. No blanket ignore.
- Corrected external four-route run38814 on the same unchanged PCK passed; no re-export. Actual254PCKmembers allMD5 valid, wholebytes privacy markers and oldPNG/import/ctex/UID/referencepayloads absent;78exact runtimefiles/69source-imported images/28actions/308frames and generic968checks pass. Packed UI21actual240checks: **rawRGBA exactly matches source-imported raw**, not merely visible normalization.
- Independent full raw receipt: `evidence-workspace/moss-equipment16-independent-integration-review/PACK_RAW_REVIEW.json`, SHA256 `db698878f261b8ca447caee15478a2cfdfedb3e52e0aa5b8a50d858b4161e13c`.

## Pending, not claimed

UI lane owns the sole native follow-on: original178 actual A interaction plus real legal-build21card display. No parallel viewer/native runner by art lane. Existing A HUD140/200 results are historical, not newfac259 acceptance. Exact native plan, CUA lease, screenshots, raw/independent review pending. No Windows runtime, normal gameplay manual acceptance, release publication or formal ledger decrement claimed.

Ledger stays56 old raster-authoritative sources at accepted release status. This isolated candidate has removed exactly one equipmentatlas dependency; only after final native/review/release acceptance may formal ledger become55. No L1held or L3–L6 included. Preserve all frozen sources and receipts while native lane proceeds.
