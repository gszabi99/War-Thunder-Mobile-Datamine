from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/config/rewardStatsPresentation.nut" import hasStatsImage
from "%appGlobals/currenciesState.nut" import balance
from "%appGlobals/pServer/bqClient.nut" import sendCustomBqEvent
from "%rGui/unlocks/unlocksConst.nut" import EVENT_TAB, PERSONAL_TAB
from "%rGui/unlocks/userstat.nut" import userstatStatsTables














let getCommonData = @(unlock) { eventType = unlock?.tabId }.__merge(
  unlock?.tabId == EVENT_TAB ? { season = userstatStatsTables.get()?.stats.season["$index"] ?? 0 } : {},
  unlock?.meta.event_id != null ? { eventId = unlock.meta.event_id } : {}
)

function sendBqQuestsTask(unlock, starsTotal, warbondDelta, currencyId) {
  let data = getCommonData(unlock).__merge({
    action = "complete_task"
    taskId = unlock.name
    stage = unlock?.sectionId ?? ""
    starsDelta = unlock.stages[0]?.updStats.findvalue(@(v) hasStatsImage(v.name, v.mode)).value.tointeger() ?? 0
    starsTotal
    warbondDelta
    warbondTotal = balance.get()?[currencyId]
  })
  sendCustomBqEvent("event_progress_1", data)
}

function sendBqQuestsStage(unlock, starsTotal, warbondDelta, currencyId) {
  let data = getCommonData(unlock).__merge({
    action = "compete_stage"
    stage = "".concat("stage_", unlock.stage)
    starsTotal
    warbondDelta
    warbondTotal = balance.get()?[currencyId]
  })
  sendCustomBqEvent("event_progress_1", data)
}

function sendBqQuestsSpeedUp(unlock, starsTotal) {
  let data = getCommonData(unlock).__merge({
    action = "progress_by_ads"
    taskId = unlock.name
    stage = unlock?.sectionId ?? ""
    starsTotal
  })
  sendCustomBqEvent("event_progress_1", data)
}

let getCommonPersonalTaskData = @(unlockOrName) {
  taskId = unlockOrName?.name ?? unlockOrName
  stage = PERSONAL_TAB
  eventType = PERSONAL_TAB
  starsDelta = unlockOrName?.stages[0].updStats.findvalue(@(v) hasStatsImage(v.name, v.mode)).value.tointeger() ?? 0
}

function sendBqQuestsReceiveTask(unlockOrName) {
  let data = getCommonPersonalTaskData(unlockOrName).__merge({ action = "receive_task" })
  sendCustomBqEvent("event_progress_1", data)
}

function sendBqQuestsRerollTask(unlockOrName) {
  let data = getCommonPersonalTaskData(unlockOrName).__merge({ action = "reroll_task" })
  sendCustomBqEvent("event_progress_1", data)
}

return {
  sendBqQuestsTask
  sendBqQuestsStage
  sendBqQuestsSpeedUp
  sendBqQuestsReceiveTask
  sendBqQuestsRerollTask
}
