from "%globalsDarg/darg_library.nut" import *
let { sendCustomBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { EVENT_TAB, progressUnlockByTab, progressUnlockBySection } = require("questsState.nut")
let { userstatStats } = require("%rGui/unlocks/userstat.nut")
let { balanceWarbond } = require("%appGlobals/currenciesState.nut")
let { statsImages } = require("%appGlobals/config/rewardStatsPresentation.nut")

/*
UI BQ event "event_progress" format:
  action [string] ("complete_task", "compete_stage", "progress_by_ads")
  eventType [string] - tabId
  stage [string] - day_N for quests, stage_N for event_progress bar
  taskId [string] - quest id (null for event_progress bar)
  starsDelta [int] - reward stats change
  starsTotal [int] - players's amount of progress stat (reward stats)
  warbondDelta [int] - warbonds change
  warbondTotal [int] - warbonds total
*/

let getCommonData = @(unlock) {
  eventType = unlock.tabId
  starsTotal = (progressUnlockByTab.get()?[unlock.tabId]
      ?? progressUnlockBySection.get()?[unlock?.sectionId]
    )?.current ?? 0
  warbondTotal  = balanceWarbond.value
}.__merge(unlock.tabId == EVENT_TAB ? { season = userstatStats.value?.stats.season["$index"] ?? 1 } : {})

let function sendBqQuestsTask(unlock, warbondDelta) {
  let data = getCommonData(unlock).__merge({
    action = "complete_task"
    taskId = unlock.name
    stage = unlock?.sectionId ?? ""
    starsDelta = unlock.stages[0]?.updStats.findvalue(@(v) v.name in statsImages).value.tointeger() ?? 0
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
    stage = unlock?.sectionId ?? ""
  })
  sendCustomBqEvent("event_progress_1", data)
}

return {
  sendBqQuestsTask
  sendBqQuestsStage
  sendBqQuestsSpeedUp
}
