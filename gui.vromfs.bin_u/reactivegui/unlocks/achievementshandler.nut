from "%globalsDarg/darg_library.nut" import *
let { is_ios, is_pc } = require("%sqstd/platform.nut")
let { eventbus_subscribe } = require("eventbus")
let { HUD_MSG_STREAK_EX } = require("hudMessages")
let { getMultiStageUnlockId } = require("%rGui/unlocks/streakPkg.nut")
let { unlockAchievement = @(_) null } = is_ios ? require("iosGameCenter.nut")
  : is_pc ? { unlockAchievement = @(id) console_print($"Unlocked achievement: {id}") } 
  : null


let sameIds = [
  "first_blood"
  "triple_kill_air"
  "triple_kill_ship"
  "triple_kill_ground"
  "squad_best"
  "uprank_kill_grade_3"
  "global_avenge_friendly"
  "squad_kill"
  "global_base_defender"
  "global_shadow_assassin"
  "tank_die_hard"
  "heroic_fighter"
]

let wtmIdToGameCenterId = sameIds.reduce(@(res, id) res.$rawset(id, id), {})

function addAchievement(data) {
  let { unlockId = "", stage = 1 } = data
  let wtmId = getMultiStageUnlockId(unlockId, stage)
  let gameCenterId = wtmIdToGameCenterId?[wtmId]
  if (gameCenterId != null)
    unlockAchievement(gameCenterId)
}

let addAchievementByHudMessage = {
  [HUD_MSG_STREAK_EX] = addAchievement
}

eventbus_subscribe("HudMessage", @(data) addAchievementByHudMessage?[data.type](data))
