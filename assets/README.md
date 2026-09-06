# Asset provenance

## Original real-time spaces

`spaces/` contains the original café, alley, night-store, and apartment geometry and a shared 128×128 atlas.
The assets are AI-assisted and code-authored under the repository's ISC license, with no third-party models or photographs.
LÖVE renders them in real time using a depth-buffered low-resolution canvas, unlike the offline district map below.
See [`spaces/README.md`](spaces/README.md) for the editable Blender scenes, controls, and build command.

## Original district map

`map/district.png` is an original low-poly district render with a 128×128 painted atlas, covered by the repository's ISC license.
The scene and texture are AI-assisted and code-authored; no external models or photographs were used.
It is a schematic navigation image, not a statement about actual travel distances or timing.
See [`map/README.md`](map/README.md) for editable source and reproduction instructions.

## Original low-poly cast

All five `suspects/<id>-psx.png` portraits replace their old photo cutouts when present.
These are original, AI-assisted code-authored models and painted textures, covered by the repository's ISC license.
No third-party character assets or photographs were used in their creation.
Each has a 128×128 texture atlas and a 144×216 offline portrait render.
The People screen uses a head crop of the same image rather than shrinking the whole bust.

| Character | Triangles | Editable source and rebuild command |
|---|---:|---|
| Mira Vale | 648 | [Mira source](suspects/mira-source/README.md) |
| Arin Ko | 654 | [Arin source](suspects/arin-source/README.md) |
| Jo Bell | 644 | [Jo source](suspects/jo-source/README.md) |
| Sasha Reed | 707 | [Sasha source](suspects/sasha-source/README.md) |
| Dan Mott | 733 | [Dan source](suspects/dan-source/README.md) |

`tools/render-mira.py` retains its original filename and defaults to Mira for compatibility.
Pass `-- --character <id>` after Blender's Python-script argument to rebuild another character.
The packed blend files use relative texture and output paths.
The old portrait pack below is retained only as a missing-asset fallback.
See the [cast verification packet](suspects/cast-verification.md) and [contact sheet](../screenshots/cast-psx.png).

## Warning: raster assets with unknown provenance

The current build still contains two raster assets with no recorded source:

- `cafe-lantern.png`
- `locations-sheet.png`

Their embedded metadata contains no author, creator, copyright, or license information.
No source files or provenance record were present when the release check was run.

Treat these files as local development assets.
Do not redistribute them until the project owner records their source and confirms the applicable rights.

Code in this repository is covered by the root ISC license.
That license does not grant rights to these two images while their provenance remains unknown.

`suspects-sheet.png` is deprecated. It remains on disk for backwards compatibility but is no longer loaded when the free individual portraits exist. It has the same unknown provenance warning and should not be redistributed. Prefer `suspects/*.png` below.

---

## Fonts - verified open-source, human-designed

Both fonts below are distributed as human-designed open-source projects under the SIL Open Font License (OFL) v1.1.
No generative-AI provenance is claimed by their upstream repositories.
This table records what is available from official sources; it does not claim independent proof beyond that evidence.

| File | Creator / Maintainer | Upstream repository | Source URL (pinned commit) | License file | License | Intended use |
|---|---|---|---|---|---|---|
| `fonts/Newsreader16pt-Regular.ttf` | Production Type (Newsreader Project Authors) | https://github.com/productiontype/Newsreader | https://raw.githubusercontent.com/productiontype/Newsreader/cfcb4f7af0e52c25e8df2a2431814c8e5fe2e155/fonts/static/ttf/Newsreader16pt-Regular.ttf | `licenses/OFL-Newsreader.txt` | SIL OFL 1.1 | Body/prose typeface (static TTF, 16pt optical size Regular, human-designed serif) |
| `fonts/IBMPlexMono-Medium.ttf` | IBM Corp. (Plex Project Authors) | https://github.com/IBM/plex | https://raw.githubusercontent.com/IBM/plex/bf260093582f04622aacc1e9f9ca604d7ccd0c42/packages/plex-mono/fonts/complete/ttf/IBMPlexMono-Medium.ttf | `licenses/OFL-IBMPlex.txt` | SIL OFL 1.1 (Reserved Font Name "Plex") | Monospace/UI typeface (static TTF, Medium weight, human-designed mono) |
| `fonts/VT323-Regular.ttf` | The VT323 Project Authors (peter.hull@oikoi.com) | https://github.com/google/fonts | https://raw.githubusercontent.com/google/fonts/main/ofl/vt323/VT323-Regular.ttf | `licenses/OFL-VT323.txt` | SIL OFL 1.1 | Display/terminal typeface (2000s low-bit) |
| `fonts/ShareTechMono-Regular.ttf` | Carrois Type Design (Ralph du Carrois) | https://github.com/google/fonts | https://raw.githubusercontent.com/google/fonts/main/ofl/sharetechmono/ShareTechMono-Regular.ttf | `licenses/OFL-ShareTechMono.txt` | SIL OFL 1.1 (Reserved Font Name "Share") | Monospace/UI typeface for cramped terminal |

### License copies

