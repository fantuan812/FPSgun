# Feedback Diode art handoff

Exactly one new item icon. Source PNG visually inspected: cream/olive two-terminal ceramic diode with violet directional inset and U-shaped copper return conductor, distinct from round cyan Fracture Coil and triangular amber Bounce Guide. No new VFX sheet, weapon mount or enemy art.

Copy `assets/items/feedback_diode.png` and merge the additive `feedback_icon_manifest.json` through the existing extra-manifest UI lookup. Full source1764×892, alpha>32 crop `[83,127,1597,671]`. Preserve original PNG bytes; use existing nearest atlas sampling. Runtime violet armed cue, return line and owner impact are programmer-authored effects and require separate native contrast review.

Built-in image_gen used. Exact prompt, provenance and SHA256 recorded in sibling files. `python3 docs/art/check_feedback_art.py .` passes11 source-resource checks; explicit source root required, no writes by checker. All references portable; no private machine paths embedded.

Native shop/inventory actual-size acceptance remains pending. Source inspection and11 checks do not certify full-motion feedback, balance, collision or exported behavior. Original high-resolution pixel aesthetic and tiny low-alpha edge residue retained; no external asset license fabricated.
