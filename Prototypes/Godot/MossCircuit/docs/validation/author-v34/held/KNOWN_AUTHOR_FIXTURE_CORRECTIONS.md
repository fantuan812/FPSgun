# Preserved author fixture correction

The original focus-fire R1 run completed224 passes/4 failures (one Orbit in-range expectation per mode/tier). Its marked target was110 world units away while the unchanged Orbit catalog reach is105; the production sweep correctly left that target untouched. The dedicated outside-range Orbit case already passed.

Only the in-range Orbit fixture moves its marked target to90; all seven aimed types retain110. No production/range/collision change. Original script and failed log are retained. Rejected script SHA-256 `477b62983e0f55bca76c0ba3d7d2f822a889f24de1fc8a90310aee131adbdafc`. Independent QA independently identified the same oracle error. Final verification requires a fresh terminal rerun, not deleting failures.
