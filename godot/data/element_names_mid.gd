class_name ElementNamesMid # Stores official element names from atomic number sixty-one through ninety.
extends RefCounted # Keeps periodic-table text independent of scene nodes.

const FIRST_ATOMIC_NUMBER: int = 61 # Identifies the atomic number represented by the first entry.
const VALUES: PackedStringArray = [ # Stores names in atomic-number order.
	"promethium", "samarium", "europium", "gadolinium", "terbium", "dysprosium", "holmium", "erbium", "thulium", "ytterbium", # Covers sixty-one through seventy.
	"lutetium", "hafnium", "tantalum", "tungsten", "rhenium", "osmium", "iridium", "platinum", "gold", "mercury", # Covers seventy-one through eighty.
	"thallium", "lead", "bismuth", "polonium", "astatine", "radon", "francium", "radium", "actinium", "thorium" # Covers eighty-one through ninety.
] # Ends the middle name table.
