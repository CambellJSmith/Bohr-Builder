"use strict";

function neutral_level_from_spec(entry, index) { // Convert one neutral recipe into a complete playable level definition.
  const atom_keys = expand_composition(entry.composition);
  const reactants = entry.composition.map(([atom_key, count]) => `${count > 1 ? count : ""}${ATOMS[atom_key].display_symbol}`).join(" + ");
  const lesson = entry.lesson || `construct ${atom_keys.length} neutral atoms. every required atom has the same number of protons and electrons.`;
  return level(
    `neutral_${String(index + 1).padStart(2, "0")}`,
    entry.formula,
    entry.name,
    `${reactants} → ${entry.formula}`,
    lesson,
    atom_keys,
    make_layout(atom_keys, false),
    make_neutral_bonds(atom_keys),
    1.8 - index * 0.016,
    "neutral",
  );
}

function ionic_formula_data(cation, anion) { // Calculate the smallest whole-number ratio that balances cation and anion charge.
  const common = gcd(cation.charge, anion.charge);
  const cation_count = Math.abs(anion.charge) / common;
  const anion_count = Math.abs(cation.charge) / common;
  return {
    cation_count,
    anion_count,
    formula: `${formula_piece(cation.symbol, cation_count)}${formula_piece(anion.symbol, anion_count)}`,
  };
}

function ionic_candidates() { // Generate many charge-balanced binary ionic challenges from the supported monatomic ions.
  const entries = [];
  for (const cation of ION_CATIONS) {
    for (const anion of ION_ANIONS) {
      const ratio = ionic_formula_data(cation, anion);
      const base_keys = [
        ...Array(ratio.cation_count).fill(cation.atom_key),
        ...Array(ratio.anion_count).fill(anion.atom_key),
      ];
      const base_cost = base_keys.reduce((total, atom_key) => total + atom_particle_cost(atom_key), 0);
      entries.push({ cation, anion, ...ratio, base_keys, base_cost });
    }
  }
  return entries.sort((a, b) => a.base_cost - b.base_cost || a.formula.localeCompare(b.formula));
}

function build_ionic_levels() { // Build exactly 150 post-introduction levels, scaling from one formula unit to larger repeated formula-unit targets.
  const candidates = ionic_candidates();
  const challenges = [];
  for (let copies = 1; copies <= 6; copies += 1) {
    for (const candidate of candidates) {
      const atom_count = candidate.base_keys.length * copies;
      if (atom_count > 30) {
        continue;
      }
      challenges.push({ ...candidate, copies, particle_cost: candidate.base_cost * copies, atom_count });
    }
  }

  challenges.sort((a, b) => a.particle_cost - b.particle_cost || a.atom_count - b.atom_count || a.copies - b.copies || a.formula.localeCompare(b.formula));

  const selected = [];
  const seen_targets = new Set();
  const introduction = challenges.find((entry) => entry.formula === "KCl" && entry.copies === 2) || challenges[0];
  selected.push(introduction);
  seen_targets.add(`${introduction.copies}|${introduction.formula}`);

  for (const challenge of challenges) {
    if (challenge.particle_cost < introduction.particle_cost) {
      continue;
    }
    const key = `${challenge.copies}|${challenge.formula}`;
    if (seen_targets.has(key)) {
      continue;
    }
    selected.push(challenge);
    seen_targets.add(key);
    if (selected.length === 150) {
      break;
    }
  }

  return selected.map((entry, index) => {
    const atom_keys = [];
    for (let copy = 0; copy < entry.copies; copy += 1) {
      atom_keys.push(...entry.base_keys);
    }
    const coefficient = entry.copies > 1 ? `${entry.copies}` : "";
    const target = `${coefficient}${entry.formula}`;
    const c_total = entry.cation_count * entry.copies;
    const a_total = entry.anion_count * entry.copies;
    const c_notation = `${c_total > 1 ? c_total : ""}${entry.cation.symbol}${superscript_charge(entry.cation.charge)}`;
    const a_notation = `${a_total > 1 ? a_total : ""}${entry.anion.symbol}${superscript_charge(entry.anion.charge)}`;
    const intro = index === 0
      ? "ions begin here. build charged atoms by changing the electron count: positive ions have fewer electrons; negative ions have more. the total positive and negative charge must balance."
      : `build charge-balanced ${entry.cation.name} and ${entry.anion.name} ions. this target contains ${atom_keys.length} ions.`;
    return level(
      `ionic_${String(index + 51).padStart(3, "0")}`,
      target,
      entry.copies > 1 ? `${entry.copies}_${entry.cation.name}_${entry.anion.name}_formula_units` : `${entry.cation.name}_${entry.anion.name}`,
      `${c_notation} + ${a_notation} → ${target}`,
      intro,
      atom_keys,
      make_layout(atom_keys, true),
      [],
      Math.max(0.68, 1.0 - index * 0.0021),
      "ionic",
    );
  });
}

