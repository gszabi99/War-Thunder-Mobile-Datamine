let { send } = require("eventbus")
let { getLocTextForLang } = require("dagor.localize")
let { send_to_bq_offer } = require("pServerApi.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { sharedStatsByCampaign } = require("%appGlobals/pServer/campaign.nut")
let { get_user_system_info = @() null } = require_optional("sysinfo")
let servProfile = require("servProfile.nut")

let addEventTime = @(data, key = "eventTime") serverTime.value > 0 ? data.__merge({ [key] = serverTime.value })
  : data //when eventTime not set, profile server will add it by self

let function addSystemInfo(data) {
  let { platform = "", uuid0 = "" } = get_user_system_info()
  return data.__merge({ platform, systemId = uuid0 })
}

let sendUiBqEvent = @(event, data = {}) send("sendBqEvent",
  { tableId = "gui_events", data = addEventTime(data.__merge({ event })) })

let sendErrorBqEvent = @(errorStr, data = {}) send("sendBqEvent",
  { tableId = "gui_events", data = addEventTime(data.__merge({ event = "error", id = errorStr })) })

let sendErrorLocIdBqEvent = @(errorLocId)
  sendErrorBqEvent(getLocTextForLang(errorLocId, "English") ?? errorLocId)

let sendCustomBqEvent = @(tableId, data) send("sendBqEvent",
  { tableId, data = addEventTime(data) })

let sendLoadingStageBqEvent = @(stage) send("sendBqEvent",
  { tableId = "loading_stages", data = addEventTime(addSystemInfo({ stage }), "commitTime") })

let sendOfferBqEvent = @(event, campaign) send_to_bq_offer(campaign, addEventTime({ event }))


let getTotalBattles = @(stats) (stats?.battles ?? 0) + (stats?.offlineBattles ?? 0)

let function needSendNewbieEvent() {
  let statsByCamp = servProfile.value?.sharedStatsByCampaign ?? {}
  foreach(stats in statsByCamp)
    if (getTotalBattles(stats) > 2)
      return false
  return true
}

let function sendNewbieBqEvent(actionId, data = {}) {
  if (!needSendNewbieEvent())
    return

  let campBattles = getTotalBattles(sharedStatsByCampaign.value)
  send("sendBqEvent",
    { tableId = "gui_events",
      data = addEventTime(data.__merge({ event = "newbieNavigation", id = actionId, level = campBattles })) })
}

return {
  sendUiBqEvent
  sendErrorBqEvent
  sendErrorLocIdBqEvent
  sendCustomBqEvent
  sendOfferBqEvent
  sendNewbieBqEvent
  sendLoadingStageBqEvent
}