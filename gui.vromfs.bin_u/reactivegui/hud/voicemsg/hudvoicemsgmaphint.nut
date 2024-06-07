from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { get_local_custom_settings_blk } = require("blkGetters")
let { TANK, SHIP } = require("%appGlobals/unitConst.nut")
let { curCampaign, lastBattles } = require("%appGlobals/pServer/campaign.nut")
let { isInMpBattle } = require("%appGlobals/clientState/clientState.nut")
let { isOnlineSettingsAvailable } = require("%appGlobals/loginState.nut")
let { unitType, isUnitDelayed } = require("%rGui/hudState.nut")
let { addCommonHintWithTtl } = require("%rGui/hudHints/commonHintLogState.nut")
let { addHudElementPointer } = require("%rGui/tutorial/hudElementPointers.nut")

let SAVE_ID_HINT_SHOW_TIMES_LEFT = "hintMinimapVoiceMsgLeft"

let SHOW_AFTER_BATTLES = 5
let SHOW_TIMES_MAX = 3
let HINT_TTL_SEC = 15

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
