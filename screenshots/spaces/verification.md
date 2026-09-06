# Real-time spaces and bottom spacing

Implemented and self-verified on macOS with LÖVE 11.5 and Blender 5.2.
Independent review is due before shipping, focusing on GPU resource/state handling and inspection-to-evidence routing.
No reviewer was invoked in this session.

## Acceptance

| Request | Result and evidence |
|---|---|
| Better spacing at the bottom | Bottom actions end at or above y=648 with the footer at y=680; stacked theory, accusation, and dialogue actions have more separation; People panel and title artwork leave room around their lower controls |
| Four actual 3D spaces | Café, service alley, night store, and apartment use runtime triangle meshes, perspective projection, and GPU depth testing |
| Fixed-camera inspection | Two views per location; `V` and Change view switch cameras; GPU canvas contents differ between views |
| Keep the approved aesthetic | Low-poly geometry, shared 128×128 nearest-filtered atlas, flat baked vertex lighting, distinct room tints, and 320×176 scene canvas |
| Scene interaction | Eleven authored evidence hotspots projected from 3D positions; numbered markers and matching keyboard-accessible inspection entries |
| Preserve case rules | Markers call existing evidence routes; no new deduction, Ink, Prolog, or save-format logic; interview-only evidence remains outside the rooms |
| Failure behavior | Unsupported shader initialization releases allocated resources; inspection list still discovers evidence; successful reload restores rendering; malformed metadata is rejected |
| Editable original assets | Four packed `.blend` files, a reproducible Blender builder, generated mesh/UV/camera metadata, and original atlas |

## Geometry

| Space | Triangles | Hotspots | Views |
|---|---:|---:|---:|
| Café | 1,668 | 6 | 2 |
| Alley | 1,268 | 2 | 2 |
| Store | 2,656 | 1 | 2 |
| Apartment | 1,680 | 2 | 2 |

Only the active room is drawn.
The four meshes, atlas, shader, and low-resolution canvas are cached at load time.
Lighting is baked into vertex colors; these are real-time geometry views, not pre-rendered images or dynamic-lighting scenes.

## Scoped file manifest

All project files were already untracked on entry, so there is no useful tracked baseline diff or commit range.
Nothing was staged or committed.

- `src/spaces.fnl` and generated `src/spaces.lua`: renderer, camera math, projection, metadata validation, caching, and fallback.
- `src/main.fnl` and generated `src/main.lua`: location inspection UI, projected markers, camera controls, bottom spacing, and a normal-entry location capture fixture.
- `src/layout.fnl` and generated `src/layout.lua`: explicit footer and action-safe-area constants.
- `tools/build-spaces.py`: original environments, atlas, and mesh/camera export.
- `assets/spaces/`: four editable blend scenes, `atlas.png`, generated `rooms.json`, `room.glsl`, and provenance/build instructions.
- `Makefile`: compile the new module, run its contract suite, and stop on the first Fennel compilation error instead of reporting a false pass.
- `tools/test-runtime.lua`: new inspection fallback/view controls, updated pagination coordinates, and bottom-safe-area assertions across 18 screens.
- `tools/test-spaces.lua`: actual exported geometry, camera projection, clip planes, hotspot catalog, and invalid-asset fallback checks.
- `DESIGN.md`, `assets/README.md`, and `screenshots/spaces/`: current design rules, provenance, captures, and this packet.

## Commands and outputs

Commands run from the repository root.

| Command | Result |
|---|---|
| `blender --background --python-exit-code 1 --python tools/build-spaces.py` | `spaces_build=pass atlas=128x128 rooms=4`; triangle counts above |
| `make build` | `ondacase_build=pass`; Fennel compilation and Lua syntax validation |
| `make runtime-test` | All three suites pass; `bottom_action_safe_area=18_screens_pass`; `spaces_contract=pass rooms=4 views=8 projected_hotspots=22 triangles=7272` |
| `make check` | Doctor, build, all 51 Prolog tests, JSON bridge, validator, Ink runtime, and 31 Ink routes pass; then the pre-existing Fennel/Ink test fails on missing `/tmp/ondacase-ink.lua` |
| `npm audit --omit=dev --audit-level=high` | `found 0 vulnerabilities` |
| `jq empty assets/spaces/rooms.json` | Exit 0 |
| `jq empty story/main.json` | Exit 0 |
| `jq empty cases/001-americano/case.json` | Exit 0 |

The old Fennel/Ink test passes when its stale temporary path is redirected in memory to the current generated module:

```sh
lua -e 'package.path=package.path..";./vendor/share/lua/5.5/?.lua"; local original=dofile; dofile=function(path) return original(path=="/tmp/ondacase-ink.lua" and "src/ink.lua" or path) end; dofile("tools/test-fennel-ink.lua")'
# fennel_ink_bridge=pass
```

This does not make the stock `make check` command green.
The unrelated fixture test and bridge were not edited.

## Native graphics and input verification

```sh
love /var/folders/9y/7rq1m85530g4lqfvfhckm0880000gn/T/opencode/ondacase-inspection
# inspection_native=pass captures=17 marker_clicks=34 depth_views=8 fallback_and_recovery=pass

love /var/folders/9y/7rq1m85530g4lqfvfhckm0880000gn/T/opencode/ondacase-spaces
# spaces_native=pass rooms=4 views=8

ONDACASE_CAPTURE=location ONDACASE_CAPTURE_PATH="$PWD/screenshots/spaces/cafe-native-entry.png" love .
ONDACASE_CAPTURE=title ONDACASE_CAPTURE_PATH="$PWD/screenshots/spaces/title-spacing.png" love .
```

The disposable probes use real LÖVE GPU meshes, shaders, depth buffers, textures, and the existing evidence bridge.
They feed asset bytes around the test harness's external-directory sandbox restriction.
The normal-entry café capture separately verifies the game's ordinary asset/shader loading path.
The probes compare actual GPU image data between camera views, click every marker in both views, and repeat café input checks at 600×600 and 1080×720.
Each click must discover exactly its intended evidence record.
A forced shader initialization error verifies cleanup, list-only inspection, and recovery on reload.
Native captures of all eight room views, the dense lower action areas, scaled windows, and fallback were inspected.
All started capture processes exited normally.

## Remaining risks and review focus

- Medium risk: new GPU renderer and shared inspection/input paths.
  Review resource lifecycle, graphics-state restoration, projection agreement, and evidence routing as one completed deliverable.
- Tested graphics platform is macOS/LÖVE 11.5 only.
  Windows/Linux drivers and older graphics hardware are not independently verified; the list-only fallback is intentional.
- This is fixed-camera inspection, not walking or arbitrary object picking.
  Only the authored numbered evidence objects are interactive.
- Room layouts are illustrative and do not establish travel times, adjacency, or additional case facts.
- The 32-pixel action safe area is measured in the logical 720×720 viewport and scales with the window.
- The stock full-check fixture failure remains unresolved outside this task.
- Blender 5.2 emits a `Material.use_nodes` deprecation warning for Blender 6.0; the documented build succeeds.
- Existing unrelated raster-asset provenance warnings remain in force.
- No independent review, commit, push, merge, or deployment was performed.
