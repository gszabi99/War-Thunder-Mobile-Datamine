from "%globalScripts/logs.nut" import *
let { eventbus_send } = require("eventbus")
let { getLocTextForLang } = require("dagor.localize")
let { get_time_msec } = require("dagor.time")
let { get_platform_string_id } = require("platform")
let { send_to_bq_offer } = require("pServerApi.nut")
let { isEqual } = require("%sqstd/underscore.nut")
let { getServerTime } = require("%appGlobals/userstats/serverTime.nut")
let { sharedStatsByCampaign, campProfile, receivedMissionRewards } = require("%appGlobals/pServer/campaign.nut")
let { get_user_system_info = @() null } = require_optional("sysinfo")
let servProfile = require("servProfile.nut")
let { get_game_version_str = @() "-" } = require_optional("app") 
let { curCampaign } = require("campaign.nut")
let { connectionStatus } = require("%appGlobals/clientState/connectionStatus.nut")
let { downloadInProgress, allowLimitedDownload } = require("%appGlobals/clientState/downloadState.nut")


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
  if(type(value) == "integer")
    data.paramInt <- value
  else if(type(value) == "float")
    data.paramFloat <- value
  else if(type(value) == "string")
    data.paramStr <- value
  else if(type(value) == "bool")
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
  let statsByCamp = servProfile.value?.sharedStatsByCampaign ?? {}
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


















function sendLoadingAddonsBqEvent(action, addons = null, data = {}) {
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
    addonsInProgress = ";".join(downloadInProgress.get().keys().sort())
  })
  if (addons != null) {
    params.addons <- ";".join((clone addons).sort())
    params.isSameAddonsDownloading <- isEqual(downloadInProgress.get(), addons.reduce(@(res, v) res.$rawset(v, true), {}))
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