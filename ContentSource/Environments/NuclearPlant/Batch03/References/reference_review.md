# Appearance-reference review before modeling

Five separate images were generated with the built-in image tool. It does not expose a verifiable Image 2.5 identity. They guide material/construction language only; JSON specs and final Blender geometry govern dimensions.

- Straight pipe: broadly useful teal barrel and bolted flange language. Apparent scale, surface weathering and bolt patterns are not measurements. Actual body radius is 0.265 m to seat in Batch01 saddles, bore radius 0.21 m, length exactly 4 m.
- Elbow: generated FRONT and RIGHT are wrongly oriented, and TOP is a side-like bend with invented straight tails. Actual bend lies in XY, centerline radius 1 m, endpoints (0,0,0) and (1,1,0). Reject the reference view labels/orientation.
- Tee: generated branch rises in Z in front/right and TOP includes perspective. Actual branch points +Y in XY. The side projection must not show a vertical riser. The actual hollow junction must have communicating bores.
- Valve: useful bonnet, handwheel and teal body. Right view labels a 0.210 m diameter despite the requested 0.21 m radius; actual bore diameter remains 0.42 m. Wheel and flange dimensions follow spec. Reference rust and cast texture are not fully reproduced by basic PBR.
- Pump: useful ribbed motor, coupler guard, feet and skid. Generated discharge points +Z and the right view invents/reorients the motor. Actual discharge points +Y at (1.5,1,1), suction -X at (0,0,1), all within 4 × 2 × 2 m. No claim of realistic internal impeller simulation.

Final front/right/top images are rendered from real Blender ORTHO cameras at the common 160 px/m, not derived from these AI images. Beauty framing is separately adaptive.
