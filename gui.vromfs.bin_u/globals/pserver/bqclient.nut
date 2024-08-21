from "%globalScripts/logs.nut" import *
let { eventbus_send } = require("eventbus")
let { getLocTextForLang } = require("dagor.localize")
let { send_to_bq_offer } = require("pServerApi.nut")
let { getServerTime } = require("%appGlobals/userstats/serverTime.nut")
let { sharedStatsByCampaign } = require("%appGlobals/pServer/campaign.nut")
let { get_user_system_info = @() null } = require_optional("sysinfo")
let servProfile = require("servProfile.nut")
let { get_game_version_str = @() "-" } = require_optional("app") //updater does not have module app

function addEventTime(data, key = "eventTime") {
  let time = getServerTime()
  return time > 0 ? data.__merge({ [key] = time }) : data
}

function addSystemInfo(data) {
  let { platform = "", uuid0 = "" } = get_user_system_info()
  return data.__merge({ platform, systemId = uuid0 })
}

let sendUiBqEvent = @(event, data = {}) eventbus_send("sendBqEvent",
  { tableId = "gui_events", data = addEventTime(data.__merge({ event, gameVersion = get_game_version_str() })) })

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

  let campBattles = getTotalBattles(sharedStatsByCampaign.value)
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

return {
  sendUiBqEvent
  sendErrorBqEvent
  sendErrorLocIdBqEvent
  sendCustomBqEvent
  sendOfferBqEvent
  sendNewbieBqEvent
  sendLoadingStageBqEvent
  sendSettingChangeBqEvent
}