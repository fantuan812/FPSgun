# Road rendering diagnosis

Actual image comparisons on 2026-10-21:

1. Revised scene, Cycles: pure black rectangles at original road intersections.
2. Revised scene, Cycles with asphalt bump disconnected: same black rectangles.
3. Untouched Batch06 scene, Cycles: same intersection artifacts, confirming this is not newly introduced road geometry.
4. Revised scene, original baseline renderer EEVEE: black rectangles disappear.

Decision: final and matched-before renders use the original EEVEE engine, unchanged daylight/world lighting, 48 samples. No exposure trick, no road geometry changed, no new top surfaces added. Existing coplanar roadway assembly remains a legacy limitation for alternate renderers; it should be resolved during a future engine-specific road mesh/collision bake, not silently called engine-ready.

The first attempt also found the local Blender lacks OpenImageDenoise. Unsupported denoising is not used.
