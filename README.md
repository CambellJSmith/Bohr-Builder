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

## Run inside Godot

The Godot project embeds the existing Bohr Builder HTML, CSS, and JavaScript directly inside the Godot window using Godot CEF. The browser implementation remains the single source of truth: Godot loads `res://index.html`, so changes to the existing web files are used automatically without maintaining a second implementation.

### One-time dependency setup

Godot does not include a desktop WebView node, so the project uses the Godot CEF GDExtension.

1. Use Godot 4.7.2 or a compatible Godot 4.7 release.
2. Install Godot CEF `v1.15.4` or newer from the Godot Asset Library or the `dsh0416/godot-cef` releases page.
3. Ensure the addon is located at `res://addons/godot_cef`.
4. Restart the Godot editor after installing the native extension.
5. Run the project with `F5`.

Bohr Builder then renders as an interactive Chromium texture inside the Godot game window. Mouse and keyboard input are handled by the embedded browser; the operating system's external browser is no longer launched.

If the native addon is missing, the project displays an in-window dependency message instead of failing to parse or closing unexpectedly.

The Godot CEF package contains native Chromium binaries and is intentionally not committed to this repository. `addons/godot_cef/` is ignored by Git so each development machine can install the appropriate native package locally.

## Project structure

- `project.godot` — Godot project configuration and main scene
- `godot/bohr_builder.tscn` — fullscreen Godot host scene and dependency fallback UI
- `godot/bohr_builder.gd` — creates and configures the embedded `CefTexture`
- `index.html` — application markup loaded directly by Godot CEF
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