const ORDERED_NEUTRAL_SPECS = [
  ...NEUTRAL_LEVEL_SPECS.slice(0, 2),
  ...NEUTRAL_LEVEL_SPECS.slice(2).sort((a, b) => neutral_spec_cost(a) - neutral_spec_cost(b) || a.formula.localeCompare(b.formula)),
];
const NEUTRAL_LEVELS = ORDERED_NEUTRAL_SPECS.map(neutral_level_from_spec);
const IONIC_LEVELS = build_ionic_levels();
const LEVELS = [...NEUTRAL_LEVELS, ...IONIC_LEVELS];

function validate_campaign() { // Enforce the requested 200-level structure and the neutral-only first fifty levels.
  if (LEVELS.length < 200) {
    throw new Error(`campaign requires at least 200 levels; generated ${LEVELS.length}`);
  }
  for (let index = 0; index < Math.min(50, LEVELS.length); index += 1) {
    for (const atom_key of LEVELS[index].atom_keys) {
      const definition = ATOMS[atom_key];
      if (definition.protons !== definition.electrons) {
        throw new Error(`ion ${atom_key} leaked into neutral-only level ${index + 1}`);
      }
    }
  }
  for (let index = 50; index < LEVELS.length; index += 1) {
    if (!LEVELS[index].atom_keys.some((atom_key) => ATOMS[atom_key].protons !== ATOMS[atom_key].electrons)) {
      throw new Error(`level ${index + 1} must contain at least one ion`);
    }
  }
}

validate_campaign();
const EXTRA_REAL_PRODUCTS = new Map([
  ["Br2", "bromine"], ["I2", "iodine"], ["O3", "ozone"], ["HBr", "hydrogen_bromide"], ["HI", "hydrogen_iodide"],
  ["HNO3", "nitric_acid"], ["H2SO4", "sulfuric_acid"], ["H3PO4", "phosphoric_acid"], ["H2CO3", "carbonic_acid"],
  ["C6H6", "benzene"], ["C6H12O6", "glucose"], ["C12H22O11", "sucrose"], ["C8H10N4O2", "caffeine"],
  ["C9H8O4", "aspirin"], ["C2H5NO2", "glycine"], ["C3H7NO2", "alanine"], ["N2O4", "dinitrogen_tetroxide"],
  ["N2O5", "dinitrogen_pentoxide"], ["P4", "tetraphosphorus"], ["S8", "octasulfur"], ["ClO2", "chlorine_dioxide"],
  ["NaCl", "sodium_chloride"], ["KCl", "potassium_chloride"], ["MgO", "magnesium_oxide"], ["CaO", "calcium_oxide"],
  ["CaCO3", "calcium_carbonate"], ["Na2CO3", "sodium_carbonate"], ["NaHCO3", "sodium_hydrogen_carbonate"],
  ["KNO3", "potassium_nitrate"], ["NaNO3", "sodium_nitrate"], ["NH4Cl", "ammonium_chloride"], ["MgCl2", "magnesium_chloride"],
  ["CaCl2", "calcium_chloride"], ["Al2O3", "aluminium_oxide"], ["Fe2O3", "iron_iii_oxide"], ["Fe3O4", "iron_ii_iii_oxide"]
]);
const PUBCHEM_CACHE = new Map();
