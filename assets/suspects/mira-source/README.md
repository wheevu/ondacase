# Mira portrait source

Original, code-authored low-poly model and painted texture for ondacase, created with AI assistance.
No third-party models, photographs, textures, or animations are used.
Covered by the repository's ISC license.

Rebuild from the repository root with Blender 5.2:

```sh
blender --background --python tools/render-mira.py
```

The script writes `mira.blend`, a 128×128 `mira-atlas.png`, and the 144×216 runtime portrait `../mira-psx.png`.
The blend file includes the packed atlas, named mesh parts, lights, and camera.
Meshes use flat shading and nearest texture sampling.
Rendering is offline; Blender is not a game dependency.

This is the approved static Mira portrait.
The remaining cast now uses the same renderer with `-- --character <id>`.
Mira's approved portrait and atlas were preserved byte-for-byte during that extension.
Animation is not part of the static portrait overhaul.
