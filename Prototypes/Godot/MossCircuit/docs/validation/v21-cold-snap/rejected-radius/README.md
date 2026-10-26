# Rejected initial cone-radius precision

The initial1e-6 world-distance tolerance missed a nominal190-unit center at315 degrees after Vector2 rounding to190.000015258789. Both field centers reproduced this independently. These original code/probe/log bytes document the rejected candidate, not final acceptance.

The shared selection/membership radius epsilon is now0.0001 world units. The corrected probe has no misses, and the focused205-check plus independent446-check suites cover all eight orientations/both modes and just-outside rejection. No damage tuning or geometry scale was changed.
