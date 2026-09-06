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
make test          # Prolog case rules and accusation contract
make validate      # authored-case integrity checks
make bridge-test   # newline JSON Prolog boundary
make ink-runtime   # Ink state and host protocol
make ink-routes    # story knot and restore traversal
make runtime-test  # Fennel/LÖVE state, layout, saves, and bridge callbacks
make check         # complete local verification
```

The validator checks the unique authored culprit, early ambiguity, minimum proof set, red-herring isolation, evidence reachability, proof coverage, and alternative elimination.

The individual checks above pass locally.
`make check` currently stops at the existing Fennel/Ink fixture because it expects `/tmp/ondacase-ink.lua`.
The workaround and full results are recorded in the [console verification packet](screenshots/console/verification.md).

## Repository map

| Path | Contents |
|---|---|
| `assets/` | Café, location, and portrait art |
| `cases/001-americano/` | Player-safe manifest and spoiler authoring record |
| `logic/` | Prolog case, named JSON server, tests, and validator |
| `src/` | Authoritative Fennel plus generated Lua |
| `story/` | Ink split by act, person, and location |
| `tools/` | Ink host and runtime contract tests |
| `vendor/` | Pinned `dkjson` runtime dependency |
| `main.lua` | Tiny LÖVE bootstrap |

`main.lua` and `src/*.lua` are generated.
Edit the Fennel files and run `make build`.

## Related documents

- [`DESIGN.md`](DESIGN.md) - presentation rules and visual constraints.
- [`PLAN.md`](PLAN.md) - current build plan and project checkpoint.
- [`assets/README.md`](assets/README.md) - asset provenance and distribution limits.
