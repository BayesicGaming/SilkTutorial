# Development log

## 1. Environment and foundation
The workspace began empty. Godot 4.6.stable.official.89cea1439 and 4.7.2.stable.official.ed1daf0bf were available for verification. No external assets or dependencies are needed.

The project targets Godot 4.6, Compatibility rendering, and 60 physics ticks/second. Input bindings live in project.godot. MovementTuning is the first Resource: shared configuration, with runtime state kept on Player. The movement lab is a separate F6 scene. All platforms will be solid to avoid adding a drop-through mechanic.

## 2. Movement verified before combat
The real CharacterBody2D passed 21 initial checks: acceleration, max speed, stopping, analog magnitude, turning, held/tapped jump trajectories, landing, coyote windows, buffer windows, terminal velocity and dual-device mappings. Measured held/tapped jump heights were 116.91/37.21 pixels. One buffer test initially failed because its teleport fixture retained coyote grace; clearing grace after teleport fixed the fixture, not the controller.

## 3. Shared combat and player attack
Health owns hit points and invulnerability. Hurtbox routes damage; Hitbox polls overlapping hurtboxes only during an enabled swing, remembering each accepted target. AttackData stores timings/damage. Player owns its attack phases and knockback response. Feedback owns short hit-stop and procedural impact bursts. This avoids duplicating health across actors or letting visuals control damage windows.

The sandbox blocked Godot's ordinary editor-settings/user-data writes on first import. After approval, the same executable imported successfully using its normal directories.

Combat passed 14 checks and the first enemy passed 5 checks before room implementation. A standalone --script test compiles dependencies before autoload identifiers are available: the hitbox now resolves Feedback by its scene-tree path at runtime. The first freeze assertion sampled after the brief freeze; it now observes impact_created when hit-stop actually begins. A bounded test runner checks log errors as well as process exit codes.

## 4. Rooms and progression
Four explicit .tscn rooms share an editor-visible platform scene. The first three have exits, entrance/return markers, and room-specific geometry. Room 4 initially contains only arena geometry for the next stage. Game swaps rooms deferred from Area2D signals. Fresh actors restore health on every entry/retry; the small GameState autoload keeps key/unlocked-door flags. Backtracking lets a player who missed the key recover. Spawn markers stand well clear of triggers.

## 5. Progression, second enemy, and boss
Progression passed 17 checks, including locked-door rejection and feedback, key persistence, return spawns, pause, and death reload. The flying moth adds a committed, telegraphed dive and a return to its perch; the enemy suite grew to 9 passing checks.

Boss implementation was incremental: activation/sweep/UI/death passed 8 checks; then leap/fall/impact slam passed 11; then charge was added. Its flat arena avoids the large body snagging underneath player-sized ledges. The three attacks cycle predictably so the pattern is learnable. A local enum and separate AttackData resources make the phases and tuning visible without a general AI framework.

## 6. Presentation and full-loop verification
The complete boss suite passed 15 checks. One presentation-only Visual child draws each distinct silhouette, procedural poses, damage flash and telegraphs. The game does not depend on these drawings. OpenGL rendered all four rooms, and captured PNGs were inspected. The boss bar was moved above the fight after that inspection. These are snapshot checks, not a human judgment of motion or input feel.

An input-action bot then ran the entire route with real physics: avoided guards, climbed every key-room ledge, collected the key, crossed room 3, interacted with the door and defeated the boss. It used no teleporting, direct damage, health overrides, or disabled enemies. The initial route took 41.52 simulated seconds with 6 health remaining. This is an optimized machine route, not evidence of a 5–10 minute human first playthrough.

Synthesized physical-key, mouse, joypad-button and stick events passed 15 input checks. A 0.6 stick event produced 142.50 px/s after the 0.2 deadzone. Initial immediate assertions needed Input.flush_buffered_events(), and the reversal test needed enough frames for the configured acceleration. Physical controller hardware remains untested.

## 7. Documentation and final quality pass
The final learning guide has all 19 requested sections, concrete scene trees, the complete movement/component/attack/damage/progression flows, a tuning reference, an exact reading order, and 16 unimplemented exercises. ARCHITECTURE.md and TESTING.md describe the implemented scene relationships and measured verification, including limitations.

