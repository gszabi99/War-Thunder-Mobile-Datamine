from "%globalsDarg/darg_library.nut" import *
let { get_time_msec } = require("dagor.time")
let { eventbus_subscribe, eventbus_send } = require("eventbus")
let { resetTimeout } = require("dagor.workcycle")
let { buttonsShowTime } = require("%rGui/debriefing/debriefingWndConsts.nut")

let debriefingData = mkWatched(persist, "debriefingData", null)
let isDebriefingAnimFinished = Watched(true)
let isNoExtraScenesAfterDebriefing = mkWatched(persist, "isNoExtraScenesAfterDebriefing", false)

eventbus_subscribe("BattleResult", @(res) debriefingData.set(res))
eventbus_send("RequestBattleResult", {})

let DEBR_TAB_MPSTATS  = 1
let DEBR_TAB_QUESTS   = 2
let DEBR_TAB_CAMPAIGN = 3
let DEBR_TAB_UNIT     = 4
let DEBR_TAB_SCORES   = 5

let curDebrTabId = mkWatched(persist, "curDebrTabId", DEBR_TAB_MPSTATS)

let debrTabsShowTime = Watched([])
let needReinitScene = Watched(true)
let showReleaseToContinueBtn = Watched(false)

let nextDebrTabId = Computed(function() {
  let list = debrTabsShowTime.get()
  let curIdx = list.findindex(@(v) v.id == curDebrTabId.get())
  return curIdx != null ? list?[curIdx + 1].id : null
})

let stopDebriefingAnimation = @() isDebriefingAnimFinished.set(true)

let maxDebrAnimTime = 20 
let maxDelayWithPause = 60
let btnActivationDelay = 300

let finalTabId = Computed(@() debrTabsShowTime.get()?[debrTabsShowTime.get().len() - 1].id ?? DEBR_TAB_SCORES)

let mkBtnsDelayComp = @(tabId = null) Computed(function() {
  let id = tabId ?? finalTabId.get()
  return isDebriefingAnimFinished.get() || id < curDebrTabId.get() ? 1
    : id == curDebrTabId.get() ? max(0, (debrTabsShowTime.get().findvalue(@(v) v.id == id)?.timeShow ?? 0) - buttonsShowTime)
    : showReleaseToContinueBtn.get() ? maxDelayWithPause : maxDebrAnimTime
  }
)

let delayToBtns_Campaign = keepref(mkBtnsDelayComp(DEBR_TAB_CAMPAIGN))
let delayToBtns_Unit = keepref(mkBtnsDelayComp(DEBR_TAB_UNIT))
let delayToBtns_Final = keepref(mkBtnsDelayComp())

let needShowBtns_Campaign = Watched(true)
let needShowBtns_Unit = Watched(true)
let needShowBtns_Final = Watched(true)
let activatingTimeBtns_Campaign = Watched(0)
let activatingTimeBtns_Unit = Watched(0)
let activatingTimeBtns_Final = Watched(0)
needShowBtns_Campaign.subscribe(@(v) activatingTimeBtns_Campaign.set(v ? get_time_msec() + btnActivationDelay : 0))
needShowBtns_Unit.subscribe(@(v) activatingTimeBtns_Unit.set(v ? get_time_msec() + btnActivationDelay : 0))
needShowBtns_Final.subscribe(@(v) activatingTimeBtns_Final.set(v ? get_time_msec() + btnActivationDelay : 0))
isDebriefingAnimFinished.subscribe(function(v) {
  needShowBtns_Campaign.set(v)
  needShowBtns_Unit.set(v)
  needShowBtns_Final.set(v)
})

let showBtns_Campaign = @() needShowBtns_Campaign.set(true)
let showBtns_Unit = @() needShowBtns_Unit.set(true)
let showBtns_Final = @() needShowBtns_Final.set(true)
delayToBtns_Campaign.subscribe(@(v) resetTimeout(v, showBtns_Campaign))
delayToBtns_Unit.subscribe(@(v) resetTimeout(v, showBtns_Unit))
delayToBtns_Final.subscribe(@(v) resetTimeout(v, showBtns_Final))

isDebriefingAnimFinished.subscribe(@(v) !v ? needReinitScene.set(false) : null)

return {
  debriefingData
  isDebriefingAnimFinished
  isNoExtraScenesAfterDebriefing
  showReleaseToContinueBtn

  curDebrTabId
  nextDebrTabId
  DEBR_TAB_MPSTATS
  DEBR_TAB_QUESTS
  DEBR_TAB_CAMPAIGN
  DEBR_TAB_UNIT
  DEBR_TAB_SCORES

  stopDebriefingAnimation

  debrTabsShowTime
  needShowBtns_Campaign
  needShowBtns_Unit
  needShowBtns_Final
  activatingTimeBtns_Campaign
  activatingTimeBtns_Unit
  activatingTimeBtns_Final
  needReinitScene
}