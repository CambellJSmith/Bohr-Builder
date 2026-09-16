class_name CampaignData # Generates the same two-hundred-level campaign as the browser implementation.
extends RefCounted # Keeps generated campaign data independent of scene nodes.

static var _levels: Array[Dictionary] = [] # Caches generated levels so campaign construction runs only once.

static func levels() -> Array[Dictionary]: # Returns the complete campaign in its deterministic browser order.
	if _levels.is_empty(): # Builds the campaign lazily the first time it is requested.
		_levels = _build_levels() # Generates fifty neutral levels followed by one hundred fifty ionic levels.
	return _levels # Reuses the cached immutable level dictionaries thereafter.

static func _build_levels() -> Array[Dictionary]: # Recreates the browser campaign generation pipeline.
	var neutral_specs: Array[Dictionary] = ChemistryData.neutral_level_specs().duplicate(true) # Copies curated neutral recipes before sorting them.
	var ordered_specs: Array[Dictionary] = [] # Holds the final neutral recipe order.
	ordered_specs.append(neutral_specs[0]) # Preserves hydrogen as the intentionally easiest opening level.
	ordered_specs.append(neutral_specs[1]) # Preserves hydrogen-deuteride as the isotope introduction.
	var remaining_specs: Array[Dictionary] = [] # Holds every neutral recipe after the two fixed introductions.
	for index: int in range(2, neutral_specs.size()): # Copies the remaining recipes for construction-cost ordering.
		remaining_specs.append(neutral_specs[index]) # Adds one neutral recipe to the sortable list.
	remaining_specs.sort_custom(_neutral_spec_before) # Matches the browser cost/formula ordering.
	ordered_specs.append_array(remaining_specs) # Appends the sorted neutral recipes after the introductions.
	var result: Array[Dictionary] = [] # Collects all generated campaign levels.
	for index: int in ordered_specs.size(): # Converts every neutral recipe to a complete playable level.
		result.append(_neutral_level_from_spec(ordered_specs[index], index)) # Preserves formulas, lessons, layouts, bonds, and assist values.
	result.append_array(_build_ionic_levels()) # Adds the generated ionic progression beginning at level fifty-one.
	_validate_campaign(result) # Rejects an accidental change to the requested neutral/ionic structure.
	return result # Returns the exact generated campaign sequence.

static func _neutral_spec_before(a: Dictionary, b: Dictionary) -> bool: # Sorts neutral recipes by physical construction cost then formula.
	var a_cost: int = _neutral_spec_cost(a) # Computes every particle required for the first recipe.
	var b_cost: int = _neutral_spec_cost(b) # Computes every particle required for the second recipe.
	if a_cost != b_cost: # Uses construction load as the primary difficulty ordering.
		return a_cost < b_cost # Places the cheaper recipe first.
	return String(a["formula"]) < String(b["formula"]) # Uses formula text as the deterministic tie-breaker.

static func _neutral_level_from_spec(entry: Dictionary, index: int) -> Dictionary: # Converts one neutral recipe into a complete level definition.
	var atom_keys: Array[String] = _expand_composition(entry["composition"] as Array) # Expands compact counts into ordered atom keys.
	var reactants: Array[String] = [] # Builds the displayed left side of the reaction equation.
	for pair: Array in entry["composition"] as Array: # Formats each unique atom requirement.
		var atom_key: String = String(pair[0]) # Reads the required isotope key.
		var count: int = int(pair[1]) # Reads the required multiplicity.
		var prefix: String = str(count) if count > 1 else "" # Omits a coefficient of one just like the browser build.
		reactants.append(prefix + String(ChemistryData.ATOMS[atom_key]["display_symbol"])) # Adds the isotope symbol with its coefficient.
	var lesson: String = String(entry["lesson"]) # Starts with any curated lesson text.
	if lesson.is_empty(): # Fills unspecified lessons using the browser's generic neutral instruction.
		lesson = "construct %d neutral atoms. every required atom has the same number of protons and electrons." % atom_keys.size() # Preserves the original wording.
	return { # Returns the native equivalent of the browser level object.
		"title": "neutral_%02d" % (index + 1), # Preserves the internal neutral level identifier.
		"formula": String(entry["formula"]), # Stores the target formula.
		"name": String(entry["name"]), # Stores the target chemical name.
		"equation": " + ".join(reactants) + " → " + String(entry["formula"]), # Stores the displayed construction equation.
		"lesson": lesson, # Stores the level guidance text.
		"atom_keys": atom_keys, # Stores the exact ordered reactant definitions.
		"layout": make_layout(atom_keys, false), # Generates the same compact neutral product arrangement.
		"bonds": make_neutral_bonds(atom_keys), # Generates the same schematic neutral bond connectivity.
		"assist": 1.8 - float(index) * 0.016, # Preserves the gradually decreasing neutral capture assistance.
		"chemistry": "neutral" # Marks the level as neutral chemistry.
	} # Ends the native level dictionary.

