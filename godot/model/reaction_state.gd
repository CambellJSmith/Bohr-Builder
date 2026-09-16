class_name ReactionState # Stores campaign or freeplay reaction animation state.
extends RefCounted # Keeps reaction data independent from rendering and scene ownership.

var elapsed: float = 0.0 # Tracks seconds elapsed since the reaction began.
var duration: float = 0.0 # Stores total animation duration in seconds.
var atom_ids: Array[int] = [] # Identifies the world atoms being consumed by the reaction.
var start_positions: Array[Vector2] = [] # Stores each atom's starting position for deterministic interpolation.
var center: Vector2 = Vector2.ZERO # Stores the freeplay product centre when applicable.
var formula: String = "" # Stores the product formula for freeplay reactions.
var product_name: String = "" # Stores the product name for freeplay reactions.
var snapshots: Array[Dictionary] = [] # Stores consumed atom composition for retained freeplay products.
var layout: Array[Vector2] = [] # Stores local product atom positions for freeplay reactions.
var bonds: Array[Array] = [] # Stores schematic [from,to,order] bond triples.
