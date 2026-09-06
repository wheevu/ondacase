# ondacase build plan

This plan keeps Case 001 ahead of generic engine work.

## 1. Logic prototype

- Keep canonical truth private to `logic/case.pl`.
- Add normalized minute helpers for all authored time comparisons.
- Expand statement semantics to distinguish false, misleading, incomplete, and mistaken claims.
- Add proof constructors for every player-visible inference.
- Add validator checks for unique solution, early ambiguity, unreachable evidence, and accidental red-herring proof.

Exit condition: SWI-Prolog tests prove that the culprit is ambiguous before the final evidence set and unique after it.

## 2. Runtime boundary

- Add a Fennel JSON message adapter for the named operations in `logic/api.pl`.
- Spawn SWI-Prolog as a child process only through the adapter.
- Keep failures visible as structured in-game states rather than silently falling back to hidden truth.
- Serialize discovered evidence, statements, hypotheses, timeline entries, and ending attempts.

Exit condition: the preview can discover an evidence ID and receive an inference or contradiction without a raw query string.

## 3. Narrative boundary

- Compile `story/main.ink` into a story artifact during development.
- Bind Ink host functions to named Fennel operations.
- Split the remaining case into the four acts and the five suspect interviews.
- Keep story conditions dependent on player-visible logic responses, never duplicated ground truth.

Exit condition: one café conversation can be replayed with different evidence orders and different reactions.

## 4. Investigation slice

- Replace procedural café blocks with one cohesive background composition.
- Add simple monochrome portrait variants for Mira, Arin, Jo, Sasha, and Dan.
- Add the alley, convenience store, and apartment as compact scenes.
- Add evidence inspection, a timeline screen, and a deliberate contradiction moment.

Exit condition: a player can complete the café investigation without pixel hunting and can inspect why Mira's departure claim fails.

## 5. Deduction and endings

- Make the board data-driven from proof and hypothesis relations.
- Add theory builder sections for who, why, how, when, and support.
- Evaluate accusations across correctness, support, uniqueness, alternatives, and ignored contradictions.
- Add conviction, lucky idiot, beautiful theory, insufficient evidence, and no-accusation endings.

Exit condition: the player can be right without proving the case, and can succeed by refusing an unsupported accusation.

## 6. Presentation pass

- Keep the charcoal, paper, warm café, and muted semantic accent palette consistent.
- Use readable sans-serif dialogue, editorial case headings, and monospaced evidence metadata only where it helps.
- Review title, dialogue, evidence, contradiction, timeline, board, accusation, and case report as static screenshots.
- Add short fades and evidence-card movement only after layout and copy are stable.
- Keep debug predicates, rule IDs, and internal IDs out of player mode.

Exit condition: every screen belongs to the same quiet, late-night case file and no screen reads like a framework default.

## Current checkpoint

The repository contains the Case 001 logic model, named Prolog API, newline-delimited JSON server, four-act Ink case, visual LÖVE presentation, Fennel bridge modules, and a cohesive presentation pass.
The café still, shared suspect portrait sheet, and alley/store/apartment location sheet live in `assets/` and are consumed by the title, investigation, dialogue, and location screens.
The preview now calls the Prolog server for discovered evidence, inferred facts, contradiction state, and accusation results.
The preview calls the compiled Ink host for the Arin and other suspect interview knots, with serialized Ink state handled by the Fennel bridge.
The story has roughly 8,900 authored words across the four acts, five suspect interviews, and four location files, with zero compiler issues.
The accusation screen supports suspect selection, a correct weak case, a coherent wrong case, and a rational insufficient-evidence ending.
Timeline, save/load, proof inspection, all five suspect records, and all four compact locations are authored.
SWI-Prolog tests, the case validator, the JSON bridge, Fennel compilation, and Lua syntax checks pass locally.
The compact build intentionally stops short of claiming a 60 to 90 minute playthrough until a timed playtest confirms it.
Automated rendering and input checks pass.
Eight real LÖVE captures at the 720 by 720 reference size live in `screenshots/` and have been visually reviewed.
