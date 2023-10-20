from "%globalsDarg/darg_library.nut" import *
let { subscribe, send } = require("eventbus")

let debriefingData = mkWatched(persist, "debriefingData", null)
let isDebriefingAnimFinished = Watched(true)
let isNoExtraScenesAfterDebriefing = mkWatched(persist, "isNoExtraScenesAfterDebriefing", false)

let DEBR_TAB_SCORES   = "scores"
let DEBR_TAB_CAMPAIGN = "camaign"
let DEBR_TAB_UNIT     = "unit"
let DEBR_TAB_MPSTATS  = "mpstats"

let curDebrTabId = mkWatched(persist, "curDebrTabId", DEBR_TAB_SCORES)

subscribe("BattleResult", @(res) debriefingData.set(res))
send("RequestBattleResult", {})

return {
  debriefingData
  isDebriefingAnimFinished
  isNoExtraScenesAfterDebriefing

  curDebrTabId
  DEBR_TAB_SCORES
  DEBR_TAB_CAMPAIGN
  DEBR_TAB_UNIT
  DEBR_TAB_MPSTATS
}