"use strict";

function atom_matches(atom, atom_key) { // Test whether a world atom exactly matches one requested isotope and neutral electron count.
  const required = ATOMS[atom_key];
  return atom.protons === required.protons && atom.neutrons === required.neutrons && atom.electrons === required.electrons;
}

function requirement_groups() { // Collapse repeated atom requirements into concise counters for the side panel.
  const groups = new Map();
  for (const atom_key of current_level().atom_keys) {
    groups.set(atom_key, (groups.get(atom_key) || 0) + 1);
  }
  return Array.from(groups.entries()).map(([atom_key, count]) => ({ atom_key, count }));
}

function find_reactants() { // Select a unique completed world atom for every ordered atom required by the current molecule layout.
  const used = new Set();
  const reactants = [];

  for (const atom_key of current_level().atom_keys) {
    const atom = atoms.find((entry) => !used.has(entry.id) && atom_matches(entry, atom_key));
    if (!atom) {
      return null;
    }
    used.add(atom.id);
    reactants.push(atom);
  }
  return reactants;
}

function check_reaction_ready() { // Start the automatic campaign reaction when every requested species exists.
  if (game_mode === "freeplay" || reaction || molecule) {
    return;
  }

  const reactants = find_reactants();
  if (!reactants) {
    return;
  }

  reaction = {
    elapsed: 0,
    duration: 2.35,
    ids: reactants.map((atom) => atom.id),
    starts: reactants.map((atom) => ({ x: atom.x, y: atom.y })),
  };
  particles = [];
  selected_atom_id = null;
  set_status("reaction ready — atoms are combining", 0);
  update_inspector();
}

function reaction_world_targets() { // Convert the current molecule's local layout coordinates into world positions around the workspace center.
  const cx = WIDTH * 0.5;
  const cy = HEIGHT * 0.42;
  return current_level().layout.map(([x, y]) => ({ x: cx + x, y: cy + y }));
}

function update_reaction(dt) { // Animate all selected reactants into the target molecule inside the same worldspace.
  if (!reaction) {
    return;
  }

  reaction.elapsed += dt;
  const t = clamp(reaction.elapsed / reaction.duration, 0, 1);
  const eased = 1 - Math.pow(1 - t, 3);
  const targets = reaction_world_targets();

  for (let i = 0; i < reaction.ids.length; i += 1) {
    const atom = atoms.find((entry) => entry.id === reaction.ids[i]);
    if (!atom) {
      continue;
    }
    atom.x = lerp(reaction.starts[i].x, targets[i].x, eased);
    atom.y = lerp(reaction.starts[i].y, targets[i].y, eased);
    atom.vx = 0;
    atom.vy = 0;
  }

  if (t >= 1) {
    const reactant_set = new Set(reaction.ids);
    atoms = atoms.filter((atom) => !reactant_set.has(atom.id));
    molecule = { x: WIDTH * 0.5, y: HEIGHT * 0.42 };
    reaction = null;
    complete_level();
  }
}

function complete_level() { // Mark the campaign level complete, unlock the next target, and expose progression controls.
  if (current_level_index < LEVELS.length - 1) {
    unlocked_level = Math.max(unlocked_level, current_level_index + 1);
    save_unlocked_level();
    populate_level_select();
    next_button.hidden = false;
    set_status(`${current_level().formula} formed — level complete — next level unlocked`, 0);
  } else {
    next_button.hidden = true;
    set_status(`${current_level().formula} formed — campaign complete`, 0);
  }
  update_requirement_ui();
}
