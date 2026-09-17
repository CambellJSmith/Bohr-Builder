class_name NeutralRecipes # Stores the fifty curated neutral campaign recipes separately from core element data.
extends RefCounted # Keeps recipe data lightweight and independent of scene nodes.

static func specs() -> Array[Dictionary]: # Returns the complete browser-equivalent neutral recipe catalogue.
	return [ # Preserves every formula, composition, name, and curated lesson from the original implementation.
		_spec("H₂", "hydrogen", [["H1", 2]], "two hydrogen atoms form the gentlest possible introduction."), # Defines the opening hydrogen molecule.
		_spec("HD", "hydrogen_deuteride", [["H1", 1], ["D2", 1]], "add one neutron to make deuterium while keeping both atoms neutral."), # Introduces isotope construction.
		_spec("CH₄", "methane", [["C12", 1], ["H1", 4]], "introduce carbon and its second Bohr shell."), # Introduces carbon and second-shell electrons.
		_spec("NH₃", "ammonia", [["N14", 1], ["H1", 3]], "build one nitrogen atom and three hydrogens."), # Defines ammonia.
		_spec("H₂O", "water", [["O16", 1], ["H1", 2]], "build oxygen-16 and two hydrogen atoms."), # Defines water.
		_spec("HF", "hydrogen_fluoride", [["H1", 1], ["F19", 1]]), # Defines hydrogen fluoride.
		_spec("CO", "carbon_monoxide", [["C12", 1], ["O16", 1]]), # Defines carbon monoxide.
		_spec("N₂", "nitrogen", [["N14", 2]]), # Defines molecular nitrogen.
		_spec("O₂", "oxygen", [["O16", 2]]), # Defines molecular oxygen.
		_spec("HCN", "hydrogen_cyanide", [["H1", 1], ["C12", 1], ["N14", 1]]), # Defines hydrogen cyanide.
		_spec("CO₂", "carbon_dioxide", [["C12", 1], ["O16", 2]]), # Defines carbon dioxide.
		_spec("H₂O₂", "hydrogen_peroxide", [["H1", 2], ["O16", 2]]), # Defines hydrogen peroxide.
		_spec("NO", "nitric_oxide", [["N14", 1], ["O16", 1]]), # Defines nitric oxide.
		_spec("NO₂", "nitrogen_dioxide", [["N14", 1], ["O16", 2]]), # Defines nitrogen dioxide.
		_spec("N₂O", "nitrous_oxide", [["N14", 2], ["O16", 1]]), # Defines nitrous oxide.
		_spec("F₂", "fluorine", [["F19", 2]]), # Defines molecular fluorine.
		_spec("CH₂O", "formaldehyde", [["C12", 1], ["H1", 2], ["O16", 1]]), # Defines formaldehyde.
		_spec("C₂H₂", "ethyne", [["C12", 2], ["H1", 2]]), # Defines ethyne.
		_spec("OF₂", "oxygen_difluoride", [["O16", 1], ["F19", 2]]), # Defines oxygen difluoride.
		_spec("C₂H₄", "ethene", [["C12", 2], ["H1", 4]]), # Defines ethene.
		_spec("C₂H₆", "ethane", [["C12", 2], ["H1", 6]]), # Defines ethane.
		_spec("CH₃OH", "methanol", [["C12", 1], ["H1", 4], ["O16", 1]]), # Defines methanol.
		_spec("H₂S", "hydrogen_sulfide", [["S32", 1], ["H1", 2]]), # Defines hydrogen sulfide.
		_spec("SO₂", "sulfur_dioxide", [["S32", 1], ["O16", 2]]), # Defines sulfur dioxide.
		_spec("BF₃", "boron_trifluoride", [["B11", 1], ["F19", 3]]), # Defines boron trifluoride.
		_spec("C₂H₄O", "ethanal", [["C12", 2], ["H1", 4], ["O16", 1]]), # Defines ethanal.
		_spec("C₂H₆O", "ethanol", [["C12", 2], ["H1", 6], ["O16", 1]]), # Defines ethanol.
		_spec("C₃H₄", "propyne", [["C12", 3], ["H1", 4]]), # Defines propyne.
		_spec("C₃H₆", "propene", [["C12", 3], ["H1", 6]]), # Defines propene.
		_spec("C₂H₄O₂", "acetic_acid", [["C12", 2], ["H1", 4], ["O16", 2]]), # Defines acetic acid.
		_spec("C₂H₆O₂", "ethylene_glycol", [["C12", 2], ["H1", 6], ["O16", 2]]), # Defines ethylene glycol.
		_spec("C₃H₈", "propane", [["C12", 3], ["H1", 8]]), # Defines propane.
		_spec("C₃H₆O", "acetone", [["C12", 3], ["H1", 6], ["O16", 1]]), # Defines acetone.
		_spec("C₃H₈O", "propanol", [["C12", 3], ["H1", 8], ["O16", 1]]), # Defines propanol.
		_spec("SO₃", "sulfur_trioxide", [["S32", 1], ["O16", 3]]), # Defines sulfur trioxide.
		_spec("SiH₄", "silane", [["Si28", 1], ["H1", 4]]), # Defines silane.
		_spec("PH₃", "phosphine", [["P31", 1], ["H1", 3]]), # Defines phosphine.
		_spec("CF₄", "carbon_tetrafluoride", [["C12", 1], ["F19", 4]]), # Defines carbon tetrafluoride.
		_spec("C₃H₆O₂", "propionic_acid", [["C12", 3], ["H1", 6], ["O16", 2]]), # Defines propionic acid.
		_spec("C₃H₈O₃", "glycerol", [["C12", 3], ["H1", 8], ["O16", 3]]), # Defines glycerol.
		_spec("BCl₃", "boron_trichloride", [["B11", 1], ["Cl35", 3]]), # Defines boron trichloride.
		_spec("C₄H₆", "butadiene", [["C12", 4], ["H1", 6]]), # Defines butadiene.
		_spec("C₄H₈", "butene", [["C12", 4], ["H1", 8]]), # Defines butene.
		_spec("C₄H₁₀", "butane", [["C12", 4], ["H1", 10]]), # Defines butane.
		_spec("SiF₄", "silicon_tetrafluoride", [["Si28", 1], ["F19", 4]]), # Defines silicon tetrafluoride.
		_spec("PCl₃", "phosphorus_trichloride", [["P31", 1], ["Cl35", 3]]), # Defines phosphorus trichloride.
		_spec("SF₄", "sulfur_tetrafluoride", [["S32", 1], ["F19", 4]]), # Defines sulfur tetrafluoride.
		_spec("Cl₂", "chlorine", [["Cl35", 2]]), # Defines molecular chlorine.
		_spec("HCl", "hydrogen_chloride", [["H1", 1], ["Cl35", 1]]), # Defines hydrogen chloride.
		_spec("SF₆", "sulfur_hexafluoride", [["S32", 1], ["F19", 6]], "the final neutral-only level combines a third-shell sulfur atom with six fluorine atoms."), # Defines the final neutral-only recipe.
	] # Ends the complete fifty-recipe catalogue.

static func _spec(formula: String, product_name: String, composition: Array, lesson: String = "") -> Dictionary: # Creates one immutable-style neutral recipe dictionary.
	return {"formula": formula, "name": product_name, "composition": composition, "lesson": lesson} # Stores the exact source recipe fields.
