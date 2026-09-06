# District diorama

Original AI-assisted, code-authored low-poly scene and 128×128 texture atlas, covered by the repository's ISC license.
No third-party models or photographs are used.
The map is a schematic arrangement of the four authored locations, not evidence of travel distances or times.

```sh
blender --background --python-exit-code 1 --python tools/render-map.py
```

Run from the repository root with Blender 5.2.
The script writes an editable, packed `district.blend`, `district-atlas.png`, and a 320×224 `district.png`.
It prints projected location anchors for the runtime's map overlays.
LÖVE displays the render with nearest filtering; Blender is an offline dependency only.
