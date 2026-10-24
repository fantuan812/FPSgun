# Remaining acceptance after the reaction-layer closure

This batch closes authored hurt/death coverage for the seven **existing** enemy archetypes. It does not claim the game or every animation is finished.

Not performed in this batch:

- Live GUI playthrough using real keyboard/mouse input, including title/mode selection, both gameplay modes, pause/resume, settings, upgrades/shop, restart and end-result screens.
- Human judgment of combat feel: reaction readability, perceived hit weight, hover/collapse transitions in motion, visual crowding, camera/scale readability and whether tells remain clear while hurt poses overlay them.
- Full arena playthrough including Wave3 Warden and Wave6 Core with real dodging, ring gaps and summons; room completion with real inputs rather than deterministic fixtures.
- Windows exported-build launch/playtest, platform input/window/audio behavior, sustained performance, memory usage or large-crowd frame pacing.
- Live reduced-flash accessibility review. Headless tests establish tint/pose/state behavior, not a human comfort guarantee.

Still intentionally outside this scope:

- Separate authored attack clips for Warden charge versus blast or Core ring versus summon; the existing attack clips are reused.
- New enemies, attacks, balance, world content, progression, production polish or a claim that all gameplay has been completed.

Evidence provided is Godot headless state/event/resource testing, exact regression traces and source hashes, static source-image inspection, pixel/registration analysis, and immutable-ZIP verification. These are complementary to, not substitutes for, the manual checks above.
