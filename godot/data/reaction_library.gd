class_name ReactionLibrary # Provides formula handling and the browser build's offline real-product whitelist.
extends RefCounted # Keeps formula utilities independent of scene nodes.

const EXTRA_REAL_PRODUCTS: Dictionary = { # Preserves the browser build's additional offline compound whitelist.
	"Br2": "bromine", "I2": "iodine", "O3": "ozone", "HBr": "hydrogen_bromide", "HI": "hydrogen_iodide", # Stores simple elemental and hydrogen-halide products.
	"HNO3": "nitric_acid", "H2SO4": "sulfuric_acid", "H3PO4": "phosphoric_acid", "H2CO3": "carbonic_acid", # Stores common acids.
	"C6H6": "benzene", "C6H12O6": "glucose", "C12H22O11": "sucrose", "C8H10N4O2": "caffeine", # Stores larger carbon compounds.
	"C9H8O4": "aspirin", "C2H5NO2": "glycine", "C3H7NO2": "alanine", "N2O4": "dinitrogen_tetroxide", # Stores additional molecular products.
	"N2O5": "dinitrogen_pentoxide", "P4": "tetraphosphorus", "S8": "octasulfur", "ClO2": "chlorine_dioxide", # Stores molecular allotropes and oxides.
	"NaCl": "sodium_chloride", "KCl": "potassium_chloride", "MgO": "magnesium_oxide", "CaO": "calcium_oxide", # Stores common binary ionic compounds.
	"CaCO3": "calcium_carbonate", "Na2CO3": "sodium_carbonate", "NaHCO3": "sodium_hydrogen_carbonate", # Stores carbonate compounds.
	"KNO3": "potassium_nitrate", "NaNO3": "sodium_nitrate", "NH4Cl": "ammonium_chloride", "MgCl2": "magnesium_chloride", # Stores nitrate, ammonium, and chloride compounds.
	"CaCl2": "calcium_chloride", "Al2O3": "aluminium_oxide", "Fe2O3": "iron_iii_oxide", "Fe3O4": "iron_ii_iii_oxide" # Stores the remaining browser whitelist products.
} # Ends the offline extra-product whitelist.

static var _static_real_products: Dictionary = {} # Caches campaign chemistry plus the extra offline whitelist.

static func static_real_products() -> Dictionary: # Returns the complete normalized offline compound lookup.
	if _static_real_products.is_empty(): # Builds the library only once.
		_static_real_products = _build_static_product_library() # Combines curated extras with every neutral campaign product.
	return _static_real_products # Returns the cached normalized lookup.

static func formula_counts_from_atoms(entries: Array[AtomState]) -> Dictionary: # Counts element symbols in any selected world atom set.
	var counts: Dictionary = {} # Maps element symbols to stoichiometric counts.
	for entry: AtomState in entries: # Counts every selected atom or ion once.
		var symbol: String = ChemistryData.element_symbol(entry.protons) # Resolves its element symbol from proton count.
		counts[symbol] = int(counts.get(symbol, 0)) + 1 # Increments the element's stoichiometric count.
	return counts # Returns the complete symbol/count mapping.

static func ascii_formula_from_atoms(entries: Array[AtomState]) -> String: # Builds a stable Hill-system ASCII molecular formula.
	var counts: Dictionary = formula_counts_from_atoms(entries) # Counts selected elements before formatting.
	return _ascii_formula_from_counts(counts) # Formats the counts in deterministic Hill order.

static func normalize_ascii_formula(formula: String) -> String: # Normalizes conventional formula text to the same Hill ordering used by selected atoms.
	var counts: Dictionary = {} # Collects parsed element counts.
	var index: int = 0 # Tracks the current source-string position.
	while index < formula.length(): # Parses every element token and optional integer count.
		var first: String = formula.substr(index, 1) # Reads the required uppercase element letter.
		if first < "A" or first > "Z": # Skips any unexpected non-element character defensively.
			index += 1 # Advances beyond the invalid character.
			continue # Continues searching for the next element token.
		var symbol: String = first # Starts the current element symbol.
		index += 1 # Advances beyond the uppercase character.
		if index < formula.length(): # Checks for a conventional lowercase second symbol letter.
			var second: String = formula.substr(index, 1) # Reads the possible lowercase suffix.
			if second >= "a" and second <= "z": # Accepts the second letter when it is lowercase.
				symbol += second # Completes the two-letter element symbol.
				index += 1 # Advances beyond the lowercase suffix.
		var digits: String = "" # Accumulates the optional numeric count.
		while index < formula.length() and formula.substr(index, 1).is_valid_int(): # Reads consecutive ASCII digits.
			digits += formula.substr(index, 1) # Appends one count digit.
			index += 1 # Advances to the next source character.
		var count: int = int(digits) if not digits.is_empty() else 1 # Defaults an omitted count to one.
		counts[symbol] = int(counts.get(symbol, 0)) + count # Adds the parsed token to any previous occurrence.
	return _ascii_formula_from_counts(counts) # Returns the normalized Hill-system formula.

