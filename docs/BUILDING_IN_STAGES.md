# Building Cinder Thread in stages

This guide is a construction order for the project. It assumes you already know how to create scenes and nodes, attach a GDScript, edit exported values in the Inspector, and run a scene. It does not repeat the full explanation of every finished subsystem; use the [Learning Guide](LEARNING_GUIDE.md) for that.

The goal is to avoid building five rooms, several enemies, a boss, and presentation code before discovering that the basic jump is wrong. Each stage adds one playable capability, tests it at the smallest useful boundary, and leaves the project in a working state.

The repository contains the finished result rather than a separate snapshot for every stage. When rebuilding it yourself, use the file lists below as the boundary for each milestone. Make a Git commit after each stage so you can experiment freely and compare designs.

## The repeated workflow

Use the same loop throughout the build:

1. Define one observable behavior, such as "the player accelerates to a maximum speed."
2. Build the smallest scene that can demonstrate it.
3. Test it manually in isolation before placing it in the full game.
4. Add or run focused automated checks for the rules that should not silently change.
5. Play the whole game briefly to catch integration problems.
6. Commit the working checkpoint before starting the next system.

Run a focused suite with:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run_tests.ps1 -Suite movement
```

Replace `movement` with `input`, `combat`, `states`, `enemies`, `progression`, `boss`, or `playthrough`. Run `-Suite all` at major milestones and before sharing the project. The final tests sometimes exercise several systems together, so a suite may not become usable until all files named in that stage exist.

## Roadmap

| Stage | Playable result | Main verification |
|---|---|---|
| 1. Project contract | Empty project imports with named inputs and collision layers | Import and input configuration |
| 2. Movement lab | One character can run and jump on gray boxes | Input and movement suites |
| 3. Player state structure | Ground and air transitions have explicit ownership | Movement and initial state checks |
| 4. Combat components | The player can strike a target and receive damage | Combat and state suites |
| 5. First enemy | A guard patrols, warns, attacks, gets hurt, and dies | Enemy and combat suites |
| 6. Game shell and rooms | The game can replace one room with another safely | Progression suite |
| 7. Persistent progression | A key and gate work across room replacement and retries | Progression suite |
| 8. Second enemy | A flying enemy reuses combat but not ground movement | Enemy suite |
| 9. Boss encounter | Three readable attacks lead to victory | Boss and state suites |
| 10. Presentation | HUD, feedback, camera, and visuals respond to gameplay state | Smoke run and manual review |
| 11. Complete route | The whole game works through ordinary input | Playthrough and full suite |

## Stage 1: establish the project contract

Start with `project.godot`, a minimal main scene, and the input/collision settings that every later system will rely on.

Define all named actions early: `move_left`, `move_right`, `jump`, `attack`, `interact`, `pause`, and `restart`. Gameplay should ask for an intention such as `jump`, never for a particular keyboard key. Add keyboard and controller events to the same action rather than building separate control paths.

Name the collision layers before authoring scenes:

- World geometry
- Player body
- Enemy body
- Player hurtbox
- Enemy hurtbox

Also choose the renderer, logical viewport, and physics tick rate. These are project-level contracts. Changing them late can affect every scene or invalidate movement measurements.

Verify that the project imports cleanly and that action names are spelled exactly once. At this point a temporary script that prints action presses is enough; the final `test_input.gd` becomes useful after the movement lab and Player exist.

### Why this approach?

Named actions keep gameplay independent of devices and make synthetic input tests possible. Reading `KEY_SPACE` directly is simpler for a prototype, but every alternative binding then becomes a code change. An input-manager singleton could add rebinding and prompt detection later, but it would be unnecessary structure for this game's fixed bindings.

## Stage 2: build movement in an isolated lab

Build these pieces before making a real room:

- `resources/movement_tuning.gd` and `player_movement.tres`
- `player/player.tscn` and the initial movement behavior
- `rooms/platform.tscn`
- `tests/movement_lab.tscn`
- focused input and movement tests

The lab needs only a floor, a few reference platforms, and the Player. It should launch directly with F6. Tune horizontal acceleration, stopping, turning, jump launch, gravity, fall speed, and variable jump height here. Then add coyote time and jump buffering as explicit countdowns.

Do not start with enemies or a camera. If running and jumping do not feel understandable in a quiet test scene, more game systems only make diagnosis harder.

### When to use `delta`

Use `delta` when applying a rate over elapsed time:

```gdscript
velocity.y += gravity * delta
velocity.x = move_toward(velocity.x, target_speed, acceleration * delta)
remaining -= delta
```

Those values mean pixels per second squared or seconds remaining, so the amount applied depends on the duration of the tick.

Do not multiply these by `delta`:

- A target velocity such as `axis * max_speed` is already in pixels per second.
- An instantaneous jump sets `velocity.y = jump_velocity`; it is an impulse, not continuous acceleration.
- `Input.get_axis()` is a dimensionless input value.
- `move_and_slide()` expects velocity in pixels per second and handles movement for the physics tick. Passing `velocity * delta` would apply time twice.
- A one-time state change, signal emission, or `is_action_just_pressed()` decision is an event, not a rate.

Use the `delta` supplied to `_physics_process()` for gameplay physics and timers that should advance with physics. `_process()` is appropriate for presentation that should redraw every rendered frame, but game rules should not depend on the render frame rate.

### Test this stage

Measure behavior rather than only checking that the character moves:

- acceleration reaches but does not exceed maximum speed;
- releasing input stops the player;
- reversing uses the intended turn rate;
- held and tapped jumps reach different heights;
- coyote and buffer inputs work just inside their windows and fail just outside;
- falling reaches a terminal speed;
- partial stick input produces partial speed.

Run `-Suite input` and `-Suite movement` once the final Player scene exists. Repeat important motions manually, because a numerical test cannot tell you whether movement feels good.

### Why a Resource?

`MovementTuning` groups related configuration and lets the lab and real game use the same values. Keeping constants in `player.gd` would be acceptable for a very small prototype. Exporting every value directly on Player is another reasonable option. A Resource becomes useful when the settings form a coherent reusable object or when you want alternate movement profiles without duplicating behavior.

## Stage 3: give player behavior explicit states

A first movement prototype can live entirely in `player.gd`. That is often the fastest way to prove the mechanics. Refactor after the rules work, when adding hurt, death, and attack behavior would otherwise produce a growing set of overlapping booleans.

First extract only Grounded and Airborne. Add Hurt, Dead, and the separate Attack machine in Stage 4, when combat creates a real need for them. The finished project ultimately contains:

- `components/actor_state.gd`
- `components/state_machine.gd`
- `player/states/`
- the `Motion` and `Attack` child machines in `player/player.tscn`

Move permission decisions into states while leaving reusable physics formulas on Player. `Grounded` decides when a ground jump is legal; `Airborne` decides when gravity and coyote logic run; Player still owns `steer()`, `apply_gravity()`, and `launch_jump()`.

Keep one `move_and_slide()` call on Player. States decide what velocity should become, but the body remains responsible for performing movement and reporting the result. The `after_move()` hook exists because landing cannot be known reliably until after that move.

The final Player uses two state machines because motion and attacking are independent. A player can be airborne while an attack is in Startup, Active, or Recovery. One combined machine would require states such as `AirborneAttacking`, `GroundedAttacking`, and more combinations as features grow.

### Test this stage

Rerun `-Suite movement` and add small state lifecycle checks for enter/update/exit order, inactive states not ticking, and ground/air transitions. Run the complete `-Suite states` after Stage 4 supplies damage, death, interruption, and both machines. The movement measurements should not change during this refactor.

### Alternatives

- **One Player script with conditionals:** easiest to read while behavior is small. It becomes harder to see who owns timers and cleanup as combinations grow.
- **One enum and `match`:** a perfectly valid finite state machine and a good middle ground. Guard and Moth use this approach.
- **One node per state:** more files and indirection, but each complex phase gets clear `enter`, update, and `exit` ownership.
- **One combined state machine:** simpler infrastructure, but poor at representing independent behaviors such as moving while attacking.

The project does not use state nodes because they are universally better. It uses them where behavior has enough phases and interruption rules to benefit from explicit ownership.

## Stage 4: add reusable combat and one player attack

Build combat without an enemy AI first. A stationary target in the movement lab is enough.

Add:

- `HealthComponent` for health, invulnerability, and death signals;
- `HurtboxComponent` for the region that receives a hit;
- `HitboxComponent` for a time-limited damaging region;
- `AttackData` and `player_attack.tres` for timing and damage;
- Player Motion states for Hurt and Dead;
- Player Attack states for Ready, Startup, Active, Recovery, and Disabled.

Keep body collision, hurtboxes, and hitboxes separate. The body answers "where can this actor move?" The hurtbox answers "where can it be struck?" The hitbox answers "where is this attack dangerous right now?" They often have different shapes and collision masks.

Enable damage only during Active. Ensure `Active.exit()` always disables the hitbox, including when damage or death interrupts the attack. That cleanup rule is more important than the normal timer path.

The Hitbox polls overlaps while active rather than relying only on `area_entered`. A target might already overlap when the active window begins, so no new enter signal would occur. Remember accepted targets so one swing cannot damage the same target every physics tick.

### Test this stage

Run `-Suite combat` and `-Suite states`. Test invalid damage, health clamping, death only once, invulnerability, real Area2D overlap, exactly one hit per swing, attack timing, knockback, and interruption during every attack phase.

### Alternatives

- Damage logic could live directly on Player and each enemy. That is initially shorter, but validation and invulnerability behavior would be duplicated.
- An animation track could turn damage on and off. That is useful in animation-heavy games, but it makes the animation asset authoritative for gameplay timing. This project keeps timing in code/Resources so tests can reason about it directly.
- A hitbox could listen only to `area_entered`. That is event-driven but misses the already-overlapping case unless additional bookkeeping is added.
- Attack values could be constants on Player. `AttackData` is chosen because several actors share the same concept while using different instances.

## Stage 5: build one complete enemy

Add the Guard before building multiple rooms. It is the first proof that the combat components are actually reusable.

Give it a small local enum FSM: Patrol, Chase, Windup, Active, Recovery, Hurt, and Dead. Add an edge probe so patrol and chase movement respect platform boundaries. Make the warning and recovery generous enough that the fight can be read without knowing the code.

Start with simple detection based on distance. Do not add navigation, a behavior tree, or an inheritance hierarchy until the game demonstrates a need for them.

### Test this stage

Run `-Suite enemies` and `-Suite combat`. Verify chase range, warning before damage, active/recovery timing, attacking in both directions, interruption, death, and stopping at edges. Then fight the guard manually using normal input.

### Why a local enum instead of state nodes?

The Guard's behavior is short and contained in one script. Splitting every phase into a file would increase navigation cost without clarifying much. The player benefits from separate state nodes because it has two interacting machines and several interruption paths. Reuse the idea of a state machine, not necessarily the exact representation.

## Stage 6: create the persistent game shell and room loading

Once one room is fun, separate the persistent game from the replaceable room:

- `game.tscn` owns `RoomRoot`, Camera, and HUD;
- each room scene owns geometry, spawn markers, Player, enemies, and exits;
- `room_exit.gd` announces a destination and spawn name;
- `game.gd` is the only code that removes and instantiates rooms.

Build two plain rooms first. Travel forward and backward before adding keys or a boss. Place arrival markers away from exit triggers so the player does not immediately bounce back.

Defer the room swap when it is requested by an Area2D overlap. Removing physics bodies while Godot is processing the overlap can produce unsafe tree changes. The exit emits intent; Game performs the lifecycle operation after the callback.

### Test this stage

Start the progression suite with checks for initial spawn, forward travel, return travel, safe arrivals, and no immediate bounce. Also test retry/death loading the intended entrance.

### Alternatives

- **One enormous world scene:** simplest if the whole game should remain loaded and spatially continuous. Separate rooms make reset and memory ownership obvious here.
- **Exit directly changes scenes:** fewer lines, but every exit then needs loading knowledge and persistent UI/camera ownership becomes awkward.
- **Coordinates instead of named spawn markers:** workable, but markers are visible and editable in the scene and survive layout changes better.
- **A dictionary/graph of rooms:** more scalable than the current indexed array. The array is sufficient for five explicit rooms, while each exit already defines the actual connections.

## Stage 7: add progression that survives room replacement

Now add the key, sealed gate, and `GameState` autoload. Keep only facts that must outlive a room in global state: key ownership, gate state, victory, and current room. Player velocity, current health, enemy timers, and hit targets should remain on the recreated actors.

Build the locked-gate failure first, including feedback. Then add key collection, key persistence after leaving the room, gate unlocking, and reset after victory. Finally add the Room 2 branch and vertical Room 5 route.

### Test this stage

Run `-Suite progression`. Check both directions through every connection, safe spawn markers, retry positions, the locked response, persistence after revisiting a room, and the unlocked boss-room transition.

### Alternatives

- Game could own these flags directly. That is reasonable while Game is guaranteed to persist; the autoload makes the lifetime explicit and keeps the state available to independently instantiated scenes and tests.
- A save file would preserve progress across application launches. This project needs only run-lifetime state, so disk persistence would add schema and migration concerns without serving the design.
- A general inventory system could represent the key. One Boolean is clearer when there is exactly one progression item and no inventory UI.

## Stage 8: add a contrasting enemy

The Moth should reuse Health/Hurtbox/Hitbox but not inherit Guard movement. Give it a hover, a clear windup, one committed dive direction, and a return phase.

This stage tests whether composition is doing useful work. Shared combat behavior remains shared, while movement and decision-making stay specific to the enemy. If adding the Moth requires conditionals inside Guard, the boundary is wrong.

Run `-Suite enemies`. Verify windup, committed rather than perfect homing, hitbox cleanup, recovery to its perch, hurt behavior, and death.

### Alternatives

An `EnemyBase` class could centralize targeting, health hookup, and death behavior. That becomes useful when several enemies truly share those policies. With only two very different enemies, a base class risks coupling unrelated movement rules. Navigation would be appropriate for obstacle-aware pursuit; this game's small platform encounters use authored positions and simple ranges instead.

## Stage 9: build the boss one attack at a time

Create the boss body, health, activation boundary, HUD binding, and death/victory path before implementing three attacks.

Then add attacks incrementally:

1. Sweep: Windup -> Sweep -> Recovery.
2. Slam: Windup -> Leap -> Fall -> Impact -> Recovery.
3. Charge: Windup -> Charge -> Recovery.

Run the boss suite after each attack rather than implementing all three before the first test. Every damaging state must disable its hitbox in `exit()`, because death can interrupt any phase.

The boss uses a node-based state machine because each attack has distinct entry work, physics, transitions, and cleanup. The Attack enum selects configuration; the state nodes execute behavior. `AttackData` stores timing/damage, while runtime timers stay on the active state.

### Test this stage

Run `-Suite boss` and `-Suite states`. Test inactive-before-activation, each warning and active phase, physical leap/landing/charge movement, damage in both directions, interruption cleanup, HUD updates, terminal death, and victory.

### Alternatives

- A single enum and `match` could implement this boss and would not be wrong. State nodes make the multi-step Slam and interruption cleanup easier to inspect independently.
- AnimationPlayer tracks could sequence attacks. That is attractive once authored animations drive exact timing, but this procedural version keeps gameplay authoritative in code.
- A behavior tree or utility AI would support dynamic choice and priorities. The predictable cycle is intentionally learnable and does not need that machinery.
- A separate scene per attack could isolate content further, but these attacks share one body and one hitbox whose shape is reconfigured.

## Stage 10: layer presentation onto working rules

Add the HUD, FollowCamera, Feedback autoload, impact bursts, and actor visuals only after their inputs are stable. Presentation reads gameplay state and responds to signals; it does not decide whether an attack lands or whether an actor is dead.

The project uses procedural `_draw()` visuals so the repository needs no art pipeline. Replace the Visual child with AnimatedSprite2D or AnimationPlayer later without changing body collision, health, or combat rules.

Use signals for announcements such as health changes, impact creation, and victory. Use direct calls for commands that need an immediate result, such as Hitbox asking Hurtbox whether damage was accepted. Signals are not automatically better than method calls; choose based on whether the sender needs to know the receiver and its return value.

Run the smoke suite and inspect the game manually. Check UI at the intended viewport, camera bounds, warnings, damage flashes, pause behavior, hit-stop restoration, and whether attacks are readable in motion. Screenshots catch layout regressions but cannot judge animation timing or game feel.

## Stage 11: verify the complete route

The final stage is integration, not another feature. Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run_tests.ps1 -Suite all
```

