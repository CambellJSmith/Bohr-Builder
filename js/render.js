"use strict";

function draw_background() { // Draw the restrained grid and playfield boundaries used for aiming.
  ctx.fillStyle = "#111317";
  ctx.fillRect(0, 0, WIDTH, HEIGHT);

  ctx.strokeStyle = "rgba(255,255,255,0.035)";
  ctx.lineWidth = 1;
  for (let x = 0; x <= WIDTH; x += 50) {
    ctx.beginPath();
    ctx.moveTo(x, 0);
    ctx.lineTo(x, HEIGHT);
    ctx.stroke();
  }
  for (let y = 0; y <= HEIGHT; y += 50) {
    ctx.beginPath();
    ctx.moveTo(0, y);
    ctx.lineTo(WIDTH, y);
    ctx.stroke();
  }

  ctx.strokeStyle = "rgba(255,255,255,0.08)";
  ctx.beginPath();
  ctx.moveTo(0, HEIGHT - 78);
  ctx.lineTo(WIDTH, HEIGHT - 78);
  ctx.stroke();
}

function draw_aim_assist() { // Highlight valid capture areas, with stronger guidance on the earliest levels.
  if (reaction || freeplay_reaction || (molecule && game_mode !== "freeplay") || scrap_mode || freeplay_select_mode) {
    return;
  }

  const assist = current_assist();
  const alpha = 0.08 + (assist - 1) * 0.2;
  for (const atom of atoms) {
    if (selected_particle === "electron") {
      const shell = next_electron_shell(atom);
      ctx.beginPath();
      ctx.arc(atom.x, atom.y, SHELL_RADII[shell], 0, Math.PI * 2);
      ctx.strokeStyle = `rgba(85,127,199,${clamp(alpha, 0.08, 0.26)})`;
      ctx.lineWidth = current_level_index === 0 ? 5 : 3;
      ctx.stroke();
    } else {
      ctx.beginPath();
      ctx.arc(atom.x, atom.y, nucleus_radius(atom) + 12, 0, Math.PI * 2);
      ctx.strokeStyle = `rgba(220,226,232,${clamp(alpha * 0.8, 0.06, 0.2)})`;
      ctx.lineWidth = 2;
      ctx.stroke();
    }
  }
}

function draw_cannon() { // Draw the cannon and current aim direction at the bottom of the workspace.
  if (molecule && game_mode !== "freeplay") {
    return;
  }

  const dx = pointer.x - CANNON.x;
  const dy = pointer.y - CANNON.y;
  const length = Math.max(1, Math.hypot(dx, dy));
  const nx = dx / length;
  const ny = dy / length;

  ctx.save();
  ctx.strokeStyle = "rgba(114, 171, 214, 0.5)";
  ctx.setLineDash([7, 8]);
  ctx.beginPath();
  ctx.moveTo(CANNON.x + nx * 35, CANNON.y + ny * 35);
  ctx.lineTo(pointer.x, pointer.y);
  ctx.stroke();
  ctx.setLineDash([]);

  if (selected_particle === "proton" && atoms.length === 0) {
    ctx.beginPath();
    ctx.arc(pointer.x, pointer.y, 19, 0, Math.PI * 2);
    ctx.strokeStyle = "rgba(200,92,92,0.5)";
    ctx.stroke();
  }

  ctx.translate(CANNON.x, CANNON.y);
  ctx.rotate(Math.atan2(dy, dx));
  ctx.fillStyle = "#464c54";
  ctx.fillRect(0, -8, 48, 16);
  ctx.fillStyle = "#2c3036";
  ctx.beginPath();
  ctx.arc(0, 0, 24, 0, Math.PI * 2);
  ctx.fill();
  ctx.strokeStyle = "#5b626c";
  ctx.stroke();
  ctx.restore();
}

function draw_particle(particle) { // Draw one moving proton, neutron, or electron projectile.
  const fill = particle.kind === "proton" ? "#c85c5c" : particle.kind === "neutron" ? "#777f89" : "#557fc7";
  const label = particle.kind === "proton" ? "p+" : particle.kind === "neutron" ? "n" : "e−";
  ctx.beginPath();
  ctx.arc(particle.x, particle.y, particle.radius, 0, Math.PI * 2);
  ctx.fillStyle = fill;
  ctx.fill();
  ctx.fillStyle = "#f7f8fa";
  ctx.font = `${particle.kind === "electron" ? 8 : 9}px system-ui`;
  ctx.textAlign = "center";
  ctx.textBaseline = "middle";
  ctx.fillText(label, particle.x, particle.y + 0.5);
}

