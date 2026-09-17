class_name ChemistryData # Exposes shared chemistry constants and focused native data modules through one stable API.
extends RefCounted # Keeps chemistry lookup independent of scene nodes.

const WORLD_SIZE: Vector2 = Vector2(1100.0, 700.0) # Matches the original browser simulation dimensions exactly.
const CANNON_POSITION: Vector2 = Vector2(550.0, 665.0) # Matches the original particle cannon position.
const FIXED_LAUNCH_SPEED: float = 660.0 # Preserves the original fixed projectile speed.
const SHELL_RADII: Array[float] = [44.0, 68.0, 92.0, 116.0, 140.0, 164.0, 188.0, 212.0] # Preserves every supported Bohr shell radius.
const MAX_ATOMIC_NUMBER: int = 118 # Limits proton count to the recognised periodic table.
const MAX_ELECTRONS: int = 126 # Preserves the sandbox electron ceiling.

static var ATOMS: Dictionary = SpeciesData.atoms() # Provides every neutral isotope and campaign monatomic ion by its original key.
static var ION_CATIONS: Array[Dictionary] = SpeciesData.cations() # Provides positive-ion notation data in the original order.
static var ION_ANIONS: Array[Dictionary] = SpeciesData.anions() # Provides negative-ion notation data in the original order.

static func neutral_level_specs() -> Array[Dictionary]: # Returns the complete curated neutral recipe catalogue.
	return NeutralRecipes.specs() # Delegates recipe storage to its focused data module.

static func element_symbol(protons: int) -> String: # Converts an atomic number into its recognised element symbol.
	if protons >= 0 and protons < ElementSymbols.VALUES.size(): # Handles all recognised elements plus the empty zero index.
		return ElementSymbols.VALUES[protons] # Returns the direct atomic-number lookup.
	return "Z%d" % protons # Provides a defensive fallback for unsupported proton counts.

static func element_name(protons: int) -> String: # Converts an atomic number into its official element name.
	if protons >= 0 and protons < ElementNamesLow.VALUES.size(): # Handles elements zero through sixty.
		return ElementNamesLow.VALUES[protons] # Returns the direct low-table entry.
	if protons >= ElementNamesMid.FIRST_ATOMIC_NUMBER and protons < ElementNamesUpper.FIRST_ATOMIC_NUMBER: # Handles elements sixty-one through ninety.
		return ElementNamesMid.VALUES[protons - ElementNamesMid.FIRST_ATOMIC_NUMBER] # Returns the offset middle-table entry.
	if protons >= ElementNamesUpper.FIRST_ATOMIC_NUMBER and protons <= MAX_ATOMIC_NUMBER: # Handles elements ninety-one through one hundred eighteen.
		return ElementNamesUpper.VALUES[protons - ElementNamesUpper.FIRST_ATOMIC_NUMBER] # Returns the offset upper-table entry.
	return "element %d" % protons # Provides a defensive fallback outside the recognised table.

static func subscript_number(value: int) -> String: # Renders positive integer stoichiometric counts as conventional Unicode subscripts.
	const DIGITS: String = "₀₁₂₃₄₅₆₇₈₉" # Maps ASCII digit index to Unicode subscript glyph.
	var result: String = "" # Builds the complete subscript string.
	for character: String in str(value): # Converts each decimal digit independently.
		result += DIGITS.substr(int(character), 1) # Appends the corresponding Unicode subscript.
	return result # Returns the chemistry-ready count text.

static func superscript_charge(charge: int) -> String: # Renders a monatomic ion charge in compact chemistry notation.
	if charge == 0: # Neutral species have no charge suffix.
		return "" # Returns no notation.
	var magnitude: int = absi(charge) # Normalizes the charge magnitude.
	var number: String = "" if magnitude == 1 else str(magnitude).replace("2", "²").replace("3", "³") # Omits a magnitude of one and preserves original superscript handling.
	return number + ("⁺" if charge > 0 else "⁻") # Appends positive or negative superscript sign.
