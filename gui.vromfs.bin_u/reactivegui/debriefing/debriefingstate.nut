from "%globalsDarg/darg_library.nut" import *
let { subscribe, send } = require("eventbus")

let debriefingData = mkWatched(persist, "debriefingData", null)
let isDebriefingAnimFinished = Watched(true)

subscribe("BattleResult", @(res) debriefingData(res))
send("RequestBattleResult", {})

return {
  debriefingData
  isDebriefingAnimFinished
}