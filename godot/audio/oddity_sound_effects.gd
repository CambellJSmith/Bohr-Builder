class_name BohrOdditySoundEffects # Routes Bohr Builder's existing generated sound palette through the standard Oddity effects category.
extends BohrSoundEffects # Preserves the established synthesis and playback implementation without duplicating it.

func _ready() -> void: # Builds the inherited sound palette and then applies standard Oddity bus routing.
	super._ready() # Creates the existing polyphonic effects player and generated audio streams.
	if _player != null: # Confirms the inherited playback host was created successfully.
		_player.bus = &"Effects" # Routes every generated gameplay and UI effect through the shared Effects bus.
