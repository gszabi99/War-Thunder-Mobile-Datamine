from "%globalsDarg/darg_library.nut" import *
let { eventbus_subscribe, eventbus_send } = require("eventbus")
let { defer, resetTimeout, clearTimer } = require("dagor.workcycle")
let { isInDebriefing } = require("%appGlobals/clientState/clientState.nut")
let { buttonsShowTime } = require("%rGui/debriefing/debriefingWndConsts.nut")

let debriefingData = mkWatched(persist, "debriefingData", null)
let isDebriefingAnimFinished = Watched(true)
let isNoExtraScenesAfterDebriefing = mkWatched(persist, "isNoExtraScenesAfterDebriefing", false)

eventbus_subscribe("BattleResult", @(res) debriefingData.set(res))
eventbus_send("RequestBattleResult", {})

let DEBR_TAB_MPSTATS  = 1
let DEBR_TAB_CAMPAIGN = 2
let DEBR_TAB_UNIT     = 3
let DEBR_TAB_SCORES   = 4

let curDebrTabId = mkWatched(persist, "curDebrTabId", DEBR_TAB_MPSTATS)

let debrTabsShowTime = Watched([])
let needReinitScene = Watched(true)

let nextDebrTabId = Computed(function() {
  let list = debrTabsShowTime.get()
  let curIdx = list.findindex(@(v) v.id == curDebrTabId.get())
  return curIdx != null ? list?[curIdx + 1].id : null
})

let stopDebriefingAnimation = @() isDebriefingAnimFinished.set(true)

let maxDebrAnimTime = 20 

let getBtnsDelayForTab = @(tabId, isAnimFinished, curTabId, tabsShowTime) isAnimFinished || tabId < curTabId ? 0
  : tabId == curTabId ? max(0, (tabsShowTime.findvalue(@(v) v.id == tabId)?.timeShow ?? 0) - buttonsShowTime)
  : maxDebrAnimTime

let getFinalTabId = @(tabsShowTime) tabsShowTime?[tabsShowTime.len() - 1].id

let delayToDebrAnimFinish = keepref(Computed(function() {
  if (isDebriefingAnimFinished.get())
    return 0
  let idx = debrTabsShowTime.get().findindex(@(v) v.id == curDebrTabId.get())
  if (idx == null)
    return 0
  local res = 0
  let tabsShowTime = debrTabsShowTime.get()
  for (local i = idx; i < tabsShowTime.len(); i++) 
    res += tabsShowTime[i].timeShow
  return res
}))
delayToDebrAnimFinish.subscribe(@(v) v <= 0
  ? defer(stopDebriefingAnimation)
  : resetTimeout(v, stopDebriefingAnimation)
)
isInDebriefing.subscribe(@(v) v ? null : clearTimer(stopDebriefingAnimation))

let delayToBtns_Campaign = keepref(Computed(@() getBtnsDelayForTab(DEBR_TAB_CAMPAIGN,
  isDebriefingAnimFinished.get(), curDebrTabId.get(), debrTabsShowTime.get())))
let delayToBtns_Unit = keepref(Computed(@() getBtnsDelayForTab(DEBR_TAB_UNIT,
  isDebriefingAnimFinished.get(), curDebrTabId.get(), debrTabsShowTime.get())))
let delayToBtns_Final = keepref(Computed(@() getBtnsDelayForTab(getFinalTabId(debrTabsShowTime.get()),
  isDebriefingAnimFinished.get(), curDebrTabId.get(), debrTabsShowTime.get())))

let needShowBtns_Campaign = Watched(true)
let needShowBtns_Unit = Watched(true)
let needShowBtns_Final = Watched(true)
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
isInDebriefing.subscribe(function(v) {
  if (!v) {
    clearTimer(showBtns_Campaign)
    clearTimer(showBtns_Unit)
    clearTimer(showBtns_Final)
  }
})
isDebriefingAnimFinished.subscribe(@(v) !v ? needReinitScene.set(false) : null)

return {
  debriefingData
  isDebriefingAnimFinished
  isNoExtraScenesAfterDebriefing

  curDebrTabId
  nextDebrTabId
  DEBR_TAB_SCORES
  DEBR_TAB_CAMPAIGN
  DEBR_TAB_UNIT
  DEBR_TAB_MPSTATS

  stopDebriefingAnimation

  debrTabsShowTime
  needShowBtns_Campaign
  needShowBtns_Unit
  needShowBtns_Final
  needReinitScene
}