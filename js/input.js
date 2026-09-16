"use strict";

for (const button of particle_buttons) {
  button.addEventListener("click", () => set_selected_particle(button.dataset.particle));
}

for (const card of mode_cards) {
  card.addEventListener("click", () => {
    set_game_mode(card.dataset.mode);
    focus_canvas();
  });
}

mode_button.addEventListener("click", () => {
  open_mode_overlay();
  focus_first_mode_card();
});

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
  set_status(freeplay_select_mode ? "select atoms or ions with the primary action" : level_default_status());
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
  set_status(scrap_mode ? "select an atom with the primary action to remove it" : "scrap mode disabled");
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
  pointer = { x: pos.x, y: pos.y, down: false };
  if (event.button === 2) {
    inspect_atom_at_pointer();
    return;
  }
  if (event.button !== 0) {
    return;
  }
  perform_canvas_primary_action(true);
  if (pointer.down) {
    canvas.setPointerCapture(event.pointerId);
  }
});

canvas.addEventListener("contextmenu", (event) => {
  event.preventDefault();
});

canvas.addEventListener("pointerup", (event) => {
  release_canvas_primary_action();
  if (canvas.hasPointerCapture(event.pointerId)) {
    canvas.releasePointerCapture(event.pointerId);
  }
});

canvas.addEventListener("pointercancel", () => {
  release_canvas_primary_action();
});

unlocked_level = clamp(unlocked_level, 0, LEVELS.length - 1);
populate_level_select();
update_level_ui();
reset_game();
open_mode_overlay();
focus_first_mode_card();
requestAnimationFrame(tick);
