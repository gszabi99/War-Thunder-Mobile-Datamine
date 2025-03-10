from "hudState" import hud_request_hud_tank_debuffs_state, hud_request_hud_ship_debuffs_state,
  hud_request_hud_crew_state
let { addOptionMode, setGuiOptionsMode, addUserOption, set_gui_option } = require("guiOptions")
let getTagsUnitName = require("%appGlobals/getTagsUnitName.nut")

let optModeTraining = addOptionMode("OPTIONS_MODE_TRAINING") //hardcoded in the native code
let optModeGameplay = addOptionMode("OPTIONS_MODE_GAMEPLAY") //hardcoded in the native code
let bulletOptions = array(BULLETS_SETS_QUANTITY).map(@(_, idx) {
  bulletOption = addUserOption($"USEROPT_BULLETS{idx}")
  bulletCountOption = addUserOption($"USEROPT_BULLET_COUNT{idx}")
})
let USEROPT_AIRCRAFT = addUserOption("USEROPT_AIRCRAFT")
let USEROPT_WEAPONS = addUserOption("USEROPT_WEAPONS")
let USEROPT_SKIN = addUserOption("USEROPT_SKIN")

function changeTrainingUnit(realUnitName, skin = "", bullets = null) {
  let unitName = getTagsUnitName(realUnitName)
  setGuiOptionsMode(optModeTraining)
  set_gui_option(USEROPT_AIRCRAFT, unitName)
  set_gui_option(USEROPT_WEAPONS, $"{unitName}_default")
  set_gui_option(USEROPT_SKIN, skin)
  foreach (idx, opts in bulletOptions) {
    set_gui_option(opts.bulletOption, bullets?[idx].name ?? "")
    set_gui_option(opts.bulletCountOption, bullets?[idx].count ?? 0)
  }
  setGuiOptionsMode(optModeGameplay)
  foreach (idx, opts in bulletOptions) { //FIXME: we receive error from ative code when bad bullets in the OPTIONS_MODE_TRAINING, but bullets not apply when they not in current options mode
    set_gui_option(opts.bulletOption, bullets?[idx].name ?? "")
    set_gui_option(opts.bulletCountOption, bullets?[idx].count ?? 0)
  }
}

function requestHudState() {
  hud_request_hud_tank_debuffs_state()
  hud_request_hud_crew_state()
  hud_request_hud_ship_debuffs_state()
}

return {
  optModeTraining
  optModeGameplay
  bulletOptions
  USEROPT_AIRCRAFT
  USEROPT_WEAPONS
  USEROPT_SKIN

  changeTrainingUnit
  requestHudState
}