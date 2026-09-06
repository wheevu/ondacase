# ondacase contributor guide

## Ownership

- Ink owns dialogue, narrative prose, choices, and character reactions.
- Fennel owns game state, scenes, rendering, input, save/load, and bridge calls.
- Prolog owns truth, inference, contradictions, alternatives, proofs, and accusation evaluation.
- Player-facing code must never query or serialize hidden truth.
- `main.lua` and `src/*.lua` are generated from Fennel. Edit `.fnl` sources instead.

## Commands

```sh
make build
make test
make validate
make check
make run
```

Run the narrow Prolog suite before the complete check when changing case logic.

## Case rules

- A suspicious fact must not imply guilt unless an authored rule establishes the link.
- Discovered, inferred, hypothesized, contradicted, possible, impossible, and proven are separate states.
- Every player-facing inference needs a structured proof.
- Keep Case 001 concrete. Do not build a generic detective engine for a future case.
- Internal IDs belong in developer output only. Player copy uses titles such as `Receipt #004`.

## Presentation

- Reference layout is 720 by 720 and must letterbox cleanly at other sizes.
- Use color and a text or line treatment together for every knowledge status.
- Preserve the charcoal, paper, sodium light, and muted blue-grey palette.
- Avoid framework-default controls, red-string corkboard imagery, neon, glow, and decorative crime motifs.