static func _build_ionic_levels() -> Array[Dictionary]: # Recreates the browser's one-hundred-fifty generated ionic levels.
	var candidates: Array[Dictionary] = _ionic_candidates() # Generates every supported binary cation/anion pairing.
	var challenges: Array[Dictionary] = [] # Holds repeated formula-unit variants before final selection.
	for copies: int in range(1, 7): # Matches the browser's one-through-six formula-unit variants.
		for candidate: Dictionary in candidates: # Expands every charge-balanced binary formula.
			var atom_count: int = (candidate["base_keys"] as Array).size() * copies # Calculates the total ion count for this repeated target.
			if atom_count > 30: # Preserves the browser playability cap.
				continue # Skips excessively large world targets.
			var challenge: Dictionary = candidate.duplicate(true) # Copies the base pairing into a standalone challenge.
			challenge["copies"] = copies # Stores the requested number of formula units.
			challenge["particle_cost"] = int(candidate["base_cost"]) * copies # Scales the construction effort by formula-unit count.
			challenge["atom_count"] = atom_count # Stores the total number of world ions.
			challenges.append(challenge) # Adds the candidate to the sortable challenge pool.
	challenges.sort_custom(_ionic_challenge_before) # Matches browser ordering by particle cost, size, copies, and formula.
	var selected: Array[Dictionary] = [] # Holds exactly one hundred fifty unique target/copy combinations.
	var seen_targets: Dictionary = {} # Tracks target keys without allocating a custom set type.
	var introduction: Dictionary = challenges[0] # Falls back to the first challenge if KCl cannot be found.
	for challenge: Dictionary in challenges: # Searches for the browser's fixed two-KCl introduction.
		if String(challenge["formula"]) == "KCl" and int(challenge["copies"]) == 2: # Matches the requested ionic introduction exactly.
			introduction = challenge # Uses the two-formula-unit potassium chloride target.
			break # Stops after finding the intended introduction.
	selected.append(introduction) # Forces the KCl introduction to be level fifty-one.
	seen_targets["%d|%s" % [int(introduction["copies"]), String(introduction["formula"])]] = true # Marks the introduction target as used.
	for challenge: Dictionary in challenges: # Selects the remaining ionic difficulty sequence.
		if int(challenge["particle_cost"]) < int(introduction["particle_cost"]): # Preserves the browser rule that no later level is easier than the introduction.
			continue # Skips cheaper challenges.
		var key: String = "%d|%s" % [int(challenge["copies"]), String(challenge["formula"])] # Builds the unique repeated-formula key.
		if seen_targets.has(key): # Prevents duplicate targets.
			continue # Skips a target already selected.
		selected.append(challenge) # Adds the next deterministic challenge.
		seen_targets[key] = true # Marks the challenge as selected.
		if selected.size() == 150: # Stops when the requested campaign length is satisfied.
			break # Leaves the remaining generated combinations unused.
	var ionic_levels: Array[Dictionary] = [] # Converts selected challenges into complete level definitions.
	for index: int in selected.size(): # Builds every post-introduction campaign level.
		ionic_levels.append(_ionic_level_from_challenge(selected[index], index)) # Preserves the browser's level formatting and assistance curve.
	return ionic_levels # Returns exactly one hundred fifty ionic levels.

static func _ionic_candidates() -> Array[Dictionary]: # Generates all supported charge-balanced binary ionic formulas.
	var entries: Array[Dictionary] = [] # Holds every cation/anion pairing.
	for cation: Dictionary in ChemistryData.ION_CATIONS: # Iterates the supported positive monatomic ions.
		for anion: Dictionary in ChemistryData.ION_ANIONS: # Iterates the supported negative monatomic ions.
			var ratio: Dictionary = _ionic_formula_data(cation, anion) # Calculates the smallest charge-balanced stoichiometric ratio.
			var base_keys: Array[String] = [] # Expands one formula unit into atom keys.
			for _index: int in int(ratio["cation_count"]): # Adds the required number of cations.
				base_keys.append(String(cation["atom_key"])) # Stores one positive-ion definition key.
			for _index: int in int(ratio["anion_count"]): # Adds the required number of anions.
				base_keys.append(String(anion["atom_key"])) # Stores one negative-ion definition key.
			var base_cost: int = 0 # Accumulates physical particle construction effort.
			for atom_key: String in base_keys: # Counts every proton, neutron, and electron in one formula unit.
				base_cost += _atom_particle_cost(atom_key) # Adds one ion's construction cost.
			entries.append({"cation": cation, "anion": anion, "cation_count": ratio["cation_count"], "anion_count": ratio["anion_count"], "formula": ratio["formula"], "base_keys": base_keys, "base_cost": base_cost}) # Stores the complete candidate.
	entries.sort_custom(_ionic_candidate_before) # Matches browser ordering by base cost then formula.
	return entries # Returns the deterministic pairing list.

