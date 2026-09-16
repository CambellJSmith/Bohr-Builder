class_name ElementNamesUpper # Stores official element names from atomic number ninety-one through one hundred eighteen.
extends RefCounted # Keeps periodic-table text independent of scene nodes.

const FIRST_ATOMIC_NUMBER: int = 91 # Identifies the atomic number represented by the first entry.
const VALUES: PackedStringArray = [ # Stores names in atomic-number order.
	"protactinium", "uranium", "neptunium", "plutonium", "americium", "curium", "berkelium", "californium", "einsteinium", "fermium", # Covers ninety-one through one hundred.
	"mendelevium", "nobelium", "lawrencium", "rutherfordium", "dubnium", "seaborgium", "bohrium", "hassium", "meitnerium", "darmstadtium", # Covers one hundred one through one hundred ten.
	"roentgenium", "copernicium", "nihonium", "flerovium", "moscovium", "livermorium", "tennessine", "oganesson" # Covers one hundred eleven through one hundred eighteen.
] # Ends the upper name table.