- `licenses/OFL-Newsreader.txt` - exact `OFL.txt` from Newsreader commit `cfcb4f7af0e52c25e8df2a2431814c8e5fe2e155` (https://raw.githubusercontent.com/productiontype/Newsreader/cfcb4f7af0e52c25e8df2a2431814c8e5fe2e155/OFL.txt).
- `licenses/OFL-IBMPlex.txt` - exact `LICENSE.txt` from Plex commit `bf260093582f04622aacc1e9f9ca604d7ccd0c42` (https://raw.githubusercontent.com/IBM/plex/bf260093582f04622aacc1e9f9ca604d7ccd0c42/LICENSE.txt).
- `licenses/OFL-VT323.txt` - `OFL.txt` from VT323 (https://raw.githubusercontent.com/google/fonts/main/ofl/vt323/OFL.txt).
- `licenses/OFL-ShareTechMono.txt` - `OFL.txt` from Share Tech Mono (https://raw.githubusercontent.com/google/fonts/main/ofl/sharetechmono/OFL.txt).

Both license texts permit use, study, modification, and redistribution provided the OFL terms are retained; bundled or embedded use must respect the reserved-name clause where applicable.

### Verification

Downloaded via `curl -fL` from the pinned `raw.githubusercontent.com` URLs above.
Verified with `file` (TrueType Font data) and absence of `<html` markers:

```
file assets/fonts/*.ttf
# assets/fonts/IBMPlexMono-Medium.ttf: TrueType Font data, digitally signed, ...
# assets/fonts/Newsreader16pt-Regular.ttf: TrueType Font data, digitally signed, ...
# assets/fonts/VT323-Regular.ttf: TrueType Font data, ...
# assets/fonts/ShareTechMono-Regular.ttf: TrueType Font data, ...
```

SHA-1 (as downloaded): `858059950b90b9c88ee5645978d73cb874839c1b` (Newsreader16pt-Regular.ttf), `cc338c1d327aecc96f47ed4659e0a44bb4c0a9f4` (IBMPlexMono-Medium.ttf), plus VT323 and ShareTechMono (OFL).

---

## Free portrait pack - subotai Suit-and-tie investigators

Five normalized single-file crops are vendored under `suspects/` for the five Case 001 characters. They replace the deprecated sheet.

| File | Creator | Source URL | Upstream zip | License file | License | No AI | Intended use |
|---|---|---|---|---|---|---|---|
| `suspects/mira.png` | subotai | https://subotai-khudozhnik.itch.io/suit-and-tie-investigators | `portraits.zip` `portraits/lady6.png` 345x1072 | `licenses/LICENSE-SUBOTAI.txt` | Free, commercial allowed, do not resell raw as is | Tagged No AI, extracted from public domain photographs | Mira Vale, cafe manager |
| `suspects/arin.png` | subotai | https://subotai-khudozhnik.itch.io/suit-and-tie-investigators | `portraits.zip` `portraits/suit3.png` 447x1198 | `licenses/LICENSE-SUBOTAI.txt` | Free, commercial allowed, do not resell raw as is | No AI | Arin Ko, food columnist |
| `suspects/jo.png` | subotai | https://subotai-khudozhnik.itch.io/suit-and-tie-investigators | `portraits.zip` `portraits/coat2.png` 399x1096 | `licenses/LICENSE-SUBOTAI.txt` | Free, commercial allowed, do not resell raw as is | No AI | Jo Bell, barista |
| `suspects/sasha.png` | subotai | https://subotai-khudozhnik.itch.io/suit-and-tie-investigators | `portraits.zip` `portraits/lady3.png` 347x1143 | `licenses/LICENSE-SUBOTAI.txt` | Free, commercial allowed, do not resell raw as is | No AI | Sasha Reed, victim's ex |
| `suspects/dan.png` | subotai | https://subotai-khudozhnik.itch.io/suit-and-tie-investigators | `portraits.zip` `portraits/photographer2.png` 380x1174 | `licenses/LICENSE-SUBOTAI.txt` | Free, commercial allowed, do not resell raw as is | No AI | Dan Mott, delivery rider |

The 30 portraits are sepia-toned PNGs about 1000px tall, transparent background, derived from public domain photographs. The itch page states No generative AI was used and in comments confirms commercial use is allowed. The author asks to be notified at subotai.illustration@gmail.com. Full details in `licenses/LICENSE-SUBOTAI.txt`.

Verification: retrieved via `POST https://subotai-khudozhnik.itch.io/suit-and-tie-investigators/file/16093197` returning a signed `itchio-mirror.../upload2/game/4186405/16093197` URL, saved as `portraits.zip` (11 MB, Zip archive data), `file portraits/*.png` shows PNG image data 345x1072 etc. No AI tag present on page.

---

## Free cafe prop pack - ODDBLOT Basic Coffee Shop

Hand-drawn props used as optional cafe dressing. No generative AI, drawn in Adobe Fresco.

| Files | Creator | Source URL | Upstream zip | License file | License | No AI | Intended use |
|---|---|---|---|---|---|---|---|
| `cafe/Basic_*_512.png` and `*_1024.png` | ODDBLOT (Rebecca H) | https://oddblotstudios.itch.io/basic-coffee-shop-pack | `BasicCoffeeShop_ODDBLOT.zip` 3 MB | `licenses/LICENSE-ODDBLOT.txt` and `licenses/ODDBLOT-Thanks.txt` | Free commercial and non-commercial, edit allowed, do not resell standalone, do not train AI | Tagged No AI and Hand-drawn | Cafe props: bar, coffee machine, deco, light, rug, shelf, stool, table, tips, walldeco, window |

Verification: retrieved via `POST https://oddblotstudios.itch.io/basic-coffee-shop-pack/file/16898285` returning signed `itchio-mirror.../upload2/game/4409046/16898285` URL, saved as `BasicCoffeeShop_ODDBLOT.zip` (3.1 MB, Zip archive data). Inside, `Thanks!.txt` contains the license reproduced in `licenses/LICENSE-ODDBLOT.txt`. `file cafe/*.png` shows PNG image data 512x512 etc.
