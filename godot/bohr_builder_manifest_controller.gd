class_name BohrBuilderManifestController # Enforces the final Oddity input contract above the existing Bohr Builder integration.
extends BohrBuilderOddityController # Reuses the shared-settings and semantic input implementation already composed into the game.

const LEGACY_ARROW_KEYS: Array[Key] = [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT] # Identifies the legacy keyboard navigation aliases excluded by the Oddity left-stick contract.

func _handle_key_event(event: InputEventKey) -> void: # Filters legacy arrow-key navigation before inherited UI or workspace handlers can consume it.
	if event.keycode in LEGACY_ARROW_KEYS: # Detects an arrow-key event that must not act as a left-stick keyboard equivalent.
		get_viewport().set_input_as_handled() # Prevents native Controls and inherited modal navigation from using the legacy arrow input.
		return # Leaves WASD as the only keyboard equivalent for canonical left-stick movement and navigation.
	super._handle_key_event(event) # Delegates all manifest-compliant semantic actions and game-specific shortcuts to the established Oddity adapter.