static func pretty_formula_from_ascii(formula: String) -> String: # Converts ASCII formula digits into chemistry-style Unicode subscripts.
	var result: String = "" # Builds the display formula incrementally.
	var digits: String = "" # Accumulates each run of numeric characters.
	for index: int in formula.length(): # Reads every source character in order.
		var character: String = formula.substr(index, 1) # Reads one formula character.
		if character.is_valid_int(): # Detects a stoichiometric digit.
			digits += character # Adds it to the pending numeric run.
			continue # Defers output until the run ends.
		if not digits.is_empty(): # Flushes a completed numeric run before the next element character.
			result += ChemistryData.subscript_number(int(digits)) # Converts the complete integer to Unicode subscripts.
			digits = "" # Clears the numeric accumulator.
		result += character # Appends the current nonnumeric character unchanged.
	if not digits.is_empty(): # Flushes a trailing numeric run at the end of the formula.
		result += ChemistryData.subscript_number(int(digits)) # Appends its Unicode subscript form.
	return result # Returns the chemistry display formula.

static func total_charge(entries: Array[AtomState]) -> int: # Sums formal charge from proton and electron totals.
	var charge: int = 0 # Accumulates net formal charge.
	for entry: AtomState in entries: # Reads every selected species.
		charge += entry.protons - entry.electrons # Adds its proton-minus-electron charge.
	return charge # Returns the complete selected charge.

static func generic_product_layout(count: int) -> Array[Vector2]: # Recreates the browser's compact freeplay product arrangement.
	if count <= 1: # Centers a one-species product.
		return [Vector2.ZERO] # Returns a single centered point.
	if count == 2: # Uses the fixed browser spacing for two species.
		return [Vector2(-58.0, 0.0), Vector2(58.0, 0.0)] # Returns the symmetric pair.
	var radius: float = minf(155.0, 58.0 + float(count) * 6.0) # Matches browser freeplay radius scaling.
	var layout: Array[Vector2] = [] # Holds generated local product coordinates.
	for index: int in count: # Places each product species around an elliptical ring.
		var angle: float = -PI * 0.5 + (float(index) / float(count)) * TAU # Calculates the evenly spaced angle.
		layout.append(Vector2(cos(angle) * radius, sin(angle) * radius * 0.72)) # Stores one product-local position.
	return layout # Returns the complete product layout.

static func generic_product_bonds(count: int) -> Array[Array]: # Recreates the browser's generic connected product bonds.
	var bonds: Array[Array] = [] # Holds [from,to,order] bond triples.
	for index: int in range(1, count): # Connects consecutive product species.
		bonds.append([index - 1, index, 1]) # Adds one schematic single bond.
	return bonds # Returns the connected product chain.

static func _build_static_product_library() -> Dictionary: # Combines additional real products with every neutral campaign target.
	var library: Dictionary = {} # Maps normalized ASCII formulas to product names.
	for formula: String in EXTRA_REAL_PRODUCTS: # Adds every curated extra product first.
		library[normalize_ascii_formula(formula)] = String(EXTRA_REAL_PRODUCTS[formula]) # Stores its normalized formula and name.
	var campaign: Array[Dictionary] = CampaignData.levels() # Reads the generated campaign once.
	for index: int in mini(50, campaign.size()): # Adds every neutral campaign product to the offline whitelist.
		var level: Dictionary = campaign[index] # Reads one neutral level definition.
		var counts: Dictionary = {} # Reconstructs formula counts from its atom definitions.
		for atom_key: String in level["atom_keys"] as Array[String]: # Counts each required neutral atom.
			var symbol: String = String(ChemistryData.ATOMS[atom_key]["short"]) # Resolves the atom's conventional symbol.
			counts[symbol] = int(counts.get(symbol, 0)) + 1 # Increments the formula count.
		var key: String = _ascii_formula_from_counts(counts) # Normalizes the level composition to Hill order.
		if not library.has(key): # Preserves any explicit curated name already stored for the same formula.
			library[key] = String(level["name"]) # Adds the campaign product name.
	return library # Returns the complete offline lookup.

static func _ascii_formula_from_counts(counts: Dictionary) -> String: # Formats element counts in deterministic Hill-system order.
	var ordered_symbols: Array[String] = [] # Holds the final element-symbol ordering.
	var symbols: Array[String] = [] # Copies dictionary keys into a sortable strongly typed list.
	for key: Variant in counts.keys(): # Reads each present element symbol.
		symbols.append(String(key)) # Converts the dictionary key into a string.
	symbols.sort() # Alphabetizes symbols for Hill-system fallback ordering.
	if counts.has("C"): # Applies carbon-first Hill ordering for carbon-containing formulas.
		ordered_symbols.append("C") # Places carbon first.
		if counts.has("H"): # Places hydrogen second when present.
			ordered_symbols.append("H") # Adds hydrogen after carbon.
		for symbol: String in symbols: # Adds every remaining symbol alphabetically.
			if symbol != "C" and symbol != "H": # Avoids duplicating carbon or hydrogen.
				ordered_symbols.append(symbol) # Adds one remaining element.
	else: # Uses pure alphabetical order for formulas without carbon.
		ordered_symbols = symbols # Reuses the already sorted symbols directly.
	var formula: String = "" # Builds the ASCII formula.
	for symbol: String in ordered_symbols: # Formats each element/count pair.
		var count: int = int(counts[symbol]) # Reads its stoichiometric count.
		formula += symbol # Appends the element symbol.
		if count != 1: # Omits a redundant count of one.
			formula += str(count) # Appends the ASCII integer count.
	return formula # Returns the normalized formula.
