from "%globalsDarg/darg_library.nut" import *
let { sendCustomBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { EVENT_TAB, progressUnlockByTab, progressUnlockBySection } = require("%rGui/quests/questsState.nut")
let { userstatStatsTables } = require("%rGui/unlocks/userstat.nut")
let { balance } = require("%appGlobals/currenciesState.nut")
let { hasStatsImage } = require("%appGlobals/config/rewardStatsPresentation.nut")













let getCommonData = @(unlock) {
  eventType = unlock?.tabId
  starsTotal = (progressUnlockByTab.get()?[unlock?.tabId]
      ?? progressUnlockBySection.get()?[unlock?.sectionId]
    )?.current ?? 0
}.__merge(
  unlock?.tabId == EVENT_TAB ? { season = userstatStatsTables.get()?.stats.season["$index"] ?? 0 } : {},
  unlock?.meta.event_id != null ? { eventId = unlock.meta.event_id } : {}
)

function sendBqQuestsTask(unlock, warbondDelta, currencyId) {
  let data = getCommonData(unlock).__merge({
    action = "complete_task"
    taskId = unlock.name
    stage = unlock?.sectionId ?? ""
    starsDelta = unlock.stages[0]?.updStats.findvalue(@(v) hasStatsImage(v.name, v.mode)).value.tointeger() ?? 0
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
