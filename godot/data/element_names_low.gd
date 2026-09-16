class_name ElementNamesLow # Stores official element names from atomic number zero through sixty.
extends RefCounted # Keeps periodic-table text independent of scene nodes.

const VALUES: PackedStringArray = [ # Uses an empty zero index so low atomic numbers map directly to their entry.
	"", "hydrogen", "helium", "lithium", "beryllium", "boron", "carbon", "nitrogen", "oxygen", "fluorine", "neon", "sodium", "magnesium", "aluminium", "silicon", "phosphorus", "sulfur", "chlorine", "argon", "potassium", "calcium", # Covers zero through twenty.
	"scandium", "titanium", "vanadium", "chromium", "manganese", "iron", "cobalt", "nickel", "copper", "zinc", "gallium", "germanium", "arsenic", "selenium", "bromine", "krypton", "rubidium", "strontium", "yttrium", "zirconium", # Covers twenty-one through forty.
	"niobium", "molybdenum", "technetium", "ruthenium", "rhodium", "palladium", "silver", "cadmium", "indium", "tin", "antimony", "tellurium", "iodine", "xenon", "caesium", "barium", "lanthanum", "cerium", "praseodymium", "neodymium" # Covers forty-one through sixty.
] # Ends the low atomic-number name table.
