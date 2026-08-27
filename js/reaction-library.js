"use strict";

function formula_counts_from_atoms(entries) { // Count elements in a selected atom set without imposing campaign requirements.
  const counts = new Map();
  for (const entry of entries) {
    const symbol = element_symbol(entry.protons);
    counts.set(symbol, (counts.get(symbol) || 0) + 1);
  }
  return counts;
}

function formula_order(counts) { // Use Hill-system ordering so formulas are stable and searchable.
  const symbols = Array.from(counts.keys());
  if (counts.has("C")) {
    return ["C", ...(counts.has("H") ? ["H"] : []), ...symbols.filter((symbol) => symbol !== "C" && symbol !== "H").sort()];
  }
  return symbols.sort();
}

function ascii_formula_from_atoms(entries) { // Build an ASCII molecular formula suitable for database lookup.
  const counts = formula_counts_from_atoms(entries);
  return formula_order(counts).map((symbol) => `${symbol}${counts.get(symbol) === 1 ? "" : counts.get(symbol)}`).join("");
}

function normalize_ascii_formula(formula) { // Normalize a conventional formula into the same Hill ordering used for selected atoms.
  const counts = new Map();
  for (const match of formula.matchAll(/([A-Z][a-z]?)(\d*)/g)) {
    const symbol = match[1];
    const count = match[2] ? Number(match[2]) : 1;
    counts.set(symbol, (counts.get(symbol) || 0) + count);
  }
  return formula_order(counts).map((symbol) => `${symbol}${counts.get(symbol) === 1 ? "" : counts.get(symbol)}`).join("");
}

function pretty_formula_from_ascii(formula) { // Convert ordinary digits into chemistry-style Unicode subscripts for the UI.
  return formula.replace(/\d+/g, (digits) => subscript_number(Number(digits)));
}

function total_charge(entries) { // Sum formal charge from proton and electron totals.
  return entries.reduce((sum, entry) => sum + entry.protons - entry.electrons, 0);
}

function build_static_product_library() { // Combine campaign chemistry with a broader offline whitelist of real compounds.
  const library = new Map();
  for (const [formula, name] of EXTRA_REAL_PRODUCTS) {
    library.set(normalize_ascii_formula(formula), name);
  }
  for (const entry of NEUTRAL_LEVELS) {
    const definitions = entry.atom_keys.map((atom_key) => ATOMS[atom_key]);
    const key = ascii_formula_from_atoms(definitions);
    if (!library.has(key)) {
      library.set(key, entry.name);
    }
  }
  return library;
}

const STATIC_REAL_PRODUCTS = build_static_product_library();

function generic_product_layout(count) { // Arrange a manually created product compactly around its reaction centre.
  if (count <= 1) {
    return [[0, 0]];
  }
  if (count === 2) {
    return [[-58, 0], [58, 0]];
  }
  const radius = Math.min(155, 58 + count * 6);
  return Array.from({ length: count }, (_, index) => {
    const angle = -Math.PI / 2 + (index / count) * Math.PI * 2;
    return [Math.cos(angle) * radius, Math.sin(angle) * radius * 0.72];
  });
}

function generic_product_bonds(count) { // Draw a schematic connected product when exact structure data is unavailable.
  const bonds = [];
  for (let index = 1; index < count; index += 1) {
    bonds.push([index - 1, index, 1]);
  }
  return bonds;
}

async function pubchem_formula_exists(formula) { // Verify an otherwise unknown formula against PubChem when network access is available.
  if (PUBCHEM_CACHE.has(formula)) {
    return PUBCHEM_CACHE.get(formula);
  }
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 4500);
  try {
    const url = `https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/fastformula/${encodeURIComponent(formula)}/cids/JSON?MaxRecords=1`;
    const response = await fetch(url, { signal: controller.signal });
    if (!response.ok) {
      PUBCHEM_CACHE.set(formula, false);
      return false;
    }
    const data = await response.json();
    const exists = Array.isArray(data?.IdentifierList?.CID) && data.IdentifierList.CID.length > 0;
    PUBCHEM_CACHE.set(formula, exists);
    return exists;
  } catch {
    return null;
  } finally {
    clearTimeout(timeout);
  }
}
