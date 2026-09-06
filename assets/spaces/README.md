# Inspectable 3D spaces

Original, AI-assisted, code-authored café, service alley, night store, and apartment environments under the repository's ISC license.
No external models or photographs are used.

```sh
blender --background --python-exit-code 1 --python tools/build-spaces.py
```

The Blender 5.2 builder exports four editable `.blend` scenes, a shared 128×128 texture atlas, and `rooms.json` with triangle meshes, fixed cameras, and authored object positions.
LÖVE renders the geometry in real time into a 320×176 depth-buffered canvas.
The UI and inspection markers remain native-resolution.
These layouts illustrate the locations; they do not add travel-time or deduction rules.

| Location | Triangles | Inspection objects | Camera views |
|---|---:|---:|---:|
| Café Lantern | 1,668 | 6 | 2 |
| Service alley | 1,268 | 2 | 2 |
| Night store | 2,656 | 1 | 2 |
| Eli's apartment | 1,680 | 2 | 2 |

Use `V` or **Change view** to switch camera angles.
Select a numbered scene marker or its matching inspection-list entry to use the existing evidence route.
The two interview-only evidence records are not exposed as room hotspots.
If assets or graphics support fail, the inspection list remains available.

`room.glsl` and `src/spaces.fnl` share a perspective projection with near/far planes at 0.1 and 50.
The shader accounts for LÖVE's top-down offscreen canvas convention.
Lighting is baked into vertex colors; geometry and camera projection are evaluated at runtime.
Textures and the scene canvas use nearest filtering, while UI text stays independently readable.
Meshes, atlas, shader, and canvas are cached and released on reload or failed initialization.

The blend files retain named meshes, packed atlas data, and both perspective cameras.
Runtime meshes and metadata in `rooms.json` are generated; edit the builder rather than the export.
See the [native gallery](../../screenshots/spaces/README.md) and [verification packet](../../screenshots/spaces/verification.md).

Capture the café through the normal game entry point:

```sh
ONDACASE_CAPTURE=location ONDACASE_CAPTURE_PATH="$PWD/screenshots/spaces/cafe-native-entry.png" love .
```
