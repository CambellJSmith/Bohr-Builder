class_name ParticleState # Stores one fired proton, neutron, or electron projectile.
extends RefCounted # Keeps transient projectile state lightweight and strongly typed.

var kind: StringName = &"proton" # Identifies the selected subatomic particle type.
var position: Vector2 = Vector2.ZERO # Stores the projectile centre in simulation coordinates.
var velocity: Vector2 = Vector2.ZERO # Stores projectile velocity in simulation units per second.
var radius: float = 9.0 # Stores collision and drawing radius.
var age: float = 0.0 # Tracks projectile lifetime for expiry and seed timing.
var target_position: Vector2 = Vector2.ZERO # Stores the original aim point used when seeding a new proton nucleus.
var target_atom_id: int = -1 # Stores a specifically targeted atom for proton footprint capture or negative one when absent.
var alive: bool = true # Marks whether the projectile remains active in the simulation.

func _init(particle_kind: StringName = &"proton") -> void: # Initializes one projectile with its selected type.
	kind = particle_kind # Retains the particle type chosen by the player.
