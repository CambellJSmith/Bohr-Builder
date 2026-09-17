class_name ElementNamesHigh # Stores official element names from atomic number sixty-one through one hundred eighteen.
extends RefCounted # Keeps periodic-table text independent of scene nodes.

const FIRST_ATOMIC_NUMBER: int = 61 # Identifies the atomic number represented by the first entry.
const VALUES: PackedStringArray = [ # Stores the remaining official names in atomic-number order.
	"promethium", "samarium", "europium", "gadolinium", "terbium", "dysprosium", "holmium", "erbium", "thulium", "ytterbium", "lutetium", "hafnium", "tantalum", "tungsten", "rhenium", "osmium", "iridium", "platinum", "gold", "mercury", # Covers sixty-one through eighty.
	"thallium", "lead", "bismuth", "polonium", "astatine", "radon", "francium", "radium", "actinium", "thorium", "protactinium", "uranium", "neptunium", "plutonium", "americium", "curium", "berkelium", "californium", "einsteinium", "fermium", # Covers eighty-one through one hundred.
	"mendelevium", "nobelium", "lawrencium", "rutherfordium", "dubnium", "seaborgium", "bohrium", "hassium", "meitnerium", "darmstadtium", "roentgenium", "copernicium", "nihonium", "flerovium", "moscovium