static func _ionic_candidate_before(a: Dictionary, b: Dictionary) -> bool: # Sorts base ionic formulas exactly like the browser build.
	if int(a["base_cost"]) != int(b["base_cost"]): # Uses one-formula-unit particle cost first.
		return int(a["base_cost"]) < int(b["base_cost"]) # Places cheaper formulas first.
	return String(a["formula"]) < String(b["formula"]) # Uses formula text as the tie-breaker.

static func _ionic_challenge_before(a: Dictionary, b: Dictionary) -> bool: # Sorts repeated ionic targets using the browser comparator.
	if int(a["particle_cost"]) != int(b["particle_cost"]): # Compares total particle construction load first.
		return int(a["particle_cost"]) < int(b["particle_cost"]) # Places cheaper challenges first.
	if int(a["atom_count"]) != int(b["atom_count"]): # Compares total ion count second.
		return int(a["atom_count"]) < int(b["atom_count"]) # Places smaller world targets first.
	if int(a["copies"]) != int(b["copies"]): # Compares formula-unit copies third.
		return int(a["copies"]) < int(b["copies"]) # Places fewer repeated units first.
	return String(a["formula"]) < String(b["formula"]) # Uses formula text as the final deterministic tie-breaker.

static func _ionic_level_from_challenge(entry: Dictionary, index: int) -> Dictionary: # Converts one selected ionic challenge into a playable level.
	var atom_keys: Array[String] = [] # Expands every repeated formula unit into ordered ion definitions.
	for _copy: int in int(entry["copies"]): # Repeats the base formula unit the requested number of times.
		for atom_key: String in entry["base_keys"] as Array[String]: # Copies each ion key from the base formula unit.
			atom_keys.append(atom_key) # Adds one ion definition to the target ordering.
	var coefficient: String = str(entry["copies"]) if int(entry["copies"]) > 1 else "" # Omits a coefficient of one from the product formula.
	var target: String = coefficient + String(entry["formula"]) # Builds the displayed repeated-formula target.
	var cation: Dictionary = entry["cation"] # Reads the positive-ion notation data.
	var anion: Dictionary = entry["anion"] # Reads the negative-ion notation data.
	var c_total: int = int(entry["cation_count"]) * int(entry["copies"]) # Calculates total cation count.
	var a_total: int = int(entry["anion_count"]) * int(entry["copies"]) # Calculates total anion count.
	var c_notation: String = (str(c_total) if c_total > 1 else "") + String(cation["symbol"]) + ChemistryData.superscript_charge(int(cation["charge"])) # Formats the reactant cations.
	var a_notation: String = (str(a_total) if a_total > 1 else "") + String(anion["symbol"]) + ChemistryData.superscript_charge(int(anion["charge"])) # Formats the reactant anions.
	var lesson: String = "" # Holds the level instruction text.
	if index == 0: # Uses the dedicated ion introduction on level fifty-one.
		lesson = "ions begin here. build charged atoms by changing the electron count: positive ions have fewer electrons; negative ions have more. the total positive and negative charge must balance." # Preserves the original introduction wording.
	else: # Uses the generated guidance for later ionic targets.
		lesson = "build charge-balanced %s and %s ions. this target contains %d ions." % [String(cation["name"]), String(anion["name"]), atom_keys.size()] # Preserves the original generated wording.
	return { # Returns the complete native ionic level object.
		"title": "ionic_%03d" % (index + 51), # Preserves the internal ionic level identifier.
		"formula": target, # Stores the repeated ionic formula target.
		"name": "%d_%s_%s_formula_units" % [int(entry["copies"]), String(cation["name"]), String(anion["name"])] if int(entry["copies"]) > 1 else "%s_%s" % [String(cation["name"]), String(anion["name"])], # Preserves generated chemical naming.
		"equation": c_notation + " + " + a_notation + " → " + target, # Stores the charge-balanced construction equation.
		"lesson": lesson, # Stores the ion-building guidance.
		"atom_keys": atom_keys, # Stores the exact ordered ionic species list.
		"layout": make_layout(atom_keys, true), # Generates the same ionic grid arrangement as the browser.
		"bonds": [], # Preserves the browser's bondless ionic rendering.
		"assist": maxf(0.68, 1.0 - float(index) * 0.0021), # Preserves the gradually decreasing ionic capture assistance.
		"chemistry": "ionic" # Marks the level as ionic chemistry.
	} # Ends the generated level dictionary.

