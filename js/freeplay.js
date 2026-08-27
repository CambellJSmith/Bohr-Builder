"use strict";

function selected_freeplay_atoms() { // Resolve the current freeplay selection to live atoms only.
  return atoms.filter((atom) => freeplay_selected_ids.has(atom.id));
}

function update_freeplay_ui() { // Keep manual reaction controls synchronized with the current selection.
  if (!freeplay_selection || game_mode !== "freeplay") {
    return;
  }
  for (const id of Array.from(freeplay_selected_ids)) {
    if (!atoms.some((atom) => atom.id === id)) {
      freeplay_selected_ids.delete(id);
    }
  }
  const selected = selected_freeplay_atoms();
  if (selected.length === 0) {
    freeplay_selection.textContent = "no reactants selected";
  } else {
    const formula = pretty_formula_from_ascii(ascii_formula_from_atoms(selected));
    const charge = total_charge(selected);
    const charge_text = charge === 0 ? "neutral total" : `net charge ${charge > 0 ? "+" : ""}${charge}`;
    freeplay_selection.innerHTML = `<strong>${formula}</strong><br>${selected.length} selected species · ${charge_text}`;
  }
  react_button.disabled = selected.length < 2 || Boolean(freeplay_reaction) || freeplay_verifying;
  clear_reactants_button.disabled = selected.length === 0 || Boolean(freeplay_reaction) || freeplay_verifying;
  react_select_button.disabled = Boolean(freeplay_reaction) || freeplay_verifying;
}

function toggle_freeplay_reactant(atom) { // Add or remove one atom or ion from the manual reaction set.
  if (freeplay_selected_ids.has(atom.id)) {
    freeplay_selected_ids.delete(atom.id);
  } else {
    freeplay_selected_ids.add(atom.id);
  }
  selected_atom_id = atom.id;
  update_inspector();
  update_freeplay_ui();
}

function start_freeplay_reaction(selected, formula, name) { // Begin a deterministic in-world merge after a real product has been validated.
  const cx = clamp(selected.reduce((sum, atom) => sum + atom.x, 0) / selected.length, 220, WIDTH - 220);
  const cy = clamp(selected.reduce((sum, atom) => sum + atom.y, 0) / selected.length, 190, HEIGHT - 220);
  const snapshots = selected.map((atom) => ({
    protons: atom.protons,
    neutrons: atom.neutrons,
    electrons: atom.electrons,
    symbol: element_symbol(atom.protons),
  }));
  const layout = generic_product_layout(selected.length);
  freeplay_reaction = {
    elapsed: 0,
    duration: 2.1,
    ids: selected.map((atom) => atom.id),
    starts: selected.map((atom) => ({ x: atom.x, y: atom.y })),
    cx,
    cy,
    formula,
    name,
    snapshots,
    layout,
    bonds: generic_product_bonds(selected.length),
  };
  freeplay_selected_ids.clear();
  freeplay_select_mode = false;
  react_select_button.classList.remove("active");
  react_select_button.textContent = "select_reactants";
  particles = [];
  selected_atom_id = null;
  set_status(`${pretty_formula_from_ascii(formula)} validated — reacting`, 0);
  update_freeplay_ui();
  update_inspector();
}

async function attempt_freeplay_reaction() { // Validate selected composition and only create a product known to exist.
  if (game_mode !== "freeplay" || freeplay_reaction || freeplay_verifying) {
    return;
  }
  const selected = selected_freeplay_atoms();
  if (selected.length < 2) {
    set_status("select at least two atoms or ions first");
    return;
  }
  const charge = total_charge(selected);
  if (charge !== 0) {
    set_status(`reaction rejected — selected reactants have net charge ${charge > 0 ? "+" : ""}${charge}`);
    return;
  }
  const formula = ascii_formula_from_atoms(selected);
  const offline_name = STATIC_REAL_PRODUCTS.get(formula);
  if (offline_name) {
    start_freeplay_reaction(selected, formula, offline_name);
    return;
  }

  freeplay_select_mode = false;
  react_select_button.classList.remove("active");
  react_select_button.textContent = "select_reactants";
  freeplay_verifying = true;
  update_freeplay_ui();
  set_status(`checking ${pretty_formula_from_ascii(formula)} against PubChem…`, 0);
  const verified = await pubchem_formula_exists(formula);
  freeplay_verifying = false;
  update_freeplay_ui();
  if (verified === true) {
    start_freeplay_reaction(selected_freeplay_atoms(), formula, "pubchem_verified_compound");
  } else if (verified === null) {
    set_status(`${pretty_formula_from_ascii(formula)} is not in the offline library and online verification is unavailable`, 3200);
  } else {
    set_status(`reaction rejected — no PubChem compound found for ${pretty_formula_from_ascii(formula)}`, 3200);
  }
}

function update_freeplay_reaction(dt) { // Animate selected freeplay species into a retained product without ending the sandbox.
  if (!freeplay_reaction) {
    return;
  }
  freeplay_reaction.elapsed += dt;
  const t = clamp(freeplay_reaction.elapsed / freeplay_reaction.duration, 0, 1);
  const eased = 1 - Math.pow(1 - t, 3);
  for (let i = 0; i < freeplay_reaction.ids.length; i += 1) {
    const atom = atoms.find((entry) => entry.id === freeplay_reaction.ids[i]);
    if (!atom) {
      continue;
    }
    const [lx, ly] = freeplay_reaction.layout[i];
    atom.x = lerp(freeplay_reaction.starts[i].x, freeplay_reaction.cx + lx, eased);
    atom.y = lerp(freeplay_reaction.starts[i].y, freeplay_reaction.cy + ly, eased);
    atom.vx = 0;
    atom.vy = 0;
  }
  if (t >= 1) {
    const consumed = new Set(freeplay_reaction.ids);
    atoms = atoms.filter((atom) => !consumed.has(atom.id));
    freeplay_molecules.push({
      x: freeplay_reaction.cx,
      y: freeplay_reaction.cy,
      formula: freeplay_reaction.formula,
      name: freeplay_reaction.name,
      snapshots: freeplay_reaction.snapshots,
      layout: freeplay_reaction.layout,
      bonds: freeplay_reaction.bonds,
    });
    const formed = pretty_formula_from_ascii(freeplay_reaction.formula);
    freeplay_reaction = null;
    set_status(`${formed} formed — freeplay continues`, 2500);
    update_freeplay_ui();
  }
}
