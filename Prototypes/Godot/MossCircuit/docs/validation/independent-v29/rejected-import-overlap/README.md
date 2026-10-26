# Rejected QA execution, not a production defect

The first candidate trace/runtime scripts were mistakenly launched while the asynchronous cold import was still running. Their missing imported-texture errors invalidate both runs, including a printed176-check pass that appeared amid engine errors. The cold import subsequently ended exit0, clean. These original logs/results are preserved. No production code was changed; replacement script runs begin only after the confirmed import exit. This known QA sequencing error is not attributed to or evidence about unrelated learning startup failures.
