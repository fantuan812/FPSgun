# v28 input-scope clarification

The original frozen contract remains preserved verbatim. Its assumption of an existing controller-mapped `ui_accept` event was tested rather than silently accepted.

A read-only probe of the accepted v27 project under the same Godot 4.6.3 engine reports `ui_accept` mappings for Enter, keypad Enter and Space only. Synthetic joypad A/B/X/Y inputs do not match that action. The initial view harness therefore failed its mapping assumption; its original script and result are retained.

The parent accepted this bounded clarification before native acceptance: test native keyboard/mouse plus synthetic `InputEventAction("ui_accept")` and focus dispatch. Do not add or inject a joypad binding. Action-level injection is controlled UI testing, not evidence of a shipped controller mapping or physical-controller gameplay support. The production input configuration is unchanged.

No card geometry or transaction test is weakened by this clarification. Native keyboard/mouse review remains a separate gate. Controller mapping and physical hardware execution are explicitly not certified.