function draw_atom(atom, now) { // Render an interactive Bohr-model atom with nucleus, shells, and orbiting electrons.
  const selected = atom.id === selected_atom_id;
  const reaction_selected = game_mode === "freeplay" && freeplay_selected_ids.has(atom.id);
  const shell_distribution = electron_shell_distribution(atom.electrons);
  const shell_count = Math.max(1, shell_distribution.length);

  ctx.save();
  ctx.translate(atom.x, atom.y);

  if (selected || reaction_selected) {
    ctx.beginPath();
    ctx.arc(0, 0, SHELL_RADII[Math.min(shell_count - 1, SHELL_RADII.length - 1)] + 16, 0, Math.PI * 2);
    ctx.strokeStyle = scrap_mode ? "rgba(201,106,106,0.85)" : reaction_selected ? "rgba(211,174,77,0.95)" : "rgba(77,154,211,0.85)";
    ctx.lineWidth = reaction_selected ? 3 : 2;
    ctx.stroke();
  }

  for (let shell = 0; shell < shell_count; shell += 1) {
    ctx.beginPath();
    ctx.arc(0, 0, SHELL_RADII[shell], 0, Math.PI * 2);
    ctx.strokeStyle = "rgba(173,184,195,0.32)";
    ctx.lineWidth = 1.25;
    ctx.stroke();
  }

  const nucleon_total = atom.protons + atom.neutrons;
  const n_radius = nucleus_radius(atom);
  if (atom.pulse > 0) {
    ctx.beginPath();
    ctx.arc(0, 0, n_radius + atom.pulse * 12, 0, Math.PI * 2);
    ctx.strokeStyle = `rgba(255,255,255,${atom.pulse * 0.2})`;
    ctx.stroke();
  }

  for (let i = 0; i < nucleon_total; i += 1) {
    const is_proton = i < atom.protons;
    const angle = i * 2.3999632297;
    const dot_radius = clamp(6.5 - nucleon_total * 0.018, 2.15, 6.5);
    const radial = Math.sqrt(i) * dot_radius * 0.82;
    ctx.beginPath();
    ctx.arc(Math.cos(angle) * radial, Math.sin(angle) * radial, dot_radius, 0, Math.PI * 2);
    ctx.fillStyle = is_proton ? "#c85c5c" : "#777f89";
    ctx.fill();
  }

  let electron_index = 0;
  for (let shell = 0; shell < shell_distribution.length; shell += 1) {
    const count = shell_distribution[shell];
    for (let index = 0; index < count; index += 1) {
      const angular_speed = 0.0006 + shell * 0.00015;
      const angle = atom.electron_phase + now * angular_speed + (index / Math.max(1, count)) * Math.PI * 2 + electron_index * 0.11;
      const x = Math.cos(angle) * SHELL_RADII[shell];
      const y = Math.sin(angle) * SHELL_RADII[shell];
      ctx.beginPath();
      ctx.arc(x, y, 5.2, 0, Math.PI * 2);
      ctx.fillStyle = "#557fc7";
      ctx.fill();
      electron_index += 1;
    }
  }

  ctx.fillStyle = "#edf0f3";
  ctx.font = "600 13px system-ui";
  ctx.textAlign = "center";
  ctx.textBaseline = "middle";
  const atom_symbol = element_symbol(atom.protons);
  ctx.fillText(atom_symbol, 0, n_radius + 17);
  const atom_charge = atom.protons - atom.electrons;
  if (atom_charge !== 0) {
    ctx.fillStyle = "rgba(237,240,243,0.88)";
    ctx.font = "700 10px system-ui";
    ctx.textAlign = "left";
    ctx.fillText(superscript_charge(atom_charge), Math.max(8, atom_symbol.length * 5), n_radius + 12);
  }
  ctx.restore();
}

function draw_bond_between(a, b, order, alpha = 0.78) { // Draw a single, double, or triple molecular bond between two world positions.
  const dx = b.x - a.x;
  const dy = b.y - a.y;
  const length = Math.max(1, Math.hypot(dx, dy));
  const nx = -dy / length;
  const ny = dx / length;
  const offsets = order === 3 ? [-8, 0, 8] : order === 2 ? [-5, 5] : [0];

  ctx.strokeStyle = `rgba(230,234,239,${alpha})`;
  ctx.lineWidth = order === 1 ? 5 : 3.5;
  for (const offset of offsets) {
    ctx.beginPath();
    ctx.moveTo(a.x + nx * offset, a.y + ny * offset);
    ctx.lineTo(b.x + nx * offset, b.y + ny * offset);
    ctx.stroke();
  }
}

