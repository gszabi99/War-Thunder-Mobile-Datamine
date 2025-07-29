from "%globalsDarg/darg_library.nut" import *
let { APP_ID } = require("app")
let { setInterval, clearTimer, deferOnce } = require("dagor.workcycle")
let { register_command } = require("console")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { curLbData, curLbSelfRow, setLbRequestData, curLbErrName,
  refreshLbData, requestSelfRow, isLbRequestInProgress
} = require("lbStateBase.nut")
let { lbCfgById } = require("lbConfig.nut")
let { lbPageRows } = require("lbStyle.nut")
let { userstatStats, seasonIntervals } = require("%rGui/unlocks/userstat.nut")


const REFRESH_PERIOD = 10.0
const MAX_PAGE_PLACE = 1000

let curLbId = mkWatched(persist, "curLbId", null)
let lbPage = mkWatched(persist, "lbPage", 0)
let isLbWndOpened = mkWatched(persist, "isLbWndOpened", false)
let isLbBestBattlesOpened = mkWatched(persist, "isLbBestBattlesOpened", false)
let isRefreshLbEnabled = mkWatched(persist, "isRefreshLbEnabled", false)

let curLbCfg = Computed(@() lbCfgById?[curLbId.value])
let lbMyPlace = Computed(@() (curLbSelfRow.get()?.idx ?? -2) + 1)
let lbMyPage = Computed(@() lbMyPlace.value < 0 ? -1 : (lbMyPlace.value - 1) / lbPageRows)
let lbTotalPlaces = Computed(function() {
  if (curLbData.get() == null)
    return -1
  return curLbData.get().findvalue(@(val) "$" in val)?["$"].total ?? 0
})
let lbLastPage = Computed(function() {
  if (curLbData.get() == null)
    return -1
  let total = lbTotalPlaces.value
  let lastPage = total > 0 ? (min(total, MAX_PAGE_PLACE) - 1) / lbPageRows : lbPage.value
  return lastPage
})

let requestDataInternal = keepref(Computed(function() {
  let { lbTable = null, sortBy = null, gameMode = "" } = curLbCfg.value
  if (lbTable == null || sortBy == null || !isLoggedIn.value)
    return null

  let curSeasonIntervals = seasonIntervals.get()?[lbTable] ?? {}
  let { prevInterval = null, interval = null } = curSeasonIntervals

  let isCurSeasonActive = interval?.isActive ?? false
  let newData =  {
    appid = APP_ID
    table = lbTable
    gameMode
    category = sortBy.field
    count = lbPageRows
    start = lbPage.value * lbPageRows
    resolveNick = 1
    group = ""
    tableIndex = isCurSeasonActive ? interval.index
      : prevInterval != null ? prevInterval.index
      : 0
  }
  return newData
}))

setLbRequestData(requestDataInternal.value)
requestDataInternal.subscribe(function(v) {
  setLbRequestData(v)
  if (isRefreshLbEnabled.value)
    deferOnce(refreshLbData)
})

curLbCfg.subscribe(@(_) lbPage(0))

curLbData.subscribe(function(v) {
  if (v != null && lbMyPlace.value == -1)
    requestSelfRow()
})

function updateRefreshTimer() {
  clearTimer(refreshLbData)
  if (isRefreshLbEnabled.value) {
    refreshLbData()
    setInterval(REFRESH_PERIOD, refreshLbData)
  }
}
updateRefreshTimer()
isRefreshLbEnabled.subscribe(@(_) updateRefreshTimer())

let ratingBattlesCount = Computed(@()
  userstatStats.value?.stats[curLbCfg.value?.lbTable].ratingSessions ?? -1)
let minRatingBattles = Watched(5) 
let bestBattles = Computed(@()
  userstatStats.value?.stats[curLbCfg.value?.lbTable]["$sessions"])
let bestBattlesCount = Computed(@() bestBattles.value?.len() ?? 0)
let hasBestBattles = Computed(@() ratingBattlesCount.value > 0 && bestBattlesCount.value > 0)

register_command(@() lbPage(lbPage.value + 1), "lb.page_next")
register_command(@() lbPage.value > 0 && lbPage(lbPage.value - 1), "lb.page_prev")
register_command(@() isLbWndOpened(true), "lb.open")

return {
  isLbWndOpened
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
  lbLastPage
  lbTotalPlaces

  ratingBattlesCount
  minRatingBattles
  bestBattlesCount
  bestBattles
  hasBestBattles

  isRefreshLbEnabled
  openLbWnd = @() isLbWndOpened(true)
}