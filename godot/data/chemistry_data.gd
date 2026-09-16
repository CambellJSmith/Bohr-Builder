class_name ChemistryData # Provides immutable chemistry constants and recipe data for the native Godot build.
extends RefCounted # Keeps chemistry data lightweight and independent of the scene tree.

const WORLD_SIZE: Vector2 = Vector2(1100.0, 700.0) # Matches the original browser simulation dimensions exactly.
const CANNON_POSITION: Vector2 = Vector2(550.0, 665.0) # Matches the original particle cannon position.
const FIXED_LAUNCH_SPEED: float = 660.0 # Preserves the browser build's fixed projectile speed.
const SHELL_RADII: Array[float] = [44.0, 68.0, 92.0, 116.0, 140.0, 164.0, 188.0, 212.0] # Preserves every supported Bohr shell radius.
const MAX_ATOMIC_NUMBER: int = 118 # Limits proton count to the recognised periodic table.
const MAX_ELECTRONS: int = 126 # Preserves the browser sandbox electron ceiling.

const ELEMENT_SYMBOLS: Array[String] = [ # Maps atomic number directly to an element symbol.
	"", "H", "He", "Li", "Be", "B", "C", "N", "O", "F", "Ne", "Na", "Mg", "Al", "Si", "P", "S", "Cl", "Ar", "K", "Ca", # Covers atomic numbers zero through twenty.
	"Sc", "Ti", "V", "Cr", "Mn", "Fe", "Co", "Ni", "Cu", "Zn", "Ga", "Ge", "As", "Se", "Br", "Kr", "Rb", "Sr", "Y", "Zr", # Covers atomic numbers twenty-one through forty.
	"Nb", "Mo", "Tc", "Ru", "Rh", "Pd", "Ag", "Cd", "In", "Sn", "Sb", "Te", "I", "Xe", "Cs", "Ba", "La", "Ce", "Pr", "Nd", # Covers atomic numbers forty-one through sixty.
	"Pm", "Sm", "Eu", "Gd", "Tb", "Dy", "Ho", "Er", "Tm", "Yb", "Lu", "Hf", "Ta", "W", "Re", "Os", "Ir", "Pt", "Au", "Hg", # Covers atomic numbers sixty-one through eighty.
	"Tl", "Pb", "Bi", "Po", "At", "Rn", "Fr", "Ra", "Ac", "Th", "Pa", "U", "Np", "Pu", "Am", "Cm", "Bk", "Cf", "Es", "Fm", # Covers atomic numbers eighty-one through one hundred.
	"Md", "No", "Lr", "Rf", "Db", "Sg", "Bh", "Hs", "Mt", "Ds", "Rg", "Cn", "Nh", "Fl", "Mc", "Lv", "Ts", "Og" # Covers atomic numbers one hundred one through one hundred eighteen.
] # Ends the element-symbol lookup.

const ELEMENT_NAMES: Array[String] = [ # Maps atomic number directly to the official element name.
	"", "hydrogen", "helium", "lithium", "beryllium", "boron", "carbon", "nitrogen", "oxygen", "fluorine", "neon", "sodium", "magnesium", "aluminium", "silicon", "phosphorus", "sulfur", "chlorine", "argon", "potassium", "calcium", # Covers atomic numbers zero through twenty.
	"scandium", "titanium", "vanadium", "chromium", "manganese", "iron", "cobalt", "nickel", "copper", "zinc", "gallium", "germanium", "arsenic", "selenium", "bromine", "krypton", "rubidium", "strontium", "yttrium", "zirconium", # Covers atomic numbers twenty-one through forty.
	"niobium", "molybdenum", "technetium", "ruthenium", "rhodium", "palladium", "silver", "cadmium", "indium", "tin", "antimony", "tellurium", "iodine", "xenon", "caesium", "barium", "lanthanum", "cerium", "praseodymium", "neodymium", # Covers atomic numbers forty-one through sixty.
	"promethium", "samarium", "europium", "gadolinium", "terbium", "dysprosium", "holmium", "erbium", "thulium", "ytterbium", "lutetium", "hafnium", "tantalum", "tungsten", "rhenium", "osmium", "iridium", "platinum", "gold", "mercury", # Covers atomic numbers sixty-one through eighty.
	"thallium", "lead", "bismuth", "polonium", "astatine", "radon", "francium", "radium", "actinium", "thorium", "protactinium", "uranium", "neptunium", "plutonium", "americium", "curium", "berkelium", "californium", "einsteinium", "fermium", # Covers atomic numbers eighty-one through one hundred.
	"mendelevium", "nobelium", "lawrencium", "rutherfordium", "dubnium", "seaborgium", "bohrium", "hassium", "meitnerium", "darmstadtium", "roentgenium", "copernicium", "nihonium", "flerovium", "mos