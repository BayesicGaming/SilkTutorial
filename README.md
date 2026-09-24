# Cinder Thread

A small, original Godot learning game: five connected rooms with a branching route, a responsive run/jump controller, one melee attack, two enemy types, an ember key, a sealed gate, and a boss with three attacks. All visuals are drawn in Godot. There are no downloaded assets, plugins, or package dependencies.

## Play

Import **project.godot** in Godot **4.7.2**, open the project, and press **F5**. This version passes the full suite with the current input settings. The main scene is **game.tscn**. For isolated movement experiments, open **tests/movement_lab.tscn** and press **F6**.

| Action | Keyboard / mouse | Standard controller |
|---|---|---|
| Move | A / D or Left / Right | Left stick or D-pad |
| Jump | Space (hold for height) | South: A / Cross |
| Strike | Left mouse button | West: X / Square |
| Use gate | E | North: Y / Triangle |
| Pause / resume | Escape | Menu / Options |
| Retry room | R | View / Share |
| New run after victory | R | View / Share |

The player faces movement, not the cursor. Platforms are solid; there is no drop-through action. The HUD uses Xbox button letters alongside keyboard controls. Keyboard and controller coexist without a mode switch.

Head right from Room 1 into Room 2, the crossroads. Its right exit leads to Room 3's moth and sealed gate; the floor opening leads down to Room 5, the Lantern Well. Collect the key at the bottom, climb the six alternating ledges, and jump into the up arrow to return to Room 2. Continue right and interact with the gate in Room 3 to reach Room 4's boss. You can jump across the opening and backtrack if you missed the key. Health restores on room entry or retry; enemies reset, while the key and gate stay unlocked for this run. The arena has no exit. Watch the boss's warning and exploit recovery. Nothing is saved after closing the game.

## Learn

To recreate the game from a small movement prototype through combat, rooms, progression, the boss, and final verification, start with [Building Cinder Thread in stages](docs/BUILDING_IN_STAGES.md). Every stage identifies a playable checkpoint, focused tests, the reason for the chosen design, and credible alternatives.

Use [the learning guide](docs/LEARNING_GUIDE.md) beside it as the detailed tour of the finished code. It covers the actual scene trees, tuning, signals, damage flow, and 18 exercises, including an outline for adding double jump yourself.

The first five things to inspect are:

1. **project.godot** — main scene, autoloads, layers and input bindings.
2. **player/player.tscn** — the player's node composition.
3. **components/state_machine.gd** — the shared enter/update/exit lifecycle.
4. **player/player.gd** — how the body ticks Motion and Attack and supplies physics helpers.
5. **player/states/airborne.gd** — a short concrete state and the extension point for an extra air jump.

Player uses independent movement and attack machines so airborne attacks remain possible. Boss behavior is split into individual states under **boss/states/**. The small guard/moth enum FSMs remain local. See Learning Guide Sections 4 and 13 for the design and extension points.

[Architecture](docs/ARCHITECTURE.md), [testing details](docs/TESTING.md), and [development log](docs/DEVELOPMENT_LOG.md) provide the shorter references.

## Verification and limits

158 automated checks pass on Godot 4.7.2, covering input, movement, components, combat, enemies, branching room transitions, boss attacks and an input-only complete playthrough. Rendered screenshots were inspected. No known parser/runtime errors block normal progression on that version. Godot 4.6 passes the new route tests but fails six device-input checks with the current project settings; see TESTING.md.

Controller mappings and code were verified, but physical controller behavior requires manual testing. Movement behavior was mechanically verified, but subjective feel requires manual testing. The 5–10 minute first-playthrough target has not been measured with a human; the scripted route, including a locked-gate visit and backtrack, finishes in about 63 simulated seconds. Judge difficulty and pacing yourself before treating that target as achieved.

Run the tests in PowerShell from this directory:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run_tests.ps1
```

The runner looks for Godot on PATH and then under your Downloads folder. Pass `-Godot 'C:\path\to\Godot_console.exe'` when it is installed elsewhere. ExecutionPolicy Bypass applies only to this PowerShell process; the script does not change system policy. Logs go to **logs/**. See TESTING.md for individual suites and direct Godot commands.