static func _ionic_formula_data(cation: Dictionary, anion: Dictionary) -> Dictionary: # Calculates the smallest whole-number charge-balanced ion ratio.
	var common: int = _gcd(int(cation["charge"]), int(anion["charge"])) # Finds the greatest common divisor of charge magnitudes.
	var cation_count: int = absi(int(anion["charge"])) / common # Computes the number of cations needed for balance.
	var anion_count: int = absi(int(cation["charge"])) / common # Computes the number of anions needed for balance.
	return {"cation_count": cation_count, "anion_count": anion_count, "formula": _formula_piece(String(cation["symbol"]), cation_count) + _formula_piece(String(anion["symbol"]), anion_count)} # Returns counts and conventional formula text.

static func _expand_composition(composition: Array) -> Array[String]: # Expands compact atom/count pairs into ordered atom keys.
	var keys: Array[String] = [] # Holds the expanded target ordering.
	for pair: Array in composition: # Reads every compact requirement pair.
		for _index: int in int(pair[1]): # Repeats the atom key according to its stoichiometric count.
			keys.append(String(pair[0])) # Adds one ordered atom key.
	return keys # Returns the expanded composition.

static func _atom_particle_cost(atom_key: String) -> int: # Calculates every subatomic particle required to construct one target species.
	var definition: Dictionary = ChemistryData.ATOMS[atom_key] # Reads the requested isotope or ion definition.
	return int(definition["protons"]) + int(definition["neutrons"]) + int(definition["electrons"]) # Returns total construction shots.

static func _neutral_spec_cost(entry: Dictionary) -> int: # Calculates total particle construction load for one neutral recipe.
	var total: int = 0 # Accumulates all required particle shots.
	for atom_key: String in _expand_composition(entry["composition"] as Array): # Expands the recipe into individual target atoms.
		total += _atom_particle_cost(atom_key) # Adds each atom's particle cost.
	return total # Returns the complete recipe effort.

static func make_neutral_bonds(atom_keys: Array[String]) -> Array[Array]: # Recreates the browser's simple readable neutral connectivity.
	if atom_keys.size() < 2: # Handles a one-atom product without a bond.
		return [] # Returns no connections.
	var scaffold: Array[int] = [] # Holds non-terminal atom indices.
	var terminals: Array[int] = [] # Holds hydrogen/halogen terminal indices.
	for index: int in atom_keys.size(): # Classifies each ordered product atom.
		var symbol: String = String(ChemistryData.ATOMS[atom_keys[index]]["short"]) # Reads the atom's display symbol.
		if symbol == "H" or symbol == "F" or symbol == "Cl": # Matches the browser terminal-symbol set.
			terminals.append(index) # Adds terminal species to the attachment pool.
		else: # Treats every other atom as part of the scaffold.
			scaffold.append(index) # Adds one scaffold index.
	var bonds: Array[Array] = [] # Holds [from,to,order] connection triples.
	if scaffold.is_empty(): # Handles products consisting only of terminal-designated species.
		for index: int in range(1, atom_keys.size()): # Connects them in an ordered chain.
			bonds.append([index - 1, index, 1]) # Adds one single bond.
		return bonds # Returns the completed terminal-only chain.
	if scaffold.size() <= 4 and scaffold.size() > 1 and String(ChemistryData.ATOMS[atom_keys[scaffold[0]]]["short"]) != "C": # Matches the browser's small non-carbon hub rule.
		for index: int in range(1, scaffold.size()): # Fans secondary scaffold atoms from the first.
			bonds.append([scaffold[0], scaffold[index], 1]) # Adds one single hub bond.
	else: # Uses a simple chain for carbon or larger scaffolds.
		for index: int in range(1, scaffold.size()): # Connects consecutive scaffold atoms.
			bonds.append([scaffold[index - 1], scaffold[index], 1]) # Adds one single scaffold bond.
	for index: int in terminals.size(): # Attaches terminal atoms around the scaffold cyclically.
		bonds.append([scaffold[index % scaffold.size()], terminals[index], 1]) # Adds one terminal single bond.
	return bonds # Returns the generated schematic connectivity.

