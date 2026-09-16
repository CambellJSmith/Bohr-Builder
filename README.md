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
- complete mouse, keyboard, and controller support for gameplay and menus

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

Bohr Builder then renders as an interactive Chromium texture inside the Godot game window. Mouse and keyboard input are handled by the embedded browser. Controller input is read by Godot and forwarded into the embedded page as semantic game actions, so it does not depend on Chromium exposing the controller through its own Gamepad API.

If the native addon is missing, the project displays an in-window dependency message instead of failing to parse or closing unexpectedly.

The Godot CEF package contains native Chromium binaries and is intentionally not committed to this repository. `addons/godot_cef/` is ignored by Git so each development machine can install the appropriate native package locally.

## Controls

Every gameplay and interface action is available by mouse, keyboard, and controller. The canvas is keyboard-focusable, all standard UI controls remain reachable with Tab and Shift+Tab, and controller D-pad navigation uses spatial focus movement between visible controls.

### Mouse

- pointer — aim
- left click / hold — primary action or continuous fire
- right click — inspect the atom under the pointer
- all buttons and selectors — normal pointer interaction

### Keyboard

- Tab / Shift+Tab — move through interface controls
- WASD — aim from anywhere outside text/select controls
- arrow keys — aim while the canvas has focus
- Space — primary canvas action / hold to fire
- Enter — primary canvas action while the canvas has focus
- I — inspect the atom under the aim point
- 1 / 2 / 3 — proton / neutron / electron
- Q / E — previous / next particle
- X — toggle scrap mode
- F — toggle freeplay reactant-selection mode
- C — clear selected freeplay reactants
- R — reset level or clear freeplay workspace
- M — open the mode chooser
- [ / ] — previous / next unlocked campaign level
- N — react selected freeplay species or advance a completed campaign level

### Controller

The controller actions are stored in Project Settings → Input Map using the project's established naming convention, so the mappings are visible and remappable directly in the Godot editor.

- `StickLeft_North`, `StickLeft_South`, `StickLeft_West`, `StickLeft_East` — aim
- `DPad_North`, `DPad_South`, `DPad_West`, `DPad_East` — navigate interface focus
- `Button_A` — activate focused UI, perform the primary canvas action, or hold to fire
- `Button_B` — inspect the atom under the aim point
- `Button_X` — toggle scrap mode
- `Button_Y` — toggle freeplay reactant-selection mode
- `Button_LB` / `Button_RB` — previous / next particle
- `Button_LT` / `Button_RT` — previous / next unlocked campaign level
- `Button_Start` — open the mode chooser
- `Button_Back` — reset level or clear freeplay workspace
- `Button_L3` — clear selected freeplay reactants
- `Button_R3` — react selected freeplay species or advance a completed campaign level

The primary action is contextual. In normal construction it fires the selected particle. In scrap mode it removes the atom under the aim point. In freeplay reactant-selection mode it toggles the atom under the aim point into or out of the reaction selection.

## Project structure

- `project.godot` — Godot project configuration, controller Input Map, and main scene
- `godot/bohr_builder.tscn` — fullscreen Godot host scene and dependency fallback UI
- `godot/bohr_builder.gd` — creates and configures the embedded `CefTexture`
- `godot/controller_bridge.gd` — owns named Godot controller actions and forwards them to the embedded page
- `index.html` — application markup loaded directly by Godot CEF
- `styles.css` — interface and workspace styling
- `input.css` — visible focus styling for keyboard and controller navigation
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
- `js/universal-input.js` — shared keyboard/controller focus, aiming, shortcuts, and contextual actions
- `js/input.js` — mouse and UI event wiring through the shared input actions
