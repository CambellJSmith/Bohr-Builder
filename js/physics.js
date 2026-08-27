"use strict";

function fire_particle(now) { // Launch one selected subatomic particle at the game's fixed skill-based speed.
  if (!game_mode || mode_prompt_open || reaction || freeplay_reaction || scrap_mode || freeplay_select_mode || freeplay_verifying || (molecule && game_mode !== "freeplay") || now - last_shot_time < 115) {
    return;
  }

  const targeted_atom = selected_particle === "proton" ? pick_atom_at(pointer.x, pointer.y) : null; // Treat a proton aimed anywhere inside an existing Bohr model as belonging to that atom.
  const dx = pointer.x - CANNON.x;
  const dy = pointer.y - CANNON.y;
  const length = Math.hypot(dx, dy);
  if (length < 8) {
    return;
  }

  const nx = dx / length;
  const ny = dy / length;
  const radius = selected_particle === "electron" ? 5 : 9;

  particles.push({
    kind: selected_particle,
    x: CANNON.x + nx * 34,
    y: CANNON.y + ny * 34,
    vx: nx * FIXED_LAUNCH_SPEED,
    vy: ny * FIXED_LAUNCH_SPEED,
    radius,
    age: 0,
    target_x: pointer.x,
    target_y: pointer.y,
    target_atom_id: targeted_atom ? targeted_atom.id : null,
    alive: true,
  });

  last_shot_time = now;
}

function create_atom_from_proton(particle) { // Turn an uncaptured proton into the seed nucleus of a new atom.
  const atom = {
    id: next_atom_id++,
    x: clamp(particle.x, 70, WIDTH - 70),
    y: clamp(particle.y, 70, HEIGHT - 110),
    vx: particle.vx * 0.08,
    vy: particle.vy * 0.08,
    protons: 1,
    neutrons: 0,
    electrons: 0,
    electron_phase: Math.random() * Math.PI * 2,
    pulse: 1,
  };
  atoms.push(atom);
  selected_atom_id = atom.id;
  set_status("new hydrogen nucleus started");
  update_inspector();
  update_freeplay_ui();
}

function nucleus_radius(atom) { // Compress large nuclei so every real element remains playable inside the Bohr diagram.
  return clamp(14 + Math.sqrt(Math.max(1, atom.protons + atom.neutrons)) * 1.25, 15, 38);
}

function next_electron_shell(atom) { // Return the principal Bohr shell that receives the next electron under Aufbau filling.
  if (atom.electrons >= MAX_ELECTRONS) {
    return SHELL_RADII.length - 1;
  }
  const before = electron_shell_distribution(atom.electrons);
  const after = electron_shell_distribution(atom.electrons + 1);
  for (let shell = 0; shell < after.length; shell += 1) {
    if ((after[shell] || 0) > (before[shell] || 0)) {
      return shell;
    }
  }
  return Math.max(0, after.length - 1);
}

function electron_shell_distribution(electron_total) { // Convert electron count into Bohr shells using orbital filling order.
  const total = clamp(Math.trunc(electron_total), 0, MAX_ELECTRONS);
  const distribution = Array(SHELL_RADII.length).fill(0);
  const orbitals = [[1,2],[2,2],[2,6],[3,2],[3,6],[4,2],[3,10],[4,6],[5,2],[4,10],[5,6],[6,2],[4,14],[5,10],[6,6],[7,2],[5,14],[6,10],[7,6],[8,2],[5,6]];
  let remaining = total;
  for (const [principal, capacity] of orbitals) {
    if (remaining <= 0) {
      break;
    }
    const placed = Math.min(capacity, remaining);
    distribution[principal - 1] += placed;
    remaining -= placed;
  }
  while (distribution.length > 1 && distribution[distribution.length - 1] === 0) {
    distribution.pop();
  }
  return distribution;
}

function capture_nucleon(particle, atom) { // Add a proton or neutron while keeping proton count inside the known periodic table.
  if (particle.kind === "proton" && atom.protons >= MAX_ATOMIC_NUMBER) {
    particle.vx *= -0.72;
    particle.vy *= -0.72;
    set_status("oganesson is element 118 — no known element has more protons");
    return false;
  }
  if (particle.kind === "proton") {
    atom.protons += 1;
  } else {
    atom.neutrons += 1;
  }
  atom.vx += particle.vx * 0.012;
  atom.vy += particle.vy * 0.012;
  atom.pulse = 1;
  selected_atom_id = atom.id;
  particle.alive = false;
  set_status(`${particle.kind} captured — nucleus is now ${element_symbol(atom.protons)}`);
  update_inspector();
  update_freeplay_ui();
  return true;
}

function capture_electron(particle, atom) { // Add an electron to the appropriate Bohr shell up to the supported ion limit.
  if (atom.electrons >= MAX_ELECTRONS) {
    particle.vx *= -0.72;
    particle.vy *= -0.72;
    set_status(`electron limit reached for this sandbox (${MAX_ELECTRONS})`);
    return false;
  }
  atom.electrons += 1;
  atom.pulse = 1;
  selected_atom_id = atom.id;
  particle.alive = false;
  set_status(`electron captured into shell ${shell_of_last_electron(atom)}`);
  update_inspector();
  update_freeplay_ui();
  return true;
}