static func make_layout(atom_keys: Array[String], ionic: bool) -> Array[Vector2]: # Generates the same product-space coordinates as the browser version.
	var count: int = atom_keys.size() # Reads target atom count once.
	if count == 1: # Centers a single species.
		return [Vector2.ZERO] # Returns the centered layout.
	if count == 2: # Uses the browser's fixed two-species spacing.
		return [Vector2(-88.0, 0.0), Vector2(88.0, 0.0)] # Returns the symmetric pair.
	var layout: Array[Vector2] = [] # Holds generated local product positions.
	if ionic: # Uses a compact stagger-free grid for ionic formula units.
		var columns: int = ceili(sqrt(float(count) * 1.45)) # Matches browser column calculation.
		var rows: int = ceili(float(count) / float(columns)) # Calculates required grid rows.
		var spacing_x: float = minf(108.0, 470.0 / float(maxi(1, columns - 1))) # Matches horizontal ionic spacing.
		var spacing_y: float = minf(100.0, 330.0 / float(maxi(1, rows - 1))) # Matches vertical ionic spacing.
		for index: int in count: # Places every ion in its row and column.
			var row: int = index / columns # Calculates the current grid row.
			var column: int = index % columns # Calculates the current grid column.
			var row_count: int = mini(columns, count - row * columns) # Centers partially filled final rows independently.
			layout.append(Vector2((float(column) - float(row_count - 1) * 0.5) * spacing_x, (float(row) - float(rows - 1) * 0.5) * spacing_y)) # Stores one ionic position.
		return layout # Returns the completed ionic grid.
	var radius: float = minf(225.0, 92.0 + float(count) * 9.0) # Matches browser neutral ring radius scaling.
	for index: int in count: # Places neutral product atoms around the generated ring.
		var angle: float = -PI * 0.5 + (float(index) / float(count)) * TAU # Calculates the evenly distributed ring angle.
		var ring: float = radius * 0.55 if count > 10 and index % 3 == 0 else radius # Pulls every third atom inward for large products.
		layout.append(Vector2(cos(angle) * ring, sin(angle) * ring * 0.72)) # Stores the browser-equivalent elliptical ring position.
	return layout # Returns the generated neutral arrangement.

static func _formula_piece(symbol: String, count: int) -> String: # Formats one element symbol and conventional Unicode subscript count.
	return symbol if count == 1 else symbol + ChemistryData.subscript_number(count) # Omits a redundant subscript of one.

static func _gcd(a: int, b: int) -> int: # Computes the greatest common divisor used for ionic ratios.
	var x: int = absi(a) # Normalizes the first charge magnitude.
	var y: int = absi(b) # Normalizes the second charge magnitude.
	while y != 0: # Runs Euclid's algorithm until the remainder vanishes.
		var next_value: int = x % y # Computes the next remainder.
		x = y # Moves the previous divisor into the first slot.
		y = next_value # Continues with the new remainder.
	return x if x != 0 else 1 # Returns a safe nonzero divisor.

static func _validate_campaign(campaign: Array[Dictionary]) -> void: # Enforces the browser campaign's requested level structure.
	assert(campaign.size() >= 200, "campaign requires at least 200 levels") # Requires at least the requested two hundred levels.
	for index: int in mini(50, campaign.size()): # Checks every neutral-only introductory level.
		for atom_key: String in campaign[index]["atom_keys"] as Array[String]: # Reads each required species definition.
			var definition: Dictionary = ChemistryData.ATOMS[atom_key] # Looks up exact proton/electron totals.
			assert(int(definition["protons"]) == int(definition["electrons"]), "ion leaked into neutral-only campaign") # Rejects an ion in levels one through fifty.
	for index: int in range(50, campaign.size()): # Checks every post-introduction ionic challenge.
		var contains_ion: bool = false # Tracks whether the target includes any charged species.
		for atom_key: String in campaign[index]["atom_keys"] as Array[String]: # Reads each required species definition.
			var definition: Dictionary = ChemistryData.ATOMS[atom_key] # Looks up proton/electron totals.
			if int(definition["protons"]) != int(definition["electrons"]): # Detects a charged monatomic species.
				contains_ion = true # Marks the level as a valid ionic target.
				break # Stops after the first ion is found.
		assert(contains_ion, "post-introduction campaign level must contain an ion") # Rejects neutral-only levels after the ion introduction.
