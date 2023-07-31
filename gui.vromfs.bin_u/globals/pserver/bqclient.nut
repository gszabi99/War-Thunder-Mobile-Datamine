//checked for explicitness
#no-root-fallback
#explicit-this
let { send } = require("eventbus")
let { send_to_bq_offer } = require("pServerApi.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")

let addEventTime = @(data) serverTime.value > 0 ? data.__merge({ eventTime = serverTime.value })
  : data //when eventTime not set, profile server will add it by self


let sendUiBqEvent = @(event, data = {}) send("sendBqEvent",
  { tableId = "gui_events", data = addEventTime(data.__merge({ event })) })

let sendCustomBqEvent = @(tableId, data) send("sendBqEvent",
  { tableId, data = addEventTime(data) })

let sendOfferBqEvent = @(event, campaign) send_to_bq_offer(campaign, addEventTime({ event }))

return {
  sendUiBqEvent
  sendCustomBqEvent
  sendOfferBqEvent
}