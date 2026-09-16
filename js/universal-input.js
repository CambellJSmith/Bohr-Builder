"use strict";

const KEYBOARD_AIM_SPEED = 430;
const CONTROLLER_AIM_SPEED = 520;
const keyboard_aim_state = { north: false, south: false, west: false, east: false };

function element_is_available(element) {
  return Boolean(element && !element.hidden && !element.disabled && element.getClientRects().length > 0);
}

function focus_canvas() {
  if (!mode_prompt_open && element_is_available(canvas)) {
    canvas.focus();
  }
}

function focus_first_mode_card() {
  const first_card = mode_cards.find((card) => element_is_available(card));
  if (first_card) {
    first_card.focus();
  }
}

function cycle_mode_focus(direction) {
  const cards = mode_cards.filter((card) => element_is_available(card));
  if (cards.length === 0) {
    return;
  }
  const current_index = cards.indexOf(document.activeElement);
  const base_index = current_index >= 0 ? current_index : 0;
  const next_index = (base_index + direction + cards.length) % cards.length;
  cards[next_index].focus();
}

function cycle_selected_particle(direction) {
  const particle_order = ["proton", "neutron", "electron"];
  const current_index = Math.max(0, particle_order.indexOf(selected_particle));
  const next_index = (current_index + direction + particle_order.length) % particle_order.length;
  set_selected_particle(particle_order[next_index]);
}

function cycle_campaign_level(direction) {
  if (game_mode === "freeplay" || mode_prompt_open) {
    return;
  }
  const max_level = Math.min(unlocked_level, LEVELS.length - 1);
  const next_index = clamp(current_level_index + direction, 0, max_level);
  if (next_index !== current_level_index) {
    load_level(next_index);
  }
}

function inspect_atom_at_pointer() {
  const atom = pick_atom_at(pointer.x, pointer.y);
  selected_atom_id = atom ? atom.id : null;
  update_inspector();
  set_status(atom ? `inspecting ${isotope_label(atom)}` : "no atom under aim");
}

function scrap_atom(atom) {
  if (!atom || reaction || freeplay_reaction || freeplay_verifying) {
    return;
  }
  atoms = atoms.filter((entry) => entry.id !== atom.id);
  freeplay_selected_ids.delete(atom.id);
  selected_atom_id = null;
  set_status("atom scrapped");
  update_inspector();
  update_freeplay_ui();
}

function perform_canvas_primary_action(hold_fire = false) {
  if (mode_prompt_open) {
    return;
  }
  const atom = pick_atom_at(pointer.x, pointer.y);
  if (game_mode === "freeplay" && freeplay_select_mode) {
    if (atom && !freeplay_reaction && !freeplay_verifying) {
      toggle_freeplay_reactant(atom);
    }
    return;
  }
  if (scrap_mode) {
    scrap_atom(atom);
    return;
  }
  pointer.down = hold_fire;
  fire_particle(performance.now());
}

function release_canvas_primary_action() {
  pointer.down = false;
}

function move_aim(x_axis, y_axis, speed, dt) {
  const magnitude = Math.hypot(x_axis, y_axis);
  if (magnitude < 0.001) {
    return;
  }
  const scale = magnitude > 1 ? 1 / magnitude : 1;
  pointer.x = clamp(pointer.x + x_axis * scale * speed * dt, 8, WIDTH - 8);
  pointer.y = clamp(pointer.y + y_axis * scale * speed * dt, 8, HEIGHT - 82);
}

function focusable_controls() {
  const candidates = [canvas, mode_button, level_select, ...particle_buttons, react_select_button, clear_reactants_button, react_button, scrap_button, reset_button, next_button];
  if (mode_prompt_open) {
    return mode_cards.filter((element) => element_is_available(element));
  }
  return candidates.filter((element) => element_is_available(element));
}

