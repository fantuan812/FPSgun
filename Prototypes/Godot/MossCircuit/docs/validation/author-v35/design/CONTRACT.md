# v35 contract draft — player damage / Mirror Shell sound feedback

DESIGN ONLY. Baseline: accepted local v34,664 engineering inputs/124 production paths, PCK250ea5966ff7ca35b42a13cd813ba5ff156288cfc97110a411dd73664ccbbe02. Historical pre-implementation design; technical clauses retained.

## 1. Fixed scope and honest alternative

Complete one missing feedback dimension: exactly two original deterministic procedural non-voice cues, for actual player HP loss and genuine Mirror Shell block. This is not repair of imaginary volume controls: current settings contain only reduced_flashes, and current README already says sound/music do not exist. Documentation-only disclosure would be smaller but would add no feedback.

No music, voice, UI/weapon/enemy/boss/upgrade sounds, random pitch/variants, positional audio, acoustic occlusion, new gameplay mechanic, item/catalog row, device selector, general mixer UI, microphone/recording feature, third-party sound/code downloads, install, engine upgrade, new persistence or OS/audio-bus-layout/volume mutation. No new license waiver or third-party licensing claim: retain existing project policy and factual original-generator provenance only.

v34 ordinary change/clear/pause-retention limits and native WM-focus-loss non-observation remain distinct, accepted limits—not bugs to fix or silently reclassify. v27 ordinary Rooms3/3 and v33 ordinary Arena6/6 are historical artifact-specific evidence, not v35 proof.

## 2. Exactly two resolved authority-to-presentation requests

Use the existing `main._hurt` branches. Do not add a new Effects event, increment its sequence/epoch, reuse a VFX ID as an event, or change damage/AI/build/RNG/cooldowns/field/targeting/proc order.

1. Preserve the first guard (`state != playing`, positive hurt_clock, positive dash_time); rejected calls request no sound.
2. Preserve `_effect_event("before_hurt",{})`. Its true result currently means the Mirror charge was consumed by `Effects.process`134–139 and the `EffectRuntime`55–58 block command. Preserve `.25` hurt-clock assignment, then request one `shield_block`, then return. No damage cue. Do not independently decide whether to spend shield, or infer a block from inventory/visuals. Current authoritative block consumption is the condition even for synthetic calls; audio adds no new incoming-damage validity rule to that existing branch.
3. Preserve, in order, actor hurt/VFX, `CharacterMotor.apply_damage`, the existing hurt effect with actual_loss, `.75` hurt clock, and possible `_finish(false)`. After these operations, request one `player_damage` only when returned actual_loss is finite and >0. Overkill still produces one fixed cue, not a louder cue based on requested damage. Synthetic zero/negative/nonfinite returned loss produces no damage cue; do not repair synthetic damage arithmetic in this unit.
4. A just-resolved lethal positive-loss cue may be submitted after existing finish cleanup under clause5. A later call in dead/won is rejected by the original guard.
5. Sound accepts only a fixed cue ID through a presentation sink; it receives no mutable world/build/effect reference. Missing/unavailable sound cannot gate/cancel/defer/retry gameplay. No await, sound-completion gameplay callback, gameplay RNG, audio-derived simulation time, or unbounded queue/allocation.
6. `hit_spark` and `shield_impact` remain visual only. The latter is also used for heal/gravity/thorns. Direct visual requests, enemy damage, healing, pickups, dash, stage settlement, reflected damage, Medic creation or Feedback Diode do not create additional cues. Genuine shield+Thorns and actual damage+Medic/Thorns still request exactly one appropriate player cue.

## 3. Two original finite PCM assets and exact generation recipe

Generate canonical WAV files with a small original standard-library Python program, no imports beyond standard library and no random source. Generation metadata records the script/parameters/toolchain and final byte/data hashes; it makes no public-domain/CC0/royalty-clearance assertion. Regeneration must be byte-equal in the pinned tested toolchain; cross-platform libm bit-identical regeneration is not promised. Canonical checked-in bytes remain authoritative.

