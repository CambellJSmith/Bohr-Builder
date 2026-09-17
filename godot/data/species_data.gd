class_name SpeciesData # Stores campaign atom, isotope, and monatomic-ion definitions in compact native tables.
extends RefCounted # Keeps species data independent of scene nodes.

const ATOM_ROWS: String = "H1|hydrogen-1|H|1|0|1;D2|hydrogen-2|D|1|1|1;He4|helium-4|He|2|2|2;Li7|lithium-7|Li|3|4|3;Be9|beryllium-9|Be|4|5|4;B11|boron-11|B|5|6|5;C12|carbon-12|C|6|6|6;N14|nitrogen-14|N|7|7|7;O16|oxygen-16|O|8|8|8;F19|fluorine-19|F|9|10|9;Ne20|neon-20|Ne|10|10|10;Na23|sodium-23|Na|11|12|11;Mg24|magnesium-24|Mg|12|12|12;Al27|aluminium-27|Al|13|14|13;Si28|silicon-28|Si|14|14|14;P31|phosphorus-31|P|15|16|15;S32|sulfur-32|S|16|16|16;Cl35|chlorine-35|Cl|17|18|17;K39|potassium-39|K|19|20|19;Ca40|calcium-40|Ca|20|20|20;LiP1|lithium-7 +1 ion|Li|3|4|2;NaP1|sodium-23 +1 ion|Na|11|12|10;KP1|potassium-39 +1 ion|K|19|20|18;BeP2|beryllium-9 +2 ion|Be|4|5|2;MgP2|magnesium-24 +2 ion|Mg|12|12|10;CaP2|calcium-40 +2 ion|Ca|20|20|18;AlP3|aluminium-27 +3 ion|Al|13|14|10;FeP2|iron-56 +2 ion|Fe|26|30|24;HM1|hydride -1 ion|H|1|0|2;FM1|fluoride -1 ion|F|9|10|10;ClM1|chloride -1 ion|Cl|17|18|18;OM2|oxide -2 ion|O|8|8|10;SM2|sulfide -2 ion|S|16|16|18;NM3|nitride -3 ion|N|7|7|10;PM3|phosphide -3 ion|P|15|16|18" # Encodes every original campaign species.
const CATION_ROWS: String = "LiP1|Li|lithium|1;BeP2|Be|beryllium|2;NaP1|Na|sodium|1;MgP2|Mg|magnesium|2;AlP3|Al|aluminium|3;KP1|K|potassium|1;CaP2|Ca|calcium|2;FeP2|Fe|iron_ii|2" # Encodes positive ionic formula metadata.
const ANION_ROWS: String = "HM1|H|hydride|-1;FM1|F|fluoride|-1;OM2|O|oxide|-2;NM3|N|nitride|-3;ClM1|Cl|chloride|-1;SM2|S|sulfide|-2;PM3|P|phosphide|-3" # Encodes negative ionic formula metadata.

static func atoms() -> Dictionary: # Expands compact species rows into the dictionaries used by native gameplay systems.
	var result: Dictionary = {} # Collects species by the original atom key.
	for row: String in ATOM_ROWS.split(";"): # Parses each encoded species row once.
		var fields: PackedStringArray = row.split("|") # Separates key, label, symbol, and particle totals.
		result[fields[0]] = {"label": fields[1], "short": fields[2], "display_symbol": fields[2], "protons": int(fields[3]), "neutrons": int(fields[4]), "electrons": int(fields[5])} # Recreates the original atom object shape.
	return result # Returns complete keyed species data.

static func cations() -> Array[Dictionary]: # Expands compact cation notation metadata.
	return _ions(CATION_ROWS) # Parses every positive ion row.

static func anions() -> Array[Dictionary]: # Expands compact anion notation metadata.
	return _ions(ANION_ROWS) # Parses every negative ion row.

static func _ions(rows: String) -> Array[Dictionary]: # Parses compact ionic formula metadata into typed dictionaries.
	var result: Array[Dictionary] = [] # Collects ion notation records in source order.
	for row: String in rows.split(";"): # Parses each encoded ion row.
		var fields: PackedStringArray = row.split("|") # Separates atom key, symbol, name, and charge.
		result.append({"atom_key": fields[0], "symbol": fields[1], "name": fields[2], "charge": int(fields[3])}) # Recreates the original ion object shape.
	return result # Returns complete ionic notation metadata.