function focus_element_in_direction(direction) {
  const controls = focusable_controls();
  if (controls.length === 0) {
    return;
  }
  const active = document.activeElement;
  if (active === level_select && (direction === "up" || direction === "down")) {
    cycle_campaign_level(direction === "up" ? -1 : 1);
    return;
  }
  if (!controls.includes(active)) {
    (mode_prompt_open ? controls[0] : canvas).focus();
    return;
  }
  const source_rect = active.getBoundingClientRect();
  const source_x = source_rect.left + source_rect.width * 0.5;
  const source_y = source_rect.top + source_rect.height * 0.5;
  let best_element = null;
  let best_score = Number.POSITIVE_INFINITY;
  for (const candidate of controls) {
    if (candidate === active) {
      continue;
    }
    const rect = candidate.getBoundingClientRect();
    const dx = rect.left + rect.width * 0.5 - source_x;
    const dy = rect.top + rect.height * 0.5 - source_y;
    const primary = direction === "left" ? -dx : direction === "right" ? dx : direction === "up" ? -dy : dy;
    if (primary <= 1) {
      continue;
    }
    const secondary = direction === "left" || direction === "right" ? Math.abs(dy) : Math.abs(dx);
    const score = primary + secondary * 0.55;
    if (score < best_score) {
      best_score = score;
      best_element = candidate;
    }
  }
  if (best_element) {
    best_element.focus();
  }
}

function activate_focused_control(pressed) {
  const active = document.activeElement;
  if (!pressed) {
    if (active === canvas) {
      release_canvas_primary_action();
    }
    return;
  }
  if (mode_prompt_open) {
    if (mode_cards.includes(active) && element_is_available(active)) {
      active.click();
    } else {
      focus_first_mode_card();
    }
    return;
  }
  if (active === canvas || active === document.body || !element_is_available(active)) {
    focus_canvas();
    perform_canvas_primary_action(true);
    return;
  }
  if (active === level_select) {
    cycle_campaign_level(1);
    return;
  }
  if (typeof active.click === "function") {
    active.click();
  }
}

function controller_context_action() {
  if (game_mode === "freeplay") {
    if (!react_button.disabled) {
      react_button.click();
    }
    return;
  }
  if (!next_button.hidden) {
    next_button.click();
  }
}

function update_universal_input(dt) {
  const x_axis = Number(keyboard_aim_state.east) - Number(keyboard_aim_state.west);
  const y_axis = Number(keyboard_aim_state.south) - Number(keyboard_aim_state.north);
  if (x_axis !== 0 || y_axis !== 0) {
    focus_canvas();
    move_aim(x_axis, y_axis, KEYBOARD_AIM_SPEED, dt);
  }
}

function keyboard_target_consumes_keys(target) {
  return target instanceof HTMLInputElement || target instanceof HTMLTextAreaElement || target instanceof HTMLSelectElement || (target instanceof HTMLElement && target.isContentEditable);
}

function set_keyboard_aim_key(code, pressed) {
  if (code === "KeyW" || code === "ArrowUp") {
    keyboard_aim_state.north = pressed;
    return true;
  }
  if (code === "KeyS" || code === "ArrowDown") {
    keyboard_aim_state.south = pressed;
    return true;
  }
  if (code === "KeyA" || code === "ArrowLeft") {
    keyboard_aim_state.west = pressed;
    return true;
  }
  if (code === "KeyD" || code === "ArrowRight") {
    keyboard_aim_state.east = pressed;
    return true;
  }
  return false;
}

