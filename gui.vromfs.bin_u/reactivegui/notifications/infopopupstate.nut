from "%globalsDarg/darg_library.nut" import *
let { deferOnce, clearTimer, resetTimeout } = require("dagor.workcycle")
let { register_command } = require("console")
let { get_local_custom_settings_blk } = require("blkGetters")
let { eventbus_send } = require("eventbus")
let { getServerTime, isServerTimeValid } = require("%appGlobals/userstats/serverTime.nut")
let { campConfigs, curCampaign, firstLoginTime } = require("%appGlobals/pServer/campaign.nut")
let { isOnlineSettingsAvailable } = require("%appGlobals/loginState.nut")


const SAVE_ID = "infoPopups"
let REPEAT_SHOW_TIME_SPREAD = 28 * 24 * 3600 
let infoPopupsCfg = Computed(@() campConfigs.get()?.infoPopups ?? [])
let popupToShow = Watched(null)

function isTimeInRange(timeRange, time, spread = 0) {
  let { start = 0, end = 0 } = timeRange
  return (start - spread <= time && (end <= 0 || end + spread >= time))
}

let getNextTime = @(curNextTime, newTime) newTime <= 0 ? curNextTime
  : curNextTime <= 0 ? newTime
  : min(curNextTime, newTime)

function updatePopupToShow() {
  if (!isServerTimeValid.get() || !isOnlineSettingsAvailable.get()) {
    popupToShow.set(null)
    return
  }

  let time = getServerTime()
  let showed = get_local_custom_settings_blk()?[SAVE_ID]

  local timeToUpdate = 0
  local popup = null
  foreach (p in infoPopupsCfg.get()) {
    let { id, timeRange, profileCreateTime } = p
    let showTime = showed?[id]
    if (showTime != null && isTimeInRange(timeRange, showTime, REPEAT_SHOW_TIME_SPREAD))
      continue 
    if (!isTimeInRange(profileCreateTime, firstLoginTime.get()))
      continue

    if (!popup && isTimeInRange(timeRange, time))
      popup = p
    else
      timeToUpdate = getNextTime(timeToUpdate, timeRange.start - time)
    timeToUpdate = getNextTime(timeToUpdate, timeRange.end - time)
  }

  popupToShow.set(popup)
  if (timeToUpdate <= 0)
    clearTimer(updatePopupToShow)
  else
    resetTimeout(timeToUpdate, updatePopupToShow)
}
popupToShow.whiteListMutatorClosure(updatePopupToShow)

updatePopupToShow()
let deferedUpdate = @(_) deferOnce(updatePopupToShow)
foreach (w in [infoPopupsCfg, isServerTimeValid, isOnlineSettingsAvailable, curCampaign, firstLoginTime])
  w.subscribe(deferedUpdate)

function markCurPopupSeen() {
  if (popupToShow.get() == null)
    return
  get_local_custom_settings_blk().addBlock(SAVE_ID)[popupToShow.get().id] = getServerTime()
  eventbus_send("saveProfile", {})
  updatePopupToShow()
}

register_command(function() {
  get_local_custom_settings_blk().removeBlock(SAVE_ID)
  eventbus_send("saveProfile", {})
  updatePopupToShow()
}, "debug.reset_info_popups")

return {
  popupToShow
  markCurPopupSeen
}