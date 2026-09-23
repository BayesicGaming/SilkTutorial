# Testing record

## Environment and scope

Initial verification: 2026-09-22. Branching-room verification: 2026-09-23, Windows PowerShell. Both available Godot versions were executed:

- **4.6.stable.official.89cea1439**
- **4.7.2.stable.official.ed1daf0bf**

The current project is saved for 4.7 and verified with Godot 4.7.2 using Compatibility rendering. No external test library, art dependency, plugin or package manager is required. Tests are plain GDScript SceneTree scripts that instantiate the real gameplay scenes.

## Automated results

The full suite passes **158 assertions on Godot 4.7.2**, with successful editor import and a separate main-scene smoke launch. The test runner rejects nonzero exit codes, ERROR/SCRIPT ERROR/WARNING log entries, and a test that never prints its completion summary.

The new progression (26 checks) and action-only playthrough (31 checks) also pass on Godot 4.6. A full 4.6 run stops at six failing keyboard/mouse input checks with the current input-map device values (keyboard 16, mouse 32); the same input suite passes on 4.7.2. The room change leaves those existing project settings intact. The runner now defaults to 4.7.2, matching the current project. Earlier dual-version results below describe the project at the time of those checks.

| Harness | Checks | What it exercises |
|---|---:|---|
| test_input.gd | 15 | Synthesized physical-key, mouse, joypad button and stick events; deadzone; partial/full analog speed; D-pad; both device paths for jump/attack/interact/pause/restart |
| test_movement.gd | 21 | Real floor collision, acceleration, maximum speed, braking, analog action strength, turning, jump trajectory/landing, held versus tapped apex, coyote inside/outside, buffering inside/outside, terminal cap, dual-device action bindings |
| test_combat.gd | 14 | Shared health validation/clamping/death-once/immunity; actual Area2D overlap route; startup/active/recovery; directional knockback/control lock; one accepted hit per swing; hit-stop entry/restoration; delayed player respawn signal |
| test_states.gd | 27 | Lifecycle ordering, active-state-only ticks, explicit restart, independent player motion/attack, damage/death interruption cleanup, recovery, unchanged single jump, boss activation/cleanup and terminal death |
| test_enemies.gd | 9 | Guard chase, warning/active/recovery, mutual combat, removal; moth warning/dive/return, damage and shared death |
| test_progression.gd | 26 | All three junction exits, vertical return, safe top/lip spawns, no bounce, key collection/persistence/revisit, retry and death at FromWell, locked feedback, unlocked entry, arena closure, pause/resume and frozen gameplay |
| test_boss.gd | 15 | Activation, health bar, sweep/slam/charge phases, physical leap/landing/charge movement, damage in both directions, bar updates, death and victory |
| test_playthrough.gd | 31 | Complete action-only route through all five rooms, gap crossing, locked-gate visit and backtrack, downward travel, bottom key, six alternating ledges, upward travel, gate interaction, boss defeat, all three attacks, new run after victory |

Editor import parses/registers scripts and imports scenes/resources. The smoke run executes game.tscn for 300 fixed frames. The focused tests actually instantiate every gameplay scene used in progression, catching missing paths at runtime as well.

Observed movement values: held jump **116.91 px**, two-frame tap **37.21 px**. A synthesized stick value of **0.6** gives **142.50 px/s** after the 0.2 deadzone; full tilt reaches **285 px/s**.

## FSM refactor verification

After converting the player and boss to state nodes, the original 105 checks still pass, with 27 additional lifecycle/interruption checks. The full 132-check suite, editor import and main-scene smoke run were rerun on both installed Godot versions. Held/tapped jump heights and the action-only playthrough time remain unchanged. Tests and visuals now observe state names; no compatibility enum or duplicate writable state flags remain on the player/boss.

The new tests deliberately interrupt player Startup/Active/Recovery with death and interrupt each damaging boss state through its exit hook. They also verify that movement and attack run concurrently, Hurt suppresses control, the boss stays inactive until activated, and death cannot restart the boss. Double jump remains an exercise, with a regression check confirming it was not added during refactoring.

## What “complete playthrough” means here

test_playthrough.gd starts a fresh run and issues only named input actions (plus an InputEventAction for interaction/restart). It runs across Room 1, jumps across Room 2's floor opening, visits the locked gate in Room 3, backtracks, drops through the down exit into Room 5, collects the key at the bottom, climbs all six real solid ledges, jumps into the up exit, returns through Room 2 to Room 3, opens the gate, fights the active boss, observes victory, and restarts the run.

It **does not teleport actors, call damage directly, modify health, disable enemies, force boss choices, or replace the movement controller**. The bot reads positions/states to decide its inputs. The branching route completed in **63.33 simulated seconds**, ending with six health. That is a perfect-information machine route, not a measured human first playthrough.

Focused tests intentionally position actors and call selected methods to isolate cases. For example, progression teleports the player near exits to test destination handling; boss tests force each attack choice and use direct lethal damage to isolate death. Those tests are not presented as ordinary playthroughs. The separate action-only test supplies that additional evidence.

The requested **5–10 minute first-playthrough target remains unverified**. A player who already knows the route can complete it much faster. The new lower room demonstrates branching and vertical transitions; its size was not chosen to manufacture a minimum duration.