window.addEventListener("keydown", (event) => {
  const active = document.activeElement;
  const target_consumes_keys = keyboard_target_consumes_keys(event.target);
  const canvas_has_focus = active === canvas;
  const button_has_focus = active instanceof HTMLButtonElement;
  if (mode_prompt_open) {
    if (event.code === "Tab") {
      event.preventDefault();
      cycle_mode_focus(event.shiftKey ? -1 : 1);
    } else if (event.code === "ArrowLeft" || event.code === "ArrowUp") {
      event.preventDefault();
      cycle_mode_focus(-1);
    } else if (event.code === "ArrowRight" || event.code === "ArrowDown") {
      event.preventDefault();
      cycle_mode_focus(1);
    }
    return;
  }
  if (!target_consumes_keys && (event.code.startsWith("Key") || canvas_has_focus) && set_keyboard_aim_key(event.code, true)) {
    event.preventDefault();
    focus_canvas();
    return;
  }
  if (target_consumes_keys) {
    return;
  }
  if (event.key === "1") {
    set_selected_particle("proton");
  } else if (event.key === "2") {
    set_selected_particle("neutron");
  } else if (event.key === "3") {
    set_selected_particle("electron");
  } else if (event.code === "Space") {
    if (button_has_focus) {
      return;
    }
    event.preventDefault();
    if (!event.repeat) {
      focus_canvas();
      perform_canvas_primary_action(true);
    }
  } else if (event.code === "Enter") {
    if (button_has_focus) {
      return;
    }
    if (canvas_has_focus) {
      event.preventDefault();
      if (!event.repeat) {
        perform_canvas_primary_action(false);
      }
    }
  } else if (event.code === "KeyI" && !event.repeat) {
    focus_canvas();
    inspect_atom_at_pointer();
  } else if (event.code === "KeyX" && !event.repeat) {
    scrap_button.click();
    focus_canvas();
  } else if (event.code === "KeyF" && !event.repeat && game_mode === "freeplay") {
    react_select_button.click();
    focus_canvas();
  } else if (event.code === "KeyC" && !event.repeat && game_mode === "freeplay") {
    clear_reactants_button.click();
  } else if (event.code === "KeyM" && !event.repeat) {
    open_mode_overlay();
    focus_first_mode_card();
  } else if (event.code === "KeyQ" && !event.repeat) {
    cycle_selected_particle(-1);
  } else if (event.code === "KeyE" && !event.repeat) {
    cycle_selected_particle(1);
  } else if (event.code === "BracketLeft" && !event.repeat) {
    cycle_campaign_level(-1);
  } else if (event.code === "BracketRight" && !event.repeat) {
    cycle_campaign_level(1);
  } else if (event.code === "KeyR" && !event.repeat) {
    reset_button.click();
  } else if (event.code === "KeyN" && !event.repeat) {
    controller_context_action();
  }
});

window.addEventListener("keyup", (event) => {
  if (set_keyboard_aim_key(event.code, false)) {
    if (document.activeElement === canvas) {
      event.preventDefault();
    }
  }
  if (event.code === "Space") {
    release_canvas_primary_action();
  }
});

window.addEventListener("blur", () => {
  keyboard_aim_state.north = false;
  keyboard_aim_state.south = false;
  keyboard_aim_state.west = false;
  keyboard_aim_state.east = false;
  release_canvas_primary_action();
});

window.bohr_controller_move_aim = (x_axis, y_axis, dt) => {
  if (mode_prompt_open) {
    return;
  }
  focus_canvas();
  move_aim(Number(x_axis) || 0, Number(y_axis) || 0, CONTROLLER_AIM_SPEED, clamp(Number(dt) || 0, 0, 0.05));
};

window.bohr_controller_navigate = (direction) => {
  if (direction === "up" || direction === "down" || direction === "left" || direction === "right") {
    focus_element_in_direction(direction);
  }
};

window.bohr_controller_action = (action, pressed = true) => {
  if (mode_prompt_open && action !== "accept" && action !== "mode") {
    return;
  }
  if (action === "accept") {
    activate_focused_control(Boolean(pressed));
  } else if (action === "inspect" && pressed) {
    focus_canvas();
    inspect_atom_at_pointer();
  } else if (action === "scrap" && pressed) {
    scrap_button.click();
    focus_canvas();
  } else if (action === "react_select" && pressed && game_mode === "freeplay") {
    react_select_button.click();
    focus_canvas();
  } else if (action === "particle_previous" && pressed) {
    cycle_selected_particle(-1);
  } else if (action === "particle_next" && pressed) {
    cycle_selected_particle(1);
  } else if (action === "level_previous" && pressed) {
    cycle_campaign_level(-1);
  } else if (action === "level_next" && pressed) {
    cycle_campaign_level(1);
  } else if (action === "mode" && pressed) {
    open_mode_overlay();
    focus_first_mode_card();
  } else if (action === "reset" && pressed) {
    reset_button.click();
  } else if (action === "clear" && pressed && game_mode === "freeplay") {
    clear_reactants_button.click();
  } else if (action === "context" && pressed) {
    controller_context_action();
  }
};

let universal_input_last_time = performance.now();

function universal_input_tick(now) {
  const dt = Math.min(0.05, (now - universal_input_last_time) / 1000);
  universal_input_last_time = now;
  update_universal_input(dt);
  requestAnimationFrame(universal_input_tick);
}

requestAnimationFrame(universal_input_tick);
