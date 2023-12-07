from "%globalsDarg/darg_library.nut" import *
let { sendCustomBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { EVENT_TAB, curSectionId, progressUnlock, PROGRESS_STAT } = require("questsState.nut")
let { userstatStats } = require("%rGui/unlocks/userstat.nut")
let { balanceWarbond } = require("%appGlobals/currenciesState.nut")

/*
UI BQ event "event_progress" format:
  action [string] ("complete_task", "compete_stage", "progress_by_ads")
  eventType [string] - tabId
  stage [string] - day_N for quests, stage_N for event_progress bar
  taskId [string] - quest id (null for event_progress bar)
  starsDelta [int] - PROGRESS_STAT change
  starsTotal [int] - players's amount of PROGRESS_STAT
  warbondDelta [int] - warbonds change
  warbondTotal [int] - warbonds total
*/

let getCommonData = @(unlock) {
  eventType = unlock.tabId
  starsTotal = progressUnlock.value?.current ?? 0
  warbondTotal  = balanceWarbond.value
}.__merge(unlock.tabId == EVENT_TAB ? { season = userstatStats.value?.stats.season["$index"] ?? 1 } : {})

let function sendBqQuestsTask(unlock, warbondDelta) {
  let data = getCommonData(unlock).__merge({
    action = "complete_task"
    taskId = unlock.name
    stage = curSectionId.value
    starsDelta = unlock.stages[0]?.updStats.findvalue(@(v) v.name == PROGRESS_STAT).value.tointeger() ?? 0
    warbondDelta
  })
  sendCustomBqEvent("event_progress_1", data)
}

let function sendBqQuestsStage(unlock, warbondDelta) {
  let data = getCommonData(unlock).__merge({
    action = "compete_stage"
    stage = "".concat("stage_", unlock.stage)
    warbondDelta
  })
  sendCustomBqEvent("event_progress_1", data)
}

let function sendBqQuestsSpeedUp(unlock) {
  let data = getCommonData(unlock).__merge({
    action = "progress_by_ads"
    taskId = unlock.name
    stage = curSectionId.value
  })
  sendCustomBqEvent("event_progress_1", data)
}

return {
  sendBqQuestsTask
  sendBqQuestsStage
  sendBqQuestsSpeedUp
}
