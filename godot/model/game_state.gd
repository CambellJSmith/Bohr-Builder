class_name BohrGameState # Centralizes mutable gameplay state shared by native Godot systems.
extends RefCounted # Keeps state independent from rendering and UI node lifetimes.

var selected_particle: StringName = &"proton" # Stores the currently loaded particle cannon type.
var particles: Array[ParticleState] = [] # Stores every active fired projectile.
var atoms: Array[AtomState] = [] # Stores every constructed atom or ion in the world.
var molecule_active: bool = false # Marks whether the completed campaign molecule is visible.
var molecule_position: Vector2 = Vector2.ZERO # Stores the completed campaign molecule centre.
var selected_atom_id: int = -1 # Stores the inspected atom identifier or negative one when none is selected.
var scrap_mode: bool = false # Marks whether primary canvas action removes atoms instead of firing.
var pointer_position: Vector2 = ChemistryData.WORLD_SIZE * Vector2(0.5, 0.4) # Stores mouse/keyboard/controller aim in simulation coordinates.
var pointer_down: bool = false # Tracks continuous primary fire from held mouse, keyboard, or controller input.
var last_shot_time_ms: float = 0.0 # Enforces the browser build's minimum interval between particle shots.
var reaction: ReactionState = null # Stores an active automatic campaign reaction or null.
var next_atom_id: int = 1 # Supplies unique identifiers to newly seeded atoms.
var current_level_index: int = 0 # Stores the active campaign level index.
var unlocked_level: int = 0 # Stores the highest campaign level currently available.
var game_mode: StringName = &"" # Stores guided, formula_only, or freeplay mode.
var mode_prompt_open: bool = true # Pauses world interaction while the mode chooser is visible.
var freeplay_select_mode: bool = false # Marks whether primary action toggles freeplay reactants.
var freeplay_selected_ids: Dictionary = {} # Acts as a set of selected atom identifiers.
var freeplay_reaction: ReactionState = null # Stores the active manual freeplay reaction or null.
var freeplay_products: Array[FreeplayProductState] = [] # Stores completed freeplay products retained in the sandbox.
var freeplay_verifying: bool = false # Prevents changes while an unknown formula is being checked online.

func clear_world() -> void: # Restores a clean world while preserving campaign progress and selected mode.
	particles.clear() # Removes every projectile from the current workspace.
	atoms.clear() # Removes every constructed atom and ion.
	molecule_active = false # Removes any completed campaign molecule.
	molecule_position = Vector2.ZERO # Resets the completed molecule position.
	selected_atom_id = -1 # Clears atom inspection.
	reaction = null # Cancels any campaign reaction animation.
	freeplay_reaction = null # Cancels any freeplay reaction animation.
	freeplay_products.clear() # Removes retained products when the workspace is reset.
	freeplay_selected_ids.clear() # Clears manual reaction selection.
	freeplay_select_mode = false # Leaves freeplay reactant-selection mode.
	freeplay_verifying = false # Clears network-verification state.
	next_atom_id = 1 # Restarts atom identifiers for the fresh workspace.
	scrap_mode = false # Leaves scrap mode.
	pointer_down = false # Releases any held fire state.
