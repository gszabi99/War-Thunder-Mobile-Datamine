from "%globalsDarg/darg_library.nut" import *
from "blkGetters" import get_local_custom_settings_blk
from "eventbus" import eventbus_send
from "%appGlobals/clientState/clientState.nut" import isInMpBattle
from "%appGlobals/loginState.nut" import isOnlineSettingsAvailable
from "%appGlobals/pServer/campaign.nut" import curCampaign, lastBattles
from "%appGlobals/unitConst.nut" import TANK, SHIP
from "%rGui/hudHints/commonHintLogState.nut" import addCommonHintWithTtl
from "%rGui/hudState.nut" import unitType, isUnitDelayed
from "%rGui/missionState.nut" import isGtFFA
from "%rGui/tutorial/hudElementPointers.nut" import addHudElementPointer


const SAVE_ID_HINT_SHOW_TIMES_LEFT = "hintMinimapVoiceMsgLeft"

const SHOW_AFTER_BATTLES = 5
const SHOW_TIMES_MAX = 3
const HINT_TTL_SEC = 15

let campaignsWithMinimap = [ "tanks", "ships" ]
let hudTypesWithMinimap = [ TANK, SHIP ]

let showTimesLeft = Watched(0)

function initSavedData() {
  if (!isOnlineSettingsAvailable.get())
    return
  showTimesLeft.set(get_local_custom_settings_blk()?[SAVE_ID_HINT_SHOW_TIMES_LEFT] ?? SHOW_TIMES_MAX)
}
isOnlineSettingsAvailable.subscribe(@(_) initSavedData())
initSavedData()

function saveData() {
  get_local_custom_settings_blk()[SAVE_ID_HINT_SHOW_TIMES_LEFT] = showTimesLeft.get()
  eventbus_send("saveProfile", {})
}

let hasEnoughBattles = Computed(function () {
  if (showTimesLeft.get() == 0)
    return false
  let campaign = curCampaign.get()
  if (!campaignsWithMinimap.contains(campaign))
    return false
  let total = lastBattles.get().reduce(@(res, v) v.campaign == campaign ? (res + 1) : res, 0)
  return total >= SHOW_AFTER_BATTLES
})

local isSeenInCurBattle = false
isInMpBattle.subscribe(function(v) {
  if (!v)
    isSeenInCurBattle = false
})

let shouldShowHint = keepref(Computed(@() showTimesLeft.get() > 0 && hasEnoughBattles.get()
  && !isSeenInCurBattle && isInMpBattle.get()
  && !isUnitDelayed.get() && hudTypesWithMinimap.contains(unitType.get())
  && !isGtFFA.get()
))

function showHint() {
  isSeenInCurBattle = true
  showTimesLeft.set(showTimesLeft.get() - 1)
  saveData()

  addCommonHintWithTtl(loc("loading/tip10"), HINT_TTL_SEC)
  addHudElementPointer("tactical_map", HINT_TTL_SEC)
}

let markMinimapVoiceMsgFeatureKnown = function() {
  if (showTimesLeft.get() == 0)
    return
  showTimesLeft.set(0)
  saveData()
}

shouldShowHint.subscribe(@(v) v ? showHint() : null)

return {
  markMinimapVoiceMsgFeatureKnown
}
