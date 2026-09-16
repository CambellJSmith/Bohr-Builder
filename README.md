# Bohr Builder

Bohr Builder is a native Godot 4 chemistry game where the player constructs atoms by firing protons, neutrons, and electrons into a shared 2D workspace. Correct reactants automatically combine in campaign mode, while freeplay lets the player build arbitrary atoms and ions and manually attempt real molecular products.

## Current Prototype

- native Godot 4.7 implementation with no browser or WebView dependency
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
- native Godot progress persistence using `user://bohr_builder.cfg`

## Run In Godot

1. Open the repository root in Godot 4.7.2 or a compatible Godot 4.7 release.
2. Run the project with `F5` or the normal project run button.

There is no HTML, JavaScript, CEF, browser, or other runtime dependency. The interface uses native Godot `Control` nodes, the atom workspace uses native `CanvasItem` drawing, the simulation and chemistry systems are GDScript, and controller input comes directly from Godot's Input Map.

The built-in freeplay compound library works fully offline. When a selected neutral formula is not in that offline library, Bohr Builder can optionally query PubChem. If no internet connection is available, the rest of the game continues normally and only that additional formula verification is unavailable.

## Controls

Every gameplay and interface action is available by mouse, keyboard, and controller. Native Godot controls are keyboard-focusable, and controller D-pad navigation moves spatially between visible controls.

### Mouse

- pointer — aim
- left click / hold — primary action or continuous fire
- right click — inspect the atom under the pointer
- all buttons and selectors — normal pointer interaction

### Keyboard

- Tab / Shift+Tab — move through native interface controls
- WASD — aim from anywhere outside the level selector
- arrow keys — aim while the workspace has focus
- Space — primary workspace action / hold to fire
- Enter — primary workspace action while the workspace has focus, or activate the focused button
- I — inspect the atom under the aim point
- 1 / 2 / 3 — proton / neutron / electron
- Q / E — previous / next particle
- X — toggle Scrap Mode
- F — toggle freeplay reactant-selection mode
- C — clear selected freeplay reactants
- R — reset level or clear freeplay workspace
- M — open the mode chooser
- [ / ] — previous / next unlocked campaign level
- N — react selected freeplay species or advance a completed campaign level

### Controller

The controller actions are stored in Project Settings → Input Map using the project's established naming convention, so they are visible and remappable directly in Godot.

- `StickLeft_North`, `StickLeft_South`, `StickLeft_West`, `StickLeft_East` — aim
- `DPad_North`, `DPad_South`, `DPad_West`, `DPad_East` — navigate interface focus
- `Button_A` — activate focused UI, perform the primary workspace action, or hold to fire
- `Button_B` — inspect the atom under the aim point
- `Button_X` — toggle Scrap Mode
- `Button_Y` — toggle freeplay reactant-selection mode
- `Button_LB` / `Button_RB` — previous / next particle
- `Button_LT` / `Button_RT` — previous / next unlocked campaign level
- `Button_Start` — open the mode chooser
- `Button_Back` — reset level or clear freeplay workspace
- `Button_L3` — clear selected freeplay reactants
- `Button_R3` — react selected freeplay species or advance a completed campaign level

The primary workspace action is contextual. In normal construction it fires the selected particle. In Scrap Mode it removes the atom under the aim point. In freeplay reactant-selection mode it toggles the atom under the aim point into or out of the reaction selection.

## Native Project Structure

- `project.godot` — Godot project configuration, controller Input Map, and native main scene
- `godot/bohr_builder_native.tscn` — complete native interface scene
- `godot/bohr_builder_controller.gd` — native application coordinator, UI state, persistence, and input routing
- `godot/ui/bohr_theme.tres` — native dark interface theme
- `godot/world/bohr_workspace.gd` — native workspace rendering and coordinate conversion
- `godot/data/chemistry_data.gd` — elements, isotopes, ions, and neutral chemistry recipes
- `godot/data/campaign_data.gd` — deterministic 200-level campaign generation
- `godot/data/reaction_library.gd` — formula handling and offline compound library
- `godot/model/atom_state.gd` — strongly typed atom/ion simulation state
- `godot/model/particle_state.gd` — strongly typed projectile state
- `godot/model/reaction_state.gd` — strongly typed reaction-animation state
- `godot/model/freeplay_product_state.gd` — retained freeplay product state
- `godot/model/game_state.gd` — composed mutable gameplay state
- `godot/systems/physics_system.gd` — particle physics, capture rules, atom motion, and electron shells
- `godot/systems/campaign_system.gd` — campaign matching, reactions, completion, and progression
- `godot/systems/freeplay_system.gd` — freeplay selection, validation, reactions, and retained products
- `godot/systems/pubchem_client.gd` — optional nonblocking PubChem verification
