//checked for explicitness
#no-root-fallback
#explicit-this

let { send_to_bq, send_to_bq_offer } = require("pServerApi.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")

let addEventTime = @(data) serverTime.value > 0 ? data.__merge({ eventTime = serverTime.value })
  : data //when eventTime not set, profile server will add it by self

let sendUiBqEvent = @(event, data = {}) send_to_bq("gui_events",
  addEventTime(data.__merge({ event })))

let sendCustomBqEvent = @(tableId, data) send_to_bq(tableId, addEventTime(data))

let sendOfferBqEvent = @(event, campaign) send_to_bq_offer(campaign, addEventTime({ event }))

return {
  sendUiBqEvent
  sendCustomBqEvent
  sendOfferBqEvent
}