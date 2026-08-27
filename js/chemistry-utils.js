"use strict";

function atom(label, symbol, protons, neutrons, electrons) { // Define one neutral atom or monatomic ion used by campaign recipes.
  return { label, short: symbol, protons, neutrons, electrons, display_symbol: symbol };
}

function spec(formula, name, composition, lesson = "") { // Store a neutral molecular composition before it becomes a playable level.
  return { formula, name, composition, lesson };
}

function ion(atom_key, symbol, name, charge) { // Store the chemistry notation needed to build charge-balanced ionic formula units.
  return { atom_key, symbol, name, charge };
}

function expand_composition(composition) { // Expand compact [atom_key,count] pairs into the ordered atoms the world must contain.
  const keys = [];
  for (const [atom_key, count] of composition) {
    for (let i = 0; i < count; i += 1) {
      keys.push(atom_key);
    }
  }
  return keys;
}

function atom_particle_cost(atom_key) { // Approximate construction effort from every proton, neutron and electron the player must place.
  const definition = ATOMS[atom_key];
  return definition.protons + definition.neutrons + definition.electrons;
}

function neutral_spec_cost(entry) { // Rank neutral levels by physical construction load while retaining a curated chemistry sequence.
  return expand_composition(entry.composition).reduce((total, atom_key) => total + atom_particle_cost(atom_key), 0);
}

function subscript_number(value) { // Render positive integer stoichiometric counts as conventional Unicode subscripts.
  const chars = "₀₁₂₃₄₅₆₇₈₉";
  return String(value).split("").map((digit) => chars[Number(digit)]).join("");
}

function superscript_charge(charge) { // Render a monatomic ion charge in compact chemistry notation.
  if (charge === 0) {
    return "";
  }
  const magnitude = Math.abs(charge);
  const number = magnitude === 1 ? "" : String(magnitude).replaceAll("2", "²").replaceAll("3", "³");
  return `${number}${charge > 0 ? "⁺" : "⁻"}`;
}

function gcd(a, b) { // Return the greatest common divisor used to reduce ionic stoichiometric ratios.
  let x = Math.abs(a);
  let y = Math.abs(b);
  while (y !== 0) {
    const next = x % y;
    x = y;
    y = next;
  }
  return x || 1;
}

function formula_piece(symbol, count) { // Format one element and omit an unnecessary subscript of one.
  return count === 1 ? symbol : `${symbol}${subscript_number(count)}`;
}

function make_neutral_bonds(atom_keys) { // Produce a readable schematic connectivity without inventing advanced bond orders.
  if (atom_keys.length < 2) {
    return [];
  }

  const terminal_symbols = new Set(["H", "F", "Cl"]);
  const scaffold = [];
  const terminals = [];
  atom_keys.forEach((atom_key, index) => {
    if (terminal_symbols.has(ATOMS[atom_key].short)) {
      terminals.push(index);
    } else {
      scaffold.push(index);
    }
  });

  const bonds = [];
  if (scaffold.length === 0) {
    for (let i = 1; i < atom_keys.length; i += 1) {
      bonds.push([i - 1, i, 1]);
    }
    return bonds;
  }

  if (scaffold.length <= 4 && scaffold.length > 1 && ATOMS[atom_keys[scaffold[0]]].short !== "C") {
    for (let i = 1; i < scaffold.length; i += 1) {
      bonds.push([scaffold[0], scaffold[i], 1]);
    }
  } else {
    for (let i = 1; i < scaffold.length; i += 1) {
      bonds.push([scaffold[i - 1], scaffold[i], 1]);
    }
  }

  terminals.forEach((terminal_index, index) => {
    bonds.push([scaffold[index % scaffold.length], terminal_index, 1]);
  });
  return bonds;
}

function make_layout(atom_keys, ionic = false) { // Generate a compact in-world target arrangement for any campaign composition.
  const count = atom_keys.length;
  if (count === 1) {
    return [[0, 0]];
  }
  if (count === 2) {
    return [[-88, 0], [88, 0]];
  }

  if (ionic) {
    const columns = Math.ceil(Math.sqrt(count * 1.45));
    const rows = Math.ceil(count / columns);
    const spacing_x = Math.min(108, 470 / Math.max(1, columns - 1));
    const spacing_y = Math.min(100, 330 / Math.max(1, rows - 1));
    return atom_keys.map((_, index) => {
      const row = Math.floor(index / columns);
      const col = index % columns;
      const row_count = Math.min(columns, count - row * columns);
      return [(col - (row_count - 1) / 2) * spacing_x, (row - (rows - 1) / 2) * spacing_y];
    });
  }

  const radius = Math.min(225, 92 + count * 9);
  return atom_keys.map((_, index) => {
    const angle = -Math.PI / 2 + (index / count) * Math.PI * 2;
    const ring = count > 10 && index % 3 === 0 ? radius * 0.55 : radius;
    return [Math.cos(angle) * ring, Math.sin(angle) * ring * 0.72];
  });
}
