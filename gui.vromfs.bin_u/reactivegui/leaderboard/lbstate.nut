from "%globalsDarg/darg_library.nut" import *
from "app" import APP_ID
from "console" import register_command
from "dagor.workcycle" import setInterval, clearTimer, deferOnce
from "%appGlobals/loginState.nut" import isLoggedIn
from "%rGui/event/eventState.nut" import isEventActive
from "%rGui/leaderboard/lbConfig.nut" import lbCfgById
from "%rGui/leaderboard/lbStateBase.nut" import curLbData, curLbSelfRow, setLbRequestData, curLbErrName,
  refreshLbData, requestSelfRow, isLbRequestInProgress
from "%rGui/leaderboard/lbStyle.nut" import lbPageRows
from "%rGui/unlocks/userstat.nut" import userstatStats, mkSeasonInterval


const REFRESH_PERIOD = 10.0
const MAX_PAGE_PLACE = 1000

let curLbId = mkWatched(persist, "curLbId", null)
let lbPage = mkWatched(persist, "lbPage", 0)
let isLbBestBattlesOpened = mkWatched(persist, "isLbBestBattlesOpened", false)
let isRefreshLbEnabled = mkWatched(persist, "isRefreshLbEnabled", false)

let curLbCfg = Computed(@() lbCfgById?[curLbId.get()])
let lbMyPlace = Computed(@() (curLbSelfRow.get()?.idx ?? -2) + 1)
let dbgMyPage = Watched(null)
let lbMyPage = Computed(@() dbgMyPage.get()
  ?? (lbMyPlace.get() <= 0 ? -1 : (lbMyPlace.get() - 1) / lbPageRows))
let lbTotalPlaces = Computed(function() {
  if (curLbData.get() == null)
    return -1
  return curLbData.get().findvalue(@(val) "$" in val)?["$"].total ?? 0
})
let dbgLastPage = Watched(null)
let isDbgFakePages  = Computed(@() dbgLastPage.get() != null)
let realLastPage = Computed(function(prev) {
  if (curLbData.get() == null)
    return prev == FRP_INITIAL ? -1 : prev
  let total = lbTotalPlaces.get()
  let lastPage = total > 0 ? (min(total, MAX_PAGE_PLACE) - 1) / lbPageRows : lbPage.get()
  return lastPage
})
let lbLastPage = Computed(@() dbgLastPage.get() ?? realLastPage.get())

let lbPaginatorLastPage = Computed(function() {
  let last = lbLastPage.get()
  return last < 0 ? last : max(min(lbMyPage.get(), last), min(last, lbPage.get() + 1))
})

let curLbSeasonInterval = mkSeasonInterval(Computed(@() curLbCfg.get()?.lbTable))

let requestDataInternal = keepref(Computed(function() {
  let { lbTable = null, sortBy = null, gameMode = "" } = curLbCfg.get()
  if (lbTable == null || sortBy == null || !isLoggedIn.get())
    return null

  let { prevInterval = null, interval = null } = curLbSeasonInterval.get()

  let isCurSeasonActive = interval?.isActive ?? false
  let newData =  {
    appid = APP_ID
    table = lbTable
    gameMode
    category = sortBy.field
    count = lbPageRows
    start = lbPage.get() * lbPageRows
    resolveNick = 1
    group = ""
    tableIndex = isCurSeasonActive ? interval.index
      : prevInterval != null ? prevInterval.index
      : 0
  }
  return newData
}))

setLbRequestData(requestDataInternal.get())
requestDataInternal.subscribe(function(v) {
  setLbRequestData(v)
  if (isRefreshLbEnabled.get())
    deferOnce(refreshLbData)
})

curLbCfg.subscribe(@(_) lbPage.set(0))

curLbData.subscribe(function(v) {
  if (v != null && lbMyPlace.get() == -1)
    requestSelfRow()
})

function updateRefreshTimer() {
  clearTimer(refreshLbData)
  if (isRefreshLbEnabled.get()) {
    refreshLbData()
    setInterval(REFRESH_PERIOD, refreshLbData)
  }
}
updateRefreshTimer()
isRefreshLbEnabled.subscribe(@(_) updateRefreshTimer())

let ratingBattlesCount = Computed(@()
  userstatStats.get()?.stats[curLbCfg.get()?.lbTable].ratingSessions ?? -1)
let minRatingBattles = Watched(5) 
let bestBattles = Computed(@()
  userstatStats.get()?.stats[curLbCfg.get()?.lbTable]["$sessions"])
let bestBattlesCount = Computed(@() bestBattles.get()?.len() ?? 0)
let hasBestBattles = Computed(@() ratingBattlesCount.get() > 0 && bestBattlesCount.get() > 0)

isEventActive.subscribe(@(isActive) isActive ? null : isLbBestBattlesOpened.set(false))

register_command(@() lbPage.set(lbPage.get() + 1), "lb.page_next")
register_command(@() lbPage.get() > 0 && lbPage.set(lbPage.get() - 1), "lb.page_prev")



register_command(function(count, myPage, curPage) {
  dbgLastPage.set(count > 0 ? count - 1 : null)
  dbgMyPage.set(count > 0 ? max(myPage - 1, -1) : null)
  lbPage.set(count > 0 ? max(curPage - 1, 0) : 0)
}, "lb.paginator_fake_pages")

return {
  isLbBestBattlesOpened
  isLbRequestInProgress
  curLbId
  curLbCfg
  curLbData
  curLbSelfRow
  curLbErrName
  lbPage
  lbMyPlace
  lbMyPage
  lbPaginatorLastPage
  isDbgFakePages
  lbTotalPlaces

  ratingBattlesCount
  minRatingBattles
  bestBattlesCount
  bestBattles
  hasBestBattles

  isRefreshLbEnabled
}