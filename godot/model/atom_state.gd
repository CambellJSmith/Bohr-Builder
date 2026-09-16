class_name AtomState # Stores one constructed atom or monatomic ion in native simulation state.
extends RefCounted # Keeps each atom lightweight while providing strongly typed fields.

var id: int = 0 # Identifies the atom uniquely inside the current workspace.
var position: Vector2 = Vector2.ZERO # Stores the atom centre in the fixed simulation coordinate system.
var velocity: Vector2 = Vector2.ZERO # Stores the atom's residual world velocity.
var protons: int = 1 # Stores the nucleus proton count and therefore atomic number.
var neutrons: int = 0 # Stores the nucleus neutron count and therefore isotope mass contribution.
var electrons: int = 0 # Stores the captured electron count and therefore formal charge.
var electron_phase: float = 0.0 # Offsets orbit animation so atoms do not rotate identically.
var pulse: float = 1.0 # Drives the short capture highlight around the nucleus.

func _init(atom_id: int = 0, atom_position: Vector2 = Vector2.ZERO) -> void: # Initializes one atom at a requested world position.
	id = atom_id # Retains the caller-assigned workspace identifier.
	position = atom_position # Retains the caller-assigned world position.
