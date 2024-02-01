from "%globalsDarg/darg_library.nut" import *
let { eventbus_subscribe } = require("eventbus")
let { sendUiBqEvent } = require("%appGlobals/pServer/bqClient.nut")

eventbus_subscribe("bigQueryAddMissionRecord", function(data) {
  log($"[MISSION_BQ] {data?.event}")
  sendUiBqEvent("mission", data.__merge({
    id = data?.event
  }))
})
