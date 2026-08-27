"use strict";

let selected_particle = "proton";
let particles = [];
let atoms = [];
let molecule = null;
let selected_atom_id = null;
let scrap_mode = false;
let pointer = { x: WIDTH * 0.5, y: HEIGHT * 0.4, down: false };
let last_time = performance.now();
let last_shot_time = 0;
let reaction = null;
let next_atom_id = 1;
let status_timeout = 0;
let current_level_index = 0;
let unlocked_level = read_unlocked_level();
let requirement_signature = "";
let game_mode = null;
let mode_prompt_open = true;
let freeplay_select_mode = false;
let freeplay_selected_ids = new Set();
let freeplay_reaction = null;
let freeplay_molecules = [];
let freeplay_verifying = false;

function level(title, formula, name, equation, lesson, atom_keys, layout, bonds, assist, chemistry = "neutral") { // Build one immutable data-driven campaign level definition.
  return { title, formula, name, equation, lesson, atom_keys, layout, bonds, assist, chemistry };
}

function read_unlocked_level() { // Restore campaign progress while safely falling back when browser storage is unavailable.
  try {
    const stored = Number(localStorage.getItem("bohr_builder_unlocked_level"));
    return Number.isInteger(stored) && stored >= 0 ? stored : 0;
  } catch {
    return 0;
  }
}

function save_unlocked_level() { // Persist the highest unlocked campaign level without making storage mandatory.
  try {
    localStorage.setItem("bohr_builder_unlocked_level", String(unlocked_level));
  } catch {
    // Storage is optional; gameplay continues without persistence.
  }
}

function populate_level_select() { // Build the campaign selector while respecting how much target information the selected mode reveals.
  level_select.innerHTML = "";
  LEVELS.forEach((entry, index) => {
    const option = document.createElement("option");
    option.value = String(index);
    const prefix = String(index + 1).padStart(2, "0");
    option.textContent = game_mode === "formula_only" ? `${prefix} — ${entry.formula}` : `${prefix} — ${entry.formula} — ${entry.name.replaceAll("_", " ")}`;
    option.disabled = index > unlocked_level;
    level_select.appendChild(option);
  });
  level_select.value = String(current_level_index);
}

function load_level(index) { // Switch to an unlocked campaign level and restore a clean workspace.
  current_level_index = clamp(Math.trunc(index), 0, Math.min(unlocked_level, LEVELS.length - 1));
  populate_level_select();
  update_level_ui();
  reset_game();
}

function open_mode_overlay() { // Pause interaction and show the two information modes without changing the current level state.
  pointer.down = false;
  mode_prompt_open = true;
  mode_overlay.hidden = false;
}

function set_game_mode(mode) { // Apply campaign information rules or switch into the open freeplay sandbox.
  if (mode !== "guided" && mode !== "formula_only" && mode !== "freeplay") {
    return;
  }
  game_mode = mode;
  mode_prompt_open = false;
  mode_overlay.hidden = true;
  mode_badge.textContent = mode;
  document.body.classList.toggle("formula_only", mode === "formula_only");
  document.body.classList.toggle("freeplay", mode === "freeplay");
  for (const element of guided_only_elements) {
    element.hidden = mode !== "guided";
  }
  for (const element of campaign_only_elements) {
    element.hidden = mode === "freeplay";
  }
  for (const element of freeplay_only_elements) {
    element.hidden = mode !== "freeplay";
  }
  requirement_signature = "";
  populate_level_select();
  update_level_ui();
  reset_game();
}

function reset_game() { // Restore the current campaign level or clear the freeplay workspace.
  particles = [];
  atoms = [];
  molecule = null;
  selected_atom_id = null;
  reaction = null;
  freeplay_reaction = null;
  freeplay_molecules = [];
  freeplay_selected_ids.clear();
  freeplay_select_mode = false;
  freeplay_verifying = false;
  next_atom_id = 1;
  scrap_mode = false;
  pointer.down = false;
  scrap_button.classList.remove("active");
  scrap_button.textContent = "scrap_mode";
  react_select_button.classList.remove("active");
  react_select_button.textContent = "select_reactants";
  reset_button.textContent = game_mode === "freeplay" ? "clear_workspace" : "reset_level";
  next_button.hidden = true;
  requirement_signature = "";
  set_status(level_default_status(), 0);
  update_requirement_ui();
  update_inspector();
  update_freeplay_ui();
}

function update_level_ui() { // Refresh campaign metadata while withholding recipe information in formula-only mode.
  const entry = current_level();
  level_number.textContent = `level_${String(current_level_index + 1).padStart(2, "0")}`;
  level_title.textContent = game_mode === "formula_only" ? "formula_challenge" : entry.title;
  level_progress.textContent = `${current_level_index + 1} / ${LEVELS.length}`;
  level_lesson.textContent = entry.lesson;
  target_formula.textContent = entry.formula;
  target_name.textContent = entry.name.replaceAll("_", " ");
  reaction_equation.textContent = entry.equation;
  if (requirement_hint) {
    requirement_hint.textContent = current_level_index < 50
      ? "atoms count only when proton, neutron and electron totals match the requested neutral isotope."
      : "ions count only when proton, neutron and electron totals match the requested isotope and ionic charge.";
  }
  document.title = game_mode === "freeplay" ? "bohr_builder — freeplay" : `bohr_builder — ${entry.formula}`;
}

function current_level() { // Return the active campaign level definition.
  return LEVELS[current_level_index];
}

function level_default_status() { // Return guidance appropriate to the selected information mode.
  if (game_mode === "freeplay") {
    return "freeplay — build any element 1–118 or ion, select reactants manually, then press react_selected";
  }
  if (game_mode === "formula_only") {
    return `target: ${current_level().formula} — work out the required atoms and build them anywhere in the workspace`;
  }
  if (current_level_index === 0) {
    return "easy start — make two hydrogen atoms: fire a proton to start each nucleus, then capture one electron on each first shell";
  }
  if (current_level_index === 50) {
    return "ions unlocked — build the listed charged atoms by giving them the required electron totals";
  }
  return `build the listed ${current_level().chemistry === "ionic" ? "ions" : "atoms"} for ${current_level().formula} anywhere in the workspace`;
}

function set_status(message, duration_ms = 1800) { // Show concise feedback for construction and reaction events.
  status_banner.textContent = message;
  status_timeout = duration_ms > 0 ? performance.now() + duration_ms : 0;
}

function set_selected_particle(kind) { // Change the projectile loaded into the particle cannon.
  selected_particle = kind;
  for (const button of particle_buttons) {
    button.classList.toggle("selected", button.dataset.particle === kind);
  }
}

function get_canvas_pointer(event) { // Convert browser pointer coordinates into fixed simulation coordinates.
  const rect = canvas.getBoundingClientRect();
  return {
    x: (event.clientX - rect.left) * (WIDTH / rect.width),
    y: (event.clientY - rect.top) * (HEIGHT / rect.height),
  };
}
