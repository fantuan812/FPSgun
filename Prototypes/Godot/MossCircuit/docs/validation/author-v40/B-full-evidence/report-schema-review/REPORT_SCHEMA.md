# Report schema correction — runner-only, original36-stop FAIL retained
No production/fixture/count/golden/180 budget changes. Current original full candidate still907, aggregate pins unchanged. Original first35 routes strictPASS;36th actual native0/checks435/emptyfailures/helperPASS was rejected by erroneous whole-dictionary comparison. This document does not relabel the original runner result.

| Route | stdout schema | file schema / additional fixed collections | Comparison |
|---|---|---|---|
| feedback_authority435 | checks,failures | checks,failures,observations36 dictionaries,scope | exact common fields; nonempty scope |
| feedback_authority_rooms338 | checks,failures | checks,failures,observations36 dictionaries,scope | exact common fields; nonempty scope |
| feedback_mixer236 | checks,failures,seconds | buffer_frames,checks,driver,engine,failures,master_gain_db,mix_rate,node_gains,scope,seconds_since_ready,shapes,status,windows | common fields, seconds==seconds_since_ready finite; statusPASS/driverDummy;windows51/shapes5/node_gains2; original7 PCM readbacks unchanged |
| feedback_views168 | checks,failures | checks,failures,samples8 dictionaries,scope | exact common fields; nonempty scope |
| settlement_types1164 | full report | audio_observations204 dictionaries,audio_scope,checks,failures,invalid_decisions102,scope | full equality, exact collection/invalid count |
| independent_B_icons201 | full report | checks,failures,observations3 dictionaries,scope | full equality, independent oracle and existing201 expectations |

Sources: actual unchanged GDScript emitters; original A sourcefull files verify existing report shapes, not new target-generated expected values. B assets shape comes from independent frozen probe. New pure-Python classifier must reject malformed/missing/extra keys, wrong collection types or lengths, differing commonfields, nonfinite seconds, failures/nonPASS. Retain all full files/console raw. QA independently verifies actual original36 fullreport before any combined continuation of remaining129; no false claim of a new all165 single run.

## Complete nested schema revision (static, original drafts retained)
Every collection now has an ordered per-element schema with exact dictionary keys, recursive list lengths and dictionary keys, scalar type and finite-number rules. Fixed mode/case/cue/audio/source/rect/label strings are literal from unchanged emitters/accepted A report; timing/gameplay numeric values are checked for valid types/finite values rather than introducing new damage or timing goldens. Explicit counter/microsecond/index fields must actual ints. Mixer engine9 keys/types and node-gains2 exact keys are recursively validated. B201 observation ID/path and nonzero-alpha/source hashes are from independent frozen EXPECTED, raw importedRGBA permits only lowercasehex64 (transparent RGB variation remains allowed). Emptydict/missing nested fields/NAN/wrong nested type/same-size wrong engine/gain keys are now among95 finite Python checks.