|cue|N samples|duration at44100Hz|f0→f1|second harmonic weight|
|---|---:|---:|---|---:|
|player_damage|7056|0.160s|320→140Hz|0.25|
|shield_block|5292|0.120s|720→1080Hz|0.15|

For n=0..N−1, t=n/44100 and T=(N−1)/44100. Phase is2π[f0·t+(f1−f0)·t²/(2T)]. Let a=min(1,n/221), r=min(1,(N−1−n)/662), envelope=sin²(πa/2)·sin²(πr/2), raw=envelope·[sin(phase)+harmonic_weight·sin(2phase)]. Subtract weighted DC: corrected=raw−envelope·sum(raw)/sum(envelope). Normalize corrected to absolute peak0.25. Quantize with Python round-to-nearest-even of32767×sample, clamp to signed16-bit range, and store little-endian. Both endpoints must remain zero. Use a minimal standard RIFF/WAVE PCM header: mono,16-bit,44100Hz,88200byte/s,block-align2; no loop/metadata chunks. No assets are generated by this draft.

For all decoded peak/RMS/DC bounds, convert each signed16 integer to a normalized sample by dividing by32768 (not32767). Independent accepted-asset bounds: exactly those sample counts, <=32KiB total WAV bytes, absolute decoded peak<=0.25, RMS0.02..0.18, absolute mean<=0.001, first/last sample0, finite values, distinct complete PCM identities. The attack/release ramps are about5/15ms. These are digital signal bounds and deliberately distinct frequency designs, not a claim that a human has listened, found them pleasant or can reliably distinguish them.

Godot import must remain mono16-bit PCM,44100Hz,nonloop, exact N and data bytes: no normalization, trimming, compression or resampling of the imported resource. Check source RIFF independently and loaded/exported AudioStreamWAV separately. A dedicated portable resource test may cover these two streams without broadening the existing export-helper schema. At runtime, invalid means missing/wrong resource type, wrong format/rate/channel/loop metadata or wrong PCM sample count. Runtime content hashing is not required; exact PCM bytes/hash identity is an acceptance test. Missing/invalid resources disable only that cue, with bounded diagnostic status; no game failure, resource fetching or regeneration during play. This graceful degradation is not a shipped-feature PASS: final acceptance requires both exact valid streams, loaded and exported.

## 4. Playback, bounded mixing and settings

One small presentation-owned controller has exactly two non-positional AudioStreamPlayer children, one fixed stream each. Both have autoplay=false, pitch_scale1, max_polyphony1 and fixed linear gain0.5. At most two voices total. Same-cue retrigger cuts/replaces its old voice; two different cues may overlap. No backlog or per-event node creation, dynamic bus creation/layout/volume changes or output-device/OS changes. Use the existing Master routing. Test instrumentation may temporarily attach capture only in an isolated test process, never the shipped game.

Two source peaks0.25 at node gain0.5 have a theoretical pre-resampling summed peak<=0.25 under a unity Master bus. Actual capture under that test condition must peak<=0.30. This is digital headroom only—not safe listening volume, device loudness or comfort certification. Actual output still depends on host/user settings.

Add one presentation-only session boolean `mute_feedback_sounds`, default false in a fresh process, retained across title/new/retry within that process and never written to disk. Muting immediately stops both players at the request/player layer and rejects new requests; audio-driver buffers can drain, so exact zero at the call instant is not promised. Unmute/resume plays nothing retroactively. No slider, test-sound button or new menu.

Rename existing DISPLAY SETTINGS entry/page to PRESENTATION SETTINGS (same title/pause routes). Keep reduced flashes intact; add one connected MUTE PLAYER FEEDBACK SOUNDS checkbox and “Only HP-loss and Mirror Shell block cues. Session only; no music.” Only boolean values in the existing settings state are accepted; wrong keys/types/states do not change settings, audio or gameplay. No recomputation/build revision/effect invalidation merely from muting.