## Commands used

From the project directory, run all checks with the local runner:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run_tests.ps1
```

Run one suite:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run_tests.ps1 -Suite movement
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run_tests.ps1 -Suite boss
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run_tests.ps1 -Suite states
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run_tests.ps1 -Suite playthrough
```

Select another installed executable (4.7.2 is also the runner default):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run_tests.ps1 -Godot 'C:\path\to\Godot_console.exe'
```

The process-only execution-policy override is needed on this machine because unsigned local scripts are disabled. The runner does not change system policy. Logs in **logs/** are overwritten by the latest run and contain the engine version.

Equivalent direct Godot calls, using the installed executable:

```powershell
$godotExe = 'C:\path\to\Godot_console.exe'
& $godotExe --version
& $godotExe --headless --path . --editor --import
& $godotExe --headless --path . --script res://tests/test_movement.gd --fixed-fps 60 --quit-after 24000
& $godotExe --headless --path . --quit-after 300 --fixed-fps 60
& $godotExe --path . res://tests/capture_visuals.tscn --quit-after 400
```

To write a direct-run log, append **--log-file** followed by an absolute file path in an existing directory. The runner constructs that path for you. These commands were checked against the installed executables; the [official command-line reference](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html) explains their engine options.

The runner's fixed-fps mode supplies deterministic simulation steps and executes quickly without waiting for real time. It uses a bounded quit-after safeguard and then requires a suite completion line, so an interrupted/hung harness cannot silently count as passing.

## Rendered verification

**tests/capture_visuals.tscn** launches the real Game, positions the player for room screenshots, requests rendered frames, and saves PNGs to **tests/artifacts/**. It requires a real rendering window; headless mode intentionally reports an error for this scene.

Godot 4.6 successfully rendered through OpenGL Compatibility. Four room captures were visually inspected for character silhouettes, key readability, environment/platform visibility, camera framing and HUD layout. The boss bar was moved from near floor level to above the action after inspection. A later capture includes the sealed gate. Screenshots are QA artifacts, not game assets.

For the branching-room change, Godot 4.7.2 rendered all five rooms plus a separate view of the well's up exit. The junction and well captures were inspected for the opening, bottom key, platforms, and arrow visibility. The down arrow was moved above the opening with a visual offset so it does not overlap the bottom controls bar; its collision trigger stays below the floor. The up arrow has an offset to keep it below the top HUD.

Still images show selected procedural poses, warning rings and the boss slam marker. They do **not** verify animation smoothness, timing perception or subjective input feel. No live human-controlled play session was performed.

## Failures encountered and fixes

| Initial issue | Resolution |
|---|---|
| Sandboxed import could not write normal Godot settings/user directories and reported certificate-store access errors | Reran with approved access to Godot's normal folders; later imports/runs were clean |
| Standalone combat --script compilation could not resolve a Feedback autoload identifier through a dependency | Hitbox resolves the autoload by /root/Feedback at runtime; the same implementation works in game and tests |
| Expired-buffer test unexpectedly jumped | Its teleport fixture still had coyote grace from standing on the floor; cleared grace in that fixture after relocation |
| Hit-stop assertion sampled after the very short freeze ended | Observe impact_created when freeze begins, then separately verify restoration |
| Immediate device-event assertions saw no action | Flush buffered synthesized events before immediate assertions |
| D-pad reversal expected full opposite speed too early | Allow 18 frames to complete configured turning/acceleration |
| Windows refused to load run_tests.ps1 | Use the documented process-only execution-policy override |
| Boss bar competed with the action near the floor | Move bar to the upper HUD region |

All of these fixes were rerun. No known parser/runtime errors prevent the intended progression.

## Manual checks still needed

Controller mappings and code were verified, but physical controller behavior requires manual testing.

Movement behavior was mechanically verified, but subjective feel requires manual testing.

1. Use your actual keyboard/mouse: run, stop, reverse, hold/tap jump, strike while moving and in the air.
2. Test your actual controller: small/full stick tilt, drift near the deadzone, D-pad, all three face actions, pause and retry.
3. Switch between keyboard and controller mid-room, including unplug/replug. Driver/layout/hotplug behavior has not been tested.
4. Try grace jumps just after an edge and buffered jumps just before landing. Decide whether the windows feel forgiving without feeling surprising.
5. Watch attack warnings, active windows, damage blink, death poses and motion in real time. Adjust timing if reading them is difficult.
6. Check camera smoothing and shake on your display and at your preferred window size; turn shake_amount down to zero if desired.
7. Fight the boss without reading its internal state. Judge fairness, recovery openings, challenge and whether the key route is understandable.
   Try both Room 2 branches: jump across the opening to discover the locked gate, then backtrack and descend. Collect the bottom key, climb every ledge, jump into the up exit, and retry with R after returning to confirm the FromWell arrival makes sense.
8. Time a human first playthrough. The desired 5–10 minute duration is a target, not a verified result.
9. Try your tuning edits and rerun relevant suites. A change to intended tuning may legitimately require adjusting a previous numerical expectation.

The automated suite is deliberately small. It does not prove every possible input sequence, display configuration, controller driver or modified scene. Tests and documentation are a starting point for your own experiments.
