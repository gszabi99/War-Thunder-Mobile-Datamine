from "%globalsDarg/darg_library.nut" import *
from "eventbus" import eventbus_subscribe
from "%appGlobals/pServer/bqClient.nut" import sendUiBqEvent


eventbus_subscribe("bigQueryAddMissionRecord", function(data) {
  log($"[MISSION_BQ] {data?.event}")
  sendUiBqEvent("mission", data.__merge({
    id = data?.event
  }))
})