Read-only status reports missing cues and actual current audio-driver name without playing or repairing anything. Dummy is explicitly labeled no physical device output; it still permits the internal mixer/mute path. A non-Dummy name is not a “speakers working” claim. No microphone/input-device enumeration/permission request. Reduced flashes changes only its old visual behavior, never sound gain/mute.

## 5. Exact named lifecycle boundaries and lethal-tail exception

Game pause is manual session.state, not necessarily SceneTree.paused. Do not rely on process_mode alone, and never use stream_paused to preserve/replay old cues.

|existing controller seam|sound-only action; existing authority sequence retained|
|---|---|
|_present_pause; _present_inventory|stop/discard both before showing the relevant modal; covers button/keyboard routes|
|_show_upgrades; _open_shop|stop/discard on entry, including queued choices|
|_begin_room_clear|stop only after the existing playing guard accepts entry|
|_complete_wave|after RunFlow.settle succeeds (not invalid/ignored), stop before presentation of next stage/modal; covers policies returning directly to playing|
|_title|stop/discard; no sound from menu navigation|
|_start_run|after valid fresh_build check, stop/discard before resetting; invalid start keeps existing semantics|
|_finish(won)|stop/discard older cues during existing cleanup; victory emits nothing|
|NOTIFICATION_APPLICATION_FOCUS_OUT|stop/discard whenever controller exists, including lethal tail, then preserve existing UI/pause handling; returning focus never resumes|
|mute=true or controller exit/free|stop/discard; no playback recreation after scene/run destruction|

After `_hurt` has completed all original positive-loss operations including `_finish(false)`, its one resolved lethal event may start the **same**160ms damage cue. Older voices are already discarded. This cue may finish naturally during existing death animation/result; direct `_finish(false)` without a positive-loss hit creates none. Later dead/won requests reject. Title/retry/focus-out/mute/teardown truncates it. No third death cue, deferred resurrection callback or blanket per-frame `state != playing => stop` that silently erases the permitted tail. A narrowly presentation-only terminal-tail permission may identify this exact already-resolved request, not authorize arbitrary dead-state calls.

Named modal/settlement boundaries may deliberately truncate a just-requested nonlethal cue. Completion of every cue, zero mixer latency and click-free interrupted tails are not promised. All tail/cutoff timers or diagnostic counters are presentation-only; none read back into gameplay.

## 6. Independent acceptance matrix, pinned before production edits

A. Authority: actual contact/projectile/blast/annulus reach unchanged hurt path; positive unblocked loss gives one damage request; genuine fresh Mirror gives one block/no damage; spent shield follows original damage path. Dash/hurt immunity/wrong phase give none. Zero/negative/nonfinite returned loss gives no damage cue. Lethal/overkill exactly one request with explicit tail. Preserve synthetic existing arithmetic rather than silently fixing it. Generic VFX/heal/enemy hit/Thorns/Medic/Feedback cannot multiply requests.

B. Purity/default compatibility: old gameplay fields/build dictionaries/HP/shield/proc counters/sequence/epochs/RNG/clocks/targets/economy/choices and animations match enabled vs muted vs missing-cue runs at identical controlled inputs. Audio nodes/counters and new setting/status are declared presentation additions only. Reuse eligible exact-v34 no-action6/24 outputs only with an explicit production-identity proof; do not relabel historical execution. No full v34 rerun solely to manufacture a new baseline claim.

C. Resources: independent RIFF reader checks exact recipe/data hashes and numeric/envelope bounds; imported and exported AudioStreamWAV matches rate/format/mono/nonloop/N/PCM. Check resource budget and each missing/invalid cue path without runtime regeneration. Full pack uses the unchanged verified ELF; Windows preset export is not Windows execution.

