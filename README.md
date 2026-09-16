# Bohr Builder

Bohr Builder is a browser-based chemistry game prototype where the player constructs atoms by firing protons, neutrons, and electrons into a shared 2D workspace. Correct reactants automatically combine in campaign mode, while freeplay lets the player build arbitrary atoms and ions and manually attempt real molecular products.

## Current prototype

- Bohr-model atom construction
- all 118 recognised elements
- isotopes and monatomic ions derived from proton, neutron, and electron counts
- 200 campaign levels
- levels 1–50 require neutral atoms only
- ions are introduced from level 51 onward
- guided and formula-only campaign modes
- freeplay mode with manual reaction selection
- fixed particle launch speed; aiming is the physics skill
- proton shots aimed inside an existing atom's Bohr footprint join that atom rather than seeding a new one

## Run locally

Open `index.html` in a modern browser. No build step is required.

## Run through Godot

This repository is also a Godot 4.7 project. The Godot version intentionally runs the existing browser application unchanged so the game remains exactly the same implementation rather than maintaining a second copy of the chemistry, physics, rendering, and campaign logic.

1. Open the repository root in Godot 4.7.2 or a compatible Godot 4.7 release.
2. Run the project with `F5` or the normal project run button.
3. Godot copies the required HTML, CSS, and JavaScript files into `user://bohr_builder_web`.
4. Godot opens the copied `index.html` in the operating system's default browser and then closes the launcher.

Changes made to the existing web files are automatically picked up the next time the Godot project is run.

## Project structure

- `project.godot` — Godot project configuration
- `godot/bohr_builder_launcher.tscn` — minimal Godot launch scene
- `godot/bohr_builder_launcher.gd` — copies and opens the unchanged browser application
- `index.html` — application markup
- `styles.css` — interface and workspace styling
- `js/dom.js` — DOM references and core constants
- `js/chemistry-data.js` — elements, atoms, ions, and campaign chemistry data
- `js/chemistry-utils.js` — chemistry and layout helpers
- `js/campaign.js` — campaign generation and validation
- `js/reaction-library.js` — freeplay formula validation and reaction lookup
- `js/state-ui.js` — game state, modes, level UI, and firing setup
- `js/physics.js` — particle motion, capture, nuclei, and Bohr shells
- `js/campaign-reaction.js` — automatic campaign reaction flow
- `js/freeplay.js` — freeplay selection and manual reactions
- `js/inspector.js` — atom inspection and requirement UI
- `js/render.js` — canvas rendering
- `js/input.js` — mouse, pointer, keyboard, and button input
