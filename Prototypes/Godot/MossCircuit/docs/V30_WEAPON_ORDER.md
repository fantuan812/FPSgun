# v30 implementation and bounded acceptance status

Status: UNVERIFIED development; true cold import and321 focused author assertions pass, plus existing reservation520/salvage147/rig245. The accepted v29 source/runtime is unchanged.

- Shared read-only `WeaponOrder.loadout_error` validates the current copy/clock arrays. Main owns shop state/generation and raw action guards; no new persistent instance IDs.
- `_move_weapon(slot, step, generation, id)` swaps adjacent IDs/clocks only after all guards, then increments build revision/shop generation and redraws. It does not call recompute or effects synchronization.
- `WeaponRig.swap_copies` carries each record's age/aim, updates slot indices and drops only the two cached poses. Historical last-shot data is retained. It never fires or edits an in-flight projectile.
- Views are detached/read-only for new availability fields. UI adds controls only to owned shop cards; ordinary purchase focus is retained.

Pending: independent no-action parity, independent no-action parity/new-action checks, controlled native both modes/sizes, final regression/resource pack, finite ordinary route, restoration/manual backup and exact reachable GitHub bytes. No validation claim yet.
