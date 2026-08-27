"use strict";

function update_requirement_ui() { // Rebuild the reactant checklist only in guided mode and only when displayed counts change.
  if (game_mode !== "guided") {
    requirement_signature = "";
    requirement_list.innerHTML = "";
    return;
  }

  const groups = requirement_groups();
  const rows = groups.map((requirement) => {
    const valid_count = atoms.filter((atom) => atom_matches(atom, requirement.atom_key)).length;
    return { ...requirement, valid_count: Math.min(valid_count, requirement.count) };
  });
  const next_signature = `${current_level_index}|${rows.map((row) => `${row.atom_key}:${row.valid_count}/${row.count}`).join("|")}|${molecule ? "done" : "active"}`;
  if (next_signature === requirement_signature) {
    return;
  }

  requirement_signature = next_signature;
  requirement_list.innerHTML = "";
  for (const row_data of rows) {
    const row = document.createElement("div");
    row.className = "requirement_row";
    row.innerHTML = `<span>${ATOMS[row_data.atom_key].label}</span><strong>${row_data.valid_count} / ${row_data.count}</strong>`;
    requirement_list.appendChild(row);
  }
}

function isotope_label(atom) { // Return the most specific campaign label for a neutral atom or ion.
  for (const definition of Object.values(ATOMS)) {
    if (atom.protons === definition.protons && atom.neutrons === definition.neutrons && atom.electrons === definition.electrons) {
      return definition.label;
    }
  }
  return `${element_name(atom.protons)}-${atom.protons + atom.neutrons}`;
}

function update_inspector() { // Show the selected species identity, isotope, charge, and particle totals.
  const atom = atoms.find((entry) => entry.id === selected_atom_id);
  if (!atom) {
    inspector.className = "inspector_empty";
    inspector.textContent = game_mode === "freeplay" ? "select or right-click an atom or ion to inspect it" : molecule ? "reaction complete" : "select an atom to inspect it";
    return;
  }
  const charge = atom.protons - atom.electrons;
  const mass_number = atom.protons + atom.neutrons;
  const charge_text = charge === 0 ? "neutral" : charge > 0 ? `+${charge}` : `${charge}`;
  const notation = `${element_symbol(atom.protons)}${superscript_charge(charge)}`;
  inspector.className = "inspector_card";
  inspector.innerHTML = `
    <div class="inspector_name"><strong>${isotope_label(atom)}</strong><span>${notation}</span></div>
    <div class="inspector_row"><span>element</span><strong>${element_name(atom.protons)}</strong></div>
    <div class="inspector_row"><span>atomic_number</span><strong>${atom.protons}</strong></div>
    <div class="inspector_row"><span>protons</span><strong>${atom.protons}</strong></div>
    <div class="inspector_row"><span>neutrons</span><strong>${atom.neutrons}</strong></div>
    <div class="inspector_row"><span>electrons</span><strong>${atom.electrons}</strong></div>
    <div class="inspector_row"><span>mass_number</span><strong>${mass_number}</strong></div>
    <div class="inspector_row"><span>charge</span><strong>${charge_text}</strong></div>
  `;
}

function pick_atom_at(x, y) { // Return the topmost atom whose Bohr model is under the pointer.
  for (let i = atoms.length - 1; i >= 0; i -= 1) {
    const atom = atoms[i];
    const outer_shell = SHELL_RADII[Math.max(0, next_electron_shell(atom))];
    if (Math.hypot(x - atom.x, y - atom.y) <= outer_shell + 18) {
      return atom;
    }
  }
  return null;
}
