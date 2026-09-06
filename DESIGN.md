# DESIGN.md - ondacase Case 001

The approved direction for Case 001, its renderer, and its original assets.

## Posture

Rough PS1 crossover, quiet, late-night investigation.
Chunky geometry, low-resolution painted faces, inset console menus, charcoal and sodium light.
No neon, corkboard, glow, or full-screen pixel filter that damages reading.

Mira's interview established the approved art direction.
All five character portraits now use that treatment, with distinct face proportions, hairstyles, and clothing.
The menus, diagrams, and area map now follow the same console treatment.

Dense where the evidence needs comparison, calm where dialogue needs reading.
Use square inset panels, hard rules, and a visible selection cursor.

The reference canvas is 720 by 720.
Keep it square and letterbox it cleanly when the window is not square.

## Voice

A specific investigator, not a clerk.
Tired, precise, dry.
Say what she saw and distinguish it from what she can prove.

She notes what she cannot establish and lets a gap stay a gap.

* Speaks to one reader.
* Names the actor, names the place, names the time.
* One true detail beats three vague ones.
* Proof travels with the claim, on the same spread.

## Palette tokens

```
paper:   #131616  charcoal background
panel:   #1F2425  blue-grey inset panels
line:    #5C6666  structural rules
ink:     #E3DEC9  warm reading text
muted:   #9CA6A3  secondary labels
gold:    #BAA16E  sodium selection and filed records
rust:    #C27A59  incompatible records
green:   #82B091  confirmed support
```

These are rounded hex equivalents of the renderer's float palette.
Avoid pure black on white, neon, and decorative glow.

Keyboard focus uses a solid sodium strip and a chevron on full-height controls.
Hover uses a lighter panel and sodium outline without impersonating keyboard focus.
The current navigation section has an underline.

## Typography

Use Share Tech Mono for controls and data, VT323 for display headings, and Newsreader for dialogue and prose.
IBM Plex Mono is the bundled label fallback.
All fonts and their OFL licenses are recorded in `assets/README.md`.
Artwork is nearest-filtered independently of text.
Font atlases use linear filtering so letters survive fractional window scaling.

Keep display type subordinate to the screen's task.
Use 12 to 13 pixel control text where space permits and 16 pixel prose for close reading.

## Character rendering

Use actual low-poly models rendered offline, not a pixel filter on photographic cutouts.
Mira has 648 triangles, a 128×128 painted atlas, and a static 144×216 portrait drawn at 2× in the reference interview layout.
Keep named meshes, the packed texture, camera, and lights in an editable Blender source.
No Blender installation is needed to display the pre-rendered portraits.
All five models now have individual packed Blender sources and 128×128 atlases.
Small People thumbnails use a 112×112 head crop from the portrait; the interview uses the entire bust.
The old portraits remain optional fallbacks, not the primary art.

The interview pairs a large bust with a separate statement panel and six choice rows.
Choice pagination sits below the choices rather than overlapping them.
Selection uses a solid sodium strip and a chevron, with visible hover feedback.
The footer describes real keyboard controls, not decorative gamepad prompts.

## Layout rules

* Keep the navigation bar above the working area and the footer rule at y=680.
* Bottom actions end at or above y=648, leaving a 32-pixel footer safe area.
* Give stacked bottom action rows at least 16 pixels of separation where the layout permits.
* Large panels use an inset rule and a short sodium corner mark.
* Dense evidence checklists must not have overlapping hitboxes.
* Portrait records use face crops and enough room for the latest player-known note.
* Paginate long lists and proofs instead of hiding entries below a panel.

## Map

The area map is a 320×224 render of an original low-poly district, drawn at 2× in the 720×720 layout.
It uses a 128×128 texture atlas and retains a packed editable Blender source.
`tools/render-map.py` prints the projected anchor pixels used by `district-anchors` in Fennel.
Changing the camera requires updating those anchors and checking every hotspot.
The map is explicitly schematic, not evidence of distances, adjacency, or travel times.
All four location controls remain usable if the image is missing.
`M` and the MAP tab open the map.

## Fixed-camera locations

The café, service alley, night store, and apartment are actual real-time 3D spaces.
They use textured triangle meshes, depth testing, and a 320×176 rendering canvas displayed at 2×.
Each location has two fixed perspective cameras, switched with `V` or Change view.
Project numbered inspection markers from their authored 3D positions using the same camera basis as the shader.
Keep a matching keyboard-accessible inspection list below the scene.
Only the existing room evidence routes are interactive; do not add deduction rules through scenery.
Assets and graphics failures must leave the inspection list usable.
Camera selection is transient presentation state and does not change the save format.

## Diagrams

The board groups eligible player-known nodes into HOLD, GUESS, and CONFLICT columns.
Do not draw suggestive causal links between unrelated nodes.
Proof connectors run only from the selected proof's actual premises to its conclusion.
Proofs paginate at six premises without dropping the remainder.
Timeline entries pair their status text with filled or open markers and solid or dotted treatment.
Accusation counts describe selected records, not proof strength.
Hypothesis inputs remain dotted and separate from the proof view.

## Motion

The district and portraits are static offline renders.
Location geometry is rendered each frame, with immediate camera switches rather than animated transitions.
Do not add idle movement or flickering to imply console hardware.
Scanlines may texture artwork but never cover reading text.

## Copy rules

* No em dash in shipped text. Use period or comma.
* No rule of three forced.
* No inline-header lists where the header restates the line.
* No empty vocabulary: additionally, crucial, delve, enduring, enhance, fostering, garner, interplay, intricate, landscape, pivotal, robust, seamless, holistic, showcase, tapestry, testament, underscore, vibrant, leverage, comprehensive, cutting-edge, empower.
* No invented numbers or quotes. Label placeholders.
* CTAs name the action: "Read receipt 004" not "Learn more".
* Read aloud after writing.

## States

Every knowledge status pairs color with text or line treatment.
Solid holds, dotted is hypothesis, muted is uncertain, and rust marks contradiction.
Never use color alone.

## Verification

Run `make build` and `make runtime-test` before the full project check.
Inspect native captures of all screens, empty and evidence-rich states, proof pagination, and the map at 600×600 and widescreen sizes.
The UI overhaul captures are in `screenshots/console/`.
The current real-time spaces and bottom-spacing captures, including the handoff packet, are in `screenshots/spaces/`.