The final suite passed 105/105 assertions on Godot 4.6 and 4.7.2. Both imported the project and ran the main-scene smoke test cleanly. The action-only playthrough also verified the natural three-attack cycle and full restart after victory. Final log scans found no errors or warnings. All external .tscn/.tres file references exist, and a source audit found no physical device checks in gameplay scripts.

Final rendered captures were inspected again after moving the boss bar and framing the gate. No gameplay depends on captured images; artifacts are ignored by the importer. No abandoned gameplay implementation files remain. Remaining human checks are controller hardware, subjective feel, real-time animation readability, difficulty and first-playthrough duration; they are listed explicitly in TESTING.md and README.md.

## 8. Explicit state-node refactor
At the user's request, player and boss behavior moved from central conditionals/enum dispatch into scene-composed state nodes. The original boss enum/match was already an FSM; the change makes its individual behaviors replaceable and gives them explicit entry/update/exit ownership.

StateMachine and ActorState provide one small shared lifecycle. Player has independent Motion (Grounded/Airborne/Hurt/Dead) and Attack (Ready/Startup/Active/Recovery/Disabled) machines to preserve air attacks without combinatorial states. Physics formulas and named-action sampling stay on Player. Hurt/Dead coordinate with the Attack machine; damaging states disable hitboxes in exit, including on interruptions. Actor state flags are derived rather than separately writable.

Boss states each have a short script under boss/states/. The actor retains tuning, target/data selection and common physics, while states own phases/timers. The boss initializes inactive until Game activates it. Guard and moth retain their concise enum FSMs; their current size does not justify the extra state files.

The 19-section learning guide now explains lifecycle order, both player machines, concrete scene trees, cancellation cleanup, the boss state scripts, and how to add double jump without implementing it. Architecture, README and testing records were updated to match. There are now 18 suggested exercises.

All 132 checks (the original 105 plus 27 FSM checks) pass on Godot 4.6 and 4.7.2, including editor import and main-scene smoke runs. The measured jump heights remain 116.91/37.21 px. The full action-only route remains 41.52 simulated seconds with six health. No parser/runtime warnings or errors were reported in either final suite.

The rendered capture scene also ran cleanly after the refactor. Player and boss snapshots were inspected to confirm their presentation still follows the new state names. Final reference checks found no missing scene resources or obsolete player/boss state APIs.

## 9. Branching rooms and vertical travel (2026-09-23)
Room 2 is now the Crossroads: left returns to Room 1, right reaches the existing moth/gate room, and a floor opening leads down to the new Room 5, Lantern Well. Room 5 holds the key at the bottom and six alternating solid platforms leading back to an up exit. Appending Room 5 preserves the existing room indices and boss-door destination.

The existing exit signal and deferred loader already support multiple destinations. Vertical exits reuse room_exit.tscn rotated +/-90 degrees. The well's Entrance sits on the upper ledge; its Up exit targets Room 2's new FromWell marker on solid ground beside the opening. These safe arrivals prevent immediate return transitions, and current_spawn makes retries/deaths use the correct entrance. An arrow_offset export keeps the vertical arrows visible away from the HUD without moving their collision triggers.

Progression now passes 26 checks, including all junction exits, no bounce on vertical arrivals, key persistence/revisit, and retries/death at the correct marker. The input-only playthrough passes 31 checks: it first jumps across the hole and visits the locked gate, then backtracks, descends, collects the key, climbs every ledge, returns upward, and finishes the boss. It takes 63.33 simulated seconds with six health remaining. This is automated traversal evidence, not human playtesting.

All 158 checks, editor import and the main-scene smoke run pass on Godot 4.7.2. The new progression and playthrough also pass on 4.6, but a full run on 4.6 now fails six keyboard/mouse input checks with the pre-existing current project input settings. The runner defaults to 4.7.2 to match the current project; the input map was not changed. Five room captures plus a close view of the well's up exit render cleanly; the junction and well views were inspected.

Learning Guide Section 15 now includes the branching map, destination/spawn table, vertical trigger setup, safe-spawn rationale, and a breakpoint walkthrough for following an exit request. README, architecture and testing records describe the five-room layout; the next-room exercise now adds Room 6.
