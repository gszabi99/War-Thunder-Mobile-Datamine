from "%globalsDarg/darg_library.nut" import *
let { sendCustomBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { EVENT_TAB, progressUnlockByTab, progressUnlockBySection } = require("questsState.nut")
let { userstatStats } = require("%rGui/unlocks/userstat.nut")
let { balance } = require("%appGlobals/currenciesState.nut")
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
}.__merge(unlock.tabId == EVENT_TAB ? { season = userstatStats.value?.stats.season["$index"] ?? 1 } : {})

function sendBqQuestsTask(unlock, warbondDelta, currencyId) {
  let data = getCommonData(unlock).__merge({
    action = "complete_task"
    taskId = unlock.name
    stage = unlock?.sectionId ?? ""
    starsDelta = unlock.stages[0]?.updStats.findvalue(@(v) v.name in statsImages).value.tointeger() ?? 0
    warbondDelta
    warbondTotal = balance.get()?[currencyId]
  })
  sendCustomBqEvent("event_progress_1", data)
}

function sendBqQuestsStage(unlock, warbondDelta, currencyId) {
  let data = getCommonData(unlock).__merge({
    action = "compete_stage"
    stage = "".concat("stage_", unlock.stage)
    warbondDelta
    warbondTotal = balance.get()?[currencyId]
  })
  sendCustomBqEvent("event_progress_1", data)
}

function sendBqQuestsSpeedUp(unlock) {
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
