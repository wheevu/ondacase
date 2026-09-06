# Low-poly cast completion

All five portraits now use the approved Mira style.
The four new characters have distinct face proportions, hair, clothing, and textures.
This completes the remaining static characters, not a broader redesign of every menu or an animation pass.

![Cast contact sheet](../../screenshots/cast-psx.png)

## Acceptance and evidence

| Requirement | Result |
|---|---|
| Remaining four low-poly characters | Arin: 654 triangles; Jo: 644; Sasha: 707; Dan: 733 |
| Low-resolution texture treatment | Separate 128×128 atlases; 144×216 portraits; nearest filtering |
| Character-specific appearance | Arin: spectacles, narrow face, blue-grey jacket; Jo: short crop, rounder face, work apron; Sasha: long auburn hair and scarf; Dan: helmet, stubble, reflective jacket |
| Preserve approved Mira | Portrait SHA-256 `c73dd471866af81407dd66a185369775366eed1d0afa6ff3ef3e6a518acf5a0c`; atlas `4ef1c787e7c510da2be7d1e0b16e337a97d5e8012d2288eb382e0e69f1da5bcc`, unchanged from the checkpoint |
| Editable source | Individual packed `.blend` files, atlases, relative paths, documented rebuild commands |
| Runtime integration | All four interview captures inspected; People uses close face crops for all five |
| Fallback safety | Tests remove each new portrait in turn and verify the old portrait still draws without a stale crop |
| No gameplay changes | No Ink, Prolog, save, evidence, or navigation logic changed in this follow-up |

## Verification

Commands run from the repository root.

```sh
for person in arin jo sasha dan; do
  blender --background --python tools/render-mira.py -- --character "$person"
done
```

Each export reported `<id>_portrait=pass` with the triangle counts above, `atlas=128x128 portrait=144x216`.
Dan was rerendered after adding helmet vents.

| Command | Output |
|---|---|
| `make build` | `ondacase_build=pass`, including Fennel compilation and Lua syntax checking |
| `make runtime-test` | Both suites pass; `lowpoly_cast=5_asset_dimensions_filtering_fallbacks_people_pass`, `console_portrait_and_focus=pass`, `fennel_runtime=pass` |
| `shasum -a 256 assets/suspects/mira-psx.png assets/suspects/mira-source/mira-atlas.png` | Both hashes match the approved checkpoint |
| `love /var/folders/9y/7rq1m85530g4lqfvfhckm0880000gn/T/opencode/ondacase-cast` | `cast_native=pass portraits=5 interviews=4 people=1 contact_sheet=1` |

The disposable native probe uses real LÖVE rendering, asset decoding, and the Ink bridge.
It feeds asset bytes around LÖVE's external-directory sandbox restriction.
All capture processes exited normally.
The contact sheet is an art comparison, not an added game screen.

## Scoped file manifest

The repository was already entirely untracked, so there is no tracked baseline diff or commit range.
Nothing was staged or committed.

- `tools/render-mira.py`: optional character selection, individualized atlas painting, geometry, and accessories.
- `src/main.fnl` and regenerated `src/main.lua`: cached face crops for small portrait widgets only.
- `tools/test-runtime.lua`: all-five loading, dimensions, nearest filtering, fallback, and People-crop coverage.
- `assets/suspects/{arin,jo,sasha,dan}-psx.png`: four new portrait renders.
- `assets/suspects/{arin,jo,sasha,dan}-source/`: packed blend files, atlases, and rebuild instructions.
- `assets/README.md`, `DESIGN.md`, and `assets/suspects/mira-source/README.md`: current provenance and completion status.
- `screenshots/{arin,jo,sasha,dan,people,cast}-psx.png`: native captures and contact sheet.
- This verification packet.

## Remaining risks

- Medium risk, limited to offline asset generation and shared small-portrait rendering.
  No public contract, persistence, auth, or deduction changes.
- Portraits are static; animation was not added.
- The previous full `make check` remains blocked by the unrelated hard-coded `/tmp/ondacase-ink.lua` fixture path.
  This follow-up reran build and both runtime suites, not the unchanged full case-logic suite.
- Blender 5.2 exports successfully but warns that `Material.use_nodes` is deprecated for Blender 6.0.
- Existing café/location asset provenance remains unresolved.
  These original cast assets do not clear the unrelated images for distribution.
- Self-verified in this session; no independent review was invoked.