function draw_reaction_bonds() { // Fade in the current level's real bond pattern as reactants converge.
  if (!reaction) {
    return;
  }

  const entries = reaction.ids.map((id) => atoms.find((atom) => atom.id === id));
  if (entries.some((atom) => !atom)) {
    return;
  }

  const strength = clamp((reaction.elapsed / reaction.duration - 0.45) / 0.4, 0, 1);
  if (strength <= 0) {
    return;
  }

  for (const [a_index, b_index, order] of current_level().bonds) {
    draw_bond_between(entries[a_index], entries[b_index], order, 0.8 * strength);
  }
}

function molecule_atom_radius(atom_key) { // Scale the finished molecule's atom circles by element while keeping the diagram readable.
  const proton_count = ATOMS[atom_key].protons;
  return clamp(28 + Math.sqrt(proton_count) * 5, 32, 49);
}

function draw_molecule(now) { // Render the completed level molecule from the same layout and bond data used by the reaction.
  if (!molecule) {
    return;
  }

  const bob = Math.sin(now * 0.0016) * 4;
  const positions = current_level().layout.map(([x, y]) => ({ x: molecule.x + x, y: molecule.y + y + bob }));

  for (const [a_index, b_index, order] of current_level().bonds) {
    draw_bond_between(positions[a_index], positions[b_index], order, 0.76);
  }

  current_level().atom_keys.forEach((atom_key, index) => {
    draw_molecule_atom(positions[index].x, positions[index].y, atom_key, now, index * 0.73);
  });

  ctx.fillStyle = "rgba(237,240,243,0.92)";
  ctx.font = "600 20px system-ui";
  ctx.textAlign = "center";
  ctx.fillText(current_level().formula, molecule.x, molecule.y + 185);
  if (game_mode === "guided") {
    ctx.fillStyle = "rgba(157,165,174,0.95)";
    ctx.font = "13px system-ui";
    ctx.fillText(current_level().name.replaceAll("_", " "), molecule.x, molecule.y + 208);
  }
}

function draw_molecule_atom(x, y, atom_key, now, phase) { // Draw one identifiable atomic center retained inside the finished molecule.
  const definition = ATOMS[atom_key];
  const radius = molecule_atom_radius(atom_key);
  const symbol = definition.display_symbol;
  const fill = definition.protons === 1 ? "#4d5661" : definition.protons === 8 ? "#934848" : definition.protons === 7 ? "#596b91" : definition.protons === 6 ? "#3f444b" : definition.protons === 9 ? "#527b64" : definition.protons === 16 ? "#8c7749" : definition.protons === 17 ? "#547b5d" : "#59616b";

  ctx.beginPath();
  ctx.arc(x, y, radius, 0, Math.PI * 2);
  ctx.fillStyle = fill;
  ctx.fill();
  ctx.strokeStyle = "rgba(255,255,255,0.18)";
  ctx.stroke();

  const valence_count = valence_electrons(definition.electrons);
  for (let i = 0; i < valence_count; i += 1) {
    const angle = now * 0.00035 + phase + (i / Math.max(1, valence_count)) * Math.PI * 2;
    const rr = radius + 13;
    ctx.beginPath();
    ctx.arc(x + Math.cos(angle) * rr, y + Math.sin(angle) * rr, 3.8, 0, Math.PI * 2);
    ctx.fillStyle = "#557fc7";
    ctx.fill();
  }

  ctx.fillStyle = "#f5f6f7";
  ctx.font = `700 ${symbol.length > 1 ? 17 : 22}px system-ui`;
  ctx.textAlign = "center";
  ctx.textBaseline = "middle";
  ctx.fillText(symbol, x, y);

  const charge = definition.protons - definition.electrons;
  if (charge !== 0) {
    ctx.fillStyle = "rgba(245,246,247,0.92)";
    ctx.font = "700 12px system-ui";
    ctx.textAlign = "left";
    ctx.fillText(superscript_charge(charge), x + radius * 0.45, y - radius * 0.52);
  }
}

function draw_freeplay_reaction_bonds() { // Fade schematic bonds in while selected freeplay reactants converge.
  if (!freeplay_reaction) {
    return;
  }
  const entries = freeplay_reaction.ids.map((id) => atoms.find((atom) => atom.id === id));
  if (entries.some((atom) => !atom)) {
    return;
  }
  const strength = clamp((freeplay_reaction.elapsed / freeplay_reaction.duration - 0.45) / 0.4, 0, 1);
  for (const [a_index, b_index, order] of freeplay_reaction.bonds) {
    draw_bond_between(entries[a_index], entries[b_index], order, 0.72 * strength);
  }
}

