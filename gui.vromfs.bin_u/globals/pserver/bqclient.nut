from "%globalScripts/logs.nut" import *
from "dagor.localize" import getLocTextForLang
from "dagor.time" import get_time_msec
from "eventbus" import eventbus_send
from "math" import min, max
from "platform" import get_platform_string_id
from "%sqstd/underscore.nut" import isEqual
from "%appGlobals/clientState/connectionStatus.nut" import connectionStatus
from "%appGlobals/clientState/downloadState.nut" import downloadInProgress, allowLimitedDownload
from "%appGlobals/pServer/campaign.nut" import sharedStatsByCampaign, campProfile, receivedMissionRewards, curCampaign
from "%appGlobals/updater/gameModeAddons.nut" import allUnitsRanks
from "%appGlobals/userstats/serverTime.nut" import getServerTime
from "pServerApi.nut" import send_to_bq_offer
import "servProfile.nut" as servProfile
from "types" import Integer, Float, String, Bool


let { get_user_system_info = @() null } = require_optional("sysinfo")
let { get_game_version_str = @() "-" } = require_optional("app") 


function addEventTime(data, key = "eventTime") {
  let time = getServerTime()
  return time > 0 ? data.__merge({ [key] = time }) : data.__merge({ ["$fillServerTime"] = { key, timeMsec = get_time_msec() }})
}

function addSystemInfo(data) {
  let { platform = "", uuid0 = "" } = get_user_system_info()
  return data.__merge({ platform, systemId = uuid0 })
}

let sendUiBqEvent = @(event, data = {}) eventbus_send("sendBqEvent",
  { tableId = "gui_events",
    data = addEventTime(data.__merge({
      event,
      gameVersion = get_game_version_str(),
      campaign = curCampaign.get() ?? "",
    }))
  })

function sendSettingChangeBqEvent(event, category, value){
  let data = addEventTime({ event, category })
  if(value instanceof Integer)
    data.paramInt <- value
  else if(value instanceof Float)
    data.paramFloat <- value
  else if(value instanceof String)
    data.paramStr <- value
  else if(value instanceof Bool)
    data.paramInt <- value ? 1 : 0
  else
    logerr($"Unknown value type for sendSettingChangeBqEvent")
  eventbus_send("sendBqEvent",
    {
      tableId = "settings_change_1",
      data
    })
}

let sendErrorBqEvent = @(errorStr, data = {}) eventbus_send("sendBqEvent",
  {
    tableId = "gui_events",
    data = addEventTime(data.__merge({ event = "error", id = errorStr, gameVersion = get_game_version_str() }))
  })

let sendErrorLocIdBqEvent = @(errorLocId)
  sendErrorBqEvent(getLocTextForLang(errorLocId, "English") ?? errorLocId)

let sendCustomBqEvent = @(tableId, data) eventbus_send("sendBqEvent",
  { tableId, data = addEventTime(data) })

let sendLoadingStageBqEvent = @(stage) eventbus_send("sendBqEvent",
  { tableId = "loading_stages", data = addEventTime(addSystemInfo({ stage }), "commitTime") })

let sendOfferBqEvent = @(event, campaign) send_to_bq_offer(campaign, addEventTime({ event }))


let getTotalBattles = @(stats) (stats?.battles ?? 0) + (stats?.offlineBattles ?? 0)

function needSendNewbieEvent() {
  let statsByCamp = servProfile.get()?.sharedStatsByCampaign ?? {}
  foreach(stats in statsByCamp)
    if (getTotalBattles(stats) > 2)
      return false
  return true
}

function sendNewbieBqEvent(actionId, data = {}) {
  if (!needSendNewbieEvent())
    return

  let campBattles = getTotalBattles(sharedStatsByCampaign.get())
  eventbus_send("sendBqEvent",
    {
      tableId = "gui_events",
      data = addEventTime(data.__merge({
        event = "newbieNavigation"
        id = actionId
        level = campBattles
        gameVersion = get_game_version_str()
      }))
    })
}

let getFirstBattleTutor = @(campaign) !campaign.endswith("_new") ? $"tutorial_{campaign}_1"
  : $"tutorial_{campaign.slice(0, -4)}_1_nc"

function buildRanksString(units, ranks, prefix, notFound) {
  local minR = null
  local maxR = null
  foreach (u in units)
    if (u not in ranks)
      notFound.append(u)
    else {
      let r = ranks[u]
      minR = min(r, minR ?? r)
      maxR = max(r, maxR ?? r)
    }
  return minR == null ? ""
    : minR == maxR ? $"{prefix}{minR}"
    : $"{prefix}{minR}-{maxR}"
}

function mkBqUnitsString(units, campaign) {
  if (units.len() <= 5)
    return ";".join((clone units).sort())

  local notFound = []
  let resArr = [buildRanksString(units, allUnitsRanks.get()?[campaign] ?? {}, campaign, notFound)]
  foreach(camp, ranks in allUnitsRanks.get()) {
    if (notFound.len() == 0)
      break
    let list = notFound
    notFound = []
    resArr.append(buildRanksString(list, ranks, camp, notFound))
  }
  return ";".join(resArr.filter(@(t) t != "").sort())
}


















function sendLoadingAddonsBqEvent(action, addons = null, units = null, data = {}) {
  let campaign = curCampaign.get()
  let { lastReceivedFirstBattlesRewardIds = {} } = campProfile.get()
  local firstBattleRewards = lastReceivedFirstBattlesRewardIds?[campaign]
  if (firstBattleRewards == null)
    firstBattleRewards = (receivedMissionRewards.get()?[getFirstBattleTutor(campaign)] ?? 0) == 0 ? -1 : 0
  else
    firstBattleRewards++

  local hasOtherCampaignProgress = null != lastReceivedFirstBattlesRewardIds.findvalue(@(v, c) c != campaign && v >= 0)

  let params = data.__merge({ action, campaign, firstBattleRewards, hasOtherCampaignProgress,
    platform = get_platform_string_id(),
    connectionStatus = connectionStatus.get(),
    allowLimitedConnectionDownload = allowLimitedDownload.get(),
    addonsInProgress = downloadInProgress.get()?.addons != null
      ? ";".join(downloadInProgress.get()?.addons.keys().sort() ?? [])
      : mkBqUnitsString(downloadInProgress.get()?.units.keys() ?? [], campaign)
  })
  if (addons != null) {
    params.addons <- ";".join((clone addons).sort())
    params.isSameAddonsDownloading <- isEqual(downloadInProgress.get()?.addons, addons.reduce(@(res, v) res.$rawset(v, true), {}))
  }
  if (units != null) {
    params.units <- mkBqUnitsString(units, campaign)
    params.isSameAddonsDownloading <- (params?.isSameAddonsDownloading ?? false)
      || isEqual(downloadInProgress.get()?.units, units.reduce(@(res, v) res.$rawset(v, true), {}))
  }
  eventbus_send("sendBqEvent", { tableId = "loading_addons_1", data = addEventTime(params) })
}

return {
  sendUiBqEvent
  sendErrorBqEvent
  sendErrorLocIdBqEvent
  sendCustomBqEvent
  sendOfferBqEvent
  sendNewbieBqEvent
  sendLoadingStageBqEvent
  sendSettingChangeBqEvent
  sendLoadingAddonsBqEvent
}