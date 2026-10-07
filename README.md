# Prism Rush — Spotlight Edition

A Roblox team arena-shooter prototype with a neon fashion-inspired art direction, expressive color customization, and competitive combat. Designed with women and girls in mind; everyone is welcome. This version is a substantial prototype, not a finished commercial game.

## Open the game (Mac / Windows)

1. Save **PrismRush.rbxl** to your computer. If you downloaded the ZIP, extract it first.
2. In Roblox Studio, stop any active test using the red square.
3. On Mac, reveal the menu bar at the very top of the screen. Choose **File → Open from File…** and select **PrismRush.rbxl**.
4. Press **Play**. The map is generated when play starts; an empty edit viewport is expected.

**Do not paste `.rbxlx` XML into a Script.** It is a complete place file. Both `.rbxl` and `.rbxlx` can be opened with File → Open from File.

For multiplayer testing, use Studio's **Server & Clients** test with two players. No Rojo/plugin installation is needed just to play the place file. Roblox Studio and the Roblox engine are unavailable in this Linux cloud environment.

## What's implemented

- **Spotlight objective:** Rose vs. Aqua teams, 10-second warmup, 150-second rounds, capture/contest states, 90-point score limit, results, and automatic next rounds. Players score by occupying a controlled objective. Empty and contested zones award no team score.
- **Three weapons:** Bloom automatic rifle, Glimmer seven-pellet scatter weapon, and Nova precision rifle. Separate magazines, reload timers, aiming, movement-dependent spread, headshots, camera recoil, and visible procedural weapon models.
- **Abilities:** collision-checked 12-stud dash (3-second cooldown), shield pulse granting up to 25 shield to nearby teammates (12-second cooldown), and passive shield regeneration after five seconds without damage.
- **Combat:** server-owned ammunition, shot cadence, hit detection, range, shields, damage, friendly-fire prevention, and elimination rewards. Client remote requests use a server-side token bucket.
- **Solo practice:** four moving training drones fire at visible players within 80 studs when only one player is present, and respawn five seconds after destruction. In multiplayer they remain moving targets but stop shooting.
- **Arena:** two elevated routes with stairs, high and low cover, neon markings, a central spotlight, signs, lighting, and protected spawn pads.
- **Presentation:** live score/timer/capture HUD, cooldown display, hit markers, tracers, impacts, damage flash, elimination feed, reload pose, and optional reduced camera recoil.
- **Style:** four switchable accent colors applied to the local weapon and character outline. Session-only StylePoints reward eliminations, objective presence, and wins. They have no shop or persistence yet.

## Controls

| Action | Mouse / keyboard | Controller |
| --- | --- | --- |
| Shoot | Hold left mouse | Hold right trigger |
| Aim | Hold right mouse | Hold left trigger |
| Reload | R | X |
| Next weapon | Q | Y |
| Dash | Left Shift | B |
| Shield pulse | E | Left bumper |
| Accent color | C | D-pad up |
| Reduced visual recoil | V | D-pad down |

Touch devices have labeled buttons and Roblox's normal movement/camera controls. Buttons and the HUD still need real-device testing. Reduced visual recoil changes presentation only, not server spread/damage.

## Development and checks

Use the existing isolated checkout; a worktree is unnecessary. Tools are installed outside the repository in `/workspace/tools/bin`.

```bash
cd /workspace/Roblox-Game
mkdir -p build
/workspace/tools/bin/luau tests/rules.spec.luau
/workspace/tools/bin/luau-compile src/shared/*.luau src/server/*.luau src/client/*.luau > /tmp/prism-bytecode.txt
/workspace/tools/bin/rojo build default.project.json -o build/PrismRush.rbxl
/workspace/tools/bin/rojo build default.project.json -o build/PrismRush.rbxlx
```

Rojo 7.6.1 generates the complete place. Luau 0.693 compiles all scripts. `tests/rules.spec.luau` executes ten assertions covering shield absorption/overflow, initial capture, contested control, empty control, takeover time, and progress limits. These standalone tests exercise the shared rules, **not Roblox engine behavior**.

Source organization:

- `src/shared/Weapons.luau`: weapon tuning and selection order.
- `src/shared/Rules.luau`: shield and objective rules used by server and tests.
- `src/server/Arena.server.luau`: generated map, lighting, drone templates.
- `src/server/Combat.server.luau`: teams, authoritative combat, abilities, drones, scoring, and rounds.
- `src/client/Controller.client.luau`: HUD, inputs, camera weapon, customization, and effects.

For live editing, run `rojo serve default.project.json` and connect a matching Rojo plugin in Studio. This is optional; no live cloud process is needed to build the downloadable place.

## Required Studio playtests

1. Solo: verify arena generation, each weapon's magazine/reload, ADS, head/body damage, drone movement/shots/respawn, shield regeneration, dash walls, pulse cooldown, color cycling, and comfort toggle. Inspect Output for client and server errors.
2. Two clients: verify team assignment, spawn orientation/protection, friendly-fire blocking, enemy damage, elimination feed, and outline replication.
3. Objective: occupy center, verify capture and scoring; leave and verify score stops; bring both teams and verify contested scoring stops; take over established control and verify the delay.
4. Rounds: test timer expiration, 90-point victory, draw, results phase, next-round respawns, and late joins.
5. Reload then die/respawn: the previous character's reload must not alter new ammunition. Switch through all weapons and verify magazines do not refill.
6. Test touch and a physical controller, narrow resolutions, focus loss, rapid inputs, latency, and shot alignment from first person.

Build success is verified in cloud. These Studio checks remain unrun here. Movement anti-cheat, matchmaking, saving/progression, original sound/animation assets, full outfits, and accessibility testing remain future work. Team balancing occurs on join; later departures can leave teams uneven. Score and style points are session-only.
