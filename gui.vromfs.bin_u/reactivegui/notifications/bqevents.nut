from "%globalsDarg/darg_library.nut" import *
let { subscribe } = require("eventbus")
let { sendUiBqEvent } = require("%appGlobals/pServer/bqClient.nut")

subscribe("bigQueryAddMissionRecord", function(data) {
  log($"[MISSION_BQ] {data?.event}")
  sendUiBqEvent("mission", data.__merge({
    id = data?.event
  }))
})
