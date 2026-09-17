class_name FreeplayProductState # Stores one completed freeplay molecule retained in the sandbox.
extends RefCounted # Keeps product data lightweight after its source atoms have been consumed.

var position: Vector2 = Vector2.ZERO # Stores the molecule centre in simulation coordinates.
var formula: String = "" # Stores the ASCII formula used by the reaction library.
var product_name: String = "" # Stores the known or verified compound name.
var snapshots: Array[Dictionary] = [] # Stores each consumed atom's particle counts for rendering.
var layout: Array[Vector2] = [] # Stores product-local atom positions.
var bonds: Array[Array] = [] # Stores schematic [from,to,order] product bonds.
