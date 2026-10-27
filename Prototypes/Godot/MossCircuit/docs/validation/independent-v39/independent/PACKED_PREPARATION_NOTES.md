# Unexecuted preparation notes
Initial runner draft inherited old best-effort one-line parsing; replaced before any execution with strict multiline JSON decoding and explicit report count, preserving the draft. Audio stdout summary and file full-report differ legitimately; all must match exact checks and empty failures, not equal entire objects.

A read-only attempt to derive source authority observation vectors from full151 logs failed an assertion: those original scripts emitted only checks/failures without a report destination. No target was run, no oracle was created, and no source-vs-packed observations equality will be claimed. Packed original assertions and their emitted full observations are still independently audited.