function draw_freeplay_product_atom(x, y, snapshot) { // Draw one element centre inside a retained freeplay product.
  const radius = clamp(25 + Math.sqrt(snapshot.protons) * 3.4, 29, 46);
  const symbol = element_symbol(snapshot.protons);
  ctx.beginPath();
  ctx.arc(x, y, radius, 0, Math.PI * 2);
  ctx.fillStyle = snapshot.protons === 1 ? "#4d5661" : snapshot.protons === 8 ? "#934848" : snapshot.protons === 7 ? "#596b91" : snapshot.protons === 6 ? "#3f444b" : "#59616b";
  ctx.fill();
  ctx.strokeStyle = "rgba(255,255,255,0.18)";
  ctx.stroke();
  ctx.fillStyle = "#f5f6f7";
  ctx.font = `700 ${symbol.length > 1 ? 15 : 20}px system-ui`;
  ctx.textAlign = "center";
  ctx.textBaseline = "middle";
  ctx.fillText(symbol, x, y);
}

function draw_freeplay_molecules(now) { // Keep every manually formed freeplay product visible while the player continues building.
  for (const product of freeplay_molecules) {
    const bob = Math.sin(now * 0.0014 + product.x * 0.01) * 2.5;
    const positions = product.layout.map(([x, y]) => ({ x: product.x + x, y: product.y + y + bob }));
    for (const [a_index, b_index, order] of product.bonds) {
      draw_bond_between(positions[a_index], positions[b_index], order, 0.58);
    }
    product.snapshots.forEach((snapshot, index) => draw_freeplay_product_atom(positions[index].x, positions[index].y, snapshot));
    const max_y = Math.max(...positions.map((position) => position.y));
    ctx.fillStyle = "rgba(237,240,243,0.9)";
    ctx.font = "600 17px system-ui";
    ctx.textAlign = "center";
    ctx.fillText(pretty_formula_from_ascii(product.formula), product.x, max_y + 48);
    ctx.fillStyle = "rgba(157,165,174,0.92)";
    ctx.font = "11px system-ui";
    ctx.fillText(product.name.replaceAll("_", " "), product.x, max_y + 66);
  }
}

function valence_electrons(electron_total) { // Return the population of the atom's outer occupied simplified Bohr shell.
  const distribution = electron_shell_distribution(electron_total);
  return distribution.length > 0 ? distribution[distribution.length - 1] : 0;
}

function render(now) { // Draw the complete current simulation state in worldspace.
  draw_background();
  draw_aim_assist();
  draw_cannon();
  draw_reaction_bonds();
  draw_freeplay_reaction_bonds();
  for (const atom of atoms) {
    draw_atom(atom, now);
  }
  for (const particle of particles) {
    draw_particle(particle);
  }
  draw_molecule(now);
  draw_freeplay_molecules(now);
}

function tick(now) { // Run the browser animation loop and update all simulation systems.
  const dt = Math.min(0.025, (now - last_time) / 1000);
  last_time = now;
  if (!mode_prompt_open) {
    if (game_mode === "freeplay") {
      if (freeplay_reaction) {
        update_freeplay_reaction(dt);
      } else {
        update_particles(dt);
        update_atoms(dt);
      }
    } else if (!reaction && !molecule) {
      update_particles(dt);
      update_atoms(dt);
      check_reaction_ready();
    } else if (reaction) {
      update_reaction(dt);
    }
    if (pointer.down) {
      fire_particle(now);
    }
  }
  if (status_timeout > 0 && now >= status_timeout) {
    status_timeout = 0;
    status_banner.textContent = game_mode === "freeplay" ? level_default_status() : molecule ? `${current_level().formula} formed — level complete` : level_default_status();
  }
  update_requirement_ui();
  update_freeplay_ui();
  render(now);
  requestAnimationFrame(tick);
}

function element_symbol(protons) { // Convert proton count into an element symbol for the supported campaign elements.
  return ELEMENTS[protons] || `Z${protons}`;
}

function element_name(protons) { // Convert proton count into the official element name for all 118 known elements.
  const symbol = element_symbol(protons);
  return ELEMENT_NAME_BY_SYMBOL.get(symbol) || ELEMENT_NAMES[protons] || `element ${protons}`;
}

function clamp(value, min, max) { // Constrain a numeric value to a closed range.
  return Math.max(min, Math.min(max, value));
}

function lerp(a, b, t) { // Interpolate smoothly between two scalar values.
  return a + (b - a) * t;
}