function shell_of_last_electron(atom) { // Report the principal shell occupied by the most recently captured electron.
  if (atom.electrons <= 0) {
    return 1;
  }
  const before = electron_shell_distribution(atom.electrons - 1);
  const after = electron_shell_distribution(atom.electrons);
  for (let shell = 0; shell < after.length; shell += 1) {
    if ((after[shell] || 0) > (before[shell] || 0)) {
      return shell + 1;
    }
  }
  return after.length;
}

function apply_particle_forces(particle, dt) { // Apply simplified electrostatic attraction or repulsion around every nucleus.
  if (particle.kind === "neutron") {
    return;
  }

  for (const atom of atoms) {
    const dx = particle.x - atom.x;
    const dy = particle.y - atom.y;
    const dist_sq = Math.max(950, dx * dx + dy * dy);
    const dist = Math.sqrt(dist_sq);
    const direction = particle.kind === "proton" ? 1 : -1;
    const charge_strength = 98000 * Math.max(1, atom.protons);
    const acceleration = direction * charge_strength / dist_sq;
    particle.vx += (dx / dist) * acceleration * dt;
    particle.vy += (dy / dist) * acceleration * dt;
  }
}

function current_assist() { // Return campaign assistance or a stable freeplay capture tolerance.
  return game_mode === "freeplay" ? 1.0 : current_level().assist;
}

function update_particles(dt) { // Advance projectile motion, forces, wall collisions, and capture tests.
  const assist = current_assist();

  for (const particle of particles) {
    if (!particle.alive) {
      continue;
    }

    particle.age += dt;
    apply_particle_forces(particle, dt);
    particle.x += particle.vx * dt;
    particle.y += particle.vy * dt;

    if (particle.x < particle.radius || particle.x > WIDTH - particle.radius) {
      particle.x = clamp(particle.x, particle.radius, WIDTH - particle.radius);
      particle.vx *= -0.72;
    }
    if (particle.y < particle.radius || particle.y > HEIGHT - particle.radius) {
      particle.y = clamp(particle.y, particle.radius, HEIGHT - particle.radius);
      particle.vy *= -0.72;
    }

    let captured = false;
    for (const atom of atoms) {
      const dx = particle.x - atom.x;
      const dy = particle.y - atom.y;
      const distance = Math.hypot(dx, dy);
      const speed = Math.hypot(particle.vx, particle.vy);

      if (particle.kind === "electron") {
        const shell = next_electron_shell(atom);
        const shell_radius = SHELL_RADII[shell];
        const shell_error = Math.abs(distance - shell_radius);
        const max_capture_speed = 780 + 120 * (assist - 1) + atom.protons * 2.2;
        if (shell_error < 10 * assist && speed > 55 && speed < max_capture_speed) {
          capture_electron(particle, atom);
          captured = true;
          break;
        }
      } else {
        const capture_radius = nucleus_radius(atom) + particle.radius + 5 + (assist - 1) * 11;
        if (distance <= capture_radius) {
          capture_nucleon(particle, atom);
          captured = true;
          break;
        }
      }
    }

    if (!captured && particle.kind === "proton" && particle.target_atom_id !== null) {
      const target_atom = atoms.find((atom) => atom.id === particle.target_atom_id);
      if (target_atom) {
        const outer_shell = SHELL_RADII[Math.max(0, next_electron_shell(target_atom))] + 18;
        const distance_to_target_atom = Math.hypot(particle.x - target_atom.x, particle.y - target_atom.y);
        if (distance_to_target_atom <= outer_shell) {
          captured = capture_nucleon(particle, target_atom);
        }
      } else {
        particle.target_atom_id = null;
      }
    }

    if (!captured && particle.kind === "proton" && particle.target_atom_id === null && particle.age > 0.03) {
      const target_distance = Math.hypot(particle.x - particle.target_x, particle.y - particle.target_y);
      if (target_distance < 16 * assist) {
        create_atom_from_proton(particle);
        particle.alive = false;
      }
    }

    if (particle.age > 7.5) {
      particle.alive = false;
    }
  }

  particles = particles.filter((particle) => particle.alive);
}

function update_atoms(dt) { // Apply gentle damping and boundaries so atoms remain stable in the shared worldspace.
  for (const atom of atoms) {
    atom.x += atom.vx * dt;
    atom.y += atom.vy * dt;
    atom.vx *= Math.pow(0.12, dt);
    atom.vy *= Math.pow(0.12, dt);
    atom.pulse = Math.max(0, atom.pulse - dt * 2.2);

    const margin = SHELL_RADII[Math.min(SHELL_RADII.length - 1, next_electron_shell(atom))] + 14;
    if (atom.x < margin) {
      atom.x = margin;
      atom.vx = Math.abs(atom.vx) * 0.3;
    }
    if (atom.x > WIDTH - margin) {
      atom.x = WIDTH - margin;
      atom.vx = -Math.abs(atom.vx) * 0.3;
    }
    if (atom.y < margin) {
      atom.y = margin;
      atom.vy = Math.abs(atom.vy) * 0.3;
    }
    if (atom.y > HEIGHT - 90 - margin) {
      atom.y = HEIGHT - 90 - margin;
      atom.vy = -Math.abs(atom.vy) * 0.3;
    }
  }
}
