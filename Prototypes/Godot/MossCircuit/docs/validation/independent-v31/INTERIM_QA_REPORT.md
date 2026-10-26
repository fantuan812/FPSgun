# Independent v31 R3 source acceptance

Status: bounded source mechanics/UI/native gate passed. Final full regression, exact packed resources, and two ordinary alternate-kit early starts remain pending.

## Identity and results
- Frozen design contract: `0f731dd1a5acfe3bdc2f19bfbf4ca6f3f08b0dc5a6353faa7dd9feec61cd980f`. `PRODUCTION_R3.json` pins121 engineering inputs; its UI README is documentation, not gameplay code.
- Actual R3 mechanics:977 checks. Actual R3 layout/actions:544 checks. No failures/application engine errors in those headless runs.
- Actual candidate replay:24 finite old-schema default cases and36 timing assertions/8 cases are byte-identical to accepted v30 outputs. Baseline outputs were reused with pinned source/scripts/output/remote proof, not executed anew. This is not whole-object identity or all-seed balance proof. The old trace does not invoke reordering; actual buy/reorder/sale appears separately in new reset tests.
- Initial R1 import was genuinely cold; subsequent corrected focused runs reuse its cache.

## Native source scope
Actual cloud Linux rendered game windows through automated CUA keyboard/mouse, external controlled fixture with simulation frozen. Both Arena/Rooms at960x540 and1280x720. All three cards and buttons now fit the first viewport; same font sizes and existing atlas icons. Distinct SELECTED/border plus fixed START weapon-kit/scrap summary. All three kits selected via actual keyboard; Scatter also mouse. Seed128 retained through Settings/Escape, Guide/Back and mode switch. Rail BASE30/1.150s/650px and Scatter9 per pellet/0.850s/300px/5pellets readouts/notes inspected.

Actual START led to Rail17 in Rooms and Scatter23 in Arena. Controlled replacement with Bankshot shows STARTED WITH Rail still distinct from current equipment. Forced result is explicitly NOT an ordinary victory. Actual Retry then New Seed restored Rail17 and128→129, as recorded by fixture logs. Inventory origin/readouts are readable at small/large sizes. Artist separately viewed13 bounded samples; no new assets.

External terminal Ctrl+C closed fixture; fresh window absence confirmed. VSync unsupported and ALSA ERR_CANT_OPEN→dummy are retained; no audio/Windows/controller hardware claim. One zero-duration fixture F2 key was unsampled, then held120ms and verified, not inferred as successful.

## Rejected findings preserved
1. R1 new START callback captured a freed LineEdit after title rerender. R2 WeakRef corrected it.
2. Independent R1 inventory-name oracle expected one space where existing cards use two before SLOT;12 false assertion failures. Original retained, only expectation corrected.
3. R2 first viewport hid all loadout cards and clipped the heading. R3 compact3-across choices fixed actual discoverability; six display strings shortened, numeric/ID registry values exact.
4. R2 retained mode callback similarly dereferenced a freed seed editor. R3 WeakRef plus strict optional generation guards for new-context seed/mode callbacks reject stale requests even before deferred free. Legacy no-generation callers unchanged.

The callback errors were controlled retained-callback reproductions with authority unchanged, not ordinary player crash claims. Raw rejected backtraces remain private; later public copies must preserve sanitization hash relationships.
