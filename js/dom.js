"use strict";

const canvas = document.getElementById("game_canvas");
const ctx = canvas.getContext("2d", { alpha: false });
const status_banner = document.getElementById("status_banner");
const inspector = document.getElementById("inspector");
const reset_button = document.getElementById("reset_button");
const next_button = document.getElementById("next_button");
const scrap_button = document.getElementById("scrap_button");
const requirement_list = document.getElementById("requirement_list");
const level_select = document.getElementById("level_select");
const level_number = document.getElementById("level_number");
const level_title = document.getElementById("level_title");
const level_progress = document.getElementById("level_progress");
const level_lesson = document.getElementById("level_lesson");
const target_formula = document.getElementById("target_formula");
const target_name = document.getElementById("target_name");
const reaction_equation = document.getElementById("reaction_equation");
const requirement_hint = document.getElementById("requirement_hint");
const mode_overlay = document.getElementById("mode_overlay");
const mode_button = document.getElementById("mode_button");
const mode_badge = document.getElementById("mode_badge");
const guided_only_elements = Array.from(document.querySelectorAll(".guided_only"));
const mode_cards = Array.from(document.querySelectorAll(".mode_card"));
const particle_buttons = Array.from(document.querySelectorAll(".particle_button"));
const campaign_only_elements = Array.from(document.querySelectorAll(".campaign_only"));
const freeplay_only_elements = Array.from(document.querySelectorAll(".freeplay_only"));
const react_select_button = document.getElementById("react_select_button");
const react_button = document.getElementById("react_button");
const clear_reactants_button = document.getElementById("clear_reactants_button");
const freeplay_selection = document.getElementById("freeplay_selection");

const WIDTH = canvas.width;
const HEIGHT = canvas.height;
const CANNON = { x: WIDTH * 0.5, y: HEIGHT - 35 };
const FIXED_LAUNCH_SPEED = 660;
const SHELL_RADII = [44, 68, 92, 116, 140, 164, 188, 212];
const MAX_ATOMIC_NUMBER = 118;
const MAX_ELECTRONS = 126;
const ELEMENTS = " H He Li Be B C N O F Ne Na Mg Al Si P S Cl Ar K Ca Sc Ti V Cr Mn Fe Co Ni Cu Zn Ga Ge As Se Br Kr Rb Sr Y Zr Nb Mo Tc Ru Rh Pd Ag Cd In Sn Sb Te I Xe Cs Ba La Ce Pr Nd Pm Sm Eu Gd Tb Dy Ho Er Tm Yb Lu Hf Ta W Re Os Ir Pt Au Hg Tl Pb Bi Po At Rn Fr Ra Ac Th Pa U Np Pu Am Cm Bk Cf Es Fm Md No Lr Rf Db Sg Bh Hs Mt Ds Rg Cn Nh Fl Mc Lv Ts Og".split(" ");
const ELEMENT_NAMES = ["", "hydrogen", "helium", "lithium", "beryllium", "boron", "carbon", "nitrogen", "oxygen", "fluorine", "neon", "sodium", "magnesium", "aluminium", "silicon", "phosphorus", "sulfur", "chlorine", "argon", "potassium", "calcium", "scandium", "titanium", "vanadium", "chromium", "manganese", "iron"];
const ELEMENT_NAME_BY_SYMBOL = new Map([
  ["H","hydrogen"],["He","helium"],["Li","lithium"],["Be","beryllium"],["B","boron"],["C","carbon"],["N","nitrogen"],["O","oxygen"],["F","fluorine"],["Ne","neon"],
  ["Na","sodium"],["Mg","magnesium"],["Al","aluminium"],["Si","silicon"],["P","phosphorus"],["S","sulfur"],["Cl","chlorine"],["Ar","argon"],["K","potassium"],["Ca","calcium"],
  ["Sc","scandium"],["Ti","titanium"],["V","vanadium"],["Cr","chromium"],["Mn","manganese"],["Fe","iron"],["Co","cobalt"],["Ni","nickel"],["Cu","copper"],["Zn","zinc"],
  ["Ga","gallium"],["Ge","germanium"],["As","arsenic"],["Se","selenium"],["Br","bromine"],["Kr","krypton"],["Rb","rubidium"],["Sr","strontium"],["Y","yttrium"],["Zr","zirconium"],
  ["Nb","niobium"],["Mo","molybdenum"],["Tc","technetium"],["Ru","ruthenium"],["Rh","rhodium"],["Pd","palladium"],["Ag","silver"],["Cd","cadmium"],["In","indium"],["Sn","tin"],
  ["Sb","antimony"],["Te","tellurium"],["I","iodine"],["Xe","xenon"],["Cs","caesium"],["Ba","barium"],["La","lanthanum"],["Ce","cerium"],["Pr","praseodymium"],["Nd","neodymium"],
  ["Pm","promethium"],["Sm","samarium"],["Eu","europium"],["Gd","gadolinium"],["Tb","terbium"],["Dy","dysprosium"],["Ho","holmium"],["Er","erbium"],["Tm","thulium"],["Yb","ytterbium"],
  ["Lu","lutetium"],["Hf","hafnium"],["Ta","tantalum"],["W","tungsten"],["Re","rhenium"],["Os","osmium"],["Ir","iridium"],["Pt","platinum"],["Au","gold"],["Hg","mercury"],
  ["Tl","thallium"],["Pb","lead"],["Bi","bismuth"],["Po","polonium"],["At","astatine"],["Rn","radon"],["Fr","francium"],["Ra","radium"],["Ac","actinium"],["Th","thorium"],
  ["Pa","protactinium"],["U","uranium"],["Np","neptunium"],["Pu","plutonium"],["Am","americium"],["Cm","curium"],["Bk","berkelium"],["Cf","californium"],["Es","einsteinium"],["Fm","fermium"],
  ["Md","mendelevium"],["No","nobelium"],["Lr","lawrencium"],["Rf","rutherfordium"],["Db","dubnium"],["Sg","seaborgium"],["Bh","bohrium"],["Hs","hassium"],["Mt","meitnerium"],["Ds","darmstadtium"],
  ["Rg","roentgenium"],["Cn","copernicium"],["Nh","nihonium"],["Fl","flerovium"],["Mc","moscovium"],["Lv","livermorium"],["Ts","tennessine"],["Og","oganesson"]
]);