Then play the intended route yourself: visit the locked gate, backtrack, descend to the key, climb out, unlock the door, observe all three boss attacks, win, and start a new run.

`test_playthrough.gd` provides a different kind of evidence from focused tests. It uses named actions against real scenes and physics, so it catches gaps, spawn positions, or wiring mistakes that isolated tests can miss. Focused tests should remain because a complete playthrough is slower and makes failures harder to diagnose.

### Testing alternatives

The project uses plain GDScript `SceneTree` scripts so there is no plugin dependency and every test can instantiate real scenes. A framework such as GUT can provide richer assertions, fixtures, filtering, and reports. Manual-only testing is fast at the beginning but becomes unreliable once a movement tweak can break a later room. The useful split is:

- focused automated tests for exact rules;
- a small number of integration/playthrough tests for wiring;
- manual play for feel, readability, controller hardware, and difficulty.

## What to study after each checkpoint

After finishing a stage, read the matching part of the [Learning Guide](LEARNING_GUIDE.md) rather than reading all of it up front:

| Construction stage | Learning Guide sections |
|---|---|
| Movement | 4-6 |
| States and composition | 3, 7-9 |
| Combat | 10-11 |
| Enemies | 12 |
| Boss | 13 |
| Progression and rooms | 14-15 |
| Presentation | 16 |
| Tuning and extensions | 17-19 |

Use [ARCHITECTURE.md](ARCHITECTURE.md) as the compact final-system map and [TESTING.md](TESTING.md) when you need exact commands, coverage, or known manual limits. The development log records the order in which this particular repository evolved, but this guide is the cleaner order for rebuilding and learning from it.