D. Actual mixer: external AudioEffectCapture reads fresh real engine mixed frames, not a play-call counter. Record engine/driver/mix rate, frames pushed/read/discarded, bus/node gains, timing and controlled input. Require discarded0 and sufficient newly captured PCM for each conclusion. Nonzero correct-shape data for each actual event; repeated/overlap bounded; node gain and combined peak bound; natural completion; lethal tail; mute/wrong-state/missing-cue and post-stop silence only after a bounded pipeline-drain window. Empty, stale or dropped ring-buffer data is not evidence of silence. Source and exact PCK both pass. No capture/recording/input permission ships.

E. Lifecycle/UI: actual settings checkbox/labels plus strict intent rejection; all clause5 transitions, focus notification, entering queued upgrades, direct-stage settlement, mute during active cue, unmute/resume no replay, valid/invalid new-run behavior, and exact lethal/no-later-dead-request exception. Keep presentation and authority snapshots separate. Both modes and practical960/1280 layout; controlled native input is not physical audio. A real focus-loss claim requires actual WM observation, not calling a notification.

F. Ordinary/platform boundary: one bounded real-control observation of an authentic damage/block event and actual settings use may supplement controlled tests, with outcomes stated honestly and no campaign/clean-story retries assumed. Event/mixer capture is not physical listening. No human timbre discrimination, comfortable loudness, Windows, all-device latency, audio accessibility or hearing-safety claim follows from A–E.

## 7. Capability gate and exact release claim

Available documentation/source makes engine capture under Dummy technically plausible, but **no probe has run**. AudioStreamWAV holds PCM, AudioEffectCapture copies bus frames and processes silence, and4.6.3 Dummy calls audio_server_process when active. Headless selects Dummy. These facts justify testing, not a capability PASS or listening claim.

Run one short isolated pre-code capability probe using an in-memory deterministic test tone, existing engine and explicit Dummy. No production WAV/candidate/accepted-root edits, installs or host-device changes. Bound process to<=10s, use a finite adequately sized ring and read frequently; require known nonzero tone and enough fresh post-stop zero/silent frames, discarded0, actual driver/mix-rate recording. Preserve any failure and its exact stage: startup timeout, script/resource failure, missing fresh frames, overflow or signal assertion failure are distinct outcomes, not evidence of absent hardware. Report BLOCKED/UNPROVEN rather than inferring that a silent device proves silence.

Recommended eventual acceptance is explicitly A–E plus whatever ordinary observation actually occurs: “Two cues implemented; PCM/resource/engine-mixer correctness verified. Physical playback and listening quality unverified.” If physical audibility is instead required, an authorized capable host/listening observation is a separate prerequisite; without it that gate remains open. Do not install drivers, request microphone access, call Dummy listening, or substitute Windows file inspection for execution. Documentation-only absence disclosure remains the smaller fallback, not a fake enabled control.

Final test and artifact evidence are separately attributed.

## Primary technical references

- [Godot4.6 AudioEffectCapture](https://docs.godotengine.org/en/4.6/classes/class_audioeffectcapture.html): sample ring and fresh/discarded-frame inspection.
- [Godot4.6 AudioStreamPlayer](https://docs.godotengine.org/en/4.6/classes/class_audiostreamplayer.html): finite polyphony, non-positional playback, stop vs paused resume.
- [Godot4.6 AudioStreamWAV](https://docs.godotengine.org/en/4.6/classes/class_audiostreamwav.html): PCM resources.
- [Godot4.6 AudioServer](https://docs.godotengine.org/en/4.6/classes/class_audioserver.html#class-audioserver-method-get-driver-name): driver/mix-rate reporting; headless Dummy.
- [Exact4.6.3 Dummy source](https://raw.githubusercontent.com/godotengine/godot/4.6.3-stable/servers/audio/audio_driver_dummy.cpp) and [capture source](https://raw.githubusercontent.com/godotengine/godot/4.6.3-stable/servers/audio/effects/audio_effect_capture.cpp): mixer activity and silent-frame processing without hardware output.
