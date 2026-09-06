# ondacase

`ondacase` is a small detective game written in Prolog, Ink, and Fennel.

<p align="center">
  <img src="screenshots/console/title.png" width="79%">
</p>

## Premise - Case 001

### The iced americano at 7:22

Eli Venn is dead in the back booth of Café Lantern.
Five people had reason to want him dead.
One of them is definitely lying alright.

### Features

- Four places to inspect and five people to question.
- Thirteen evidence records on a live timeline.
- A board to hold evidence and work out the connections.
- Theory and accusation tools with more than one ending.




## Screenshots

Everything below was captured in-game.
Older captures are still in the folder for comparison.
The full sets are in the [console gallery](screenshots/console/README.md) and the [spaces gallery](screenshots/spaces/README.md).

### Case file


<p align="center">
  <img src="screenshots/console/case-tour.gif" alt="Animated tour through the title, map, interview, evidence, board, accusation, and report">
</p>



<p align="center">
  <img src="screenshots/console/investigate.png" alt="Area map with four places to visit" width="49%">
  <img src="screenshots/console/evidence.png" alt="Evidence file with records and conclusions" width="49%">
</p>

### The cast

<p align="center">
  <img src="screenshots/console/dialogue.png" alt="Interview with Mira Vale, cafe manager" width="49%">
  <img src="screenshots/console/people.png" alt="All five suspect records with face crops" width="49%">
</p>

<p align="center">
  <img src="screenshots/cast-psx.png" alt="The full Case 001 cast" width="100%">
</p>

### Locations

<p align="center">
  <img src="screenshots/spaces/rooms-tour.gif" alt="Animated tour of both camera views in the cafe, alley, store, and apartment">
</p>

<p align="center">
  <img src="screenshots/spaces/cafe-1.png" alt="Cafe Lantern from the first camera" width="49%">
  <img src="screenshots/spaces/alley-1.png" alt="Service alley from the first camera" width="49%">
</p>

<p align="center">
  <img src="screenshots/spaces/store-1.png" alt="The first fixed-camera view of the night store" width="49%">
  <img src="screenshots/spaces/apartment-1.png" alt="The first fixed-camera view of Eli's apartment" width="49%">
</p>

### UI


<p align="center">
  <img src="screenshots/console/board.png" alt="The reasoning board separating held facts, guesses, and conflicts" width="49%">
  <img src="screenshots/console/contradiction.png" alt="A contradiction between two records" width="49%">
</p>

<p align="center">
  <img src="screenshots/console/accuse.png" alt="Building a structured accusation for Arin" width="49%">
  <img src="screenshots/console/ending.png" alt="A case report showing the correct suspect but an unproven case" width="49%">
</p>

## Stack

| Language | Job |
|---|---|
| Ink | Dialogue, reactions, and conversation branches |
| Fennel | The LÖVE runtime, game state, rendering, input, saves, and bridge calls |
| Prolog | Case truth, inference, contradictions, proof trees, alternatives, and accusation evaluation |

## Development

Setup, controls, save behavior, verification commands, and the repository map live in the [development guide](GUIDE.md).
Presentation rules are in [`DESIGN.md`](DESIGN.md), and the current build plan is in [`PLAN.md`](PLAN.md).

The current raster artwork has no embedded author or license metadata.
See [`assets/README.md`](assets/README.md) before distributing a build.
