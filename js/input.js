"use strict";

for (const button of particle_buttons) {
  button.addEventListener("click", () => set_selected_particle(button.dataset.particle));
}

for (const card of mode_cards) {
  card.addEventListener("click", () => set_game_mode(card.dataset.mode));
}

mode_button.addEventListener("click", open_mode_overlay);

react_select_button.addEventListener("click", () => {
  if (game_mode !== "freeplay" || freeplay_reaction || freeplay_verifying) {
    return;
  }
  freeplay_select_mode = !freeplay_select_mode;
  scrap_mode = false;
  scrap_button.classList.remove("active");
  scrap_button.textContent = "scrap_mode";
  react_select_button.classList.toggle("active", freeplay_select_mode);
  react_select_button.textContent = freeplay_select_mode ? "selecting_reactants" : "select_reactants";
  set_status(freeplay_select_mode ? "click atoms or ions to toggle them into the reaction" : level_default_status());
});

clear_reactants_button.addEventListener("click", () => {
  if (freeplay_reaction || freeplay_verifying) {
    return;
  }
  freeplay_selected_ids.clear();
  update_freeplay_ui();
  set_status("reaction selection cleared");
});

react_button.addEventListener("click", () => {
  void attempt_freeplay_reaction();
});

level_select.addEventListener("change", () => {
  load_level(Number(level_select.value));
});

scrap_button.addEventListener("click", () => {
  if (reaction || freeplay_reaction || freeplay_verifying) {
    return;
  }
  scrap_mode = !scrap_mode;
  freeplay_select_mode = false;
  react_select_button.classList.remove("active");
  react_select_button.textContent = "select_reactants";
  scrap_button.classList.toggle("active", scrap_mode);
  scrap_button.textContent = scrap_mode ? "scrap_mode_on" : "scrap_mode";
  set_status(scrap_mode ? "click an atom to remove it" : "scrap mode disabled");
});

reset_button.addEventListener("click", reset_game);

next_button.addEventListener("click", () => {
  if (current_level_index < LEVELS.length - 1) {
    load_level(current_level_index + 1);
  }
});

canvas.addEventListener("pointermove", (event) => {
  pointer = { ...pointer, ...get_canvas_pointer(event) };
});

canvas.addEventListener("pointerdown", (event) => {
  const pos = get_canvas_pointer(event);
  const atom = pick_atom_at(pos.x, pos.y);
  pointer = { x: pos.x, y: pos.y, down: false };

  if (event.button === 2) {
    selected_atom_id = atom ? atom.id : null;
    update_inspector();
    return;
  }

  if (game_mode === "freeplay" && freeplay_select_mode) {
    if (event.button === 0 && atom && !freeplay_reaction && !freeplay_verifying) {
      toggle_freeplay_reactant(atom);
    }
    return;
  }

  if (scrap_mode) {
    if (atom && !reaction && !freeplay_reaction && !freeplay_verifying) {
      atoms = atoms.filter((entry) => entry.id !== atom.id);
      freeplay_selected_ids.delete(atom.id);
      selected_atom_id = null;
      set_status("atom scrapped");
      update_inspector();
      update_freeplay_ui();
    }
    return;
  }

  if (event.button !== 0) {
    return;
  }

  pointer.down = true;
  canvas.setPointerCapture(event.pointerId);
  fire_particle(performance.now());
});

canvas.addEventListener("contextmenu", (event) => {
  event.preventDefault();
});

canvas.addEventListener("pointerup", (event) => {
  pointer.down = false;
  if (canvas.hasPointerCapture(event.pointerId)) {
    canvas.releasePointerCapture(event.pointerId);
  }
});

canvas.addEventListener("pointercancel", () => {
  pointer.down = false;
});

window.addEventListener("keydown", (event) => {
  if (event.target instanceof HTMLInputElement || event.target instanceof HTMLButtonElement || event.target instanceof HTMLSelectElement) {
    return;
  }
  if (event.key === "1") {
    set_selected_particle("proton");
  } else if (event.key === "2") {
    set_selected_particle("neutron");
  } else if (event.key === "3") {
    set_selected_particle("electron");
  } else if (event.code === "Space") {
    event.preventDefault();
    fire_particle(performance.now());
  }
});

unlocked_level = clamp(unlocked_level, 0, LEVELS.length - 1);
populate_level_select();
update_level_ui();
reset_game();
open_mode_overlay();
requestAnimationFrame(tick);
