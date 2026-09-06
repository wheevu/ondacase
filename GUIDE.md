# Development guide

This guide covers local setup, controls, verification, and the repository layout.

## Try it locally

The development build needs LÖVE 11.x, Fennel, SWI-Prolog, Node.js, Lua, and `jq`.

Install the JavaScript dependency, then check the tools:

```sh
npm ci
make doctor
```

Build the Ink and Fennel artifacts, then launch the game:

```sh
make build
make run
```

## Save files

Save files use a checksum to catch accidental corruption.
The checksum is not a signature or an anti-tamper control.
The loader allowlists IDs and types, removes derived reasoning data, and checks that restored fields match the evidence set.

## Controls

| Key | Action |
|---|---|
| `E` | Evidence file |
| `T` | Timeline |
| `B` | Case board |
| `A` | Accusation |
| `P` / `Esc` | Pause or back |
| `Tab` | Move focus |
| `Enter` | Choose |

## Check the build

```sh
make test          # Prolog engine, case rules, and accusation contract
make validate      # authored-case integrity checks
make manifest      # regenerate the player-safe manifest from Prolog
make bridge-test   # newline JSON Prolog boundary
make ink-runtime   # Ink state and host protocol
make ink-routes    # story knot and restore traversal
make runtime-test  # Fennel/LÖVE state, layout, saves, and bridge callbacks
make check         # complete local verification
```

The validator checks the unique authored culprit, early ambiguity, minimum proof set, red-herring isolation, evidence reachability, proof coverage, alternative elimination, ending reachability, statement resolvability, discovery-order independence, accusation explanations, and generated-manifest parity.

The individual checks above pass locally.
`make check` currently stops at the existing Fennel/Ink fixture because it expects `/tmp/ondacase-ink.lua`.
The workaround and full results are recorded in the [console verification packet](screenshots/console/verification.md).

## Repository map

| Path | Contents |
|---|---|
| `assets/` | Café, location, and portrait art |
| `cases/001-americano/` | Authored case content plus the generated player-safe manifest |
| `logic/` | Prolog engine, named JSON server, tests, and validator |
| `src/` | Authoritative Fennel plus generated Lua |
| `story/` | Ink split by act, person, and location |
| `tools/` | Ink host and runtime contract tests |
| `vendor/` | Pinned `dkjson` runtime dependency |
| `main.lua` | Tiny LÖVE bootstrap |

`main.lua` and `src/*.lua` are generated.
Edit the Fennel files and run `make build`.

## Case architecture

Prolog owns case truth and progression. Fennel renders. Ink writes dialogue.

- `cases/001-americano/case_content.pl` holds every authored Case 001 fact and rule, including hidden truth.
- `logic/engine.pl` holds the generic machinery: player state, requirements, proofs, knowledge states, hypothesis evaluation, accusation verdicts, and explanations.
- `logic/case.pl` is a thin facade preserving the `case` module contract. Hidden truth never appears in its exports.
- `logic/case_data.pl` holds display metadata: people, locations, timeline, evidence titles, board nodes, and lock reasons.
- `cases/001-americano/case.json` is generated from Prolog by `logic/export_manifest.pl`. Never edit it by hand.
- `src/case_manifest.lua` is generated from the manifest by `tools/build-case-manifest.lua`. The timeline, location routes, suspect list, and statement list in the UI come from this file.

To change the case, edit `case_content.pl` or `case_data.pl`, then run `make manifest` and `make build`.
`make validate` fails if the checked-in manifest drifts from the generated one.

The runtime talks to Prolog through named JSON operations only. Useful queries beyond discovery and accusation: `case_info`, `timeline`, `available_evidence`, `why_locked`, `perform`, `why_not`, `what_changed`, `alternative_case`, and `board`.

## Related documents

- [`DESIGN.md`](DESIGN.md) - presentation rules and visual constraints.
- [`PLAN.md`](PLAN.md) - current build plan and project checkpoint.
- [`assets/README.md`](assets/README.md) - asset provenance and distribution limits.
