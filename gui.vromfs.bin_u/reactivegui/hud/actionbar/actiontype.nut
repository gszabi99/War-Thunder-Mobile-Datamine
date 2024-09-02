from "%appGlobals/unitConst.nut" import *
require("%rGui/onlyAfterLogin.nut")
let hudActionBarConst = require("hudActionBarConst")
let { EII_SPECIAL_UNIT } = hudActionBarConst

let actions = [
  "TORPEDO", "TOOLKIT", "EXTINGUISHER", "SMOKE_SCREEN", "MEDICALKIT", "DEPTH_CHARGE", "MINE", "MORTAR", "ROCKET", "ROCKET_SECONDARY", "IRCM", "FIREWORK",
  "SUPPORT_PLANE", "SUPPORT_PLANE_2", "SUPPORT_PLANE_3", "SUPPORT_PLANE_4", "SUPPORT_PLANE_CHANGE", "SUPPORT_PLANE_GROUP_FLY_TO",
  "SUPPORT_PLANE_GROUP_ATTACK", "SUPPORT_PLANE_GROUP_HUNT", "SUPPORT_PLANE_GROUP_DEFEND", "SUPPORT_PLANE_GROUP_RETURN", "STRATEGY_MODE",
  "SUPPORT_PLANE_GROUP_ADD_FLY_TO", "SUPPORT_PLANE_GROUP_ADD_ATTACK", "SUPPORT_PLANE_GROUP_CANCEL", "DIVING_LOCK", "SMOKE_GRENADE", "ARTILLERY_TARGET",
  "WINCH", "WINCH_ATTACH", "WINCH_DETACH", "MANUAL_ANTIAIR", "ELECTRONIC_WARFARE"
]

let simpleActionTypes = {}
let eiiToAb = {}
foreach (a in actions) {
  let eii = hudActionBarConst[$"EII_{a}"]
  let ab = $"AB_{a}"
  simpleActionTypes[ab] <- ab
  eiiToAb[eii] <- ab
}

let correlation = { //only custom types
  AB_PRIMARY_WEAPON = @(a) a?.triggerGroupNo == TRIGGER_GROUP_PRIMARY,
  AB_SECONDARY_WEAPON = @(a) a?.triggerGroupNo == TRIGGER_GROUP_SECONDARY,
  AB_SPECIAL_WEAPON = @(a) a?.triggerGroupNo == TRIGGER_GROUP_SPECIAL_GUN,
  AB_MACHINE_GUN = @(a) a?.triggerGroupNo == TRIGGER_GROUP_MACHINE_GUN
    || a?.triggerGroupNo == TRIGGER_GROUP_COAXIAL_GUN,
  AB_EXTRA_GUN_1 = @(a) a?.triggerGroupNo == TRIGGER_GROUP_EXTRA_GUN_1,
  AB_EXTRA_GUN_2 = @(a) a?.triggerGroupNo == TRIGGER_GROUP_EXTRA_GUN_2,
  AB_EXTRA_GUN_3 = @(a) a?.triggerGroupNo == TRIGGER_GROUP_EXTRA_GUN_3,
  AB_EXTRA_GUN_4 = @(a) a?.triggerGroupNo == TRIGGER_GROUP_EXTRA_GUN_4,
  AB_SPECIAL_FIGHTER = @(a) a.type == EII_SPECIAL_UNIT && a.killStreakTag == "fighter",
  AB_SPECIAL_BOMBER = @(a) a.type == EII_SPECIAL_UNIT && a.killStreakTag == "bomber",
}

let actionTypes = simpleActionTypes.__merge(correlation.map(@(_, a) a))

let getActionType = @(action) eiiToAb?[action.type] ?? correlation.findindex(@(isFit) isFit(action))

return actionTypes.__merge({
  getActionType
})