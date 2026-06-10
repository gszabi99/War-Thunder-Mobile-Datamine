from "%globalsDarg/darg_library.nut" import *
let { deferOnce } = require("dagor.workcycle")
let { register_command } = require("console")
let { get_local_custom_settings_blk } = require("blkGetters")
let { eventbus_send } = require("eventbus")
let { getCountryCode } = require("auth_wt")
let { getServerTime, isServerTimeValid } = require("%appGlobals/userstats/serverTime.nut")
let { campConfigs, curCampaign, firstLoginTime } = require("%appGlobals/pServer/campaign.nut")
let { isOnlineSettingsAvailable } = require("%appGlobals/loginState.nut")
let { resetExtTimeout, clearExtTimer } = require("%appGlobals/timeoutExt.nut")


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

let getSavedPopup = @(cfg, id) type(cfg?[id]) != "integer"
  ? (cfg?[id] ?? { lastTime = 0, count = 0 })
  : { lastTime = cfg[id], count = 1 }

function getSavedShowCount(savedPopup, timeRange) {
  let lastShowTime = savedPopup.lastTime
  return (lastShowTime > 0 && isTimeInRange(timeRange, lastShowTime, REPEAT_SHOW_TIME_SPREAD)) ? savedPopup.count : 0
}

function updatePopupToShow() {
  if (!isServerTimeValid.get() || !isOnlineSettingsAvailable.get()) {
    popupToShow.set(null)
    return
  }

  let time = getServerTime()
  let showed = get_local_custom_settings_blk()?[SAVE_ID]

  let countryCode = getCountryCode()
  local timeToUpdate = 0
  local popup = null
  foreach (p in infoPopupsCfg.get()) {
    let { id, timeRange, profileCreateTime, maxShowCount = 1, minTimeBetweenShowsSec = 0, locations = [] } = p
    if (locations.len() > 0 && !locations.contains(countryCode))
      continue

    let savedPopup = getSavedPopup(showed, id)
    let lastShowTime = savedPopup.lastTime
    let showCount = getSavedShowCount(savedPopup, timeRange)

    if (showCount >= maxShowCount)
      continue
    if (!isTimeInRange(profileCreateTime, firstLoginTime.get()))
      continue

    let nextShowTime = (lastShowTime > 0 && minTimeBetweenShowsSec > 0) ? lastShowTime + minTimeBetweenShowsSec : 0
    let isReadyToShow = isTimeInRange(timeRange, time) && (nextShowTime <= 0 || nextShowTime <= time)

    if (!popup && isReadyToShow)
      popup = p

    timeToUpdate = getNextTime(timeToUpdate, timeRange.start - time)
    timeToUpdate = getNextTime(timeToUpdate, nextShowTime - time)
    timeToUpdate = getNextTime(timeToUpdate, timeRange.end - time)
  }

  popupToShow.set(popup)
  if (timeToUpdate <= 0)
    clearExtTimer(updatePopupToShow)
  else
    resetExtTimeout(timeToUpdate, updatePopupToShow)
}
popupToShow.whiteListMutatorClosure(updatePopupToShow)

updatePopupToShow()
let deferedUpdate = @(_) deferOnce(updatePopupToShow)
foreach (w in [infoPopupsCfg, isServerTimeValid, isOnlineSettingsAvailable, curCampaign, firstLoginTime])
  w.subscribe(deferedUpdate)

function markCurPopupSeen() {
  let { id = null, timeRange = null } = popupToShow.get()
  if (id == null)
    return

  let blk = get_local_custom_settings_blk()
  let savedPopup = getSavedPopup(blk?[SAVE_ID], id)
  let prevCount = getSavedShowCount(savedPopup, timeRange)
  let saveIdBlk = blk.addBlock(SAVE_ID)

  if (type(saveIdBlk?[id]) == "integer")
    saveIdBlk[id] = null

  let savedBlk = saveIdBlk.addBlock(id)

  savedBlk["lastTime"] = getServerTime()
  savedBlk["count"] = prevCount + 1

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