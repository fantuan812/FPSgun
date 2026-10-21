# Image-reference review — deliberately not used as dimensional proof

Eight references were created using the available built-in image-generation tool. The tool does not expose a selectable or verifiable “Image 2.5” model identity. No claim is made that a specific image model version was used.

Every reference was generated before the respective Blender module mesh. The exact module spec and interface coordinates override visual contradictions.

| Module | Useful appearance | Observed deviations rejected in modeling |
| --- | --- | --- |
| Straight catwalk | Yellow tube rails, galvanized grating, bolted graphite frame | Front and right show floor tops/perspective; top/front scale differs; projecting supports extend below requested 0.20 m frame |
| 90-degree corner | L-shaped grating, inside/outer safety rails | Projection tilt and inconsistent scale; dimension label placement contradicts footprint; extraneous feet and closed-port suggestions |
| T-junction | T layout and continuous industrial material family | Main front guardrail omitted; perspective, branch-width proportions and cross-view scale unreliable |
| Stair | Open grating treads, yellow rail, dark stringer | FRONT/RIGHT orientation is swapped relative to world-axis convention; too many stairs; perspective and inconsistent scale |
| Open railing | Four posts, middle rail, toe kick | Overall length-to-height proportion is approximate; end view is wider than a 0.125 m depth should appear at uniform scale |
| Infill railing | Framed vertical metal bars and steel fasteners | Infill spacing and panel length-to-height ratio differ; enlarged end profile |
| Column | Bolted H section and yellow warning band | Top is enlarged; top view shows section through a cap rather than the actual opaque cap top; base/cap depth is not consistent |
| Pipe support | Portal frame, upward-open saddles | Right view incorrectly shows semicircular saddle face; proportions and scale differ; prompt-required dimensions remain authoritative |

The generated references are retained as reference_sheet.png. True geometry verification is in front.png, right.png and top.png, rendered from one Blender mesh with actual ORTHO cameras. Each image is 1024 × 1024 at 160 pixels per meter; camera axis and scale are recorded in validation.json. These views intentionally disagree with the AI image where it violates dimensions, orientation, open interfaces or physical construction.
